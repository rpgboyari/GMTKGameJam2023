extends Node2D

const SHAPE_CAST_OFFSET_X = 16
const SHAPE_CAST_OFFSET_Y = 16

signal minion_placed

var smith = preload("res://Scenes/Entities/Minions/Smith.tscn")
var peasant = preload("res://Scenes/Entities/Minions/Peasant.tscn")

@export var succesful_place_sounds: Array
@export var failed_place_sounds: Array
@export var world_space: Node2D

@onready var audio_player = $AudioStreamPlayer2D
@onready var peasant_dummy = $Peasant_Placement_Dummy
@onready var smith_dummy = $Smith_Placement_Dummy

var placing: bool
var shape_cast_offset_x
var shape_cast_offset_y
var active_choice
var active_dummy

func _ready():
	AudioControl.hook_in_sfx_player(audio_player)

func _input(event):
	if placing && event is InputEventMouseButton && event.pressed:
		if event.button_index == 1:
			if active_dummy.overlapping:
				play_random_sound(failed_place_sounds)
			else:
				var new_minion = active_choice.instantiate()
				new_minion.position = position
				world_space.add_child(new_minion)
				minion_placed.emit(new_minion)
				unset_choice()
				play_random_sound(succesful_place_sounds)
			
		elif event.button_index == 2:
			unset_choice()

func _physics_process(delta):
	if placing:
		position = get_global_mouse_position()

func _on_spawn_peasant_pressed():
	print_debug("spawn_peasant pressed")
	active_choice = peasant
	active_dummy = peasant_dummy
	new_choice()


func _on_spawn_smith_pressed():
	print_debug("spawn_smith pressed")
	active_choice = smith
	active_dummy = smith_dummy
	new_choice()

func new_choice():
	placing = true
	active_dummy.enable()

func play_random_sound(sound_array):
	var to_play = sound_array.pick_random()
	audio_player.stop()
	audio_player.stream = to_play
	audio_player.play()

func unset_choice():
	placing = false
	active_dummy.disable()
