extends PathFollow2D

enum GROUP_BEHAVIOR_STATE {WALKING, FIGHTING, LOOTING, GROUPING}
var behavior_state

@export var max_hp: int
var hp = max_hp
@export var max_potions: int
var potions = max_potions

@onready var party = {"archer":$Archer, "barbarian":$Barbarian,
		"knight":$Knight, "rogue":$Rogue}

func enemy_spotted():
	if behavior_state == GROUP_BEHAVIOR_STATE.FIGHTING:
		return
	elif behavior_state == GROUP_BEHAVIOR_STATE.LOOTING:
		pass
	else:
		start_fighting()

func start_grouping(point):
	if !point:
		point = (party.archer.position + party.barbarian.position 
				+ party.knight.position + party.rogue.position) / 4
	behavior_state = GROUP_BEHAVIOR_STATE.GROUPING
	for key in party:
		party[key].start_walking(point)

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
