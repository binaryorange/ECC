extends Spatial

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

# export our lerpweight for the camera
export (float) var LerpWeight = 0.03

# export our rotational speed
export (float) var RotationSpeed = 1.75

# export our collision probe size
export (float) var CollisionProbeSize = 2.0

# export our max and min camera angles
export (float) var MaxCameraAngle = 70
export (float) var MinCameraAngle = -45

# export our clip offset multiplier
export (float) var ClipOffsetMultiplier = 1.075

# export our view cam distance modifier
export (float) var ViewCamDistanceModifier = 1.05

# allow the user to choose if there's a follow delay or not
export (bool) var EnableFollowDelay = false
export (float) var FollowDelayWeight = 0.07

# allow the user to choose to allow mouse input if gamepad is not being used
export (bool) var EnableMouseInput = false
export (float) var MouseSensitivity = 2

export (float) var ZoomDelay = 1.0

# our local variables
var cam_up = 0.0
var cam_right = 0.0
var zoom  = 0
var clip_cam
var view_cam 
var can_clip = false
var y_gimbal
var x_gimbal
var max_zoom_level
var zoom_level_array = []
var gimbal_offset
var is_in_confined_space = false
var collision_probe_hit = false
var collision_probe_shape
var is_clipping = false
var counting_down = false

# hide these when we are running the game
var helper_mesh

# this allows us to toggle between mouse/gamepad input
var mouse_captured = false

# we use this to track if the mouse moved or not during the last frame
var mouse_moved = false

# we use this array to determine if there are more than one bodies in the CollisionProbe.
var collision_probe_array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# grab our nodes
	y_gimbal = self
	x_gimbal = $"X Gimbal"
	view_cam = get_node(ViewCamera)
	clip_cam = get_node(ClipCamera)
	helper_mesh = $"X Gimbal/HelperMesh"
	collision_probe_shape = $"X Gimbal/ViewCamera/CanClipDetector/CollisionShape"
	
	# set our helper meshes to be invisible
	helper_mesh.visible = false
	
	# set gimbal as top level
	self.set_as_toplevel(true)
	
	# store the offset of the gimbal relative to its parent node
	gimbal_offset = self.transform.origin - get_parent().transform.origin
	print("Stored the Gimbal's offset value as " + str(gimbal_offset))
	
	# add the zoom nodes local z transform to the array
	for z in ZoomLevels.size():
		zoom_level_array.insert(z, get_node(ZoomLevels[z]).transform.origin.z)
		print("Added zoom value " + str(zoom_level_array[z]) + " to the zoom array")
		
	# ensure we set the max zoom level for the zoom array
	max_zoom_level = ZoomLevels.size()
	print("Max Zoom Level set to " + str(max_zoom_level))
	
	# set the default zoom level of the cameras
	clip_cam.transform.origin.z = zoom_level_array[0]
	view_cam.transform.origin.z += ViewCamDistanceModifier

	# add the ClipCameraException node
	clip_cam.add_exception(get_node(ClipCameraException))
	print("Added " + str(get_node(ClipCameraException).name) + " to " + str(get_node(ClipCamera).name) + " as collision exception")
	
	# set the size of our collision probe
	collision_probe_shape.shape.radius = CollisionProbeSize
	print("Set CollisionProbeSize to: " + str(collision_probe_shape.shape.radius))
	
	# capture the mouse if we have enabled mouse input
	if EnableMouseInput:
		mouse_captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	$ZoomTimer.wait_time = ZoomDelay

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_get_input()
	_update_camera(delta)

# get our input for the camera
func _get_input():
	
	# get joystick movement data if we are not using the mouse
	if !mouse_captured:
		# store the right movement
		cam_right = Input.get_action_strength("cam_look_right") - Input.get_action_strength("cam_look_left")
		
		# store the up movement
		cam_up = Input.get_action_strength("cam_look_down") - Input.get_action_strength("cam_look_up")
		
		# zoom the camera
		if Input.is_action_just_pressed("zoom") and !counting_down:
			_zoom_camera(1)
				
	# uncapture or recapture the mouse
	if Input.is_action_just_pressed("capture_mouse"):
		mouse_captured = !mouse_captured
		
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
# update the camera's position and rotation
func _update_camera(delta):
	
	# position the gimbal to the player's position, plus the offset
	if EnableFollowDelay:
		self.transform.origin = lerp(self.transform.origin, 
		get_parent().transform.origin + gimbal_offset, 
		FollowDelayWeight)
	else:
		self.transform.origin = get_parent().transform.origin + gimbal_offset
	
	# position the clip cam
	clip_cam.transform.origin.z = zoom_level_array[zoom]
	
	# clamp the x rotation
	var x_gimbal_rotation = x_gimbal.rotation_degrees
	x_gimbal_rotation.x = clamp(x_gimbal_rotation.x, MinCameraAngle, MaxCameraAngle)
	x_gimbal.rotation_degrees = x_gimbal_rotation
	
	# set the rotational values of the gimbals
	if !mouse_captured:
		self.rotate_y(cam_right * RotationSpeed * delta)
		x_gimbal.rotate_x(cam_up * RotationSpeed * delta)
	elif mouse_captured and mouse_moved:
		self.rotate_y(cam_right * MouseSensitivity * delta)
		x_gimbal.rotate_x(cam_up * MouseSensitivity * delta)
	
	# now check for occluding geometry
	_check_for_occlusion()

