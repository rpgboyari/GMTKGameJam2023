extends Button

func _on_pressed():
	AudioControl.change_track(AudioControl.dungeon_theme_intro)
	get_tree().change_scene_to_file("res://main.tscn")
