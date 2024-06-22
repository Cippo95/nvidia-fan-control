# nvidia-fan-control

I often see solutions that I don't like to control fans on NVIDIA's graphics cards:
- They can be too complex and as you will see a short script could be more than enough;
- They can be too simple, for example having a stepped fan curve or not implementing temperature hysteresis.

My solution starts from a simple bash script which just needs three commands to:
1. Enable manual fan tuning;
2. Check the temperature;
3. Set the fan speed.

There are few ways of executing these commands, some are really slow, some are really fast but custom as the binary files that I use.  
I'll explain all the stuff in detail: you have the freedom of using what you think is good enough for you.

Caveats:
- This is intended to be used with NVIDIA's drivers.
- The Bash script is intended for X11 users, using the binaries it is the fastest script to use;
- The Python script is intended for all users because it doesn't depend on X11 but on a Python library;

As an end note: this software works well enough for me, I'm doing this as an hobby and your mileage may vary.

## Requirements

### NVIDIA's driver
You need NVIDIA's driver (proprietary or the new open kernel modules) to use this software.

### Requirements for the Bash script

#### Run X11 as root
> This section is adapted from [nvfancontrol](https://github.com/foucault/nvfancontrol/tree/master) guide.  
> If you use a desktop manager you may not need this, I run X from console with `startx` and I need this.  

NVIDIA wants you to run X11 as root to control the fan speed.  
You will have to add this to your `/etc/X11/Xwrapper.config` (create the file if it doesn't exist).

```
allowed_users=anybody
needs_root_rights=yes
```

Depending on how your distribution packages X11 you might have to setuid /usr/lib/Xorg.wrap as well.  
You can do so by running in a terminal:
`sudo chmod u+s /usr/lib/Xorg.wrap`

#### Enable Coolbits for fan control
You need to enable coolbits with value of 4, you have multiple ways of doing this:
- You can execute `sudo nvidia-xconfig --cool-bits=4` and it will change your `xorg.conf`.
- You can manually modify the `xorg.conf` [(arch wiki tips)](https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Enabling_overclocking).

#### Dependencies to compile the binaries

I don't have the exact list but while compiling the compiler should complain about the libraries that it lacks.  
You should be able to install them, just pay attention to the fact that the exact packages names depend on your package manager.

### Requirements for the Python script

#### Install nvidia-ml-py
Install [(nvidia-ml-py)](https://pypi.org/project/nvidia-ml-py/) as a super user.

## Usage

### Bash script

I use the Bash script with the binaries, but setting up could be tricky for the newbie, you need to:  
1. Modify `nvidia-fan-curve.sh` so it can find `nv-control-core-temperature` and `nv-control-fan`, or put the binaries on your $PATH (I have it in my `~/.local/bin` folder);
2. Launch `nvidia-fan-curve.sh` as you wish, I advise to try it on a terminal to see if it works correctly.  

**If you don't like to use the binaries** you can replace them in the script with different commands, I have examples below in "Technical informations".  

You can make it a startup script in multiple ways: I use i3wm so I just have to add it to my config file.  

### Python script

You need to execute the script as a super user because setting fan speed still needs it with NVML.
> I have tried with i3, then using X11, but it should work with Wayland (for some reason Hyprland crashes on me right now).

You can make it a startup script in multiple ways, looking online it is often recommended to make systemd services.
> I haven't tried yet, I have done some systemd service in the past but for now I don't put the steps in this documentation.

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

I have compiled two binaries `nv-control-fan` and `nv-control-core-temperature` using the NV-CONTROL extension:
- `nv-control-fan` controls the fans: **it sets all the fans of the graphics card to the same speed**;
- `nv-control-core-temperature` queries the core GPU temperature.

Both this commands can be changed with commands already available from the installed NVIDIA's driver:
- `nv-control fan $fan_speed` can be changed with `nvidia-settings -a gputargetfanspeed=$fan_speed` **but I have noticed in-game stuttering with it**.
- `nv-control-core-temperature` can be changed with:
  - `nvidia-settings -q gpucoretemp -t` **but I have noticed in-game stuttering with it**.
  - `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader` **it seems stutters free but it takes 11-12 milliseconds to execute on my PC**.

I have tested the execution time of the main loop on my computer (with a Ryzen 5 5600, using the `time` command):
- If fan speed doesn't need to change it takes around 1.5 milliseconds.
- If fan speed needs to change it takes around 2.5 milliseconds.  
This is something that gets done every second by default (but you can change it with sleep_seconds).

You can compile these binaries yourself, but you need to:
1. Download the nvidia-settings repository: https://github.com/NVIDIA/nvidia-settings;
2. Put the source C files in the `sample` folder;
3. Modify the `Makefile` to compile also the new source code;
4. Execute `make all` and you will have your binaries.

In case this repository gets more attention, I can look to make this process available directly in my repo, since it should all be open source software.

### Python script and NVML

Having found out about NVML I was looking to compile some binary for using it, but I have found out a Python library doing the wrapping.
I have installed the library and translated my original bash script in Python which depends only on that library.

Since it doesn't depend on X11 I think it should be great for Wayland users and maybe also for users from SSH connections, but I would like some feedback on this.

The only caveat is that it is significantly slower then my bash script + binaries, but it doesn't seem to cause stuttering in game.
