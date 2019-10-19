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

# this will capture our raycast node
export (NodePath) var RayCastNode

# export our zoom levels in an array
export(Array, NodePath) var ZoomLevels

# export our lerpweight for the camera
export (float) var LerpWeight = 0.03

# export our rotational speed
export (float) var RotationSpeed = 2.0

# export our max occlude distance
export (float) var MaxOccludeDistance = 5.0

# export our max and min camera angles
export (float) var MaxCameraAngle = 70
export (float) var MinCameraAngle = -35

# export our clip offset multiplier
export (float) var ClipOffsetMultiplier = 1

# export our view cam distance modifier
export (float) var ViewCamDistanceModifier = 0.15

# our local variables
var cam_up : float = 0.0
var cam_right : float = 0.0
var zoom : int = 0
var clip_cam
var view_cam 
var can_clip : bool = true
var y_gimbal
var x_gimbal
var max_zoom_level
var zoom_level_array = []
var gimbal_offset
var raycast
var x_rot
var is_in_confined_space = false

# hide these when we are running the game
var helper_mesh

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# grab our nodes
	y_gimbal = self
	x_gimbal = $"X Gimbal"
	view_cam = get_node(ViewCamera)
	clip_cam = get_node(ClipCamera)
	helper_mesh = $"X Gimbal/HelperMesh"
	raycast = get_node(RayCastNode)
	
	# set our helper meshes to be invisible
	helper_mesh.visible = false
	
	# set gimbal as top level
	self.set_as_toplevel(true)
	
	# store the offset of the gimbal relative to its parent node
	gimbal_offset = self.transform.origin - get_parent().transform.origin
	
	# add the zoom nodes to the array
	for z in ZoomLevels.size():
		zoom_level_array.insert(z, get_node(ZoomLevels[z]).transform.origin.z)
		
	# ensure we set the max zoom level for the zoom array
	max_zoom_level = ZoomLevels.size()
	
	# set the default zoom level of the cameras
	clip_cam.transform.origin.z = zoom_level_array[0]
	view_cam.transform.origin.z += ViewCamDistanceModifier
	raycast.transform.origin.z += ViewCamDistanceModifier

	# add the ClipCameraException node
	clip_cam.add_exception(get_node(ClipCameraException))
	raycast.add_exception(get_node(ClipCameraException))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_get_input()
	_update_camera(delta)

# get our input for the camera
func _get_input():
	# store the right movement
	cam_right = Input.get_action_strength("cam_look_right") - Input.get_action_strength("cam_look_left")
	
	# store the up movement
	cam_up = Input.get_action_strength("cam_look_down") - Input.get_action_strength("cam_look_up")
	
	# zoom the camera
	if Input.is_action_just_pressed("zoom"):
		
		# check that the zoom level isn't past the cap
		if zoom >= max_zoom_level - 1:
			zoom = 0
		else:
			zoom += 1
		
		print(zoom)

# update the camera's position and rotation
func _update_camera(delta):
	
	# position the gimbal to the player's position, plus the position of the gimbal
	self.transform.origin = get_parent().transform.origin + gimbal_offset
	
	# position the clip cam
	clip_cam.transform.origin.z = zoom_level_array[zoom]
	
	# clamp the x rotation
	var x_gimbal_rotation = x_gimbal.rotation_degrees
	x_gimbal_rotation.x = clamp(x_gimbal_rotation.x, MinCameraAngle, MaxCameraAngle)
	x_gimbal.rotation_degrees = x_gimbal_rotation
	
	# set the rotational values of the gimbals
	self.rotate_y(cam_right * RotationSpeed * delta)
	x_gimbal.rotate_x(cam_up * RotationSpeed * delta)
	
	# now check for occluding geometry
	_check_for_occlusion()

# check for occluding objects by casting a ray back to the player
func _check_for_occlusion():
	# store the gimbal's x rotation
	x_rot = x_gimbal.rotation_degrees.x
	
	# ensure the raycast node is positioned at the appropriate zoom level
	raycast.transform.origin.z = zoom_level_array[zoom] + ViewCamDistanceModifier
	
	# cast a ray from the RayCast node
	raycast.set_cast_to(Vector3(0, 0, abs(zoom_level_array[zoom] + ViewCamDistanceModifier)))
	
	# check if it's hitting anything
	if raycast.is_colliding():
		if !raycast.get_collider().is_in_group("Player"):
			
			var hit_pos = raycast.get_collision_point()
			var difference = (raycast.global_transform.origin - hit_pos)
			var distance = difference.length()
			print (str(distance) + "/" + str(MaxOccludeDistance))
	
			if distance < MaxOccludeDistance:
				can_clip = true
			else:
				# check to see if we are rotating the camera. if we aren't, clip then
				if cam_right != 0:
					can_clip = false
				else:
					# check to see if we are in a confined space
					if is_in_confined_space:
						can_clip = true
					else:
						can_clip = false
						
	else:
		can_clip = true
						
	# if we are clipping, set the view cam's local z to the clip cam's information
	if can_clip:
		
		# get the clip cam's clip offset
		var clip_offset = clip_cam.get_clip_offset()
	
		# set the view cam's position
		if clip_offset > 0:

			# show the target
			view_cam.transform.origin.z = zoom_level_array[zoom] + ViewCamDistanceModifier + clip_offset * ClipOffsetMultiplier
				
		else:
			view_cam.transform.origin.z = lerp(view_cam.transform.origin.z, 
			zoom_level_array[zoom] + ViewCamDistanceModifier, 
			LerpWeight)

# tells us when the player has entered a confined space
func _on_ConfinedSpaceArea_body_entered(body):
	is_in_confined_space = true


# tells us when the player has exited a confined space
func _on_ConfinedSpaceArea_body_exited(body):
	is_in_confined_space = false
