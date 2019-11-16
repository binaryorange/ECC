extends Spatial

export (bool) var RotatePlatform = true
export (float) var RotateSpeed = 1.0

var change_parent = false
var reparenting = false
var on_platform
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if RotatePlatform:
		self.rotate_y(RotateSpeed * delta)
	
		
		if player:
			if player.on_platform:
				var offset = player.global_transform.origin - self.global_transform.origin
				if player.h != 0 or player.v != 0:
					player.set_as_toplevel(true)
					player.global_transform.origin = self.global_transform.origin + offset
				else:
					player.set_as_toplevel(false)


			

		 
func _on_EnterPlatform_body_entered(body):
	if body.is_in_group("inherit_platform") and !change_parent and !reparenting:
		change_parent = true
		reparenting = true
		call_deferred("do_enter", body)
		
func do_enter(body):
		var t = body.global_transform   
		get_parent().remove_child(body)
		self.add_child(body)
		body.global_transform = t
		reparenting = false
		on_platform = true
		player = get_node("TestPlayer")
		player.on_platform = true

func _on_ExitPlatform_body_exited(body):
	if body.is_in_group("inherit_platform") and change_parent and !reparenting:  
		change_parent = false
		reparenting = true
		call_deferred("do_exit", body)

func do_exit(body):
		get_node("TestPlayer").on_platform = false
		
		on_platform = false
		var t = body.global_transform        
		self.remove_child(body)
		get_parent().add_child(body)
		body.global_transform = t
		reparenting = false


