extends PathFollow2D

signal all_done_walking()

enum GROUP_BEHAVIOR_STATE {WALKING, FIGHTING, LOOTING, GROUPING}
var behavior_state

@export var max_hp: int
var hp = max_hp
@export var max_potions: int
var potions = max_potions
@export var group_travel_speed: int

@onready var party = {"archer":$Archer, "barbarian":$Barbarian,
		"knight":$Knight, "rogue":$Rogue}

var enemies_detected = 0
var walking_progress = 0

func _ready():
	progress = 0.0
	start_walking()
	
	for key in party:
		party[key].damaged.connect(_on_party_member_damaged)
		party[key].enemy_detected.connect(_on_enemy_detected)
		party[key].enemy_undetected.connect(_on_enemy_undetected)
		#party_member.no_enemies_detected.connect(_on_no_enemies_detected)
		party[key].destination_reached.connect(_on_party_member_done_walking)
	#call_deferred("party_setup")
	
func _physics_process(delta):
	if behavior_state == GROUP_BEHAVIOR_STATE.WALKING:
		progress += group_travel_speed * delta
	
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

func start_walking():
	await start_grouping()
	behavior_state = GROUP_BEHAVIOR_STATE.WALKING
	for key in party:
		party[key].start_marching()

func start_grouping(point = global_position): 
	#point = (party.archer.position + party.barbarian.position 
	#			+ party.knight.position + party.rogue.position) / 4
	#print_debug("grouping at " + str(point))
	walking_progress = 0
	behavior_state = GROUP_BEHAVIOR_STATE.GROUPING
	for key in party:
		#print_debug(str(party[key]) + " grouping at " + str(point + party[key].group_offset))
		party[key].start_grouping(point)
	
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
	if enemies_detected < 1:
		if behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
			stop_loot_fighting()
		elif behavior_state != GROUP_BEHAVIOR_STATE.FIGHTING:
			start_grouping()

#func _on_no_enemies_detected():
#	assert(behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING or behavior_state == GROUP_BEHAVIOR_STATE.LOOTING)
#	if (behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING):
#		stop_fighting()
#	elif (behavior_state == GROUP_BEHAVIOR_STATE.LOOTING):
#		stop_loot_fighting()

func _on_party_member_done_walking():
	walking_progress += 1
	#print_debug(str(walking_progress) + " party members done walking")
	if walking_progress > 3:
		emit_signal("all_done_walking")
