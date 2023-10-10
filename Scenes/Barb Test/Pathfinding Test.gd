extends Node2D
@export var map: TileMap
@export var tiles: TileSet
var mouse_tile
var overwritten_tile_atlas_pos
var path_start
var path_end
var path

func _process(delta):
	var old_mouse_tile = mouse_tile
	var mouse_pos = get_viewport().get_mouse_position()
	mouse_tile = map.world_to_map(mouse_pos)
	if mouse_tile != old_mouse_tile:
		if old_mouse_tile && overwritten_tile_atlas_pos != null:
			map.set_cell(1, old_mouse_tile, 1, overwritten_tile_atlas_pos)
		if mouse_tile:
			overwritten_tile_atlas_pos = map.get_cell_atlas_coords(1, mouse_tile)
			map.set_cell(1, mouse_tile, 1, Vector2i(1, 1))

func _input(event):
	if event is InputEventMouseButton && event.is_pressed():
		if !path_start:
			if path:
				for tile in path:
					map.set_cell(1, tile, 1)
			
			path_start = mouse_tile
			map.set_cell(1, mouse_tile, 1, Vector2i(0, 1))
			overwritten_tile_atlas_pos = Vector2i(0, 1)
		else:
			path_end = mouse_tile
			map.set_cell(1, mouse_tile, 1, Vector2i(1, 0))
			overwritten_tile_atlas_pos = Vector2i(1, 0)
			
			path = await(map.find_path(path_start, path_end))
			if path: 
				for tile in path:
					if tile != path_start && tile != path_end:
						map.set_cell(1, tile, 1, Vector2i(0, 0))
			else:
				path = [path_start, path_end]
			
			path_start = null
			path_end = null
