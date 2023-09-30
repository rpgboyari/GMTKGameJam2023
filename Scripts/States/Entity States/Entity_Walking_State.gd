extends "res://Scripts/States/Entity_State.gd"
var _destination
var _speed
var _previous_position = Vector2.ZERO

func _init(params):
	super(params)
	assert(params.destination, "tried to put " + str(_entity) + " in walking state without providing a destination")
	_destination = params.destination
	_speed = params.speed if params.has("speed") else false

func process(delta):
	if _close_to_point(_destination):
		return pop_state()
	
	var distance_moved = (_previous_position - _entity.position).length_squared()
	if distance_moved < 0.1: #entity didn't move last frame
		return pop_state()
	_previous_position = _entity.position
	# --AVOIDANCE START--
	var space_state = _entity.get_world_2d().direct_space_state
	var entity_rect = _entity.collision_rect
	
	var rect_position = entity_rect.position + _entity.position
	var top_corner
	var bottom_corner
	if _destination.x * _destination.y > 0:
		top_corner = rect_position + Vector2(entity_rect.size.x, 0) #top right
		bottom_corner = rect_position + Vector2(0, entity_rect.size.y) #bottom left
	else:
		top_corner = rect_position #top left
		bottom_corner = rect_position + entity_rect.size #bottom right
		
	var top_ray = PhysicsRayQueryParameters2D.create(
			top_corner, _destination, _entity.collision_mask)
	var bottom_ray = PhysicsRayQueryParameters2D.create(
			bottom_corner, _destination, _entity.collision_mask)
	var top_hit = space_state.intersect_ray(top_ray)
	var bottom_hit = space_state.intersect_ray(bottom_ray)
	
	var direction = _destination - _entity.position
	if top_hit.is_empty() != bottom_hit.is_empty():
		var hit_direction = top_corner if !top_hit.is_empty() else bottom_corner
		hit_direction -= _entity.position
		if direction.y * hit_direction.x > 0: #dodge right
			direction = Vector2(-direction.y, direction.x)
		else: #dodge left
			direction = Vector2(direction.y, -direction.x)
#	elif !top_hit.is_empty() && !bottom_hit.is_empty():
#		pass
	_entity.give_walk_command(direction, _speed)

	#  --AVOIDANCE END--
	return self

func pop_state():
	_previous._reentry_position = _entity.position
	return super()
