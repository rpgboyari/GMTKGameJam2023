extends Node2D#PathFollow2D

signal all_done_walking()

enum GROUP_BEHAVIOR_STATE {WALKING, FIGHTING, LOOTING, GROUPING}
var behavior_state: GROUP_BEHAVIOR_STATE

const PARTY_SPACING = 30
const PARTY_OFFSETS = {
		"archer":Vector2(-PARTY_SPACING, -PARTY_SPACING),
		"barbarian":Vector2(PARTY_SPACING, -PARTY_SPACING),
		"knight":Vector2(PARTY_SPACING, PARTY_SPACING), 
		"rogue":Vector2(-PARTY_SPACING, PARTY_SPACING)}

@export var max_hp: int
var hp = max_hp
@export var max_potions: int
var potions = max_potions
@export var group_travel_speed: int
@export var party_core: PathFollow2D

@onready var party: Dictionary = {"archer":$Archer, "barbarian":$Barbarian,
		"knight":$Knight, "rogue":$Rogue}
#@onready var party_core: PathFollow2D = $Party_Core


var _destinations: Dictionary = {}
var enemies_detected: int = 0
var party_members_done_walking: int = 0
var travel_direction: Vector2 = Vector2.RIGHT
var previous_position: Vector2

func _ready():
	start_walking_new_direction()
	
	for key in party:
		party[key].damaged.connect(_on_party_member_damaged)
		party[key].enemy_detected.connect(_on_enemy_detected)
		party[key].enemy_undetected.connect(_on_enemy_undetected)
		#party_member.no_enemies_detected.connect(_on_no_enemies_detected)
		party[key].destination_reached.connect(_on_party_member_done_walking)
	#call_deferred("party_setup")
	
func _physics_process(delta):
#	var command_params = {"delta":delta}
	if behavior_state == GROUP_BEHAVIOR_STATE.WALKING:
		party_core.progress += group_travel_speed * delta
		var vector_travelled = party_core.position - party_core.previous_position
		var direction_travelled = vector_travelled.normalized()
#		command_params.direction = direction_travelled
		for key in party:
			var member: Entity = party[key]
			member.give_command(member.walk_behaviour.new(member, direction_travelled))
#			party[key].walk_behaviour.execute(party[key], command_params)
		if !travel_direction or travel_direction != direction_travelled:
			travel_direction = direction_travelled
			start_walking_new_direction()
		previous_position = position
	
	elif behavior_state == GROUP_BEHAVIOR_STATE.GROUPING:
		for key in _destinations:
			var member = party[key]
			var distance: Vector2 = _destinations[key] - member.position
			if distance.length_squared() < member.walk_speed * member.walk_speed:
				_destinations.erase(key)
				_on_party_member_done_walking()
				continue
			var angle = (distance).normalized()
			member.give_command(member.walk_behaviour.new(member, delta, angle))
	
	elif behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
		pass
	
	
#func party_setup():
	#await get_tree().physics_frame
	#progress = 0.0



func enemy_spotted():
	if behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
		return
	elif behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
		pass
	else:
		start_fighting()

func start_walking_new_direction():
	print_debug("starting grouping before walk...")
	await start_grouping()
	print_debug("...finished grouping, starting to walk")
	behavior_state = GROUP_BEHAVIOR_STATE.WALKING
#	for key in party:
#		party[key].start_marching()

func start_grouping(point = party_core.position): 
	#point = (party.archer.position + party.barbarian.position 
	#			+ party.knight.position + party.rogue.position) / 4
	#print_debug("grouping at " + str(point))
	party_members_done_walking = 0
	behavior_state = GROUP_BEHAVIOR_STATE.GROUPING
	for key in party:
		#print_debug(str(party[key]) + " grouping at " + str(point + party[key].group_offset))
		var rotated_offset = PARTY_OFFSETS[key].rotated(travel_direction.angle())
		_destinations[key] = point + rotated_offset
	
	await all_done_walking

func start_fighting():
	behavior_state = GROUP_BEHAVIOR_STATE.FIGHTING
	for key in party:
		party[key].start_fighting()

func start_loot_fighting():
	for key in party:
		if key != "archer":
			party[key].start_fighting()
func stop_loot_fighting():
	for key in party:
		if key != "archer":
			party[key].start_idling()

func try_drink_potion():
	if potions > 0:
		potions -= 1
		hp = max_hp

func _on_party_member_damaged(damage):
	hp -= damage
	if hp <= 0:
		try_drink_potion()

func _on_enemy_detected(enemy):
	for key in party:
		party[key].add_nearby_enemy(enemy)
	enemies_detected += 1
	if behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
		start_loot_fighting()
	elif behavior_state != GROUP_BEHAVIOR_STATE.FIGHTING:
		start_fighting()

func _on_enemy_undetected(enemy):
	for key in party:
		party[key].subtract_nearby_enemy(enemy)
	enemies_detected -= 1
	print_debug("enemy undetected, total enemies still detected: " + str(enemies_detected))
	if enemies_detected < 1:
		if behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
			stop_loot_fighting()
		elif behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
			start_walking_new_direction()

#func _on_no_enemies_detected():
#	assert(behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING or behavior_state == GROUP_BEHAVIOR_STATE.LOOTING)
#	if (behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING):
#		stop_fighting()
#	elif (behavior_state == GROUP_BEHAVIOR_STATE.LOOTING):
#		stop_loot_fighting()

func _on_party_member_done_walking():
	party_members_done_walking += 1
	print_debug(str(party_members_done_walking) + " party members done walking")
	if party_members_done_walking > 3:
		emit_signal("all_done_walking")
