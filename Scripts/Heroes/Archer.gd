extends Entity

func _ready():
	Globals.heroes["archer"] = self

func enemy_value(enemy): # targets the lowest hp enemy
	return target.hp
