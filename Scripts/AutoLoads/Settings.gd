extends Node

const _MAX_VOLUME = 20
#const _MAX_SFX_VOLUME = 0
const _MIN_VOLUME = -20
#const _MIN_SFX_VOLUME = -20
const _VOLUME_OFF = -80

signal music_volume_changed
signal sfx_volume_changed

var music_volume: float = 0:
	get:
		return music_volume
	set(value):
		if value > _MAX_VOLUME:
			print_debug("value of " + str(value) + " is going over max volumne, returning")
			return
		if value < _MIN_VOLUME:
			if value < music_volume:
				print_debug("value of " + str(value) + " is going under min volume, pausing")
				value = _VOLUME_OFF
			else:
				value = _MIN_VOLUME
		music_volume = value
		print_debug("music volume succesfully set to " + str(value))
		music_volume_changed.emit(value)
var sfx_volume: float = 0:
	get:
		return sfx_volume
	set(value):
		if value > _MAX_VOLUME:
			return
		if value < _MIN_VOLUME:
			if value < sfx_volume:
				value = _VOLUME_OFF
			else:
				value = _MIN_VOLUME
		sfx_volume = value
		print_debug("sfx volume succesfully set to " + str(value))
		sfx_volume_changed.emit(value)
