extends Node2D

const SHAPE_CAST_OFFSET_X = 16
const SHAPE_CAST_OFFSET_Y = 16

var smith = preload("res://Scenes/Minions/Smith.tscn")
var peasant = preload("res://Scenes/Minions/Peasant.tscn")
@export var thumbnails: Dictionary
@export var succesful_place_sounds: Array
@export var failed_place_sounds: Array
#var error_soud = preload("res://Sound Effects/Misc/Little_Blip_Noise.mp3")

@onready var shape_cast = $ShapeCast2D
@onready var audio_player = $AudioStreamPlayer2D

var placing = false
var shape_cast_offset_x
var shape_cast_offset_y
var active_choice

func _input(event):
	if placing && event is InputEventMouseButton && event.pressed:
		if event.button_index == 1:
			shape_cast.position = event.position + Vector2(shape_cast_offset_x, shape_cast_offset_y)
			shape_cast.force_shapecast_update()
			if shape_cast.is_colliding():
				play_random_sound(failed_place_sounds)
			else:
				var new_minion = active_choice.instantiate()
				get_node("/root").add_child(new_minion)
				unset_choice()
				play_random_sound(succesful_place_sounds)
		elif event.button_index == 2:
			unset_choice()

func _on_spawn_peasant_pressed():
	active_choice = peasant
	new_choice("peasant")


func _on_spawn_smith_pressed():
	active_choice = smith
	new_choice("smith")

func new_choice(choice):
	print_debug(choice + " clicked")
	var thumbnail: Texture2D = thumbnails[choice]
	shape_cast_offset_x = thumbnail.get_width() / 2
	shape_cast_offset_y = thumbnail.get_height()
	Input.set_custom_mouse_cursor(thumbnail)
	placing = true

func play_random_sound(sound_array):
	var to_play = sound_array.pick_random()
	audio_player.stop()
	audio_player.stream = to_play
	audio_player.play()

func unset_choice():
	placing = false
	Input.set_custom_mouse_cursor(null)
