extends Entity

@export var damage_negation: int

#func _ready():
#	super()
#	Globals.heroes["knight"] = self

func take_damage(damage, source):
	damage = max(damage - damage_negation, 0)
	super(damage, source)
