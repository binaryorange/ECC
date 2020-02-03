extends Node


# this script houses all common game functions 


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# we use this function to apply the deadzone for controllers
func apply_deadzone(var input_vector, var deadzone):
	if input_vector.length() < deadzone:
		input_vector = Vector2.ZERO
	else:
		input_vector = input_vector.normalized() * ((input_vector.length() - deadzone) / (1 - deadzone))
		
	# return the input vector
	return input_vector
