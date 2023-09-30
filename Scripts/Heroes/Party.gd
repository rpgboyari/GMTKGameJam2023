extends Node2D

#enum GROUP_BEHAVIOR_STATE {WALKING, FIGHTING, LOOTING, REGROUPING, LOOTFIGHT}

const ENTITY_STATE = preload("res://Scripts/States/Entity_State.gd")
const PARTY_SPACING = 30
const PARTY_OFFSETS = {
	"archer":Vector2(-PARTY_SPACING, -PARTY_SPACING),
	"barbarian":Vector2(PARTY_SPACING, -PARTY_SPACING),
	"knight":Vector2(PARTY_SPACING, PARTY_SPACING), 
	"rogue":Vector2(-PARTY_SPACING, PARTY_SPACING)
}
const _MARCH_SPEED = 80

@export var max_hp: int
var hp = max_hp
@export var max_potions: int
var potions = max_potions
@export var group_travel_speed: int
@export var path_nodes: Array[Vector2]
#@export var party_core: PathFollow2D

@onready var _party: Dictionary = {
	"archer":$Archer, "barbarian":$Barbarian,
	"knight":$Knight, "rogue":$Rogue
}

@onready var _party_states: Dictionary = {
	"archer":ENTITY_STATE.IDLE_STATE.new({"entity":_party.archer, "previous":null}),
	"barbarian":ENTITY_STATE.IDLE_STATE.new({"entity":_party.barbarian, "previous":null}),
	"knight":ENTITY_STATE.IDLE_STATE.new({"entity":_party.knight, "previous":null}),
	"rogue":ENTITY_STATE.IDLE_STATE.new({"entity":_party.rogue, "previous":null})
}

var _party_targeting_values: Dictionary = {
	"archer":func(enemy): # value lowest health enemy
		return enemy.hp,
	"barbarian":func(enemy): # value enemy nearest to barbarian
		return _party.barbarian.position.distance_to(enemy.position),
	"knight":func(enemy): # value deadliest enemy
		return -enemy.get_damage(),
	"rogue":func(enemy): # value ranged enemies
		if enemy.is_ranged:
			return 0
		else:
			return 1,
}

var _next_path_node: int
var _party_facing: Vector2
var _in_formation: bool = false
#var _party_center: Vector2
#var _party_grouped: bool
#var _on_track: bool
#var _group_state: GROUP_BEHAVIOR_STATE
#var _routines: Dictionary = {}
#var _interruptable: Dictionary = {"archer":true, "barbarian":true,
#		"knight":true, "rogue":true}
#var _destinations: Dictionary = {}
var _undetected_enemies: Array = []
var _detected_enemies: Array = []
#var enemies_detected: int = 0
#var party_members_done_walking: int = 0
#var travel_direction: Vector2 = Vector2.RIGHT
#var previous_position: Vector2

func _ready():
	#start_walking_new_direction()
#	for key in _party:
#		print_debug(key + " in party, state is " + str(_party_states[key]))
	for key in _party:
		_party[key].damaged.connect(_on_party_member_damaged)
		_party[key].position = path_nodes[0]
	_next_path_node = 1
	_take_formation()
#	_party_grouped = false
#	_on_track = false
#	_update_party_center()

func _physics_process(delta):
	# DETECT ENEMIES
	var space_state = get_world_2d().direct_space_state
	var newly_detected_enemies = []
	for enemy in _undetected_enemies:
		var query = PhysicsRayQueryParameters2D.create(
				global_position, enemy.global_position, 0b10)
		var result = space_state.intersect_ray(query)
		print_debug("raycast towards " + str(enemy) + " collided with " + str(result.collider))
		if result.collider == enemy:
			_detected_enemies.append(enemy)
			newly_detected_enemies.append(enemy)
	# enemies detected
	if !newly_detected_enemies.is_empty():
		for key in _party:
			_party_states[key].change_state("fighting", {
				"enemies":newly_detected_enemies,
				"targeting_priority":null})
#		if _on_track:
#			_update_party_center()
#			_on_track = false
#			_party_grouped = false
#		for key in _party:
#			if _interruptable[key]:
#				_routines.erase(key)
		for enemy in newly_detected_enemies:
			_undetected_enemies.erase(enemy)
	
	var idle_members = 0
