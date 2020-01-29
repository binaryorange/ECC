extends KinematicBody

export (float) var MoveSpeed = 3
export (float) var Gravity = -0.98
export (float) var Downforce = -2.0
export (float) var TerminalVelocity = -19.80
export (float) var AccelerationForce = 2
export (float) var DecelerationForce = 0.005
export (float) var AccelerationRate = 0.25
export (float) var SlipForce = 3.0
export (float) var JumpForce = 30
export (bool) var EnableSlide = true
export (NodePath) var FollowCamera

var velocity = Vector3(0, 0, 0)
var gravity = 0
var accel_time = 0.1

var moveSpeed

var v
var h
var yVelocity = 0
var hv
var character
var accel
var parent

var camera
var is_jumping = false
var is_falling = false
var is_grounded = false
var can_slide = false

var floor_test_array = []

var stickInput = Vector2()
var new_velocity = Vector3()
var old_velocity = Vector3()


# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_node(FollowCamera)
	character = get_node(".")
	moveSpeed = MoveSpeed
	
	for i in range ($FloorTestArray.get_child_count()):
		floor_test_array.insert(floor_test_array.size(), $FloorTestArray.get_child(i))
		floor_test_array[i].add_exception(self)
		print("added " + str(floor_test_array[i].name))
		
		
	if EnableSlide:
		can_slide = true
	else:
		can_slide = false

# warning-ignore:unused_argument
func _physics_process(delta):
	parent = $DynamicPlatformCheck.prev_parent
	
	# get our input
	_get_input(delta)
	
	if is_on_floor():
		yVelocity = Downforce
	else:
		# account for gravity
		gravity = Gravity
		yVelocity += gravity
		
	if Input.is_action_just_pressed("jump") and !is_jumping and is_on_floor():
		yVelocity = JumpForce
		is_jumping = true
			
	# limit the y speed
	if yVelocity <= TerminalVelocity:
		yVelocity = TerminalVelocity

	if is_on_ceiling():
		yVelocity = TerminalVelocity/4
	
	# reset is_jumping to false while falling
	if yVelocity < 0 and !is_on_floor():
		is_jumping = false
		is_falling = true
	elif is_on_floor():
		is_jumping = false
		is_falling = false
	else:
		is_falling = false
	
	# rotate the character
	if stickInput.x != 0 or stickInput.y != 0:
		var angle = atan2(-hv.x, -hv.z)
		var char_rot = character.get_rotation()
		char_rot.y = angle
		character.rotation = char_rot
		

		
	_sliding()

func _get_input(delta):
	
	# get the input
	h = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	v = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	# store the input in a Vector2
	stickInput = Vector2(h, v)
	
	# apply the deadzone function to the input vector
	stickInput = GameFunctions.apply_deadzone(stickInput, GameManager.StickDeadzone)

	
	# store the camera's tranform vectors multiplied by our input vectors
	var x = camera.transform.basis.x * stickInput.x
	var z = camera.transform.basis.z * stickInput.y
	
	
	# create our movement vector
	var move = x + z
	
	# zero the y of move
	move.y = 0
	
	# apply our movement vector to our velocity vector
	if EnableSlide:
		if stickInput.length() > 0:
			velocity = move
	else:
		velocity = move
	
	
	# get the horizontal velocity
	hv = velocity
	hv.y = yVelocity
	
	var new_pos = move * moveSpeed
	
	if (move.dot(hv) > 0):
		if EnableSlide and is_on_floor():
			# slowly increase the acceleration rate as the player begins to move on ice
			if accel != AccelerationForce:
				accel_time *= AccelerationRate
				accel = accel_time
				
				# when accel is equal to the AccelerationForce, break out of here
				if accel >= AccelerationForce:
					accel = AccelerationForce
					accel_time = 0.1
		else:
			accel = AccelerationForce
	else:
		accel_time = 0.1
		accel = DecelerationForce

	hv = hv.linear_interpolate(new_pos, accel * moveSpeed)
	
	velocity = velocity.normalized()
	
	velocity.x = hv.x
	velocity.y = yVelocity
	velocity.z = hv.z
	
	new_velocity = velocity
	
	new_velocity = move_and_slide(new_velocity, Vector3(0, 1, 0), true, 4, 0.79, false)
	
	# always ensure we have the y velocity correct
	new_velocity.y = yVelocity
		
func _sliding():
	# allow the player to slide when can_slide is true
	if can_slide:
		EnableSlide = true
	else:
		EnableSlide = false

