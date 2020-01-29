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

# export our CameraSmoothing for the camera
export (float) var CameraSmoothing = 0.03

# export our rotational speed
export (float) var RotationSpeed = 1.75

# export our collision probe size
export (float) var CollisionRadius = 3

# export our max and min camera angles
export (float) var MaxCameraAngle = 45
export (float) var MinCameraAngle = -50

# export our minimum camera distance
export (float) var MinViewCamDistance = 0.5

# export our clip cam z adjuster
export (float) var ClipCamOffset = 3

# export our view cam offset adjuster
export (float) var ViewCamOffset = 0

export (float) var ClipModifier = 1.01

# allow the user to choose if there's a follow delay or not
export (bool) var EnableFollowDelay = true
export (float) var FollowSmoothing = 0.07

# allow the user to choose to allow mouse input if gamepad is not being used
export (bool) var EnableMouseInput = false
export (float) var MouseSensitivity = 2

# the zoom delay is used to disallow the player from changing the camera view super fast
export (float) var ZoomDelay = 0.5

# this lets us set the minimum distance that the raycast for detecting Confined Spaces will work
export (float) var MinConfinedSpaceDistance = 2.0

export (float) var MaxConfinedSpaceDistance = 8.0

# our local variables

# input variables
var cam_up = 0.0
var cam_right = 0.0
var player_right = 0.0
var player_up = 0.0
var zoom = 0
var stickInput = Vector2()

# node storage variables
var clip_cam
var view_cam 
var y_gimbal
var x_gimbal
var player
var collision_probe_shape
var helper_mesh

# our booleans
var can_clip = false
var confined_space = false
var clipping = false
var counting_down = false
var mouse_captured = false
var mouse_moved = false

# our arrays, probe is for bodies that can be clipped to by the camera, zooms is to hold our zoom positions
var probe = []
var zooms = []

# our offset variables
var gimbal_offset
var raycast_offset 

# other variables
var max_zoom_level
var rot_y_angle = 0
var new_lerp_weight
var distance = 0.0
var new_distance = 0.0
var clip_offset = 0.0
var view_cam_z = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# grab our nodes
	y_gimbal = self
	x_gimbal = $"X Gimbal"
	view_cam = get_node(ViewCamera)
	clip_cam = get_node(ClipCamera)
	player = get_node(ClipCameraException)
	helper_mesh = $"X Gimbal/HelperMesh"
	collision_probe_shape = $"X Gimbal/ViewCamera/CanClipDetector/CollisionShape"
	
	# set our helper meshes to be invisible
	helper_mesh.visible = false
	
	# set gimbal as top level
	self.set_as_toplevel(true)
	
	# set raycaster as toplevel
	$ConfinedSpaceCheck.set_as_toplevel(true)
	
	# store the position offset of the raycast node
	raycast_offset = $ConfinedSpaceCheck.global_transform.origin - player.global_transform.origin
	print("Stored the raycast's offset value as " + str(raycast_offset))
	
	
	# store the offset of the gimbal relative to its parent node
	gimbal_offset = self.transform.origin - player.transform.origin
	print("Stored the Gimbal's offset value as " + str(gimbal_offset))
	
	# find the zoom markers under the "ZoomMarkers" node, and store their origin.z component
	# in our zooms as our Zoom Levels
	var zoom_marker = $"X Gimbal/ClipCameraTarget/ZoomMarkers"
	var zoom_marker_count = zoom_marker.get_child_count()
	for z in zoom_marker_count:
		zooms.insert(z, zoom_marker.get_child(z).transform.origin.z)
		print("Added zoom value " + str(zooms[z]) + " to the zoom array")
		
	# ensure we set the max zoom level for the zoom array
	max_zoom_level = zoom_marker_count
	print("Max Zoom Level set to " + str(max_zoom_level))
	
	# set the default zoom level of the cameras
	# set the clip camera to be one unit BEHIND of the zoom marker
	clip_cam.transform.origin.z = zooms[0] + ClipCamOffset
	print("Clip Cam Positioned at " + str(clip_cam.transform.origin.z))
	
	# set the view camera to be one unit AHEAD of the zoom marker
	view_cam.transform.origin.z = zooms[0] - ViewCamOffset
	print("View Cam Positioned at " + str(view_cam.transform.origin.z))
	
	print("Zoom value 1 at " + str(zooms[0]))
	
	# set view_cam_z to the view cam's z transform
	view_cam_z = view_cam.transform.origin.z

	# add the ClipCameraException node
	clip_cam.add_exception(get_node(ClipCameraException))
	print("Added " + str(get_node(ClipCameraException).name) + " to " + str(get_node(ClipCamera).name) + " as collision exception")
	
	# set the size of our collision probe
	collision_probe_shape.shape.radius = CollisionRadius
	print("Set CollisionRadius to: " + str(collision_probe_shape.shape.radius))
	
	# capture the mouse if we have enabled mouse input
	if EnableMouseInput:
		mouse_captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	$ZoomTimer.wait_time = ZoomDelay
	
	new_lerp_weight = CameraSmoothing
	
	# set the default distance
	distance = view_cam_z

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	_get_input()
	_update_camera(delta)

