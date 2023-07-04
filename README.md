# simple-nvidia-fancontrol

"Do one thing do it well."
I don't like overly complicated scripts/programs just to adjust the fans of my graphics card.   
I have made a bash script which is around 100 lines (including debugging lines and comments) and it is good for me.  

## Usage
Modify nvidia-fancurve.sh so it can find nv-control-fan (or put the binary on your PATH, I have it in my ~/.local/bin/ folder.  
Launch nvidia-fancurve.sh as you wish, I advise to try it to see if it works correctly.  
Then you can make it a startup script in multiple ways, I use i3wm so I just have to add it to my config file.  

## Technical informations

This script will set the fan speed accordingly to a fan curve specified with points.  
The points have two coordinates specified with two arrays, one for temperature and one for fan speed, it is the most common way of doing things.  

[INSERT PICTURE HERE?]

The scripts has sensible named variables so you can understand what is going on...still, I will probably change them if I find some better naming (and I have already some idea).

I have implemented a fan hysteresis logic.  

I use a "custom made by me" binary to control the fans with NV-CONTROL, so this works under X11, I don't think it works for Wayland environments.  
You can find the source code of the binary, it needs to be compiled with other source code you can find in the nvidia-settings repository.  
I have just adjusted one of their sample files to control fans, that's it.  

I have done this because using nvidia-settings would cause mild stuttering in game and I didn't liked it at all!
