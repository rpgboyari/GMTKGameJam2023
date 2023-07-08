class_name AI_Entity extends Entity

signal no_enemies_detected()
signal destination_reached()

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var group_top: bool
@export var group_right: bool
var group_offset: Vector2

var long_term_state

var regions: Dictionary = {}
var nearby_enemies: Dictionary = {}
var target
var destination

func _ready():
	var group_offset_x = 30 if group_right else -30
	var group_offset_y = -30 if group_top else 30
	group_offset = group_offset_x * Vector2.RIGHT + group_offset_y * Vector2.DOWN
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	print_debug(str(self) + " connected to nav agent velocity_computed")

func _physics_process(delta):
	if immediate_state == INDIVIDUAL_BEHAVIOR_STATE.FIGHTING: # entity is mid attack
		return
		
	if long_term_state == INDIVIDUAL_BEHAVIOR_STATE.WALKING:
		if navigation_agent.is_navigation_finished():
			print_debug(str(self) + " navigation complete at " + str(global_position))
			start_idling()
			emit_signal("destination_reached")
			return
		var next_path_position = navigation_agent.get_next_path_position()
		print_debug(str(self) + " next path position " + str(next_path_position))
		var move_velocity = next_path_position - global_position
		move_velocity = move_velocity.normalized() * walk_speed
		if navigation_agent.avoidance_enabled:
			#print_debug("setting navigation agent velocity to " + str(move_velocity))
			navigation_agent.set_velocity(move_velocity)
		else:
			_on_velocity_computed(move_velocity)
	if long_term_state == INDIVIDUAL_BEHAVIOR_STATE.FIGHTING:
		pass
	if long_term_state == INDIVIDUAL_BEHAVIOR_STATE.IDLE:
		pass

func add_nearby_enemy(enemy):
	if !nearby_enemies[enemy]:
		nearby_enemies[enemy] = 1
	else:
		nearby_enemies[enemy] += 1
func subtract_nearby_enemy(enemy):
	nearby_enemies[enemy] -= 1
	if nearby_enemies[enemy] < 1:
		nearby_enemies.erase(enemy)
func enter_region(region: Region):
	regions[region] = true
	var region_enemies
	match team:
		TEAM.HERO:
			region_enemies = region.villains
			region.villain_entered.connect(_on_enemy_entered_region)
			region.villain_exited.connect(_on_enemy_exited_region)
		TEAM.VILLAIN:
			region_enemies = region.heroes
			region.hero_entered.connect(_on_enemy_entered_region)
			region.hero_exited.connect(_on_enemy_exited_region)
	for enemy in region_enemies:
		add_nearby_enemy(enemy)
func exit_region(region):
	regions.erase(region)
	var region_enemies
	match team:
		TEAM.HERO:
			region_enemies = region.villains
			region.villain_entered.disconnect(_on_enemy_entered_region)
			region.villain_exited.disconnect(_on_enemy_exited_region)
		TEAM.VILLAIN:
			region_enemies = region.heroes
			region.hero_entered.disconnect(_on_enemy_entered_region)
			region.hero_exited.disconnect(_on_enemy_exited_region)
	for enemy in region_enemies:
		subtract_nearby_enemy(enemy)

func enemy_value(enemy): #returns how valuable of a target 'enemy' would be, lower is better
	assert(false)
func find_target():
	var best_value
	var best_enemies = []
	var enemy_value
	for enemy in nearby_enemies:
		enemy_value = enemy_value(enemy)
		if best_value:
			if enemy_value > best_value:
				continue
			if enemy_value < best_value:
				best_enemies.clear()
		best_value = enemy_value
		best_enemies.append(enemy)
	if best_enemies.is_empty():
		no_enemies_detected.emit()
	else:
		target = best_enemies.pick_random()

func start_walking(point):
	print_debug(str(self) + " started walking towards " + str(point))
	navigation_agent.target_position = point
	print_debug(str(self) + " navigating target of " + str(navigation_agent.target_position))
	long_term_state = INDIVIDUAL_BEHAVIOR_STATE.WALKING
	animator.play("walking")
func start_fighting():
	print_debug(str(self) + " started fighting")
	long_term_state = INDIVIDUAL_BEHAVIOR_STATE.FIGHTING
	find_target()
func start_idling():
	print_debug(str(self) + " started idling")
	long_term_state = INDIVIDUAL_BEHAVIOR_STATE.IDLE
	animator.play("idle")

func _on_enemy_entered_region(enemy):
	add_nearby_enemy(enemy)
func _on_enemy_exited_region(enemy):
	subtract_nearby_enemy(enemy)

func _on_velocity_computed(safe_velocity):
	#print_debug("safe velocity computed")
	velocity = safe_velocity
	move_and_slide()