#	print_debug("starting process loop...")
	for key in _party:
#		print_debug("again, " + key + " is in party, state is " + str(_party_states[key]))
		_party_states[key] = _party_states[key].process(delta)
		if _party_states[key] is ENTITY_STATE.IDLE_STATE:
#			print_debug(key + " is in idle state")
			idle_members += 1
	if idle_members == 4:
		if !_in_formation:
			_take_formation()
		else:
			if _next_path_node >= path_nodes.size():
				return
			for key in _party:
#				print_debug("changing to walk state for " + key)
				_party_states[key] = _party_states[key].change_state("walking",
						{"destination":path_nodes[_next_path_node] + _adjusted_offset(key),
						"speed":_MARCH_SPEED})
			_next_path_node += 1
			_in_formation = false
	
	
	# GIVE ROUTINES TO PARTY MEMBERS
#	if !_detected_enemies.is_empty(): # give combat routines
#		for key in _party:
#			if !_routines.has(key):
#				pass
#	elif _routines.is_empty():
#		if !_party_grouped: # give all routine of regrouping
#			if _on_track:
#				_update_party_center()
#				_next_path_node += 1
#				_party_facing = path_nodes[_next_path_node] - path_nodes[_next_path_node - 1]
#			else:
#				_on_track = true
#			for key in _party:
#				var member = _party[key]
#				var destination = _party_center + _adjusted_offset(key)
#				_routines[key] = _lambda_walk_to(member, destination)
#			_party_grouped = true
#		#elif party is at chest:
#			#_on_track = false
#			#give all routine of looting
#		else: # give all routine of walking
#			_party_grouped = false
#			var party_direction
#			for key in _party:
#				var member = _party[key]
#				var destination = path_nodes[_next_path_node] + _adjusted_offset(key)
#				print_debug("setting walk destination of " + str(member) + " to " + str(destination))
#				_routines[key] = _lambda_walk_to(member, destination)
#
#	# RUN ROUTINES ON ALL PARTY MEMBERS, CLEAR ROUTINES FROM FINISHED MEMBERS
#	for key in _party:
#		if _routines.has(key) && _routines[key].call():
#			_routines.erase(key)

#func _change_group_state(new_state):
#	# leave previous state
#	match _group_state:
#		GROUP_BEHAVIOR_STATE.WALKING:
#			_update_party_center()
#	# enter new state
#	match new_state:
#		GROUP_BEHAVIOR_STATE.WALKING:
#			pass
#		GROUP_BEHAVIOR_STATE.FIGHTING:
#			pass
#		GROUP_BEHAVIOR_STATE.IDLING:
#			pass
#	_group_state = new_state
#func _lambda_walk_to(entity, destination):
#	return func():
#		entity.give_walk_command(destination - entity.position)
#		return (destination - entity.position).length_squared() <= entity.walk_speed^2

func _take_formation():
	_in_formation = true
	if _next_path_node >= path_nodes.size():
		return
	_party_facing = path_nodes[_next_path_node] - path_nodes[_next_path_node - 1]
	var party_center = Vector2.ZERO
	for key in _party:
		party_center += _party[key].position
	party_center /= 4
	for key in _party:
		print_debug("destination of " + str(_party[key]) + " equals party center position: " + str(party_center) + " plus adjusted offset of party-member: " + str(_adjusted_offset(key)))
		_party_states[key] = _party_states[key].change_state("walking", 
				{"destination":party_center + _adjusted_offset(key)})

func _adjusted_offset(key):
	return PARTY_OFFSETS[key].rotated(_party_facing.angle())

#func _update_party_center():
#	_party_center = Vector2.ZERO
#	for key in _party:
#		_party_center += _party[key].global_position
#	_party_center /= 4

func _try_drink_potion():
	if potions > 0:
		potions -= 1
		hp = max_hp

func _on_enemy_added(enemy):
	_undetected_enemies.append(enemy)
	enemy.dying.connect(_on_enemy_dying)

func _on_enemy_dying(enemy):
	_undetected_enemies.erase(enemy)
	_detected_enemies.erase(enemy)
