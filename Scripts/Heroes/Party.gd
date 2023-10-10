extends Node2D

signal party_health_changed(value, old)

#const ENTITY_STATE = preload("res://Scripts/States/Entity_State.gd")
const PARTY_SPACING = 24
const PARTY_OFFSETS = {
	"archer":Vector2(-PARTY_SPACING, -PARTY_SPACING),
	"barbarian":Vector2(PARTY_SPACING, -PARTY_SPACING),
	"knight":Vector2(PARTY_SPACING, PARTY_SPACING), 
	"rogue":Vector2(-PARTY_SPACING, PARTY_SPACING)
}
const _MARCH_SPEED = 80

@export_category("stats")
@export var max_hp: int
@onready var hp = max_hp
@export var max_potions: int
@onready var potions = max_potions
@export var group_travel_speed: int

@export_category("level data")
@export var path_nodes: Array[Vector2]
@export var map: TileMap

@onready var _party: Dictionary = {
	"archer":$Archer, "barbarian":$Barbarian,
	"knight":$Knight, "rogue":$Rogue
}

@onready var _party_states: Dictionary = {
	"archer":Entity_State.IDLE_STATE.new({"entity":_party.archer, "previous":null, "map":map}),
	"barbarian":Entity_State.IDLE_STATE.new({"entity":_party.barbarian, "previous":null, "map":map}),
	"knight":Entity_State.IDLE_STATE.new({"entity":_party.knight, "previous":null, "map":map}),
	"rogue":Entity_State.IDLE_STATE.new({"entity":_party.rogue, "previous":null, "map":map})
}

var _party_targeting_values: Dictionary = {
	"archer":func(enemy): # value lowest health enemy
		return enemy.hp,
	"barbarian":func(enemy): # value enemy nearest to barbarian
		return _party.barbarian.position.distance_to(enemy.position),
	"knight":func(enemy): # value deadliest enemy
		return -enemy.damage,
	"rogue":func(enemy): # value ranged enemies
		return -enemy.range
}

var _next_path_node: int
var _party_facing: Vector2
var _in_formation: bool = false
var _undetected_enemies: Array = []
var _detected_enemies: Array = []

func _ready():
	for key in _party:
		_party[key].damaged.connect(func(damage, hp): _on_party_member_damaged(damage, _party[key]))
		_party[key].position = path_nodes[0]
	_next_path_node = 1
	_take_formation()

func _physics_process(delta):
	# DETECT ENEMIES
	var space_state = get_world_2d().direct_space_state
	var newly_detected_enemies = []
	var party_center = _party_center()
	for enemy in _undetected_enemies:
		var query = PhysicsRayQueryParameters2D.create(
				party_center, enemy.global_position, 0b10)
		var result = space_state.intersect_ray(query)
		if !result.is_empty() && result.collider == enemy:
			_detected_enemies.append(enemy)
			newly_detected_enemies.append(enemy)
	# enemies detected
	if !newly_detected_enemies.is_empty():
		for key in _party:
			_party_states[key] = _party_states[key].change_state("fighting", {
				"enemies":newly_detected_enemies,
				"targeting_value":_party_targeting_values[key]})
		for enemy in newly_detected_enemies:
			_undetected_enemies.erase(enemy)
	
	var idle_members = 0
	for key in _party:
		_party_states[key] = _party_states[key].process(delta)
		if _party_states[key] is Entity_State.IDLE_STATE:
			idle_members += 1
	if idle_members == 4:
		if !_in_formation:
			_take_formation()
		else:
			if _next_path_node >= path_nodes.size():
				return
			for key in _party:
				_party_states[key] = _party_states[key].change_state("walking",
						{"destination":path_nodes[_next_path_node] + _adjusted_offset(key),
						"speed":_MARCH_SPEED})
			_next_path_node += 1
			_in_formation = false

func _take_formation():
	_in_formation = true
	if _next_path_node >= path_nodes.size():
		return
	_party_facing = path_nodes[_next_path_node] - path_nodes[_next_path_node - 1]
	var party_center = _party_center()
	for key in _party:
		_party_states[key] = _party_states[key].change_state("walking", 
				{"destination":party_center + _adjusted_offset(key)})

func _adjusted_offset(key):
	return PARTY_OFFSETS[key].rotated(_party_facing.angle())

func _party_center():
	var party_center = Vector2.ZERO
	for key in _party:
		party_center += _party[key].position
	party_center /= 4
	return party_center

func _try_drink_potion():
	if potions > 0:
		emit_signal("party_health_changed", max_hp, hp)
		potions -= 1
		hp = max_hp

func _on_enemy_added(enemy):
	_undetected_enemies.append(enemy)
	enemy.dying.connect(_on_enemy_dying)

func _on_enemy_dying(enemy):
	_undetected_enemies.erase(enemy)
	_detected_enemies.erase(enemy)

func _on_party_member_damaged(damage, member):
	emit_signal("party_health_changed", hp - damage, hp)
	member.hp = member.max_hp
	hp -= damage
	if hp <= 0:
		_try_drink_potion()

