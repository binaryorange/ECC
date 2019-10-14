extends Spatial

# this is the exception that will be added to EVERY ClippedCamera.
# this is so that we don't clip to ourselves! 
export (NodePath) var ClippedCameraException

# this is the array that stores ALL of the ClippedCameras.
# each camera is then accessed with the zoom variable to properly get the correct camera
# at each zoom level. Pretty clever, eh?
export (Array,NodePath) var cam_array = []

# this is the camera that will actually be used to display the scene.
export (NodePath) var ViewCam

# rotation speed for the camera
export (float) var RotationSpeed = 2.0

# weight for camera lerp. Effectively used as the lerping speed. Default is 0.03, but you can change it.
export (float) var LerpWeight = 0.03

# this multiplies the current clip camera's clip offset. 
# change this if you'd like it clip in closer, further away, or even BACKWARDS.
export (float) var ClipDistanceMultiplier = 1.15

# we use this to modify the exact distance the target will move when clipping.
# helps ensure that we still clip accurately in tight spots.
export (float) var SpringArmDistanceMultiplier = 0.1

# we will move the camera's target back to 0 if we exceed this value in the xGimbal's
# x rotation value.  Useful to ensure accurate clipping when looking down at the player.
export (float) var LookUpAngleThreshold = -20

# the minimum camera angle limit (default is -70)
export (float) var MinCameraAngleLimit = -70

# the maximum camera angle (default is 35)
export (float) var MaxCameraAngleLimit = 35

# allows for a smoothing effect when the camera is pulling ahead through geometry, giving a little more flexibility 
# to the overall system.  Default is false for instant clipping.
export (bool) var EnablePullAheadSmoothing = false

export (float) var PullAheadSmoothingWeight = 0.2

# node variables 
var yGimbal
var xGimbal
var viewCam

# input and other variables
var zoom = 0
var cam_right
var cam_up
var gimbal_offset

# we use this array to store the distances of each ClipCamera at runtime so we don't have to worry about 
# swapping and changing around values
var clipcam_target_distance_array = []

# we use this array to store the local z of the clipcamera relative to its parent.
# we do this so we can easily change the distance of the camera without swapping values back and forth!
var clipcam_distance_array = []

var clipCamera = true

# use this to switch between debug camera and regular view camera
var isDebugCameraActive = false

# called when the node enters the scene tree for the first time.
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
		
		# add the transform.z value of the clipcam's parent to each clipcam_target_distance_array element
		clipcam_target_distance_array.insert(cam, get_node(cam_array[cam]).get_parent().transform.origin.z)
		
		# now store the offset of each clipcam and its parent
		clipcam_distance_array.insert(cam, get_node(cam_array[cam]).transform.origin.z)
		
		# debug logs
		print("Added camera " + str(get_node(cam_array[cam]).name) + " to cam_array")
		print("Added distance value " + str(clipcam_target_distance_array[cam]) + " to clipcam_target_distance_array")
		print("Added clipcam offset value " + str(clipcam_distance_array[cam]) + " to clipcam_distance_array")
		
		
	# disable all but the first clip camera and the confined space cam automatically
	get_node(cam_array[1]).set_clip_to_bodies(false)
	get_node(cam_array[2]).set_clip_to_bodies(false)

	# set the view camera to the view cam node
	viewCam = get_node(ViewCam)
	
	# set the view camera to the local z axis of the first clip cam
	viewCam.transform.origin.z = get_node(cam_array[0]).transform.origin.z
	
	# get the gimbal offset to accurately position the gimbal
	gimbal_offset = yGimbal.transform.origin - get_parent().transform.origin


func _process(delta):
	_get_input(delta)
	_update_camera()
	_update_active_clip_camera()
	_switch_camera()
	
	# update the gimbal's position to the origin of the player
	yGimbal.transform.origin = get_parent().transform.origin + gimbal_offset

