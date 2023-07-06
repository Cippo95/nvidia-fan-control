#!/bin/bash
# Script: NVIDIA fan control
# Author: Cippo95
# Description: a simple fan control for NVIDIA cards, it works for my setup 
# but probably this kind of simplicity is not good for every system.

# FAN CURVE PARAMETERS (YOU CAN EDIT THESE):

# These arrays define the fan curve: they need to be the same length! 
temperature_points=(0 60 75 85)
fan_speed_points=(25 25 50 100)

# Sleep interval to have less CPU activity 
sleep_seconds=1

# Temperature hysteresis needed to lower fan speed
temperature_hysteresis=5

# FAN CURVE PARAMETERS (DON'T EDIT THESE): 

# Effective temperature where the fan speed gets lowered for fan hysteresis
step_down_temperature=0

# Effective fan speed currently setted 
# fan_speed doesn't always update this because of fan speed hysteresis
setted_fan_speed=${fan_speed_points[0]}

# TEST THE VALIDITY OF THE FAN CURVE POINTS: 

# 1. Test that fan curve arrays are the same length
if [[ ${#temperature_points[@]} -ne ${#fan_speed_points[@]} ]]; then
	echo "ERROR: temperature_points and fan_speed_points are not the same length!"
	exit 1
fi

# 2. Test that fan curve arrays have increasing numbers (fan speed can also be equal)
for (( i=0; i<${#temperature_points[@]}-1; i++ ));
do
	if [[ ${temperature_points[i]} -ge ${temperature_points[i+1]} ]]; then
		echo "ERROR: temperature_points values are not strictly increasing!"
		exit 1
	fi
	if [[ ${fan_speed_points[i]} -gt ${fan_speed_points[i+1]} ]]; then
		echo "ERROR: fan_speed_points values are not increasing!"
		exit 1
	fi
done

# FAN CONTROL INITIALIZATION:

# Enable fan control and set minimum fan speed
nvidia-settings -a gpufancontrolstate=1 &>/dev/null
nvidia-settings -a gputargetfanspeed=${fan_speed_points[0]} &>/dev/null

# MAIN LOOP: 

while true
do
	# 1. Check temperature (nvidia-smi doesn't cause frame spikes)
	temperature=`nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader`
	echo "temperature: $temperature"

	# 2. Reset current point 
	point=0

	# 3. Find the point defining the current fan curve range
	while [ $temperature -ge ${temperature_points[point]} ]
	do
		let "point += 1"
	done
	echo "point: $point"

	# 4. Calculate the temperature delta in this fan curve range
	let "temperature_delta = temperature_points[point] - temperature_points[point - 1]"
	echo "temperature_delta: $temperature_delta"
	
	# 5. Calculate the fan speed delta in this fan curve range
	let "fan_speed_delta = fan_speed_points[point] - fan_speed_points[point - 1]"
	echo "fan_speed_delta: $fan_speed_delta"

	# 6. Calculate the current temperature increment (needed for fan_speed_increment)
	let "temperature_increment = temperature - temperature_points[point - 1]"
	echo "temperature_increment: $temperature_increment"

	# 7. Calculate the fan speed increment 
	let "fan_speed_increment = fan_speed_delta*temperature_increment/temperature_delta"
	echo "fan_speed_increment: $fan_speed_increment"

	# 8. Calculate the fan speed
	let "fan_speed = fan_speed_points[point - 1] + fan_speed_increment"
	echo "fan_speed: $fan_speed"

	# 9. Set fan speed checking hysteresis or higher fan speed (higher temperature)
	if [[ temperature -lt step_down_temperature || fan_speed -gt setted_fan_speed ]]; then
		# 9a. Set the fan speed
		nv-control-fan $fan_speed

		# 9b. Update setted_fan_speed to the current one
		setted_fan_speed=$fan_speed
		echo "setted_fan_speed: $setted_fan_speed"

		# 9c. Calculate temperature needed to lower the fan speed
		let "step_down_temperature = temperature - temperature_hysteresis"
		echo "step_down_temperature: $step_down_temperature"
	fi
	echo -e

	# 10. Sleep before checking temperature again
	sleep $sleep_seconds 
done
