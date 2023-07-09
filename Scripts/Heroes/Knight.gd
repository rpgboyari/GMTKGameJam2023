extends AI_Entity

@export var damage_negation: int

#func _ready():
#	super()
#	Globals.heroes["knight"] = self

func enemy_value(enemy): # targets the deadliest enemy
	return -enemy.damage

func take_damage(damage):
	damage = max(damage - damage_negation, 0)
	super(damage)
