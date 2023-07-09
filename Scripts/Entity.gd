class_name Entity extends CharacterBody2D

signal damaged(damage)

enum IMMEDIATE_STATE {WALKING, ATTACKING, IDLE}
enum TEAM {HERO, VILLAIN}

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon: Area2D = $Weapon

const MELEE_RANGE = 25

@export var max_hp: int
@export var damage: int
@export var attack_time: float
@export var walk_speed: int
@export var is_ranged: bool
@export var team: TEAM

var immediate_state: IMMEDIATE_STATE

var individual = false
var hp = max_hp

func _ready():
	weapon.damage = damage
	weapon.attack_time = attack_time
	weapon.is_ranged = is_ranged
	match team:
		TEAM.HERO:
			weapon.collision_mask = 0b10
		TEAM.VILLAIN:
			weapon.collision_mask = 0b01

func attack(direction):
	immediate_state = IMMEDIATE_STATE.ATTACKING
	animator.play("attacking")
	weapon.attack(direction)
	await get_tree().create_timer(attack_time).timeout
	animator.stop()
	immediate_state = IMMEDIATE_STATE.IDLE

func take_damage(damage):
	if individual:
		hp -= damage
	damaged.emit(damage)
