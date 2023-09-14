extends AudioStreamPlayer

const title_theme = preload("res://Music/Title_Theme.mp3")
const dungeon_theme_intro = preload("res://Music/Dungeon_Theme_IMPROVED_NON_LOOP.mp3")
const dungeon_theme_loop = preload("res://Music/Dungeon_Theme_IMPROVED_LOOP.mp3")
const chest_theme_intro = preload("res://Music/Chest_Theme_FIXED.mp3")
const chest_theme_loop = preload("res://Music/Chest_Theme_LOOP.mp3")


const _MAX_VOLUME = 10
const _MIN_VOLUME = -20
const _NO_VOLUME = -80
const _VOLUME_STEP = 5
const _TIME_TO_FADE = 1
const _FADE_RATE = 20

#var normal_volume = 0
var _music_volume = 0
var _music_off = false
var _sfx_volume = 0
var _sfx_off = false
var _fading_out = false
var _time_spent_fading
var _current_track

var _sfx_players: Array[AudioStreamPlayer2D] = []

func _ready():
	finished.connect(_on_finished)
	_current_track = title_theme
	finish_changing_track()
	volume_db = _music_volume
#	_setup_volume.call_deferred()

func _process(delta):
	if _fading_out:
		volume_db -= _FADE_RATE * delta
		_time_spent_fading += delta
		if _time_spent_fading > _TIME_TO_FADE:
			stop()
			_fading_out = false
			_time_spent_fading = 0.0
			volume_db = _music_volume
			print_debug("fading finished")
			finish_changing_track()
	
func change_track(new_track):
	_fading_out = true
	_time_spent_fading = 0.0
	_current_track = new_track
func finish_changing_track():
	stream = _current_track
	play()

func _on_finished():
	if _fading_out:
		finish_changing_track()
	elif _current_track == chest_theme_intro:
		_current_track = chest_theme_loop
		finish_changing_track()
	elif _current_track == dungeon_theme_intro:
		_current_track = dungeon_theme_loop
		finish_changing_track()
	else:
		play()

func _update_music_volume(new_volume):
	_music_volume = new_volume
	volume_db = new_volume
	_update_music_paused()
func _update_sfx_volume(new_volume):
	for sfx_player in _sfx_players:
		_sfx_volume = new_volume
		sfx_player.volume_db = new_volume
	_update_sfx_paused()
func _update_music_paused():
	stream_paused = _music_off || _music_volume == _NO_VOLUME
func _update_sfx_paused():
	for sfx_player in _sfx_players:
		sfx_player.stream_paused = _sfx_off || _sfx_volume == _NO_VOLUME
func turn_up_music(amount = 1):
	assert(amount >= 1)
	var new_volume
	if _music_volume == _NO_VOLUME:
		new_volume = _MIN_VOLUME + (amount - 1) * _VOLUME_STEP
	else:
		new_volume = min(_MAX_VOLUME, _music_volume + amount * _VOLUME_STEP)
	_update_music_volume(new_volume)
func turn_up_sfx(amount = 1):
	assert(amount >= 1)
	var new_volume
	if _sfx_volume == _NO_VOLUME:
		new_volume = _MIN_VOLUME + (amount - 1) * _VOLUME_STEP
	else:
		new_volume = min(_MAX_VOLUME, _sfx_volume + amount * _VOLUME_STEP)
	_update_sfx_volume(new_volume)
func turn_down_music(amount = 1):
	var new_volume = _music_volume - amount * _VOLUME_STEP
	if new_volume < _MIN_VOLUME:
		new_volume = _NO_VOLUME
	_update_music_volume(new_volume)
func turn_down_sfx(amount = 1):
	var new_volume = _sfx_volume - amount * _VOLUME_STEP
	if new_volume < _MIN_VOLUME:
		new_volume = _NO_VOLUME
	_update_sfx_volume(new_volume)
func set_music_volume(value):
	var new_volume
	if value > _MAX_VOLUME:
		new_volume = _MAX_VOLUME
	elif value < _MIN_VOLUME:
		new_volume = _NO_VOLUME
	else:
		new_volume = value
	_update_music_volume(new_volume)
func set_sfx_volume(value):
	var new_volume
	if value > _MAX_VOLUME:
		new_volume = _MAX_VOLUME
	elif value < _MIN_VOLUME:
		new_volume = _NO_VOLUME
	else:
		new_volume = value
	_update_sfx_volume(new_volume)
func turn_off_music():
	_music_off = true
	_update_music_paused()
func turn_on_music():
	_music_off = false
	_update_music_paused()
func turn_off_sfx():
	_sfx_off = true
	_update_sfx_paused()
func turn_on_sfx():
	_sfx_off = false
	_update_sfx_paused()

func hook_in_sfx_player(sfx_player: AudioStreamPlayer2D):
	_sfx_players.append(sfx_player)
	sfx_player.volume_db = _sfx_volume
func remove_sfx_player(sfx_player: AudioStreamPlayer2D):
	_sfx_players.erase(sfx_player)
