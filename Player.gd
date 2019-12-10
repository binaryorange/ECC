extends KinematicBody

export (float) var MoveSpeed = 3
export (float) var Gravity = -0.98
export (float) var TerminalVelocity = -19.80
export (float) var AccelerationForce = 3
export (float) var DecelerationForce = 5
export (float) var JumpForce = 30
export (NodePath) var FollowCamera

var velocity = Vector3(0, 0, 0)
var gravity = 0

var moveSpeed

var v
var h
var yVelocity = 0
var hv
var character

var camera
var is_jumping = false
var is_falling = false
var is_grounded = false
var on_platform = false
var stepping_on = false

var floor_test_array = []

var stickInput = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_node(FollowCamera)
	character = get_node(".")
	moveSpeed = MoveSpeed
	
	for i in range ($FloorTestArray.get_child_count()):
		floor_test_array.insert(floor_test_array.size(), $FloorTestArray.get_child(i))
		floor_test_array[i].add_exception(self)
		print("added " + str(floor_test_array[i].name))

# warning-ignore:unused_argument
func _physics_process(delta):
	# account for gravity
	gravity = Gravity
	yVelocity += gravity
	
	# get our input
	_get_input()
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and !is_jumping:
			yVelocity = JumpForce
			is_jumping = true
			
	# limit the y speed
	if yVelocity <= TerminalVelocity:
		yVelocity = TerminalVelocity
	
	# if our head touches the bottom of something, make us fall
	if is_on_ceiling():
		yVelocity = 0
	
	# reset is_jumping to false while falling
	if yVelocity >= 0:
		is_jumping = false
		is_falling = true
	else:
		is_falling = false
	
	# rotate the character
	if stickInput.x != 0 or stickInput.y != 0:
		var angle = atan2(-hv.x, -hv.z)
		var char_rot = character.get_rotation()
		char_rot.y = angle
		character.rotation = char_rot

func _get_input():
	
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
	velocity = move
	
	# get the horizontal velocity
	hv = velocity
	hv.y = 0
	
	var new_pos = move * moveSpeed
	var accel = DecelerationForce
	
	if (move.dot(hv) > 0):
		accel = AccelerationForce
		
	hv = hv.linear_interpolate(new_pos, accel * moveSpeed)
	
	velocity = velocity.normalized()
	
	velocity.x = hv.x
	velocity.y = yVelocity
	velocity.z = hv.z
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0), false, 4, 0.79, false)

