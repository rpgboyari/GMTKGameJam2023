class_name Entity_State#extends "res://Scripts/States/State.gd"
const IDLE_STATE = preload("res://Scripts/States/Entity States/Entity_Idle_State.gd")
const WALKING_STATE = preload("res://Scripts/States/Entity States/Entity_Walking_State.gd")
const DIRECT_WALKING_STATE = preload("res://Scripts/States/Entity States/Entity_Direct_Walking_State.gd")
const FIGHTING_STATE = preload("res://Scripts/States/Entity States/Entity_Fighting_State.gd")
const LOOTING_STATE = preload("res://Scripts/States/Entity States/Entity_Looting_State.gd")
var _entity: Entity
var _map: TileMap
var _previous: Entity_State
var _reentry_position: Vector2

func _init(params):
	assert(params.entity, "tried to initialize an entity state without providing an entity")
	_entity = params.entity
	assert(params.map, "tried to initialize an entity state without providing a map")
	_map = params.map
	_previous = params.previous

func change_state(state_name, params):
	exit()
	params.entity = _entity
	params.map = _map
	params.previous = self
	var new_state
	match state_name:
		"fighting":
			new_state = FIGHTING_STATE.new(params)
		"looting":
			new_state = LOOTING_STATE.new(params)
		"walking":
			new_state = WALKING_STATE.new(params)
		"direct_walking":
			new_state = DIRECT_WALKING_STATE.new(params)
		"idle":
			new_state = IDLE_STATE.new(params)
		_:
			assert(false, "tried changing state to an undefined name")
	return new_state.enter()

func process(delta):
	return self

func enter():
	return self

func reenter():
	if _reentry_position && !_close_to_point(_reentry_position):
		print(str(_entity) + " returning to " +  str(_reentry_position))
		var new_state = WALKING_STATE.new({"map":_map, "entity":_entity, "previous":self, "destination":_reentry_position})
		return new_state.enter()
	else:
		return self

func exit():
	_reentry_position = _entity.position

func pop_state():
	assert(_previous, "tried popping out of the bottom-most state")
	exit()
	return _previous.reenter()

func _close_to_point(point, error = 0):
	return (point - _entity.position).length_squared() < (
			_entity.walk_speed * Global_Constants.PHYS_FRAME_DELTA + error)**2

func _walkable(tile_coords):
	return _map.get_cell_tile_data(0, tile_coords).get_meta("walkable")
