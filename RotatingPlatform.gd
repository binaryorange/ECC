extends Spatial

export (float) var RotateSpeed = 0.75
export (bool) var RotatePlatform = true

var parent_to_platform = false
var parent_to_world = false
var reparenting = false
var entity = null
var on_platform = false
var big_body

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if RotatePlatform:
		self.rotate_y(RotateSpeed * delta)
	
#	if entity and entity.on_platform:
#		if entity.h != 0 or entity.v != 0:
#			entity.rotation = entity.rotation - rotation
#
#	# parent the player to the platform when the player enters the trigger
#	if reparenting and parent_to_platform:
#		big_body.new_parent = self
#		big_body.on_platform = true
#		call_deferred("do_enter", big_body)
#
#	# parent the player back to the world when the player exits the trigger
#	if reparenting and parent_to_world:
#		call_deferred("do_exit", big_body)





#func _on_EnterPlatform_body_entered(body):
#	if body.is_in_group("inherit_platform") and !parent_to_platform and !reparenting:
#		body.stepping_on = true
#		big_body = body
#		parent_to_platform = true
#		reparenting = true
#
#
#func _on_EnterPlatform_body_exited(body):
#	if body.is_in_group("inherit_platform") and !parent_to_world and !reparenting: 
#		parent_to_world = true
#		reparenting = true
		
		
func do_enter(body):
	var t = body.global_transform   
	body.parent.remove_child(body)
	body.new_parent.add_child(body)
	body.global_transform = t
	entity = get_node(body.name)
	reparenting = false
	parent_to_platform = false
	print("Parented " + str(body.name) + " to " + str(self.name))
	
func do_exit(body):
	body.new_parent = body.master_parent
	body.stepping_on = false
	var t = body.global_transform  
	body.parent.remove_child(body)
	body.new_parent.add_child(body)
	body.global_transform = t
	entity = null
	reparenting = false
	parent_to_world = false
	body.on_platform = false
	print("Parented " + str(body.name) + " to " + str(get_parent().name))
	big_body = null
