class_name Attack extends Area2D

signal attack_finished()

var damage = 0
var cooldown = 0

@onready var _cooldown_timer: Timer = Timer.new()

var _mid_attack: bool = false
var _buffered_attack: bool = false
var _buffered_attack_id
var _canceled_attack: bool = false
var _buffered_direction: Vector2

func _ready():
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.stop()

func _begin_attack():
	_mid_attack = true
	_buffered_attack = false
	_cooldown_timer.start()

func _end_attack():
	_mid_attack = false
	_canceled_attack = false
	attack_finished.emit()

func start(direction, attack_id):
	_buffered_attack = true
	_buffered_attack_id = attack_id
	_buffered_direction = direction

func cancel():
	_buffered_attack = false
	if _mid_attack:
		_canceled_attack = true
