extends Entity

@export var damage_negation: int

func take_damage(damage, source):
	damage = max(damage - damage_negation, 0)
	super(damage, source)
