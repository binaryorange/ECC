extends Spatial

export (bool) var RotatePlatform = true
export (float) var RotateSpeed = 1.0
export (float) var IdleDuration = 4
export (float) var TravelDuration = 6.0
export (bool) var EnableDebugDraw = false

onready var tween = $UpdatePosition
onready var destination = $"Destination Marker".global_transform.origin
onready var platform = $"."

var parent_to_world = false
var parent_to_platform = false
var big_body = null
var reparenting = false
var on_platform
var entity
var offset = Vector3.ZERO
var initial_pos = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# store the platform's initial position here
	initial_pos = self.global_transform.origin
	
	# ensure the destination marker doesn't move from its position in the world (for debug purposes)
	$"Destination Marker".set_as_toplevel(true)
	
	# hide the destination marker
	if !EnableDebugDraw:
		$"Destination Marker".hide()
	else:
		$"Destination Marker".show()
	
	# start the tween 
	_init_moving()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if RotatePlatform:
		self.rotate_y(RotateSpeed * delta)
			
		# if the entity is on the platform and it is rotating, we want to make sure we
		# allow the entity to retain independent rotation when they are moving on the platform
		if entity and entity.on_platform:
			# ensure we are moving
			if entity.h != 0 or entity.v != 0:
				entity.set_rotation(entity.rotation - rotation)
				
	
	# parent the player to the platform when the player enters the trigger
	if reparenting and parent_to_platform:
		if big_body.stepping_on:
			big_body.new_parent = self
			big_body.on_platform = true
			call_deferred("do_enter", big_body)

	# parent the player back to the world when the player exits the trigger
	if reparenting and parent_to_world:
		if !big_body.stepping_on:
			big_body.new_parent = big_body.master_parent
		big_body.on_platform = false
		call_deferred("do_exit", big_body)

func _init_moving():
	
	tween.interpolate_property(self, "translation", initial_pos, destination, TravelDuration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, IdleDuration)
	tween.interpolate_property(self, "translation", destination, initial_pos, TravelDuration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, TravelDuration + IdleDuration * 2)
	tween.start()


func _on_EnterPlatform_body_entered(body):
	if body.is_in_group("inherit_platform") and !parent_to_platform and !reparenting:
		big_body = body
		parent_to_platform = true
		reparenting = true
		print("Landed!")


func _on_EnterPlatform_body_exited(body):
	if body.is_in_group("inherit_platform") and !parent_to_world and !reparenting: 
		parent_to_world = true
		reparenting = true
		
func do_enter(body):
	var t = body.global_transform   
	body.previous_parent = body.parent
	body.parent.remove_child(body)
	body.new_parent.add_child(body)
	body.global_transform = t
	entity = get_node(body.name)
	reparenting = false
	parent_to_platform = false
	print("Parented " + str(body.name) + " to " + str(self.name))
	
func do_exit(body):
	var t = body.global_transform   
	body.previous_parent = body.parent  
	body.parent.remove_child(body)
	body.new_parent.add_child(body)
	body.global_transform = t
	entity = null
	reparenting = false
	parent_to_world = false
	big_body = null
	print("Parented " + str(body.name) + " to " + str(get_parent().name))
