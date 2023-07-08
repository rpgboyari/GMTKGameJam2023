class_name Entity extends CharacterBody2D

signal damaged(damage)

enum INDIVIDUAL_BEHAVIOR_STATE {WALKING, FIGHTING, IDLE}
enum TEAM {HERO, VILLAIN}

@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
#@onready var weapon = $Weapon

@export var max_hp: int
@export var damage: int
@export var attack_time: float
@export var walk_speed: int
@export var is_ranged: bool
@export var team: TEAM

var immediate_state: INDIVIDUAL_BEHAVIOR_STATE

var individual = false
var hp = max_hp

func attack(direction):
	immediate_state = INDIVIDUAL_BEHAVIOR_STATE.FIGHTING
	animator.play("attacking")
	#weapon.attack(direction)
	await get_tree().create_timer(attack_time).timeout
	animator.stop()
	immediate_state = INDIVIDUAL_BEHAVIOR_STATE.IDLE

func take_damage(damage):
	if individual:
		hp -= damage
	damaged.emit(damage)
