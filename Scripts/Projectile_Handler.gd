extends Node2D

func receive_projectile(projectile):
	add_child(projectile)

func _ready():
	SignalBus.projectile_constructed.connect(receive_projectile)
