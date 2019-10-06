extends Node

""" This script switches between the currently selected ClippedCamera node.
	This is necessary so that we can turn off the cameras which are NOT currently
	selected. """
	
# first set up some local variables to represent the cam_array and zoom index
var index
var cam_array

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	cam_array = get_parent().get_parent().cam_array
	var cam_script = get_parent().get_parent()
	if !cam_array == null:
		if cam_script.zoom == 0:
			# we are using the first camera, so turn off 2 and 3
			get_node(cam_array[0]).set_clip_to_bodies(true)
	#		cam_array[1].set_clip_to_bodies(false)
	#		cam_array[2].set_clip_to_bodies(false)
	#
	#	elif index == 1:
	#		# we are using the second camera, so turn off 1 and 3
	#		cam_array[0].set_clip_to_bodies(false)
	#		cam_array[1].set_clip_to_bodies(true)
	#		cam_array[2].set_clip_to_bodies(false)
	#
	#	elif index == 2:
	#		# we are using the third camera, so turn off 1 and 2
	#		cam_array[0].set_clip_to_bodies(false)
	#		cam_array[1].set_clip_to_bodies(false)
	#		cam_array[2].set_clip_to_bodies(true)

