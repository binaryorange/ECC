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
var oldRot
var character

var camera
var is_jumping = false
var is_falling = false
var is_grounded = false
var on_platform = false


# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_node(FollowCamera)
	character = get_node(".")
	oldRot = self.rotation
	moveSpeed = MoveSpeed

# warning-ignore:unused_argument
func _physics_process(delta):
	gravity = Gravity
	# account for gravity
	yVelocity += gravity
	
	# get the input
	h = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	v = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	var x = camera.transform.basis.x * h
	var z = camera.transform.basis.z * v
	
	var move = x + z
	
	# zero the y of move
	move.y = 0
	
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
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
	
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
	if h != 0 or v != 0:
		var angle = atan2(-hv.x, -hv.z)
		var char_rot = character.get_rotation()
		char_rot.y = angle
		character.rotation = char_rot
