extends Spatial

export (float) var RotateSpeed = 0.75
export (bool) var RotatePlatform = true

var on_platform = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if RotatePlatform:
		self.rotate_y(RotateSpeed * delta)
	

