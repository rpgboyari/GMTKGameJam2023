class_name AI_Entity extends Entity

#signal no_enemies_detected()
signal enemy_detected(enemy)
signal enemy_undetected(enemy)
signal destination_reached()

enum LONG_TERM_STATE {MARCHING, FIGHTING, LOOTING, GROUPING, IDLING}
var long_term_state: LONG_TERM_STATE

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var group_top: bool
@export var group_right: bool
var group_offset: Vector2


var regions: Dictionary = {}
var nearby_enemies: Dictionary = {}
var target: Entity
var destination: Vector2

func _ready():
	super()
	var group_offset_x = 30 if group_right else -30
	var group_offset_y = -30 if group_top else 30
	group_offset = group_offset_x * Vector2.RIGHT + group_offset_y * Vector2.DOWN
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	#print_debug(str(self) + " connected to nav agent velocity_computed")

func _physics_process(delta):
	if immediate_state == IMMEDIATE_STATE.ATTACKING: # entity is mid attack
		return
	elif immediate_state == IMMEDIATE_STATE.WALKING:
		if navigation_agent.is_navigation_finished():
			#print_debug(str(self) + " navigation complete at " + str(global_position))
			idle()
			emit_signal("destination_reached")
			return
		var next_path_position = navigation_agent.get_next_path_position()
		#print_debug(str(self) + " next path position " + str(next_path_position))
		var move_velocity = next_path_position - global_position
		move_velocity = move_velocity.normalized() * walk_speed
		if navigation_agent.avoidance_enabled:
			#print_debug("setting navigation agent velocity to " + str(move_velocity))
			navigation_agent.set_velocity(move_velocity)
		else:
			_on_velocity_computed(move_velocity)
	elif long_term_state == LONG_TERM_STATE.FIGHTING:
		if !target:
			find_target()
		var to_target: Vector2 = target.global_position - global_position
		var target_distance = to_target.length()
		if is_ranged || target_distance <= MELEE_RANGE + 5:
			print_debug(str(self) + " attacking" + str(target))
			attack(to_target)
		else:
			print_debug("target_distance: " + str(target_distance) + " MELEE_RANGE + 5: " + str(MELEE_RANGE + 5))
			print_debug(str(self) + " walking to " + str(to_target) + " to get " + str(target))
			walk_to(target.global_position - (to_target * MELEE_RANGE / (target_distance * 2)))
	elif long_term_state == LONG_TERM_STATE.LOOTING:
		pass

func add_nearby_enemy(enemy):
	
	if !nearby_enemies.has(enemy):
		nearby_enemies[enemy] = 1
	else:
		nearby_enemies[enemy] += 1
	if individual && long_term_state != LONG_TERM_STATE.FIGHTING:
		start_fighting()
func subtract_nearby_enemy(enemy):
	nearby_enemies[enemy] -= 1
	if nearby_enemies[enemy] < 1:
		nearby_enemies.erase(enemy)
	if individual && nearby_enemies.is_empty():
		pass
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
		if individual:
			add_nearby_enemy(enemy)
		else:
			emit_signal("enemy_detected", enemy)
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
		if individual:
			subtract_nearby_enemy(enemy)
		else:
			emit_signal("enemy_undetected", enemy)

func enemy_value(enemy): #returns how valuable of a target 'enemy' would be, lower is better
	return 0 #all enemies prioritized equally
func find_target():
	var best_value
	var best_enemies = []
	var enemy_value
	for enemy in nearby_enemies:
		print_debug("finding value of " + str(enemy))
		enemy_value = enemy_value(enemy)
		if best_value:
			if enemy_value > best_value:
				continue
			if enemy_value < best_value:
				best_enemies.clear()
		best_value = enemy_value
		best_enemies.append(enemy)
	assert(!best_enemies.is_empty())
	#if best_enemies.is_empty():
	#	no_enemies_detected.emit()
	#else:
	target = best_enemies.pick_random()

func walk_to(point):
	#print_debug(str(self) + " started walking towards " + str(point))
	navigation_agent.target_position = point
	#print_debug(str(self) + " navigating target of " + str(navigation_agent.target_position))
	immediate_state = IMMEDIATE_STATE.WALKING
	animator.play("walking")
func idle():
	#print_debug(str(self) + " started idling")
	immediate_state = IMMEDIATE_STATE.IDLE
	animator.play("idle")

func start_marching():
	long_term_state = LONG_TERM_STATE.MARCHING
	animator.play("walking")
func start_fighting():
	#print_debug(str(self) + " started fighting")
	long_term_state = LONG_TERM_STATE.FIGHTING
	find_target()
func start_looting():
	long_term_state = LONG_TERM_STATE.LOOTING
func start_grouping(point, direction):
	long_term_state = LONG_TERM_STATE.GROUPING
	var rotated_offset = group_offset.rotated(direction.angle())
	walk_to(point + rotated_offset)
func start_idling():
	long_term_state = LONG_TERM_STATE.IDLING
	immediate_state = IMMEDIATE_STATE.IDLE

func _on_enemy_entered_region(enemy):
	if individual:
		add_nearby_enemy(enemy)
	else:
		emit_signal("enemy_detected", enemy)
func _on_enemy_exited_region(enemy):
	if individual:
		subtract_nearby_enemy(enemy)
	else:
		emit_signal("enemy_undetected", enemy)

func _on_velocity_computed(safe_velocity):
	#print_debug("safe velocity computed")
	velocity = safe_velocity
	animator.flip_h = velocity.x < 0
	move_and_slide()
