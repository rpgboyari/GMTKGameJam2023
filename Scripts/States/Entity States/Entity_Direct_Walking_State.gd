extends Entity_State
var _destination
#var _speed
var _previous_position = Vector2.ZERO

func _init(params):
	super(params)
	_destination = params.destination
	print("creating direct walking state from " + str(_entity))
	#_speed = params.speed

func process(delta):
	var distance_moved = (_previous_position - _entity.position).length_squared()
	_previous_position = _entity.position
	if _close_to_point(_destination) || distance_moved < 0.1:
		return pop_state()
	var direction = _destination - _entity.position
	_entity.give_walk_command(direction)
	return self

func pop_state():
	_previous._reentry_position = _entity.position
	return super()
