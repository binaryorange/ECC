# Welcome to ECC - Extended ClippedCamera
Improving Godot's default behavior of the ClippedCamera node.

# Project Goals
-Reusable scene consisting of a typical gimbal setup

-Controllable with mouse/keyboard or gamepad

-Take the chore of creating a polished third-person camera system away so that the end-user can spend more time developing their game!

# What is working so far?
- Scene is fully reusable and can be imported into any project
- Camera controls nicely and ignores occlusion from objects if they aren't close enough to warrant clipping
- The camera will clip to occluding geometry once the player stops rotating the camera, thus always showing the player
- Even from far distances, if the camera is pointing down at the player and the player travels under geometry, it will clip to show the player, regardless of distance.  

# What still needs done?
- Mouse/keyboard support
- Creating demo scenes
- Figuring out how to make the camera clip better to thinner geometry

