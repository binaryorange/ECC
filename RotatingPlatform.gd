extends Spatial

export (float) var RotateSpeed = 0.75

var change_parent = false
var reparenting = false
var entity = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotate_y(RotateSpeed * delta)
	
	if entity and entity.on_platform:
		if entity.h != 0 or entity.v != 0:
			entity.set_rotation(entity.rotation - rotation)


func _on_EnterPlatform_body_entered(body):
	if body.is_in_group("inherit_platform") and !change_parent and !reparenting:
		body.on_platform = true
		change_parent = true
		reparenting = true
		call_deferred("do_enter", body)


func _on_EnterPlatform_body_exited(body):
	if body.is_in_group("inherit_platform") and change_parent and !reparenting: 
		body.on_platform = false
		change_parent = false
		reparenting = true
		call_deferred("do_exit", body)
		
func do_enter(body):
	var t = body.global_transform   
	get_parent().remove_child(body)
	self.add_child(body)
	body.global_transform = t
	reparenting = false
	entity = get_node(body.name)
	
func do_exit(body):
		var t = body.global_transform        
		self.remove_child(body)
		get_parent().add_child(body)
		body.global_transform = t
		reparenting = false
		entity = null
