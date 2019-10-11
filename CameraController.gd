extends Spatial

# This is the exception that will be added to EVERY ClippedCamera.
# This is so that we don't clip to ourselves! 
export (NodePath) var ClippedCameraException

# This is the array that stores ALL of the ClippedCameras.
# Each camera is then accessed with the zoom variable to properly get the correct camera
# at each zoom level. Pretty clever, eh?
export (Array,NodePath) var cam_array = []

# This is the camera that will actually be used to display the scene.
export (NodePath) var ViewCam

# Rotation speed for the camera
export (float) var RotationSpeed = 2.0

# Weight for camera lerp. Effectively used as the lerping speed. Default is 0.03, but you can change it.
export (float) var LerpWeight = 0.03

# By default, this is set to 5 - which is the offset of the ClipCam's local z relative to their parent nodes. 
# You *can* change this, but it may cause inaccurate distances!
export (float) var CameraDistanceOffset = 5.0

# This multiplies the current clip camera's clip offset. 
# Change this if you'd like it clip in closer, further away, or even BACKWARDS.
# By default, set to 0.25 so that it divides the clip offset to be a bit of a tighter zoom.
export (float) var ClipDistanceMultiplier = 0.25

# This is the maximum distance an object needs to be away from the view camera to not clip through.
# By default set to 5, since that seemed to be the number that played the nicest! 
export (float) var MaxOccludeDistance = 5.0

# This is the maximum angle the camera can look up before switching to the ConfinedSpaceCam
# 18 by default, but can be adjusted to better suit your needs.
export (float) var MaxAngleLimit = 18.0

# node variables 
var yGimbal
var xGimbal
var viewCam

# input and other variables
var zoom = 0
var oldZoom = 0
var oldClipCamera
var newDistance
var cam_right
var cam_up

# we use this array to store the distances of each ClipCamera at runtime so we don't have to worry about 
# swapping and changing around values
var viewcam_distance_array = []

# we use this array to store the local z of the clipcamera relative to its parent.
# this is so we can properly calculate the offset when we use the ConfinedSpaceCam, which has a different 
# local z value (because it needs to be a tighter view)
var clipcam_offset_array = []

var clipCamera = true
var inConfinedSpace = false

# use this to switch between debug camera and regular view camera
var isDebugCameraActive = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# get the camera gimbals
	yGimbal = self
	xGimbal = $XGimbal
	
	# ensure the gimbal doesn't inherit rotational information from the player
	yGimbal.set_as_toplevel(true)
	
	# add the Exception node to every ClippedCamera in cam_array
	for cam in range(cam_array.size()):
		get_node(cam_array[cam]).add_exception(get_node(ClippedCameraException))
		print(get_node(cam_array[cam]).name + " received " + get_node(ClippedCameraException).name + " as collision exception at " + str(OS.get_time()))
		
		# add the transform.z value of the clipcam's parent to each viewcam_distance_array element
		viewcam_distance_array.insert(cam, get_node(cam_array[cam]).get_parent().transform.origin.z)
		
		# now store the offset of each clipcam and its parent
		clipcam_offset_array.insert(cam, get_node(cam_array[cam]).transform.origin.z)
		
		# debug logs
		print("Added camera " + str(get_node(cam_array[cam]).name) + " to cam_array")
		print("Added distance value " + str(viewcam_distance_array[cam]) + " to viewcam_distance_array")
		print("Added clipcam offset value " + str(clipcam_offset_array[cam]) + " to clipcam_offset_array")
		
		
	# disable all but the first clip camera and the confined space cam automatically
	get_node(cam_array[1]).set_clip_to_bodies(false)
	get_node(cam_array[2]).set_clip_to_bodies(false)

	# set the view camera to the view cam node
	viewCam = get_node(ViewCam)
	
	# set the view camera to the local z axis of the first clip cam
	viewCam.transform.origin.z = get_node(cam_array[0]).transform.origin.z


func _process(delta):
	_get_input(delta)
	_update_camera()
	_update_active_clip_camera()
	_switch_camera()
	
	# update the gimbal's position to the origin of the player
	yGimbal.transform.origin = get_parent().transform.origin