#	if _detected_enemies.find(enemy):
#		assert(_detected_enemies.find(enemy) != -1, "turns out -1 does not evaluate to false, idiot")

func _on_party_member_damaged(damage):
	hp -= damage
	if hp <= 0:
		_try_drink_potion()
#	if behavior_state == GROUP_BEHAVIOR_STATE.WALKING:
#		party_core.progress += group_travel_speed * delta
#		var vector_travelled = party_core.position - party_core.previous_position
#		var direction_travelled = vector_travelled.normalized()
##		command_params.direction = direction_travelled
#		for key in party:
#			var member: Entity = party[key]
#			member.give_command(member.walk_behaviour.new(member, direction_travelled))
##			party[key].walk_behaviour.execute(party[key], command_params)
#		if !travel_direction or travel_direction != direction_travelled:
#			travel_direction = direction_travelled
#			start_walking_new_direction()
#		previous_position = position
#
#	elif behavior_state == GROUP_BEHAVIOR_STATE.GROUPING:
#		for key in _destinations:
#			var member = party[key]
#			var distance: Vector2 = _destinations[key] - member.position
#			if distance.length_squared() < member.walk_speed * member.walk_speed:
#				_destinations.erase(key)
#				_on_party_member_done_walking()
#				continue
#			var angle = (distance).normalized()
#			member.give_command(member.walk_behaviour.new(member, delta, angle))
#
#	elif behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
#		pass
	
	
#func party_setup():
	#await get_tree().physics_frame
	#progress = 0.0



#func enemy_spotted():
#	if behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
#		return
#	elif behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
#		pass
#	else:
#		start_fighting()

#func start_walking_new_direction():
#	print_debug("starting grouping before walk...")
#	await start_grouping()
#	print_debug("...finished grouping, starting to walk")
#	behavior_state = GROUP_BEHAVIOR_STATE.WALKING
#	for key in party:
#		party[key].start_marching()

#func start_grouping(point = party_core.position): 
#	#point = (party.archer.position + party.barbarian.position 
#	#			+ party.knight.position + party.rogue.position) / 4
#	#print_debug("grouping at " + str(point))
#	party_members_done_walking = 0
#	behavior_state = GROUP_BEHAVIOR_STATE.GROUPING
#	for key in party:
#		#print_debug(str(party[key]) + " grouping at " + str(point + party[key].group_offset))
#		var rotated_offset = PARTY_OFFSETS[key].rotated(travel_direction.angle())
#		_destinations[key] = point + rotated_offset
#
#	await all_done_walking
#
#func start_fighting():
#	behavior_state = GROUP_BEHAVIOR_STATE.FIGHTING
#	for key in party:
#		party[key].start_fighting()
#
#func start_loot_fighting():
#	for key in party:
#		if key != "archer":
#			party[key].start_fighting()
#func stop_loot_fighting():
#	for key in party:
#		if key != "archer":
#			party[key].start_idling()
#
#func _on_enemy_detected(enemy):
#	for key in party:
#		party[key].add_nearby_enemy(enemy)
#	enemies_detected += 1
#	if behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
#		start_loot_fighting()
#	elif behavior_state != GROUP_BEHAVIOR_STATE.FIGHTING:
#		start_fighting()
#
#func _on_enemy_undetected(enemy):
#	for key in party:
#		party[key].subtract_nearby_enemy(enemy)
#	enemies_detected -= 1
#	print_debug("enemy undetected, total enemies still detected: " + str(enemies_detected))
#	if enemies_detected < 1:
#		if behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
#			stop_loot_fighting()
#		elif behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
#			start_walking_new_direction()
#
##func _on_no_enemies_detected():
##	assert(behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING or behavior_state == GROUP_BEHAVIOR_STATE.LOOTING)
##	if (behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING):
##		stop_fighting()
##	elif (behavior_state == GROUP_BEHAVIOR_STATE.LOOTING):
##		stop_loot_fighting()
#
#func _on_party_member_done_walking():
#	party_members_done_walking += 1
#	print_debug(str(party_members_done_walking) + " party members done walking")
#	if party_members_done_walking > 3:
#		emit_signal("all_done_walking")
