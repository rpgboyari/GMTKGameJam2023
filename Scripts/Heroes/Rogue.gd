extends AI_Entity

func _ready():
	super()
	Globals.heroes["rogue"] = self

func start_looting():
	pass
func stop_looting():
	pass

func enemy_value(enemy): # targets a ranged enemy
	if enemy.is_ranged:
		return 0
	else:
		return 1