# check for occluding objects by casting a ray back to the player
func _check_for_occlusion():
	
	# check if the CollisionProbe is hitting anything
	if collision_probe_hit:
		can_clip = true
	else:
		# check to see if we are in a confined space
		if is_in_confined_space:
			can_clip = true
		else:
			can_clip = false

		
	# if we are clipping, set the view cam's local z to the clip cam's information
	if can_clip:
		
		# get the clip cam's clip offset
		var clip_offset = clip_cam.get_clip_offset()
	
		# set the view cam's position
		if clip_offset > 0:
			
			# alert the collision probe that we are clipping
			is_clipping = true
			
			# show the target
			view_cam.transform.origin.z = zoom_level_array[zoom] + ViewCamDistanceModifier + clip_offset * ClipOffsetMultiplier
				
		else:
			is_clipping = false
			
	# position the camera to the current zoom level from the zoom level array
	view_cam.transform.origin.z = lerp(view_cam.transform.origin.z, 
	zoom_level_array[zoom] + ViewCamDistanceModifier, 
	LerpWeight)
	
	# reset mouse_moved so that we don't update the gimbal's rotation automatically every frame
	# while using the mouse instead of the gamepad
	mouse_moved = false
	
# support mouse input
func _input(event):
	if mouse_captured:
		if event is InputEventMouseMotion:
			cam_up = deg2rad(event.relative.y * -1)
			cam_right = deg2rad(event.relative.x)
			mouse_moved = true
			
		if event is InputEventMouseButton and !counting_down:
			if event.is_action_pressed("mouse_zoom_out"):
				_zoom_camera(1)
			if event.is_action_pressed("mouse_zoom_in"):
				_zoom_camera(-1)


func _zoom_camera(var amount):
	# only change zoom levels while the timer is not counting down
	$ZoomTimer.start(ZoomDelay)
	counting_down = true
	if $ZoomTimer.time_left == ZoomDelay:
		# if we are at the cap and using the mouse, keep zoomed out
		if mouse_captured:
			zoom += amount
			
			if zoom >= max_zoom_level - 1:
				zoom = max_zoom_level - 1
			elif zoom <= 0:
				zoom = 0
		else:
			if zoom >= max_zoom_level - 1:
				zoom = 0
			else:
				zoom += amount

# tells us when the player has entered a confined space
func _on_ConfinedSpaceArea_body_entered(body):
	if !body.is_in_group("Player") and !is_in_confined_space:
		is_in_confined_space = true
		print("In Confined Space: " + str(is_in_confined_space))


# tells us when the player has exited a confined space
func _on_ConfinedSpaceArea_body_exited(body):
	if !body.is_in_group("Player") and is_in_confined_space:
		is_in_confined_space = false
		print("In Confined Space: " + str(is_in_confined_space))

# this tells us when the camera can clip against walls or other occluding objects
func _on_CanClipDetector_body_entered(body):
	if !body.is_in_group("Player"):
		
		# check to make sure this body doesn't exist in the array.
		# if it doesn't, we will add it to the array, and set collision_probe_hit to true!
		if collision_probe_array.find(body) == -1:
			collision_probe_hit = true
			collision_probe_array.insert(collision_probe_array.size(), body)
			print("Collision Probe Hit: " + str(collision_probe_hit) + " | Added " + str(body) + " at index [" + str(collision_probe_array.size()-1) + "]")
		else:
			print("I'm already here, man!")

# this tells us when the camera has stopped clipping against walls
func _on_CanClipDetector_body_exited(body):
	if !body.is_in_group("Player"):
		
		# check array to make sure it is not empty
		if collision_probe_array.size() != -1:
			# search for the body and remove it
			var body_to_remove = collision_probe_array.find(body)
			if body_to_remove != -1:
				collision_probe_array.remove(body_to_remove)
				print("Removed " + str(body) + " from index [" + str(collision_probe_array.size()) + "]")
		
		if collision_probe_array.empty() and !is_clipping:
			collision_probe_hit = false
			print("CollisionProbeHit: " + str(collision_probe_hit))


func _on_ZoomTimer_timeout():
	# stop the zoomtimer
	$ZoomTimer.stop()
	$ZoomTimer.wait_time = ZoomDelay
	counting_down = false
