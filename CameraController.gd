extends Spatial


export (NodePath) var Exception
export (Array,NodePath) var cam_array = []
export (NodePath) var ViewCam

# rotation
export (float) var RotationSpeed = 2.0

# weight for camera lerp
export (float) var LerpWeight = 0.03

export (float) var CameraDistanceOffset = 5.0

# limit for camera clipping at zoom level 3
# if this angle is exceeded, the camera will clip as normal despite being zoomed out fully
export (float) var MaxZoomAngleLimit = -18.0

export (float) var ClipDistanceMultiplier = 1.5

export (float) var MaxOccludeDistance = 3.0


# private variables
var yGimbal
var xGimbal
var viewCam

var zoom = 0
var oldDistance
var newDistance
var cam_right
var cam_up

var distance_array = []

var clipCamera = true

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
		get_node(cam_array[cam]).add_exception(get_node(Exception))
		print(get_node(cam_array[cam]).name + " received " + get_node(Exception).name + " as collision exception at " + str(OS.get_time()))
		
		# add the transform.z value to each distance_array element
		distance_array.insert(cam, get_node(cam_array[cam]).get_parent().transform.origin.z)
		
	# disable the second and third clip cameras automatically
	get_node(cam_array[1]).set_clip_to_bodies(false)
	get_node(cam_array[2]).set_clip_to_bodies(false)

	# set the view camera to the view cam node
	viewCam = get_node(ViewCam)
	
	# set the view camera to the local z axis of the first clip cam
	viewCam.transform.origin.z = get_node(cam_array[0]).transform.origin.z
	
	# default oldDistance
	oldDistance = get_node(cam_array[0]).transform.origin.z
	

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
	
	var oldZ = current_clip_cam.get_parent().transform.origin.z
	
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
		
		if distance_between.length() < MaxOccludeDistance:
			clipCamera = true
		else:
			# now check if we are not doing any left/right camera rotation, or if we're
			# rotating above the Max Zoom Angle Limit. CLip through if they are true.
			if x_rot < MaxZoomAngleLimit or x_rot > abs(MaxZoomAngleLimit):
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
	# if it is less than the current value in distance_array, set the local Z of the target
	# of the current ClipCamera to that exact value, to "push" the camera forward to keep the player in sight!
	if zoom > 0:
		
		var distance_between2 = (viewCam.global_transform.origin - get_parent().global_transform.origin)
			
		if distance_between2.length() < distance_array[zoom]:
			current_clip_cam.get_parent().transform.origin.z = viewCam.transform.origin.z
	elif current_clip_cam.get_clip_offset() == 0:
		current_clip_cam.get_parent().transform.origin.z = distance_array[zoom]

	

	# set the z position of the viewCam to the lerped distance
	viewCam.transform.origin.z = lerp(viewCam.transform.origin.z, distance_array[zoom] + CameraDistanceOffset, LerpWeight)
	
func _update_active_clip_camera():
	
	# choose which clip camera from the cam_array is active depending on index
	if zoom == 0 and !get_node(cam_array[0]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(true)
		get_node(cam_array[1]).set_clip_to_bodies(false)
		get_node(cam_array[2]).set_clip_to_bodies(false)
		print(get_node(cam_array[0]).name + ": Clipping set to: " + str(get_node(cam_array[0]).is_clip_to_bodies_enabled()))
		print(get_node(cam_array[1]).name + ": Clipping set to: " + str(get_node(cam_array[1]).is_clip_to_bodies_enabled()))
		print(get_node(cam_array[2]).name + ": Clipping set to: " + str(get_node(cam_array[2]).is_clip_to_bodies_enabled()))
	elif zoom == 1 and !get_node(cam_array[1]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(false)
		get_node(cam_array[1]).set_clip_to_bodies(true)
		get_node(cam_array[2]).set_clip_to_bodies(false)
		print(get_node(cam_array[0]).name + ": Clipping set to: " + str(get_node(cam_array[0]).is_clip_to_bodies_enabled()))
		print(get_node(cam_array[1]).name + ": Clipping set to: " + str(get_node(cam_array[1]).is_clip_to_bodies_enabled()))
		print(get_node(cam_array[2]).name + ": Clipping set to: " + str(get_node(cam_array[2]).is_clip_to_bodies_enabled()))
	elif zoom == 2 and !get_node(cam_array[2]).is_clip_to_bodies_enabled():
		get_node(cam_array[0]).set_clip_to_bodies(false)
		get_node(cam_array[1]).set_clip_to_bodies(false)
		get_node(cam_array[2]).set_clip_to_bodies(true)
		print(get_node(cam_array[0]).name + ": Clipping set to: " + str(get_node(cam_array[0]).is_clip_to_bodies_enabled()))
		print(get_node(cam_array[1]).name + ": Clipping set to: " + str(get_node(cam_array[1]).is_clip_to_bodies_enabled()))
		print(get_node(cam_array[2]).name + ": Clipping set to: " + str(get_node(cam_array[2]).is_clip_to_bodies_enabled()))
		
func _switch_camera():
	if Input.is_action_just_pressed("switch_camera_to_debug"):
		# flip the bool
		isDebugCameraActive = !isDebugCameraActive
		get_parent().get_node("DebugCamera").current = isDebugCameraActive
		
		# flip it back here...
		viewCam.current = !isDebugCameraActive



