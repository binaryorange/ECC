extends Spatial

export (bool) var RotatePlatform = true
export (float) var RotateSpeed = 1.0
export (float) var IdleDuration = 1
export (float) var TravelDuration = 5.0

onready var tween = $UpdatePosition
onready var destination = $"Destination Marker".global_transform.origin
onready var platform = $"."

var change_parent = false
var reparenting = false
var on_platform
var player
var offset = Vector3.ZERO
var initial_pos = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# store the platform's initial position here
	initial_pos = self.global_transform.origin
	
	# ensure the destination marker doesn't move from its position in the world (for debug purposes)
	$"Destination Marker".set_as_toplevel(true)
	
	# start the tween 
	_init_moving()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if RotatePlatform:
		self.rotate_y(RotateSpeed * delta)
		
		var distance = initial_pos - destination
		var current_pos = self.global_transform.origin
	
		# if the player is on the platform and it is rotating, we want to make sure we
		# allow the player to retain independent rotation when they are moving on the platform
		if player:
			
			# ensure we are actually ON the platform
			if on_platform:
				
				# ensure we are moving
				if player.h != 0 or player.v != 0:
					player.set_rotation(player.rotation - self.rotation)

					
func _init_moving():
	
	tween.interpolate_property(self, "translation", initial_pos, destination, TravelDuration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, IdleDuration)
	tween.interpolate_property(self, "translation", destination, initial_pos, TravelDuration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, TravelDuration + IdleDuration * 2)
	tween.start()
		 
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
		player = get_node(body.name)


func do_exit(body):
		
		on_platform = false
		var t = body.global_transform        
		self.remove_child(body)
		get_parent().add_child(body)
		body.global_transform = t
		reparenting = false

func _on_EnterPlatform_body_exited(body):
	if body.is_in_group("inherit_platform") and change_parent and !reparenting:  
		change_parent = false
		reparenting = true
		call_deferred("do_exit", body)
