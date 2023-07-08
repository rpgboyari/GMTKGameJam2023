class_name Entity extends CharacterBody2D

signal damaged(damage)

enum INDIVIDUAL_BEHAVIOR_STATE {WALKING, FIGHTING, IDLE}

@onready var animator = $AnimatedSprite2D
#@onready var weapon = $Weapon

@export var max_hp: int
@export var damage: int
@export var attack_time: float
@export var walk_speed: int
@export var is_ranged: bool

var immediate_state

var invincible = false
var hp = max_hp


func take_damage(damage):
	if !invincible:
		hp -= damage
	damaged.emit(damage)
