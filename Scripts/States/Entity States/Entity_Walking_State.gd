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
	#var destination_reached = (_destination - _entity.position).length_squared() < (_entity.walk_speed * delta)^2
	if _close_to_point(_destination):
		return pop_state()
	
	var distance_moved = (_previous_position - _entity.position).length_squared()
	if distance_moved < 0.1: #entity didn't move last frame
#			print_debug("no movement, popping state")
		return pop_state()
	_previous_position = _entity.position
#		var direction = _destination - _entity.position
#		var adjusted_direction = direction
#		if _speed:
#			var direction_length = direction.length()
#			var adjusted_distance_travelled = _speed * delta
#			if adjusted_distance_travelled < direction_length:
#				adjusted_direction = (direction / direction_length) * adjusted_distance_travelled
#				print_debug("adjusting walk destination for " + str(_entity) + " to " + 
#						str(adjusted_direction) + ", with a length of " + 
#						str(adjusted_distance_travelled) + " instead of " + str(direction_length))
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
	
#
#	var tl_corner = entity_rect.position + _entity.position
#	var tr_corner = tl_corner + Vector2(entity_rect.size.x, 0)
#	var bl_corner = tl_corner + Vector2(0, entity_rect.size.y)
#	var br_corner = tl_corner + entity_rect.size
##	print_debug(str(_entity) + " tl:" + str(tl_corner) + " tr:" + str(tr_corner) + " bl:" + str(bl_corner) + " br:" + str(br_corner))
#	var tl_ray = PhysicsRayQueryParameters2D.create(
#			tl_corner, _destination, _entity.collision_mask)
##	print_debug(str(_entity) + " tl raycasting from " + str(tl_corner) + " to " + str(_destination))
#	var tr_ray = PhysicsRayQueryParameters2D.create(
#			tr_corner, _destination, _entity.collision_mask)
#	var bl_ray = PhysicsRayQueryParameters2D.create(
#			bl_corner, _destination, _entity.collision_mask)
#	var br_ray = PhysicsRayQueryParameters2D.create(
#			br_corner, _destination, _entity.collision_mask)
#
#	var tl_hit = space_state.intersect_ray(tl_ray)
#	var tr_hit = space_state.intersect_ray(tr_ray)
#	var bl_hit = space_state.intersect_ray(bl_ray)
#	var br_hit = space_state.intersect_ray(br_ray)
#
#	if !tl_hit.is_empty():
#		print_debug(str(_entity) + "'s top left hit " + str(tl_hit.collider) + " at " + str(tl_hit.position) + 
#			"\n     square distance of " + str(_entity.position.distance_squared_to(tl_hit.position)) +
#			"\n vs destination's square distance of " + str(_entity.position.distance_squared_to(_destination)))
	
#	var dodge_vector = Vector2.ZERO
#	if !tl_hit.is_empty() && (_entity.position.distance_squared_to(tl_hit.position)
#			< _entity.position.distance_squared_to(_destination)):
#		print_debug(str(_entity) + " at " + str(_entity.position ) + "'s top left hit " + str(tl_hit.collider) + " at " + str(tl_hit.position) + 
#			"\n     square distance of " + str(_entity.position.distance_squared_to(tl_hit.position)) +
#			"\n vs destination's square distance of " + str(_entity.position.distance_squared_to(_destination)) +
#			"\n corner position: " + str(tl_corner))
#		dodge_vector += Vector2(1, 1)
#	if !tr_hit.is_empty() && (_entity.position.distance_squared_to(tr_hit.position)
#			< _entity.position.distance_squared_to(_destination)):
#		print_debug(str(_entity) + " at " + str(_entity.position ) +  "'s top right hit " + str(tr_hit.collider) + " at " + str(tr_hit.position) + 
#			"\n     square distance of " + str(_entity.position.distance_squared_to(tr_hit.position)) +
#			"\n vs destination's square distance of " + str(_entity.position.distance_squared_to(_destination)) +
#			"\n corner position: " + str(tr_corner))
#		dodge_vector += Vector2(-1, 1)
#	if !bl_hit.is_empty() && (_entity.position.distance_squared_to(bl_hit.position)
#			< _entity.position.distance_squared_to(_destination)):
#		print_debug(str(_entity) + " at " + str(_entity.position ) +  "'s bottom left hit " + str(bl_hit.collider) + " at " + str(bl_hit.position) + 
#			"\n     square distance of " + str(_entity.position.distance_squared_to(bl_hit.position)) +
#			"\n vs destination's square distance of " + str(_entity.position.distance_squared_to(_destination)) +
#			"\n corner position: " + str(bl_corner))
#		dodge_vector += Vector2(1, -1)
#	if !br_hit.is_empty() && (_entity.position.distance_squared_to(br_hit.position)
#			< _entity.position.distance_squared_to(_destination)):
#		print_debug(str(_entity) + " at " + str(_entity.position ) +  "'s bottom right hit " + str(br_hit.collider) + " at " + str(br_hit.position) + 
#			"\n     square distance of " + str(_entity.position.distance_squared_to(br_hit.position)) +
#			"\n vs destination's square distance of " + str(_entity.position.distance_squared_to(_destination)) +
#			"\n corner position: " + str(br_corner))
#		dodge_vector += Vector2(-1, -1)
	
	#  --AVOIDANCE END--
#
#	if dodge_vector == Vector2.ZERO:
#		_entity.give_walk_command(_destination - _entity.position, _speed)
#	else:
#		print_debug(str(_entity) + " dodging towards " + str(dodge_vector))
#		_entity.give_walk_command(dodge_vector, _speed)
	return self

func pop_state():
	_previous._reentry_position = _entity.position
	return super()
