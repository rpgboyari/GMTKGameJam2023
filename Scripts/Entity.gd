class_name Entity extends CharacterBody2D

signal damaged(damage)

enum IMMEDIATE_STATE {WALKING, ATTACKING, IDLE}
enum TEAM {HERO, VILLAIN}

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon: Weapon = $Weapon

const MELEE_RANGE = 55

@export var weapon_shape: Shape2D
@export var weapon_sound_effects: Array[AudioStream]
@export var projectile: PackedScene
@export var max_hp: int
@export var damage: int
@export var attack_time: float
@export var walk_speed: int
@export var is_ranged: bool
@export var team: TEAM
@export var individual: bool = false
@export var sound_effects: Array

var immediate_state: IMMEDIATE_STATE

var hp = max_hp

func _ready():
	weapon.weapon_shape = weapon_shape
	weapon.sound_effects = weapon_sound_effects
	weapon.projectile = projectile
	weapon.damage = damage
	weapon.attack_time = attack_time
	match team:
		TEAM.HERO:
			weapon.collision_layer = 0b10
			weapon.collision_mask = 0b10
		TEAM.VILLAIN:
			weapon.collision_layer = 0b01
			weapon.collision_mask = 0b01

func attack(direction):
	animator.flip_h = direction.x < 0 #facing left
	immediate_state = IMMEDIATE_STATE.ATTACKING
	animator.play("attacking")
	weapon.attack(direction)
	await get_tree().create_timer(attack_time).timeout
	animator.stop()
	immediate_state = IMMEDIATE_STATE.IDLE

func take_damage(damage):
	if team == TEAM.HERO:
		play_random_sound()
	if individual:
		hp -= damage
		if hp <= 0:
			die()
	damaged.emit(damage)
func die():
	if team == TEAM.VILLAIN:
		play_random_sound()
	free()

func play_random_sound():
	var to_play = sound_effects.pick_random()
	audio_player.stop()
	audio_player.stream = to_play
	audio_player.play()
