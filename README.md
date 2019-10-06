# BIOCC - BinaryOrange's Improved ClippedCamera
 Attempting to improve the default behavior of Godot's ClippedCamera node. 

<hr></hr>

# Why Am I Doing This?
The default behavior of the ClippedCamera node (introduced in Godot 3.1) is, for all intents and purposes, completely functional. It does exactly what it sets out to do, which is always show its parent node, the target.  It will always clip through any occluding geometry that gets between it and its target, and I do mean always.  It does not take any distancing into account, so whether the occluding object is 1 unit in front of the camera, or 100 units, it will ALWAYS clip.  That... isn't quite a good solution.

It also offers no smoothing, so the action of clipping and going back to a non-clipping state are quite jarring.  A camera should <i>follow</i> the player, not <i>teleport</i> to the player.

The reason I am doing this is to greatly improve the usefullness and reusability of the ClippedCamera node. 

# TODO, and coming up - instructions on how to use this node when it is officially released! Stay tuned!
