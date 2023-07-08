class_name AI_Entity extends Entity

signal no_enemies_detected()

@onready var navigation_agent = $NavigationAgent2D

var long_term_state

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
	long_term_state = INDIVIDUAL_BEHAVIOR_STATE.WALKING
	animator.play("walking")
func start_fighting():
	long_term_state = INDIVIDUAL_BEHAVIOR_STATE.FIGHTING
	find_target()
func start_idling():
	long_term_state = INDIVIDUAL_BEHAVIOR_STATE.IDLE
	animator.stop()
