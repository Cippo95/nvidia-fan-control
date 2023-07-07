# nvidia-fan-control

I have made this software because I often see too complex or too simple solutions:  
- It works with NVIDIA's proprietary drivers, X11 and x86-64 computers;
- It is the combination of a simple bash script and two binary files (one for checking temperature and one for setting fan speed).

This software works well enough for me, but it is still work in progress!  

## Usage

It could be tricky for the newbie, but you need to:  
1. Modify `nvidia-fan-curve.sh` so it can find `nv-control-core-temperature` and `nv-control-fan`, or put the binaries on your $PATH (I have it in my `~/.local/bin` folder);
2. Launch `nvidia-fan-curve.sh` as you wish, I advise to try it on a terminal to see if it works correctly.  

You can make it a startup script in multiple ways: I use i3wm so I just have to add it to my config file.  

## Technical informations

### Fan curve points

This script will set the fan speed accordingly to a fan curve specified by points.  

The points have two coordinates specified by two arrays:
- `temperature_points` for temperatures;
- `fan_speed_points` for fan speed.

![fan curve example](./fan_curve_example.png)

**You need to edit the arrays with the values that you want!**

### Self explanatory variables

I think that the script has self explanatory variables, so it should be easy to understand and debug.

### Fan hysteresis logic

It was a nice to have feature so I have implemented a simple fan hysteresis logic, it is controlled by `temperature_hysteresis` variable.  
When a new fan speed gets setted, the temperature for which the fan speed decreases is calculated as `step_down_temperature`.

### Reason of the binary files

I have compiled two binary file `nv-control-fan` and `nv-control-core-temperature` using the NV-CONTROL extension:
- `nv-control-fan` controls the fans: **it sets all the fans of the graphics card to the same speed**;
- `nv-control-core-temperature` queries the core GPU temperature.

Both this commands can be changed with commands already available from the installed NVIDIA's driver:
- `nv-control fan $fan_speed` can be changed with `nvidia-settings -a gputargetfanspeed=$fan_speed` **but I have noticed in-game stuttering with it**.
- `nv-control-core-temperature` can be changed with:
  - `nvidia-settings -q gpucoretemp -t` **but I have noticed in-game stuttering with it**.
  - `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader` **it doesn't cause stutters but it takes 11-12 milliseconds (and I can do better)**.

You can compile these binaries yourself, but you need to:
1. Download the nvidia-settings repository: https://github.com/NVIDIA/nvidia-settings;
2. Put the source C files in the `sample` folder;
3. Modify the `Makefile` to compile also the new source code;
4. Execute `make all` and you will have your binaries.

In case this repository gets more attention, I can look to make this process available directly in my repo, since it should all be open source software.

### Comment on different solutions

I have seen many different solutions:
- Some being more simple with just temperature/fan speed steps, no hysteresis... just too simple.
- Some using the nvidia-settings commands causing in game stuttering at regular intervals.
- Some being very complex:
  - Many lines of code doing... to be honest I don't know what.
  - GreenWithEnvy (nice software) but too heavy to just adjust fan speed.
