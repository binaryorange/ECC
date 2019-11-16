extends Spatial

export (bool) var RotatePlatform = true
export (float) var RotateSpeed = 1.0

var change_parent = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if RotatePlatform:
		self.rotate_y(RotateSpeed * delta)
		
		# set which area is active based on change_parent
		if change_parent:
			$ExitPlatform/CollisionShape.disabled = false
			$EnterPlatform/CollisionShape.disabled = true
		else:
			$ExitPlatform/CollisionShape.disabled = true
			$EnterPlatform/CollisionShape.disabled = false
			
func _on_EnterPlatform_body_entered(body):
	if body.is_in_group("inherit_platform") and !change_parent:
		print("Enter!")
		var t = body.global_transform   
		print(t)    
		get_parent().remove_child(body)
		print(get_parent().remove_child(body))
		self.add_child(body)
		print(self.add_child(body))
		body.global_transform = t
		change_parent = true

func _on_ExitPlatform_body_exited(body):
	if body.is_in_group("inherit_platform") and change_parent:  
		print("Exit!")
		var t = body.global_transform        
		self.remove_child(body)
		get_parent().add_child(body)
		body.global_transform = t
		change_parent = false

