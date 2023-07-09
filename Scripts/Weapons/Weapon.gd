class_name Weapon extends Area2D

#@export var shape: Shape2D
#@export var texture: Texture
var sound_effects: Array[AudioStream]
var projectile: PackedScene
var damage: int
var attack_time: int
var parent_offset: int
var weapon_shape
#var TESTING: bool

@onready var attack_timer: Timer = $Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


var instantiated_projectiles = []
var projectile_index = 0
var attack_direction

func _ready():
	if weapon_shape:
		collision_shape.shape = weapon_shape
	attack_timer.timeout.connect(_on_attack_end)
	#collision_shape.shape = shape
	#sprite.texture = texture
	#audio_player.stream = sound_effect
	
	if projectile:
		var to_add: Projectile
		print_debug("instantiating projectiles")
		for i in 3:
			to_add = projectile.instantiate()
			get_node("/root").add_child(to_add)
			instantiated_projectiles.append(to_add)
	
	_on_attack_end()


func attack(direction, origin = Vector2.ZERO):
	attack_direction = direction
	rotation = attack_direction.angle()
	#print_debug(str(self) + " attacking from " + str(origin) + " at attack_direction: " + str(attack_direction) + " times parent offset: " + str(parent_offset))
	#print_debug("attack_direction: " + str(attack_direction) + " * parent_offset: " + str(parent_offset) + " + origin: " + str(origin))
	position = attack_direction * parent_offset + origin
	#print_debug("new position " + str(position))
	collision_shape.disabled = false
	show()
	
	if !sound_effects.is_empty():
		audio_player.stream = sound_effects.pick_random()
		audio_player.play()
	
	if !instantiated_projectiles.is_empty():
		var to_shoot = instantiated_projectiles[projectile_index]
		to_shoot.collision_mask = collision_mask
		print_debug("shooting " + str(to_shoot))
		to_shoot.attack(attack_direction, global_position)
		projectile_index = (projectile_index + 1) % 3
	
	attack_timer.start(attack_time)
	
func _on_attack_end():
	hide()
	call_deferred("disable_collision")
	#collision_shape.disabled = true
	attack_timer.stop()
func disable_collision():
	collision_shape.disabled = true


func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	print_debug(str(body) + " hit!")
#func _process(delta): # for testing
#	if Input.is_action_just_pressed("Weapon_Test") && TESTING:
#		attack((get_viewport().get_mouse_position() - global_position).normalized())
