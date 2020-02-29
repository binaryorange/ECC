___ UPDATE 2/28/2020 ____

I am no longer working on this project as some things have come up in life that require more attention. Please, feel free to download it, modify it, and use it in your projects, if you can get the annoying issues I was having with it sorted out!

# Welcome to ECC - Extended ClippedCamera
Improving Godot's default behavior of the ClippedCamera node.

# Project Goals
- Reusable scene consisting of a typical gimbal setup with easy-to-use values in Inspector tab.

- Controllable with mouse/keyboard or gamepad with individual settings for both.

- Take the chore of creating a polished third-person camera system away so that the end-user can spend more time developing their game!

# What is working so far?
- Scene is fully reusable and can be imported into any project easily.
- Camera controls nicely and ignores occlusion from objects if they aren't close enough to warrant clipping.
- The camera will clip to occluding geometry once the player stops rotating the camera, thus always showing the player when stationary.
- Even from far distances, if the camera is pointing down at the player and the player travels under geometry, it will clip to show the player, regardless of distance. 

# What still needs done?
- Improved mouse and keyboard controls (currently still just very rudimentary controls)
- Customisable controls the player can specify (I imagine this will be trickier than I anticipate at the moment)
- Documentation

