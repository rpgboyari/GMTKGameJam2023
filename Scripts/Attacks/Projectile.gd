class_name Projectile extends Area2D

@export var speed: int
var damage: int
var direction: Vector2
var ground_offset: int
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	position += speed * direction * delta

func fire(origin: Vector2, direction: Vector2):
	print_debug("projectile fired")
	var offset_vector = Vector2(0, ground_offset)
	sprite.position = Vector2.ZERO
#	self.direction = (direction - offset_vector).normalized()
	self.direction = (direction).normalized()
	position = origin
	rotation = self.direction.angle()
	sprite.global_position += offset_vector
	enable.call_deferred()

func disable():
	visible = false
	process_mode = PROCESS_MODE_DISABLED

func enable():
	visible = true
	process_mode = PROCESS_MODE_INHERIT
	
func _on_impact(impact):
	print_debug("projectile impacted " + str(impact))
	disable.call_deferred()


func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
		_on_impact(body)

func _on_area_entered(area):
	_on_impact(area)
