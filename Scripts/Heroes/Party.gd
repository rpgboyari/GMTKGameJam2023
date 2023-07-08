extends PathFollow2D

signal all_done_walking()

enum GROUP_BEHAVIOR_STATE {WALKING, FIGHTING, IDLE, LOOTING, GROUPING}
var behavior_state

@export var max_hp: int
var hp = max_hp
@export var max_potions: int
var potions = max_potions
@export var group_travel_speed: int

@onready var party = {"archer":$Archer, "barbarian":$Barbarian,
		"knight":$Knight, "rogue":$Rogue}

var walking_progress = 0

func _ready():
	progress = 0.0
	start_walking()
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
	await start_grouping(global_position)
	behavior_state = GROUP_BEHAVIOR_STATE.WALKING
	for key in party:
		party[key].start_idling()
		party[key].animator.play("walking")

func start_grouping(point = (party.archer.position + party.barbarian.position 
				+ party.knight.position + party.rogue.position) / 4):
	print_debug("grouping at " + str(point))
	walking_progress = 0
	behavior_state = GROUP_BEHAVIOR_STATE.GROUPING
	for key in party:
		print_debug(str(party[key]) + " grouping at " + str(point + party[key].group_offset))
		party[key].start_walking(point + party[key].group_offset)
	
	await all_done_walking
	behavior_state = GROUP_BEHAVIOR_STATE.IDLE

func start_fighting():
	behavior_state = GROUP_BEHAVIOR_STATE.FIGHTING
	for key in party:
		party[key].start_fighting()
func stop_fighting():
	pass

func try_drink_potion():
	if potions > 0:
		potions -= 1
		hp = max_hp

func group_damaged(damage):
	hp -= damage
	if hp <= 0:
		try_drink_potion()
		
func no_enemies_detected():
	assert(behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING or behavior_state == GROUP_BEHAVIOR_STATE.LOOTING)
	if (behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING):
		stop_fighting()
	elif (behavior_state == GROUP_BEHAVIOR_STATE.LOOTING):
		pass
		
func party_member_done_walking():
	walking_progress += 1
	print_debug(str(walking_progress) + " party members done walking")
	if walking_progress > 3:
		emit_signal("all_done_walking")

func _on_archer_damaged(damage):
	group_damaged(damage)
func _on_barbarian_damaged(damage):
	group_damaged(damage)
func _on_knight_damaged(damage):
	group_damaged(damage)
func _on_rogue_damaged(damage):
	group_damaged(damage)

func _on_archer_no_enemies_detected():
	no_enemies_detected()
func _on_barbarian_no_enemies_detected():
	no_enemies_detected()
func _on_knight_no_enemies_detected():
	no_enemies_detected()
func _on_rogue_no_enemies_detected():
	no_enemies_detected()
	
func _on_archer_destination_reached():
	party_member_done_walking()
func _on_barbarian_destination_reached():
	party_member_done_walking()
func _on_knight_destination_reached():
	party_member_done_walking()
func _on_rogue_destination_reached():
	party_member_done_walking()
