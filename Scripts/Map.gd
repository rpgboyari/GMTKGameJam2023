extends TileMap

const UPDATE_TIME = 0.5

@export var party: Node2D
var _entities: Array[Entity] = []
var _positions: Array[Vector2i] = []
var _time_since_update: float = 0


class _pathfind_tile_data:
	enum {OPEN, CLOSED, UNVISITED}
	var tile
	var previous
	var cost
	var estimate
	var state = UNVISITED
class _pathfinding_heap:
	var heap: Array = []
	func _parent(index):
		index -= 1
		index -= index % 2
		index /= 2
		return index
	func _sibling(index):
		index += (index % 2) * 2
		index -= 1
		return index
	func _smallest_of_children_and_self(index):
		var child_1 = index * 2 + 1
		var child_2 = child_1 + 1
		if child_1 < heap.size() && heap[child_1].estimate < heap[index].estimate:
			index = child_1
		if child_2 < heap.size() && heap[child_2].estimate < heap[index].estimate:
			index = child_2
		return index
	func _swap(index_1, index_2):
		var hold = heap[index_1]
		heap[index_1] = heap[index_2]
		heap[index_2] = hold
	func _find_tile(tile_data, index):
		var child_1_index = index * 2 + 1
		var child_1 = heap[child_1_index]
		if child_1 == tile_data:
			return child_1_index
		if child_1.estimate < tile_data.estimate:
			var result = _find_tile(tile_data, child_1_index)
			if result: return result
		var child_2_index = child_1_index + 1
		var child_2 = heap[child_2_index]
		if child_2 == tile_data:
			return child_2_index
		if child_2.estimate < tile_data.estimate:
			return _find_tile(tile_data, child_2_index)
		return false
	func find_tile(tile_data):
		if heap[0] == tile_data:
			return 0
		return _find_tile(tile_data, 0)
	func add_tile(tile_data):
		heap.append(tile_data)
		var index = heap.size() - 1
		var parent_index = _parent(index)
		while heap[parent_index].estimate > heap[index].estimate:
			_swap(index, parent_index)
			index = parent_index
			parent_index = _parent(index)
	func remove_smallest():
		heap[0] = heap[-1]
		heap.remove_at(heap.size() - 1)
		var index = 0
		var small = _smallest_of_children_and_self(index)
		while small != index:
			_swap(index, small)
			index = small
			small = _smallest_of_children_and_self(index)
	func smallest_cost():
		return heap[0]
func _neighboring_tiles(tile):
	var neighbors = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			if !(i == 0 && j == 0):
				neighbors.append(tile + Vector2i(i, j))
	return neighbors
func find_path(start, end):
	var start_data = _pathfind_tile_data.new()
	start_data.tile = start
	start_data.previous = null
	start_data.cost = 0
	start_data.estimate
	var open = _pathfinding_heap.new()
	var closed = _pathfinding_heap.new()
	var current
	var direction
	while !open.is_empty():
		current = open.smallest_cost()

func _ready():
	for entity in party._party:
		_add_entity(entity)

func _physics_process(delta):
	_time_since_update += delta
	if _time_since_update < UPDATE_TIME:
		return
	
	_time_since_update = 0
	for i in _entities.size():
		_entity_moved_from(_positions[i])
		var new_pos = _entities[i].get_map_position()
		_entity_moved_to(new_pos)
		_positions[i] = new_pos

func _add_entity(entity):
	_entities.append(entity)
	_positions.append(null)
	entity.dying.connect(_on_entity_dying)

func _entity_moved_from(position):
	if position:
		get_cell_tile_data(0, position).set_meta("walkable", true)
func _entity_moved_to(position):
	get_cell_tile_data(0, position).set_meta("walkable", false)

func _on_entity_dying(entity: Entity):
	var index = _entities.find(entity)
	_entities.remove_at(index)
	_entity_moved_from(_positions[index])
	_positions.remove_at(index)

func _on_minion_placer_minion_placed(minion: Entity):
	_add_entity(minion)
