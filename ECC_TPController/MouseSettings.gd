extends Node

# This script directly communicates with ECC_TPController.gd to relay the 
# information for mouse settings directly to it.
# Set the values in the exposed settings in the Inspector to utilize it!

# This is what we use to determine if we start with the mouse or not
export (bool) var MouseMode = false

# This determines our smoothing of the rotation when we use the mouse
export (float, 0.1, 3.0) var MouseSensitivity = 2.0

# This determines our maximum mouse speed
export (float, 250.0, 500.0) var MaxMouseMoveSpeed = 250.0

# This will override our view camera distance settings when using the mouse, to allow better
# clipping
export (float, 0, 3.0) var ViewCamDistanceOverride = 1.0

export (float, 1.0, 3.0) var ClipDistanceMultiplier = 1.0


# our private variables
var mouse_captured = false
var mouse_moved = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
