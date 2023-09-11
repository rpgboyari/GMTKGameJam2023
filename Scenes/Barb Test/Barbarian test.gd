extends Node2D

@onready var player: Entity = $Barbarian

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child.has_signal("input_event"):
			child.input_event.connect(
					func(viewport, event, shape_idx): 
						_on_entity_input_event(child, event)
						print_debug("in lambda of " + str(child))
			)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("Attack"):
		print_debug("giving attack command")
		var attack_direction = (get_viewport().get_mouse_position() - player.position).normalized()
		player.give_command(player.attack_behaviour.new(player, attack_direction))
	var move_direction = Vector2.ZERO
	if Input.is_action_pressed("Move_Down"):
		move_direction += Vector2.DOWN
	if Input.is_action_pressed("Move_Left"):
		move_direction += Vector2.LEFT
	if Input.is_action_pressed("Move_Right"):
		move_direction += Vector2.RIGHT
	if Input.is_action_pressed("Move_Up"):
		move_direction += Vector2.UP
	if move_direction != Vector2.ZERO:
		move_direction = move_direction.normalized()
		player.give_command(player.walk_behaviour.new(player, move_direction))
	
	


func _on_entity_input_event(child, event):
	print_debug("in _on_entity of " + str(child))
	if event is InputEventMouseButton && event.pressed && event.button_index == 1:
		player = child
		print_debug(str(child) + " set to player")

