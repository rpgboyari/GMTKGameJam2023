extends Node2D

var player: Entity

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !player: return
	if Input.is_action_just_pressed("Attack"):
		var attack_direction = Vector2.ZERO
		if player.is_ranged:
			attack_direction = (get_viewport().get_mouse_position() - player.position)
		player.give_attack_command(attack_direction)#player.attack_behaviour.new(player, attack_direction))
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
		move_direction = move_direction
		player.give_walk_command(move_direction)#player.walk_behaviour.new(player, move_direction))
	
func _on_entity_dying(entity):
	if player == entity:
		player = null

func _on_entity_input_event(entity, event):
	print_debug("entity input event registered")
	if event is InputEventMouseButton && event.pressed && event.button_index == 1:
		player = entity
		print_debug("player field set")

func _on_minion_placer_minion_placed(minion):
	print_debug("minion place registered")
	minion.input_event.connect(
			func(viewport, event, shape_idx):
				_on_entity_input_event(minion, event)
	)
	minion.dying.connect(_on_entity_dying)
