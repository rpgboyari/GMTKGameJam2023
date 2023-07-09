extends Node2D

@export var parent_offset: int
@export var projectile_speed: int

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_timer: Timer = $Timer

var damage
var attack_time
var is_ranged

var attack_direction

func _ready():
	attack_timer.timeout.connect(_on_attack_end)
	_on_attack_end()

func _physics_process(delta):
	if !attack_timer.is_stopped() && is_ranged:
		position += attack_direction * projectile_speed * delta

func attack(direction):
	attack_direction = direction
	if !attack_timer.is_stopped():
		return
	position = attack_direction * parent_offset
	collision_shape.disabled = false
	show()
	attack_timer.start(attack_time)
	
func _on_attack_end():
	print_debug("attack ended attacked")
	hide()
	collision_shape.disabled = true
	attack_timer.stop()


func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if is_ranged:
		_on_attack_end()
	print_debug(str(body) + " hit!")
func _process(delta): # for testing
	if Input.is_action_just_pressed("Weapon_Test") && is_ranged:
		print_debug("weapon attacked")
		attack(get_viewport().get_mouse_position() - global_position)
