extends PathFollow2D

#var walking: bool = false
var previous_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	previous_position = position
	progress = 0.0
