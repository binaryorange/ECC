extends Node

# This script directly communicates with ECC_TPController.gd to relay the 
# information for mouse settings directly to it.
# Set the values in the exposed settings in the Inspector to utilize it!

# This is what we use to determine if we start with the mouse or not
export (bool) var EnableMouse = false

# This determines our smoothing of the rotation when we use the mouse
export (float, 2.0, 4.0) var MouseSensitivity = 2.0

# This will override our view camera distance settings when using the mouse, to allow better
# clipping
export (float, 0, 3.0) var ViewCamDistanceOverride = 0.25

# our private variables
var mouse_moved = false