# get our input for the camera
func _get_input():
	
	# get joystick movement data if we are not using the mouse
	if !mouse_captured:
		
		# store the player's input information
		player_right = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
		player_up = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
		
		# store the right movement
		cam_right = Input.get_action_strength("cam_look_left") - Input.get_action_strength("cam_look_right")
		
		# store the up movement
		cam_up = Input.get_action_strength("cam_look_up") - Input.get_action_strength("cam_look_down")
		
		# now store the movement in the input vector
		stickInput = Vector2(cam_right, cam_up)
		
		# now apply the deadzone
		stickInput = GameFunctions.apply_deadzone(stickInput, GameManager.StickDeadzone)
		
		# zoom the camera
		if Input.is_action_just_pressed("zoom") and !can_clip:
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
	# now check for occluding geometry
	_check_for_occlusion()
	
	# update the camera's position
	_position_camera()
	
	# now update the camera's rotation
	_rotate_camera(delta)
	
	# now check for any confined spaces
	_confined_space_check()
	
	# now rotate to the player
	_rotate_to_player()

# position the camera
func _position_camera():
	# position the gimbal to the player's position, plus the offset
	if EnableFollowDelay:
		self.global_transform.origin = lerp(self.global_transform.origin, 
		player.global_transform.origin + gimbal_offset, 
		FollowSmoothing)
	else:
		self.global_transform.origin = player.global_transform.origin + gimbal_offset
	
	# position the clip cam
	clip_cam.transform.origin.z = zooms[zoom] + ClipCamOffset

	
func _rotate_camera(delta):
	# clamp the x rotation
	var x_gimbal_rotation = x_gimbal.rotation_degrees
	x_gimbal_rotation.x = clamp(x_gimbal_rotation.x, MinCameraAngle, MaxCameraAngle)
	x_gimbal.rotation_degrees = x_gimbal_rotation
	
	# set the rotational values of the gimbals
	if !mouse_captured:
		self.rotate_y(stickInput.x * RotationSpeed * delta)
		x_gimbal.rotate_x(stickInput.y * RotationSpeed * delta)
	elif mouse_captured and mouse_moved:
		self.rotate_y(cam_right * MouseSensitivity * delta)
		x_gimbal.rotate_x(cam_up * MouseSensitivity * delta)
		
	# reset mouse_moved so that we don't update the gimbal's rotation automatically every frame
	# while using the mouse instead of the gamepad
	mouse_moved = false

# check for occluding objects
func _check_for_occlusion():
	
	# store the clip cam offset
	clip_offset = clip_cam.get_clip_offset()
	
	# determine if the clip camera is clipping
	if clip_offset > 0:
		clipping = true
	else:
		clipping = false
	
	# shorthand to determine if the probe array is empty
	var empty = probe.empty()
	
	# shorthand for player's stick input length
	var player_input = player.stickInput.length()

	# check if the CollisionProbe is hitting anything
	if !empty and clipping or confined_space and clipping:
		can_clip = true
	else:
		can_clip = false
		
	if can_clip:
		
		# set the new distance
		new_distance = zooms[zoom] - ViewCamOffset - clip_offset * ClipModifier
		
		# check the new distance. If it is less than the current distance, immediately clip to the new distance
		if new_distance < view_cam_z:
			view_cam_z = new_distance
		elif new_distance >= view_cam_z:
			# we are still clipping against something behind the camera while possibly in a confined space,
			# so move back slowly instead of snapping immediately to the clipping point
			distance = new_distance
	else:
		# set the new distance
		new_distance = zooms[zoom] - ViewCamOffset - clip_offset * ClipModifier
		
		# lerp the camera backwards with the clip offset in mind because there *IS* a collision, it's just
		# not registering yet but we know it will
		if clipping and new_distance >= view_cam_z:
			
			# set distance with clip offset in mind
			distance = new_distance
			
		elif clipping and stickInput.length() == 0 and player_input == 0:
			# we are not rotating the camera or moving the player, and we're still clipping to something,
			# so show the player by snapping the camera forward again
			view_cam_z = zooms[zoom] - ViewCamOffset - clip_offset * ClipModifier
		else:
			# no collision at all, so set the camera to the correct distance
			distance = zooms[zoom] - ViewCamOffset
			
	# ensure the camera doesn't go past its distance minimum
	if view_cam_z <= MinViewCamDistance:
		view_cam_z = MinViewCamDistance
		
	# position the camera to the currently defined distance
	view_cam_z = lerp(view_cam_z, distance, CameraSmoothing)
	
	# set the camera
	view_cam.transform.origin.z = view_cam_z

