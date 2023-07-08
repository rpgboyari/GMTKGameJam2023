extends AudioStreamPlayer

func _on_finished():
	play()

func _on_tab_bar_tab_changed(tab):
	if tab == 4:
		self.volume_db = -80
	else:
		self.volume_db = 0 - tab * 5
