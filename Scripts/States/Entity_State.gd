#extends "res://Scripts/States/State.gd"
const IDLE_STATE = preload("res://Scripts/States/Entity States/Entity_Idle_State.gd")
const WALKING_STATE = preload("res://Scripts/States/Entity States/Entity_Walking_State.gd")
const FIGHTING_STATE = preload("res://Scripts/States/Entity States/Entity_Fighting_State.gd")
const LOOTING_STATE = preload("res://Scripts/States/Entity States/Entity_Looting_State.gd")
var _entity
var _previous
var _reentry_position

func _init(params):
	assert(params.entity, "tried to initialize an entity state without providing an entity")
	_entity = params.entity
	#assert(params.previous, "tried to put " + str(_entity) + " in a new state without providing previous state")
	_previous = params.previous

func change_state(state_name, params):
#	print_debug(str(_entity) + " changing state to " + state_name)
	exit()
	params.entity = _entity
	params.previous = self
	var new_state
	match state_name:
		"fighting":
			new_state = FIGHTING_STATE.new(params)
		"looting":
			new_state = LOOTING_STATE.new(params)
		"walking":
			new_state = WALKING_STATE.new(params)
		"idle":
			new_state = IDLE_STATE.new(params)
		_:
			assert(false, "tried changing state to an undefined name")
	return new_state.enter()

func process(delta):
	return self

func enter():
	if _reentry_position && !_close_to_point(_reentry_position):
		var new_state = WALKING_STATE.new({"entity":_entity, "previous":self, "destination":_reentry_position})
		return new_state.enter()
	else:
		return self

func exit():
	_reentry_position = _entity.position

func pop_state():
#	print_debug("popping state! from " + str(_entity))
	assert(_previous, "tried popping out of the bottom-most state")
	exit()
	return _previous.enter()

func _close_to_point(point, delta = Global_Constants.PHYS_FRAME_DELTA):
	return (point - _entity.position).length_squared() < (_entity.walk_speed * delta)**2
