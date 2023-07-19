extends AudioStreamPlayer

const title_theme = preload("res://Music/Title_Theme.mp3")
const dungeon_theme_intro = preload("res://Music/Dungeon_Theme_IMPROVED_NON_LOOP.mp3")
const dungeon_theme_loop = preload("res://Music/Dungeon_Theme_IMPROVED_LOOP.mp3")
const chest_theme_intro = preload("res://Music/Chest_Theme_FIXED.mp3")
const chest_theme_loop = preload("res://Music/Chest_Theme_LOOP.mp3")

const time_to_fade = 1
const fade_rate = 20

var normal_volume = 0
var fading_out = false
var time_spent_fading
var current_track

func _ready():
	finished.connect(_on_finished)
	current_track = title_theme
	finish_changing_track()

func _process(delta):
	if fading_out:
		volume_db -= fade_rate * delta
		time_spent_fading += delta
		if time_spent_fading > time_to_fade:
			stop()
			fading_out = false
			time_spent_fading = 0.0
			volume_db = normal_volume
			print_debug("fading finished")
			finish_changing_track()
	
func change_track(new_track):
	fading_out = true
	time_spent_fading = 0.0
	current_track = new_track
func finish_changing_track():
	stream = current_track
	play()

func _on_finished():
	if fading_out:
		finish_changing_track()
	elif current_track == chest_theme_intro:
		current_track = chest_theme_loop
		finish_changing_track()
	elif current_track == dungeon_theme_intro:
		current_track = dungeon_theme_loop
	else:
		play()

func _on_tab_bar_tab_changed(tab):
	if tab == 4:
		self.volume_db = -80
	else:
		self.volume_db = 0 - tab * 5
