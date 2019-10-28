extends KinematicBody

export (float) var MoveSpeed = 10
export (float) var Gravity = 9.8
export (float) var JumpForce = 90.0

var velocity = Vector3(0, 0, 0)
var gravity = 0

var v
var h
var oldRot
var character
var acceleration = 3
var deceleration = 5

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
	velocity = velocity.normalized()
	
	# get the horizontal velocity
	var hv = velocity
	hv.y = 0
	
	var new_pos = move * MoveSpeed
	var accel = deceleration
	
	if (move.dot(hv) > 0):
		accel = acceleration
		
	hv = hv.linear_interpolate(new_pos, accel * MoveSpeed * delta)
	
	velocity.x = hv.x
	velocity.z = hv.z
	
	# check for a jump
	if $FloorTester.is_colliding():
		if Input.is_action_just_pressed("jump"):
			velocity.y += JumpForce
	else:
		velocity.y -= gravity
		
	velocity = move_and_slide(velocity, Vector3.DOWN)
	
	# rotate the character
	if velocity.x != 0 or velocity.z != 0:
		var angle = atan2(hv.x, hv.z)
		var char_rot = character.get_rotation()
		char_rot.y = angle
		character.set_rotation(char_rot)
		oldRot.y = angle
	else:
		character.set_rotation(oldRot)


		
	
