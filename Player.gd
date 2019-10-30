extends KinematicBody

export (float) var MoveSpeed = 3
export (float) var Gravity = 19.80
export (float) var TerminalVelocity = -19.80
export (float) var AccelerationForce = 3
export (float) var DecelerationForce = 5
export (float) var JumpForce = 30


var velocity = Vector3(0, 0, 0)
var gravity = 0

var v
var h
var yVelocity = 0
var oldRot
var character

var camera


# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_node("ECC_ThirdPerson")
	character = get_node(".")
	oldRot = self.rotation

# warning-ignore:unused_argument
func _physics_process(delta):
	gravity = Gravity
	
	# get the input
	h = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	v = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	
	var x = camera.transform.basis.x * h
	var z = camera.transform.basis.z * v
	
	var move = x + z
	
	# zero the y of move
	move.y = 0
	
	velocity = move
	
	
	# get the horizontal velocity
	var hv = velocity
	hv.y = 0
	
	var new_pos = move * MoveSpeed
	var accel = DecelerationForce
	
	if (move.dot(hv) > 0):
		accel = AccelerationForce
		
	hv = hv.linear_interpolate(new_pos, accel * MoveSpeed)
	
	velocity = velocity.normalized()
	
	velocity.x = hv.x
	velocity.y = yVelocity
	velocity.z = hv.z
	
	velocity = move_and_slide(velocity, Vector3.DOWN)
	
	# account for gravity
	yVelocity -= gravity
	
	if $FloorTester.is_colliding():
		if Input.is_action_just_pressed("jump"):
			yVelocity = JumpForce
			
	# limit the y speed
	if yVelocity <= TerminalVelocity:
		yVelocity = TerminalVelocity
	
	# rotate the character
	if h != 0 or v != 0:
		var angle = atan2(hv.x, hv.z)
		var char_rot = character.get_rotation()
		char_rot.y = angle
		character.rotation = lerp(character.rotation, char_rot, 0.99)
		oldRot = char_rot


		
	
