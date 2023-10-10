extends ColorRect
var fill_bar
var max_size
var max_health

func _ready():
	fill_bar = $Health_Bar_Fill
	max_size = fill_bar.size.x
	pass

func _on_party_health_changed(value, old):
	if !max_health:
		max_health = old
	fill_bar.size.x = max_size * (float(value) / max_health)
