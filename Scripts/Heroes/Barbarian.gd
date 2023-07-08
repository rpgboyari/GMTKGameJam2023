extends Entity

@onready var animator = $AnimatedSprite2D

func _ready():
	Globals.heroes["barbarian"] = self

func enemy_value(enemy): # targets the closest enemy
	return position.distance_to(enemy.position)
