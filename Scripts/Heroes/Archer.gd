extends AI_Entity

#func _ready():
#	super()
#	Globals.heroes["archer"] = self

func enemy_value(enemy): # targets the lowest hp enemy
	return target.hp
