class_name Weapon extends Area2D

#@export var shape: Shape2D
#@export var texture: Texture
@export var TESTING: bool
@export var unique_shape: Shape2D
@export var sound_effects: Array[AudioStream]
@export var projectile: PackedScene
@export var damage: int
@export var attack_time: float
@export var parent_offset: int

@onready var attack_timer: Timer = $Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


var instantiated_projectiles = []
var projectile_index = 0
var attack_direction

func _ready():
	if unique_shape:
		collision_shape.shape = unique_shape
	
	#attack_timer.timeout.connect(_on_attack_end)
	#sprite.texture = texture
	#audio_player.stream = sound_effect
	
	if projectile:
		var to_add: Projectile
		print_debug("instantiating projectiles")
		for i in 3:
			to_add = projectile.instantiate()
			get_node("/root").add_child(to_add)
			instantiated_projectiles.append(to_add)
	
	attack_end()


func attack(direction, origin = Vector2.ZERO):
	attack_direction = direction
	rotation = attack_direction.angle()
	#print_debug(str(self) + " attacking from " + str(origin) + " at attack_direction: " 
	#		+ str(attack_direction) + " times parent offset: " + str(parent_offset))
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
	await attack_timer.timeout
	
	attack_end()

func attack_end():
	hide()
	call_deferred("disable_collision")
	#collision_shape.disabled = true
	attack_timer.stop()
func disable_collision():
	collision_shape.disabled = true


func _on_body_entered(body):
	print_debug(str(get_parent()) + "'s weapon hit " + str(body))
	if body.has_method("take_damage"):
		body.take_damage(damage)
func _process(delta): # for testing
	if Input.is_action_just_pressed("Weapon_Test") && TESTING:
		attack((get_viewport().get_mouse_position() - global_position).normalized())

