extends Spatial

""" ------ Welcome to ECCS - Enhanced ClippedCamera Setup! ------ 
	--  This is a simple Gimbal setup, which will allow you to --
	-- drop this scene into your player.tscn, and go from there! --
"""

# first set up our external variables that we want to edit through the inspector

# we will first export nodepaths

# this will capture our view camera
export (NodePath) var ViewCamera

# this will capture our clip camera
export (NodePath) var ClipCamera

# this will capture our exception for the clip camera, which should be the player,
# so that we don't clip to ourselves!
export (NodePath) var ClipCameraException

# export our zoom levels in an array
export(Array, NodePath) var ZoomLevels

# export our rotational speed
export (float) var RotationSpeed = 2.0

# export our max occlude distance
export (float) var MaxOccludeDistance = 5.0

# export our max and min camera angles
export (float) var MaxCameraAngle = 35
export (float) var MinCameraAngle = -70

# export our clip offset multiplier
export (float) var ClipOffsetMultiplier = 1


# our local variables
var cam_up : float = 0.0
var cam_right : float = 0.0
var zoom : int = 0
var clip_cam
var view_cam 
var is_clipping : bool = false
var y_gimbal
var x_gimbal
var max_zoom_level




# Called when the node enters the scene tree for the first time.
func _ready():
	
	# grab our nodes
	y_gimbal = self
	x_gimbal = $"X Gimbal"
	
	view_cam = get_node(ViewCamera)
	clip_cam = get_node(ClipCamera)
	
	# first set as top level
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_get_input()
	_update_camera(delta)

func _get_input():
	# store the right movement
	cam_right = Input.get_action_strength("cam_look_right") - Input.get_action_strength("cam_look_left")
	
	# store the up movement
	cam_up = Input.get_action_strength("cam_look_down") - Input.get_action_strength("cam_look_up")

	
func _update_camera(delta):
	
	# clamp the x rotation
	var x_gimbal_rotation = x_gimbal.rotation_degrees
	x_gimbal_rotation.x = clamp(x_gimbal_rotation.x, MinCameraAngle, MaxCameraAngle)
	x_gimbal.rotation_degrees = x_gimbal_rotation
	
	# set the rotational values of the gimbals
	self.rotate_y(cam_right * RotationSpeed * delta)
	x_gimbal.rotate_x(cam_up * RotationSpeed * delta)

	

