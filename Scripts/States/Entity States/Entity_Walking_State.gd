extends Entity_State#"res://Scripts/States/Entity_State.gd"
const _DODGE_STEP = 16
const _OFFSET_VARIANCE = 4
var _path
var _progress
var _destination
var _offset
#optional variables:
var _speed
var _max_distance

func _init(params):
	super(params)
	assert(params.destination, "tried to put " + str(_entity) + " in walking state without providing a destination")
	_path = _map.find_path(_map.world_to_map(_entity.position), _map.world_to_map(params.destination))
	_offset = Vector2.ZERO
	_offset.x = _map.tile_set.tile_size.x / 2 # int(_entity.position.x) % _map.tile_set.tile_size.x
	#_offset.x += randi_range(-_OFFSET_VARIANCE, _OFFSET_VARIANCE) # _entity.position.x - int(_entity.position.x)
	_offset.y = _map.tile_set.tile_size.y / 2 # int(_entity.position.y) % _map.tile_set.tile_size.y
	#_offset.y += randi_range(-_OFFSET_VARIANCE, _OFFSET_VARIANCE) # _entity.position.y - int(_entity.position.y)
	if !_path: _path = [_map.world_to_map(_entity.position)]
	_speed = params.speed if params.has("speed") else false
	_max_distance = params.max_distance if params.has("max_distance") else false
	_progress = 1

func _destination_setup():
	if _progress == _path.size() || (_max_distance && _progress == _max_distance):
			return pop_state()
	_destination = _map.map_to_world(_path[_progress])
	var destination_on_edge = _map.tile_on_edge(_path[_progress])
	var old_offset = _offset
	if destination_on_edge:
		_offset.x = _map.tile_set.tile_size.x / 2
		_offset.x -= destination_on_edge.x * ((_entity.collision_rect.size.x
				- _map.tile_set.tile_size.x) / 2 + 5)
	_destination += _offset
	
	var travel_dir = (_destination - _entity.position).normalized()
	if (old_offset - _offset).length() > 0.1 && abs(travel_dir.y) > 0.7:
		var dodge_wall_destination = _map.map_to_world(_map.world_to_map(_entity.position))
		dodge_wall_destination += _offset
		print(str(_entity) + " dodging!")
		return change_state("direct_walking", {"destination":dodge_wall_destination})
	else:
		return self

func enter():
	return _destination_setup()

func process(delta):
	if _close_to_point(_destination): #|| distance_moved < 0.1:
		_progress += 1
		var destination_setup = _destination_setup()
		if destination_setup != self: return destination_setup.process(delta)
	var direction = _destination - _entity.position
	_entity.give_walk_command(direction, _speed)
	return self

	# --AVOIDANCE START--
#	var space_state = _entity.get_world_2d().direct_space_state
#	var entity_rect = _entity.collision_rect
#
#	var rect_position = entity_rect.position + _entity.position
#	var top_corner
#	var bottom_corner
#	if _destination.x * _destination.y > 0:
#		top_corner = rect_position + Vector2(entity_rect.size.x, 0) #top right
#		bottom_corner = rect_position + Vector2(0, entity_rect.size.y) #bottom left
#	else:
#		top_corner = rect_position #top left
#		bottom_corner = rect_position + entity_rect.size #bottom right
#
#	var top_ray = PhysicsRayQueryParameters2D.create(
#			top_corner, _destination, _entity.collision_mask)
#	var bottom_ray = PhysicsRayQueryParameters2D.create(
#			bottom_corner, _destination, _entity.collision_mask)
#	var top_hit = space_state.intersect_ray(top_ray)
#	var bottom_hit = space_state.intersect_ray(bottom_ray)
#
#	var direction = _destination - _entity.position
#	if top_hit.is_empty() && bottom_hit.is_empty():
#		_entity.give_walk_command(direction, _speed)
#		return self
#
#	var hit_direction
#	if top_hit.is_empty() != bottom_hit.is_empty():
#		hit_direction = top_corner if !top_hit.is_empty() else bottom_corner
#	else:
#		if (_entity.position.distance_squared_to(top_hit.position) < 
#				_entity.position.distance_squared_to(bottom_hit.position)):
#			hit_direction = top_corner
#		else:
#			hit_direction = bottom_corner
#	hit_direction -= _entity.position
#	var dodge_direction
#	if direction.y * hit_direction.x > 0: #dodge right
#		dodge_direction = Vector2(-direction.y, direction.x)
#	else: #dodge left
#		dodge_direction = Vector2(direction.y, -direction.x)
#	var dodge_destination = _entity.position + (dodge_direction.normalized() * _DODGE_STEP)
#	print_debug(str(_entity) + " dodging to " + str(dodge_destination))
#	return change_state("walking", 
#			{"destination":dodge_destination,
#			"speed":_speed})

func pop_state():
	_previous._reentry_position = _entity.position
	return super()
