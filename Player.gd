extends KinematicBody

export (float) var MoveSpeed = 200
export (float) var Gravity = -9.8

var velocity = Vector3(0, 0, 0)
var gravity = 0

var v
var h


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	
	# get the input
	h = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	v = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	velocity = Vector3(h, gravity, v) * MoveSpeed * delta
	
	velocity = move_and_slide(velocity, Vector3.DOWN)
	
