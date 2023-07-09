extends Button

func _on_pressed():
	MusicPlayer.change_track(MusicPlayer.dungeon_theme_intro)
	get_tree().change_scene_to_file("res://main.tscn")