func _get_input(delta):
	
	# store the input in a local var
	cam_right = Input.get_action_strength("cam_look_right") - Input.get_action_strength("cam_look_left")
	cam_up = Input.get_action_strength("cam_look_down") - Input.get_action_strength("cam_look_up")
	
	# rotate the gimbals around their local axis
	self.rotate_y(cam_right * RotationSpeed * delta)
	xGimbal.rotate_x(cam_up * RotationSpeed * delta)
	
	# clamp the camera so it can't rotate too far south or north, yeah
	
	var xGimbalRotation = xGimbal.rotation_degrees
	xGimbalRotation.x = clamp(xGimbalRotation.x, MinCameraAngleLimit, MaxCameraAngleLimit)
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
	
	# store the clip offset of the current clip camera
	var clip_offset = current_clip_cam.get_clip_offset()

	if clip_offset > 0:

		# update the viewcam's local z position to the current clip cam's PARENT node's local z,
		# then subtract the current clip cam's clip offset multiplied by ClipDistanceMultiplier
		
		if EnablePullAheadSmoothing:
			viewCam.transform.origin.z = lerp(viewCam.transform.origin.z,
			clipcam_target_distance_array[zoom] + clipcam_distance_array[zoom] - clip_offset * ClipDistanceMultiplier,
			PullAheadSmoothingWeight)
		else:
			viewCam.transform.origin.z = clipcam_target_distance_array[zoom] + clipcam_distance_array[zoom] - clip_offset * ClipDistanceMultiplier
		

	# if we are at a zoom level greater than 0, calculate the distance from the camera to the player,
	# then subtract that distance divided by 2 from the camera's local z position to treat the 
	# camera target like a spring.
	if zoom > 0:
		
		var distance_from_player = (viewCam.global_transform.origin - get_parent().global_transform.origin)
		
		
		if clip_offset > 0:
	
			current_clip_cam.get_parent().transform.origin.z = viewCam.transform.origin.z - distance_from_player.length()/2 + x_rot/4 * SpringArmDistanceMultiplier
			
			if current_clip_cam.get_parent().transform.origin.z <= 0:
				current_clip_cam.get_parent().transform.origin.z = 0
			
			current_clip_cam.transform.origin.z = clipcam_target_distance_array[zoom] + clipcam_distance_array[zoom]
		else:
			
			# if we are rotating up, move the target forward to a max value of 0 so that if the player goes under any overhanging geometry,
			# we will clip through as expected.
			if x_rot < LookUpAngleThreshold:
				current_clip_cam.get_parent().transform.origin.z = clipcam_target_distance_array[zoom] + x_rot/4
				
				if current_clip_cam.get_parent().transform.origin.z <= 0:
					current_clip_cam.get_parent().transform.origin.z = 0
				
				current_clip_cam.transform.origin.z = clipcam_target_distance_array[zoom] + clipcam_distance_array[zoom]
			else:
			
				# set the clip camera and its target back to its previous values
				current_clip_cam.get_parent().transform.origin.z = clipcam_target_distance_array[zoom]
				current_clip_cam.transform.origin.z = clipcam_distance_array[zoom]

	# set the z position of the viewCam to the lerped distance
	viewCam.transform.origin.z = lerp(viewCam.transform.origin.z, clipcam_target_distance_array[zoom] + clipcam_distance_array[zoom], LerpWeight)
	
func _update_active_clip_camera():
	
	# choose which clip camera from the cam_array is active depending on index
	if zoom == 0 and !get_node(cam_array[0]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(true)
		get_node(cam_array[1]).set_clip_to_bodies(false)
		get_node(cam_array[2]).set_clip_to_bodies(false)
		
		get_node(cam_array[0]).get_parent().visible = true
		get_node(cam_array[1]).get_parent().visible = false
		get_node(cam_array[2]).get_parent().visible = false
		
		print(get_node(cam_array[0]).name + ": Clipping set to: " + str(get_node(cam_array[0]).is_clip_to_bodies_enabled()))
		
		
	elif zoom == 1 and !get_node(cam_array[1]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(false)
		get_node(cam_array[1]).set_clip_to_bodies(true)
		get_node(cam_array[2]).set_clip_to_bodies(false)
		
		get_node(cam_array[0]).get_parent().visible = false
		get_node(cam_array[1]).get_parent().visible = true
		get_node(cam_array[2]).get_parent().visible = false
		print(get_node(cam_array[1]).name + ": Clipping set to: " + str(get_node(cam_array[1]).is_clip_to_bodies_enabled()))
		
	elif zoom == 2 and !get_node(cam_array[2]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(false)
		get_node(cam_array[1]).set_clip_to_bodies(false)
		get_node(cam_array[2]).set_clip_to_bodies(true)
		
		get_node(cam_array[0]).get_parent().visible = false
		get_node(cam_array[1]).get_parent().visible = false
		get_node(cam_array[2]).get_parent().visible = true
		print(get_node(cam_array[2]).name + ": Clipping set to: " + str(get_node(cam_array[2]).is_clip_to_bodies_enabled()))
		
func _switch_camera():
	if Input.is_action_just_pressed("switch_camera_to_debug"):
		# flip the bool
		isDebugCameraActive = !isDebugCameraActive
		get_parent().get_node("DebugCamera").current = isDebugCameraActive
		
		# flip it back here...
		viewCam.current = !isDebugCameraActive



