extends RigidBody2D

class_name Entity

signal damaged(damage)
signal no_enemies_detected()

enum INDIVIDUAL_BEHAVIOR_STATE {WALKING, FIGHTING, IDLE}
enum IMMEDIAT_

#@onready var weapon = $Weapon

@export var max_hp: int
@export var damage: int
@export var attack_time: float
@export var walk_speed: int
@export var is_ranged: bool

var behavior_state
var individual = false
var hp = max_hp

var nearby_enemies = []
var target

func enemy_value(enemy): #returns how valuable of a target 'enemy' would be, lower is better
	assert(false)
func find_target():
	var best_value
	var best_enemies = []
	var enemy_value
	for enemy in nearby_enemies:
		enemy_value = enemy_value(enemy)
		if best_value:
			if enemy_value > best_value:
				continue
			if enemy_value < best_value:
				best_enemies.clear()
		best_value = enemy_value
		best_enemies.append(enemy)
	if best_enemies.is_empty():
		no_enemies_detected.emit()
	else:
		target = best_enemies.pick_random()
	
func start_walking(point):
	behavior_state = INDIVIDUAL_BEHAVIOR_STATE.WALKING
func stop_walking():
	pass
func start_fighting():
	behavior_state = INDIVIDUAL_BEHAVIOR_STATE.FIGHTING
	#find_target()
func stop_fighting():
	pass
func start_idling():
	behavior_state = INDIVIDUAL_BEHAVIOR_STATE.IDLE
func stop_idling():
	pass

func take_damage(damage):
	if individual:
		hp -= damage
	else:
		damaged.emit(damage)

func _on_body_entered(body):
	if body.has_method("damage"):
		body.damage(self)
