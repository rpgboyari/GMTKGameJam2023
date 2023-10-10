extends Entity_State#"res://Scripts/States/Entity_State.gd"
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
		_enemies.append_array(params.enemies)
		_connect_enemy_signals(params.enemies)
		return self
	else:
		print_debug(str(_entity) + " leaving fighting state for " + state_name)
		return super(state_name, params)

func process(delta):
	if _enemies.is_empty():
		print(str(_entity) + " done fighing")
		return pop_state()
	else:
		_choose_target()
	
	if _target_in_range():
		_entity.give_attack_command(_target.position - _entity.position)
	else:
		var destination
		if _entity.range > 0:
			destination = _target.position
		else:
			var target_right_side = _target_right_side()
			var target_left_side = _target_left_side()
			var right_side_distance = (target_right_side - _entity.position).length()
			var left_side_distance = (target_left_side - _entity.position).length()
			if right_side_distance < left_side_distance:
				destination = target_right_side
			else:
				destination = target_left_side
		
		return change_state("walking", {"destination":destination, "max_distance":3})#.process(delta)
	return self

func enter():
	return self

func _target_left_side():
	return _target.position - Vector2(_entity.collision_rect.size.x / 2 +
			_target.collision_rect.size.x / 2 + 2, 0)
func _target_right_side():
	return _target.position + Vector2(_entity.collision_rect.size.x / 2 +
			_target.collision_rect.size.x / 2 + 2, 0)

func _target_in_range() -> bool:
	if _entity.range > 0:
		if (_target.position - _entity.position).length() > _entity.range:
			return false
		var space_state = _entity.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
				_entity.position, _target.global_position, 0b10)
		var result = space_state.intersect_ray(query)
		return !result.is_empty() && result.collider == _target
	else:
		return (_close_to_point(_target_left_side(), 12) || 
				_close_to_point(_target_right_side(), 12))

func _choose_target():
	var new_target
	var new_target_value
	if _target:
		new_target = _target
		new_target_value = _targeting_value.call(_target)
	_enemies.shuffle()
	for enemy in _enemies:
		var enemy_value = _targeting_value.call(enemy)
		if !new_target_value || enemy_value < new_target_value:
			new_target = enemy
			new_target_value = enemy_value
	_target = new_target
	assert(_target, "choose target finished, but entity has no target. entity:" + str(_entity))

func _connect_enemy_signals(enemies):
	for enemy in enemies:
		enemy.dying.connect(_on_enemy_dying)
func _on_enemy_dying(enemy):
	_enemies.erase(enemy)
	if _target == enemy:
		_target = null

func pop_state():
	if _previous is WALKING_STATE:
		print(str(_entity) + " leaving a fighing state for a walking state")
	return super()
