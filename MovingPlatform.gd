extends Spatial

export (bool) var RotatePlatform = true
export (float) var RotateSpeed = 1.0
export (float) var IdleDuration = 4
export (float) var TravelDuration = 6.0
export (bool) var EnableDebugDraw = false

onready var tween = $UpdatePosition
onready var destination = $"Destination Marker".global_transform.origin
onready var platform = $"."


var initial_pos = Vector3()
var on_platform

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# store the platform's initial position here
	initial_pos = self.global_transform.origin
	
	# ensure the destination marker doesn't move from its position in the world (for debugging purposes)
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

func _init_moving():
	
	tween.interpolate_property(self, "translation", initial_pos, destination, TravelDuration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, IdleDuration)
	tween.interpolate_property(self, "translation", destination, initial_pos, TravelDuration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, TravelDuration + IdleDuration * 2)
	tween.start()



