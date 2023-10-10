extends TileMap

#const UPDATE_TIME = 0.5
#
#@export var party: Node2D
#var _entities: Array[Entity] = []
#var _positions: Array[Vector2i] = []
#var _time_since_update: float = 0


class _pathfind_tile_data:
	var tile
	var previous
	var cost
	var estimate
	var closed = false
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
#	func _find_tile(tile_data, index):
#		var child_1_index = index * 2 + 1
#		var child_1 = heap[child_1_index]
#		if child_1 == tile_data:
#			return child_1_index
#		if child_1.estimate < tile_data.estimate:
#			var result = _find_tile(tile_data, child_1_index)
#			if result: return result
#		var child_2_index = child_1_index + 1
#		var child_2 = heap[child_2_index]
#		if child_2 == tile_data:
#			return child_2_index
#		if child_2.estimate < tile_data.estimate:
#			return _find_tile(tile_data, child_2_index)
#		return false
#	func find_tile(tile_data):
#		if heap[0] == tile_data:
#			return 0
#		return _find_tile(tile_data, 0)
	func is_empty():
		return heap.is_empty()
	func add_tile(tile_data):
		heap.append(tile_data)
		var index = heap.size() - 1
		var parent_index = _parent(index)
		while index > 0 && heap[parent_index].estimate > heap[index].estimate:
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
	var new_neighbor
	var new_neighbor_tile_data
	for i in range(-1, 2, 2):
		for j in range(-1, 2, 2):
			# add orthogonal connections
			new_neighbor = tile + Vector2i((i - j) / 2, (i + j) / 2)
			if tile_walkable(new_neighbor):
				neighbors.append(new_neighbor)
			# add diagonal connections
			new_neighbor = tile + Vector2i(i, j)
			if (tile_walkable(new_neighbor) &&
					tile_walkable(new_neighbor - Vector2i(i, 0)) &&
					tile_walkable(new_neighbor - Vector2i(0, j))):
				neighbors.append(new_neighbor)
	return neighbors
func _heuristic(start, end):
	var x_distance = abs(end.x - start.x)
	var y_distance = abs(end.y - start.y)
	var short_distance = min(x_distance, y_distance)
	var long_distance = max(x_distance, y_distance)
	return short_distance * 0.4 + long_distance
func find_path(start, end):
	if !tile_walkable(end):
		return false
	var visited = []
	visited.resize(Global_Constants.MAP_WIDTH_TILES * Global_Constants.MAP_HEIGHT_TILES)
	var start_data = _pathfind_tile_data.new()
	start_data.tile = start
	start_data.previous = null
	start_data.cost = 0
	start_data.estimate = _heuristic(start, end)
	var open = _pathfinding_heap.new()
	open.add_tile(start_data)
	visited[start.x + start.y * Global_Constants.MAP_WIDTH_TILES] = start_data
	var current
	while !open.is_empty():
		current = open.smallest_cost()
		open.remove_smallest()
		current.closed = true
		if current.tile == end:
			break;
		var neighbors = _neighboring_tiles(current.tile)
		for neighbor in neighbors:
			var old_data = visited[neighbor.x + neighbor.y * Global_Constants.MAP_WIDTH_TILES]
			var new_data = _pathfind_tile_data.new()
			if neighbor.x == current.tile.x || neighbor.y == current.tile.y:
				new_data.cost = current.cost + 1 # neighbor is orthogonally adjacent
			else:
				new_data.cost = current.cost + 1.4 # neighbor is diagonally adjacent
			new_data.estimate = _heuristic(neighbor, end) + new_data.cost
			new_data.previous = current
			if !old_data:
				new_data.tile = neighbor
				open.add_tile(new_data)
				visited[neighbor.x + neighbor.y * Global_Constants.MAP_WIDTH_TILES] = new_data
			elif old_data.estimate > new_data.estimate:
				old_data.cost = new_data.cost
				old_data.estimate = new_data.estimate
				old_data.previous = new_data.previous
				if old_data.closed:
					open.add_tile(old_data)
					old_data.closed = false
			
	if current && current.tile == end:
		var path = [current.tile]
		while current.previous:
			current = current.previous
			path.append(current.tile)
		path.reverse()
		return path
	print("no path found from " + str(start) + " to " + str(end))
	return false

func tile_walkable(tile):
	var tile_data = get_cell_tile_data(0, tile)
#	var right_data = get_cell_tile_data(0, tile + Vector2i.RIGHT)
#	var left_data = get_cell_tile_data(0, tile + Vector2i.LEFT)
	return (tile_data && tile_data.get_custom_data("walkable")) #&&
#			right_data && right_data.get_meta("walkable") &&
#			left_data && left_data.get_meta("walkable"))

func tile_on_edge(tile):
	if !tile_walkable(tile + Vector2i.LEFT):
		return Vector2i.LEFT
	if !tile_walkable(tile + Vector2i.RIGHT):
		return Vector2i.RIGHT
	return false

func world_to_map(world_position):
	var x = int(world_position.x / tile_set.tile_size.x)
	var y = int(world_position.y / tile_set.tile_size.y)
	return Vector2i(x, y)
func map_to_world(map_position):
	var x = map_position.x * tile_set.tile_size.x# + tile_set.tile_size.x / 2
	var y = map_position.y * tile_set.tile_size.y# + tile_set.tile_size.y / 2
	return Vector2(x, y)

#func _ready():
#	for entity in party._party:
#		_add_entity(entity)
#
#func _physics_process(delta):
#	_time_since_update += delta
#	if _time_since_update < UPDATE_TIME:
#		return
#
#	_time_since_update = 0
#	for i in _entities.size():
#		_entity_moved_from(_positions[i])
#		var new_pos = _entities[i].get_map_position()
#		_entity_moved_to(new_pos)
#		_positions[i] = new_pos
#
#func _add_entity(entity):
#	_entities.append(entity)
#	_positions.append(null)
#	entity.dying.connect(_on_entity_dying)
#
#func _entity_moved_from(position):
#	if position:
#		get_cell_tile_data(0, position).set_meta("walkable", true)
#func _entity_moved_to(position):
#	get_cell_tile_data(0, position).set_meta("walkable", false)
#
#func _on_entity_dying(entity: Entity):
#	var index = _entities.find(entity)
#	_entities.remove_at(index)
#	_entity_moved_from(_positions[index])
#	_positions.remove_at(index)
#
#func _on_minion_placer_minion_placed(minion: Entity):
#	_add_entity(minion)
