class_name Projectile extends Area2D

@export var speed: int
var damage: int
var direction: Vector2

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	position += speed * direction * delta

func fire(direction: Vector2):
	print_debug("projectile fired")
	self.direction = direction
	position = Vector2.ZERO
	rotation = direction.angle()
	enable()

func disable():
	visible = false
	process_mode = PROCESS_MODE_DISABLED

func enable():
	visible = true
	process_mode = PROCESS_MODE_INHERIT
	
func _on_impact(impact):
	print_debug("projectile impacted " + str(impact))
	disable()


func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
		_on_impact(body)

func _on_area_entered(area):
	_on_impact(area)
