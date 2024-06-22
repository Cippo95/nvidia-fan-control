#!/bin/bash
# Script: nvidia-fan-control
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

# previous_temperature, used to check temperature increases
previous_temperature=0

# setted_fan_speed, used to update fan_speed only if needed
setted_fan_speed=${fan_speed_points[0]}

# TEST THE VALIDITY OF THE FAN CURVE POINTS: 

# Test that fan curve arrays are the same length
if [[ ${#temperature_points[@]} -ne ${#fan_speed_points[@]} ]]; then
	echo "ERROR: temperature_points and fan_speed_points are not the same length!"
	exit 1
fi

# Test that fan curve arrays have increasing numbers (fan speed can also be equal)
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
nvidia-settings -a gpufancontrolstate=1
nv-control-fan ${fan_speed_points[0]}

# MAIN LOOP: 

while true
do
	# Check temperature
	temperature=`nv-control-core-temperature`
	echo "temperature: $temperature"
 
        # Check temperature validity or stop the script
        case $temperature in
            ''|*[!0-9]*) exit 1;;
            *) echo "temperature: $temperature";;
        esac
	
	if [[ temperature -lt step_down_temperature || temperature -gt previous_temperature ]]; then
		# Reset current point 
		point=0

		# Find the point defining the current fan curve range
		while [ $temperature -ge ${temperature_points[point]} ]
		do
			let "point += 1"
		done
		echo "point: $point"

		# Save previous point, since it is used multiple times
		let "previous_point = point - 1"
		echo "previous_point: $previous_point"

		# Calculate the temperature delta in this fan curve range
		let "temperature_delta = temperature_points[point] - temperature_points[previous_point]"
		echo "temperature_delta: $temperature_delta"
		
		# Calculate the fan speed delta in this fan curve range
		let "fan_speed_delta = fan_speed_points[point] - fan_speed_points[previous_point]"
		echo "fan_speed_delta: $fan_speed_delta"

		# Calculate the current temperature increment (needed for fan_speed_increment)
		let "temperature_increment = temperature - temperature_points[previous_point]"
		echo "temperature_increment: $temperature_increment"

		# Calculate the fan speed increment 
		let "fan_speed_increment = fan_speed_delta*temperature_increment/temperature_delta"
		echo "fan_speed_increment: $fan_speed_increment"

		# Calculate the fan speed
		let "fan_speed = fan_speed_points[previous_point] + fan_speed_increment"
		echo "fan_speed: $fan_speed"

		# Set the fan speed if different from setted_fan_speed, to avoid an expensive call
		if [[ fan_speed -ne setted_fan_speed ]]; then
			# Set the fan speed
			nv-control-fan $fan_speed

			# Update setted_fan_speed
			setted_fan_speed=$fan_speed
		fi

		# Update previous temperature to current one 
		previous_temperature=$temperature
		echo "previous_temperature: $previous_temperature"

		# Calculate temperature needed to lower the fan speed
		let "step_down_temperature = temperature - temperature_hysteresis"
		echo "step_down_temperature: $step_down_temperature"

	fi
	echo -e

	# Sleep before checking temperature again
	sleep $sleep_seconds 
done