# check for confined spaces
func _confined_space_check():
	# check if we are colliding against geometry above the player
	if $ConfinedSpaceCheck.is_colliding():
		# calculate the distance and make sure it isn't below the min distance
		var collision_point = $ConfinedSpaceCheck.get_collision_point()
		var distance = $ConfinedSpaceCheck.global_transform.origin - collision_point
		if distance.length() >= MinConfinedSpaceDistance and distance.length() <= MaxConfinedSpaceDistance:
			confined_space = true
		else:
			confined_space = false
	else: # we are not colliding so set it to false
		confined_space = false
		
	# position the raycast
	$ConfinedSpaceCheck.global_transform.origin = player.global_transform.origin + raycast_offset
	
# rotate to orbit the player
func _rotate_to_player():
	if player.velocity.length() > 5 and !player.is_on_wall():
		# rotate the camera gimbal to the player's rotation
		if stickInput.x == 0 and stickInput.y == 0:
			if player.stickInput.x < 0:
				rot_y_angle = 1.8
			elif player.stickInput.x > 0:
				rot_y_angle = -1.8
	
			# rotate the camera in the direction given determined by player_right's value
			# and only rotate when the player is not directly walking backwards "into" the camera!
			if player.stickInput.x != 0:
				self.rotate_y((rot_y_angle/100) * abs(player.stickInput.x * 0.95))

# support mouse input
func _input(event):
	if mouse_captured:
		# move the gimbal depending on mouse movement
		if event is InputEventMouseMotion:
			cam_up = deg2rad(event.relative.y * -1)
			cam_right = deg2rad(event.relative.x)
			# set mouse_moved to true to tell the camera we are moving the gimbal
			mouse_moved = true
			
		# change the zoom level depending on which mouse wheel action has taken place
		if event is InputEventMouseButton:
			if event.is_action_pressed("mouse_zoom_out"):
				_zoom_camera(1)
			if event.is_action_pressed("mouse_zoom_in"):
				_zoom_camera(-1)

# change the zoom level of the camera
func _zoom_camera(var amount):
	# only change zoom levels while the timer is not counting down, to ensure
	# that the player cannot blast through the zoom levels too quickly!
	if !counting_down:
		$ZoomTimer.start(ZoomDelay)
		counting_down = true
		
	if $ZoomTimer.time_left == ZoomDelay:
		# cap the zoom level differently if using the mouse for input
		if mouse_captured:
			zoom += amount
			
			# don't let the player go past the last zoom level
			if zoom >= max_zoom_level - 1:
				zoom = max_zoom_level - 1
				
			# don't let the player go past the first zoom level
			elif zoom <= 0:
				zoom = 0
		else:
			# cap the zoom level back to 0 when using a controller, as a "cycle"
			if zoom >= max_zoom_level - 1:
				zoom = 0
			else:
				zoom += amount
				
	print(clip_cam.transform.origin.z)

# this tells us when the camera can clip against walls or other occluding objects
func _on_CanClipDetector_body_entered(body):
	if !body.is_in_group("noclip"):
		
		# check to make sure this body doesn't exist in the array.
		# if it doesn't, we will add it!
		if probe.find(body) == -1:
			probe.insert(probe.size(), body)
			#print("Added " + str(body) + " at index [" + str(probe.size()-1) + "]")

# this tells us when the camera has stopped clipping against walls
func _on_CanClipDetector_body_exited(body):
	if !body.is_in_group("noclip"):
		
		# check array to make sure it is not empty
		if probe.size() != -1:
			# search for the body and remove it
			var body_to_remove = probe.find(body)
			if body_to_remove != -1:
				probe.remove(body_to_remove)
				#print("Removed " + str(body) + " from index [" + str(probe.size()) + "]")
			
# when the zoomtimer times out, reset it
func _on_ZoomTimer_timeout():
	# stop the zoomtimer
	$ZoomTimer.stop()
	$ZoomTimer.wait_time = ZoomDelay
	counting_down = false
