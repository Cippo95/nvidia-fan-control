#!/bin/bash
# Script: NVIDIA fan control
# Author: Cippo95
# Description: a simple (?) fan control for NVIDIA cards, it works for my setup 
# but probably this kind of simplicity is not good for every system.

# VARIABLES:

# These arrays define the fan curve, they have to be same length! 
temperature_points=(0 60 75 85)
fan_speed_points=(25 25 50 100)

# Sleep interval to have less CPU activity 
sleep_seconds=1

# Temperature hysteresis
temperature_hysteresis=5

# step_down_temperature for fan hysteresis, 0 at the beginning
step_down_temperature=0

# setted_fan_speed rappresents the current fan speed 
# fan_speed won't update always the setted_fan_speed (fan hysteresis)
setted_fan_speed=${fan_speed_points[0]}

# TEST THE VALIDITY OF THE FAN CURVE POINTS: 

# test that fan curve arrays are same length
if [[ ${#temperature_points[@]} -ne ${#fan_speed_points[@]} ]]; then
	echo "ERROR: temperature_points and fan_speed_points are not the same length!"
	exit 1
fi

# test that fan curve arrays have increasing numbers (fan speed can be equal)
for (( i=0; i<${#temperature_points[@]}-1; i++ ));
do
	if [[ ${temperature_points[i]} -ge ${temperature_points[i+1]} ]]; then
		echo "ERROR: temperature_points values are not strictly increasing"
		exit 1
	fi
	if [[ ${fan_speed_points[i]} -gt ${fan_speed_points[i+1]} ]]; then
		echo "ERROR: fan_speed_points values are not increasing"
		exit 1
	fi
done

# INIALIZATION:

# Enable fan control and set minimum fan speed
nvidia-settings -a gpufancontrolstate=1 &>/dev/null
nvidia-settings -a gputargetfanspeed=${fan_speed_points[0]} &>/dev/null

# MAIN LOOP: 

while true
do
	# check temperature: nvidia-smi doesn't cause frame spikes
	temperature=`nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader`
	echo "temperature: $temperature"

	# calculate fanspeed: I need to look for every point
	point=0

	# calculate the temperature_point
	while [ $temperature -ge ${temperature_points[point]} ]
	do
		let "point += 1"
	done
	echo "point: $point"

	# calculate the temperature delta in this temperature range
	let "temperature_delta = temperature_points[point] - temperature_points[point - 1]"
	echo "temperature_delta: $temperature_delta"
	
	# calculate the fan speed delta in this temperature range
	let "fan_speed_delta = fan_speed_points[point] - fan_speed_points[point - 1]"
	echo "fan_speed_delta: $fan_speed_delta"

	# calculate the current temperature increment
	let "temperature_increment = temperature - temperature_points[point - 1]"
	echo "temperature_increment: $temperature_increment"

	# calculate the fan_speed_increment 
	let "fan_speed_increment = fan_speed_delta*temperature_increment/temperature_delta"
	echo "fan_speed_increment: $fan_speed_increment"

	# calculate the fanspeed
	let "fan_speed = fan_speed_points[point - 1] + fan_speed_increment"
	echo "fan_speed: $fan_speed"

	# set fan speed checking hysteresis or higher temperature (higher fan_speed)
	if [[ temperature -lt step_down_temperature || fan_speed -gt setted_fan_speed ]]; then
		# set the fan_speed
		nv-control-fan $fan_speed

		# update setted_fan_speed
		setted_fan_speed=$fan_speed
		echo "setted_fan_speed: $setted_fan_speed"

		# calculate temperature for lowering fan speed
		let "step_down_temperature = temperature - temperature_hysteresis"
		echo "step_down_temperature: $step_down_temperature"

	fi
	echo -e

	# sleep some time before checking temperature again
	sleep $sleep_seconds 
done
