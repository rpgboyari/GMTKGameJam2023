extends "res://Scripts/States/Entity_State.gd"
var _targeting_value
var _enemies
var _target

func _init(params):
	super(params)
	assert(params.targeting_value, "tried to put " + str(_entity) + " in fighting state without providing targeting value")
	_targeting_value = params.targeting_value
	assert(params.enemies, "tried to put " + str(_entity) + " in fighting state without providing enemies")
	_enemies = params.enemies
	_connect_enemy_signals(_enemies)
	print_debug(str(_entity) + " entered fighting state")

func change_state(state_name, params):
	if state_name == "fighting":
		assert(params.enemies, "tried to put " + str(_entity) + " in fighting state without providing enemies")
		_enemies.append(params.enemies)
		_connect_enemy_signals(params.enemies)
		return self
	else:
		print_debug(str(_entity) + " leaving fighting state for " + state_name)
		return super(state_name, params)

func process(delta):
	if !_target:
		var potential_targets = []
		var lowest_target_value
		for enemy in _enemies:
			var enemy_value = _targeting_value.call(enemy)
			if !lowest_target_value || lowest_target_value > enemy_value:
				potential_targets.clear()
				lowest_target_value = enemy_value
				potential_targets.append(enemy)
			elif lowest_target_value == enemy_value:
				potential_targets.append(enemy)
		_target = potential_targets.pick_random()
		if !_target:
			print_debug(str(_entity) + " popping out of fighting state")
			return pop_state()
	
	
	if _close_to_point(_target.position) || _entity.is_ranged:
		_entity.give_attack_command(_target.position - _entity.position)
	else:
		return change_state("walking", {"destination": _target.position})
	return self

func enter():
	return self

func _connect_enemy_signals(enemies):
	for enemy in enemies:
		enemy.dying.connect(_on_enemy_dying)
func _on_enemy_dying(enemy):
	_enemies.erase(enemy)
	if _target == enemy:
		_target = null
