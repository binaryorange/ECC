extends Panel

export (NodePath) var Player

var player

func _ready():
	player = get_node(Player)
	
	# ensure that we are hiding the debug panel
	$Debug.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player:
		var xPos = " X:" + str(round(player.global_transform.origin.x))
		var yPos = " Y:" + str(round(player.global_transform.origin.y))
		var zPos = " Z:" + str(round(player.global_transform.origin.z))
		
		var xRot = " X:" + str(player.rotation_degrees.x)
		var yRot = " Y:" + str(player.rotation_degrees.y)
		var zRot = " Z:" + str(player.rotation_degrees.z)
		
		$Debug/Velocity.text = "Velocity: " + str(player.new_velocity)
		$Debug/Acceleration.text = "Acceleration: " + str(player.accel)
		$Debug/Deceleration.text = "Deceleration: " + str(player.DecelerationForce)
		
		$Debug/Grounded.text = "Grounded: " + str(player.is_on_floor())
		$Debug/Falling.text = "Falling: " + str(player.is_falling)
		$Debug/Jumping.text = "Jumping: " + str(player.is_jumping)
		$Debug/CanSlide.text = "Can Slide: " + str(player.can_slide)
		$Debug/Parent.text = "Current Parent: " + str(player.parent.name)
		$Debug/Position.text = "Player Position: " + xPos + yPos + zPos
		$Debug/Rotation.text = "Player Rotation: " + xRot + yRot + zRot
		
		$Debug/WorldName.text = "World Name: " + str(get_parent().name)
		$Debug/Objects.text = "Objects In World: " + str(get_parent().get_child_count() - 1)


func _on_ShowInfo_pressed():
	$Debug.visible = !$Debug.visible
	$ShowInfo.visible = !$ShowInfo.visible


func _on_HideInfo_pressed():
	$Debug.visible = !$Debug.visible
	$ShowInfo.visible = !$ShowInfo.visible