func _get_input(delta):
	
	# store the input in a local var
	cam_right = Input.get_action_strength("cam_look_left") - Input.get_action_strength("cam_look_right")
	cam_up = Input.get_action_strength("cam_look_up") - Input.get_action_strength("cam_look_down")
	
	# rotate the gimbals around their local axis
	self.rotate_y(cam_right * RotationSpeed * delta)
	xGimbal.rotate_x(cam_up * RotationSpeed * delta)
	
	# clamp the camera so it can't rotate too far south or north, yeah
	
	var xGimbalRotation = xGimbal.rotation_degrees
	xGimbalRotation.x = clamp(xGimbalRotation.x, -80, 80)
	xGimbal.rotation_degrees = xGimbalRotation
	
	# zoom the camera out or in
	if Input.is_action_just_pressed("zoom"):
		zoom += 1
		if zoom > 2:
			zoom = 0

func _update_camera():
	# store the current ClipCamera
	var current_clip_cam = get_node(cam_array[zoom])
	
	# store the xGimbal's x rotation
	var x_rot = xGimbal.rotation_degrees.x
	
	# cast a ray from the View Camera to the player. If an object is in the way, 
	# calculate the distance between it and the camera. If it is less than the Max Occlude Distance, 
	# ALWAYS clip and pull through, but if it is more than or equal to the Occlude Distance, ignore it
	# until the player stops giving the camera input, or if the x angle of the yGimbal is at it's Max Zoon Angle Limit.
	
	var space_state = get_world().direct_space_state
	var ray_cast = space_state.intersect_ray(viewCam.global_transform.origin, get_parent().global_transform.origin)
	
	# check to see if a body is in the way or not
	if !ray_cast.collider.is_in_group("Player"):
		# calculate distance
		var distance_between = (viewCam.global_transform.origin - ray_cast.collider.global_transform.origin)
		
		if distance_between.length() < MaxOccludeDistance*viewcam_distance_array[zoom]:
			clipCamera = true
		else:
			clipCamera = false
		
	if clipCamera:
		# store the clip offset of the current clip camera
		var clip_offset = current_clip_cam.get_clip_offset()
	
		if clip_offset > 0:

			# update the viewcam's local z position to the current clip cam's PARENT node's local z,
			# then subtract the current clip cam's clip offset multiplied by ClipDistanceMultiplier
			viewCam.transform.origin.z = lerp(viewCam.transform.origin.z,
			current_clip_cam.get_parent().transform.origin.z - clip_offset * ClipDistanceMultiplier,
			LerpWeight * 10)
		

	# calculate the distance from the camera back to the player.
	# if it is less than the current value in viewcam_distance_array, set the local Z of the target
	# of the current ClipCamera to that exact value, to "push" the camera forward to keep the player in sight!
	if zoom > 0:
		
		var distance_between2 = (viewCam.global_transform.origin - get_parent().global_transform.origin)
			
		if distance_between2.length() < viewcam_distance_array[zoom]:
			current_clip_cam.get_parent().transform.origin.z = viewCam.transform.origin.z
	elif current_clip_cam.get_clip_offset() == 0:
		current_clip_cam.get_parent().transform.origin.z = viewcam_distance_array[zoom]

	# set the z position of the viewCam to the lerped distance
	viewCam.transform.origin.z = lerp(viewCam.transform.origin.z, viewcam_distance_array[zoom] + clipcam_offset_array[zoom], LerpWeight)
	
func _update_active_clip_camera():
	
	# choose which clip camera from the cam_array is active depending on index
	if zoom == 0 and !get_node(cam_array[0]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(true)
		get_node(cam_array[1]).set_clip_to_bodies(false)
		get_node(cam_array[2]).set_clip_to_bodies(false)
		print(get_node(cam_array[0]).name + ": Clipping set to: " + str(get_node(cam_array[0]).is_clip_to_bodies_enabled()))
		
	elif zoom == 1 and !get_node(cam_array[1]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(false)
		get_node(cam_array[1]).set_clip_to_bodies(true)
		get_node(cam_array[2]).set_clip_to_bodies(false)
		print(get_node(cam_array[1]).name + ": Clipping set to: " + str(get_node(cam_array[1]).is_clip_to_bodies_enabled()))
		
	elif zoom == 2 and !get_node(cam_array[2]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(false)
		get_node(cam_array[1]).set_clip_to_bodies(false)
		get_node(cam_array[2]).set_clip_to_bodies(true)
		print(get_node(cam_array[2]).name + ": Clipping set to: " + str(get_node(cam_array[2]).is_clip_to_bodies_enabled()))
		
func _switch_camera():
	if Input.is_action_just_pressed("switch_camera_to_debug"):
		# flip the bool
		isDebugCameraActive = !isDebugCameraActive
		get_parent().get_node("DebugCamera").current = isDebugCameraActive
		
		# flip it back here...
		viewCam.current = !isDebugCameraActive



