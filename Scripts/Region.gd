class_name Region extends Area2D

signal hero_entered(hero)
signal villain_entered(villain)
signal hero_exited(hero)
signal villain_exited(villain)

var heroes: Dictionary = {}
var villains: Dictionary  = {}

func _on_body_entered(body):
	if !body is Entity:
		return
	if body.has_method("enter_region"):
		body.enter_region(self)
	if body.team == body.TEAM.HERO:
		heroes[body] = true
		emit_signal("hero_entered", body)
	if body.team == body.TEAM.VILLAIN:
		villains[body] = true
		emit_signal("villain_entered", body)

func _on_body_exited(body):
	if !body is Entity:
		return
	if body.has_method("exit_region"):
		body.exit_region(self)
	if body.team == body.TEAM.HERO:
		heroes.erase(body)
		emit_signal("hero_exited", body)
	if body.team == body.TEAM.VILLAIN:
		villains.erase(body)
		emit_signal("villain_exited", body)
