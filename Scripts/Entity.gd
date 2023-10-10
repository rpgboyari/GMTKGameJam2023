class_name Entity extends CharacterBody2D

signal damaged(damage, hp)
signal dying(entity)

enum ANIMATION_STATE {WALKING, ATTACKING, IDLE}
enum TEAM {HERO, VILLAIN}

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack: Attack = $Attack
@onready var collision_rect: Rect2 = $CollisionShape2D.shape.get_rect()

const _MAX_COMMANDS_QUEUED = 1
const _DAMAGE_GRACE_TIME = 2
const _BLINK_SPEED = 0.1
const _BLINK_DURATION = 3

@export_category("variables")
@export var max_hp: int
@export var damage: int
@export var attack_cooldown: float
@export var walk_speed: int

@export_category("unit data")
@export var range: int = 0
@export var team: TEAM
@export var attack_sounds: Array
@export var hurt_sounds: Array
@export var death_sounds: Array

var hp

var _walk_behaviour = Command.Walk_Command
var _attack_behaviour = Command.Attack_Command
var _busy = false
var _disabled: bool = false
var _command_queue: Array[Command]
var _animation_state: ANIMATION_STATE
var _damage_source_graces: Dictionary = {}
var _cooldown_timer: Timer
var _blink_cycle_timer: Timer
var _blink_count: int
#var _blink_duration_timer: Timer
#var _blinking: bool

func _physics_process(delta):
	if _busy || _disabled || (_cooldown_timer && !_cooldown_timer.is_stopped()):
		return
	var command_to_process = _command_queue.pop_front()
	if command_to_process:
		command_to_process.execute(delta)
	else:
		if _animation_state == ANIMATION_STATE.IDLE: return
		animator.play("idle")
		_animation_state = ANIMATION_STATE.IDLE

func _ready():
	hp = max_hp
	motion_mode = MOTION_MODE_FLOATING
	AudioControl.hook_in_sfx_player(audio_player)
	attack.damage = damage
	attack.attack_finished.connect(_on_attack_finished)
	
	if attack_cooldown > 0:
		_cooldown_timer = Timer.new()
		_cooldown_timer.one_shot = true
		_cooldown_timer.wait_time = attack_cooldown
		_cooldown_timer.stop()
		add_child.call_deferred(_cooldown_timer)
	
	match team:
		TEAM.HERO:
			collision_layer = 0b001
			collision_mask = 0b100
			attack.collision_layer = 0b001
			attack.collision_mask = 0b010
		TEAM.VILLAIN:
			collision_layer = 0b010
			collision_mask = 0b100
			attack.collision_layer = 0b010
			attack.collision_mask = 0b001
	
	_blink_cycle_timer = Timer.new()
	_blink_cycle_timer.wait_time = _BLINK_SPEED
	_blink_cycle_timer.timeout.connect(_blink)
	add_child.call_deferred(_blink_cycle_timer)

func _attack(direction, attack_id):
	_change_facing(direction)
	animator.play("attacking")
	_animation_state = ANIMATION_STATE.ATTACKING
	_play_random_sound(attack_sounds)
	_busy = true
	if _cooldown_timer:
		_cooldown_timer.start()
	attack.start(direction, attack_id)

func _walk(direction, delta, speed = walk_speed):
	_change_facing(direction)
	if _animation_state != ANIMATION_STATE.WALKING:
		animator.play("walking")
		_animation_state = ANIMATION_STATE.WALKING
	velocity = direction if direction.length_squared() <= 1 else direction.normalized()
	velocity *= speed
	move_and_slide()

func _die():
	attack.cancel()
	animator.play("idle")
	_disabled = true
	_play_random_sound(death_sounds)
	collision_layer = 0
	audio_player.finished.connect(queue_free)
	dying.emit(self)
	_start_blinking()
	AudioControl.remove_sfx_player(audio_player)

func _play_random_sound(sound_effects):
	if sound_effects.is_empty():
		return
	var to_play = sound_effects.pick_random()
	audio_player.stop()
	audio_player.stream = to_play
	audio_player.play()

func _change_facing(direction):
	if direction.x < 0:
		scale.y = -1
		rotation = PI
	elif direction.x > 0:
		scale.y = 1
		rotation = 0

func _blink():
	visible = !visible
	if visible && !_disabled:
		_blink_count += 1
		if _blink_count >= _BLINK_DURATION:
			_stop_blinking()

func _start_blinking():
	_blink_cycle_timer.start()
	_blink_count = 0

func _stop_blinking():
	_blink_cycle_timer.stop()

func _on_attack_finished():
	animator.play("idle")
	_animation_state = ANIMATION_STATE.IDLE
	_busy = false

func take_damage(damage, source):
	if _disabled: return
	if _damage_source_graces.has(source):
		return
	_damage_source_graces[source] = true
	_play_random_sound(hurt_sounds)
	hp -= damage
	if hp <= 0:
		_die()
	damaged.emit(damage, hp)
	
	_start_blinking()
	
	await get_tree().create_timer(_DAMAGE_GRACE_TIME).timeout
	_damage_source_graces.erase(source)

func give_command(command: Command):
	assert(!(_command_queue.size() > _MAX_COMMANDS_QUEUED))
	if _command_queue.size() == _MAX_COMMANDS_QUEUED:
		if command is Command.Attack_Command:
			_command_queue.pop_front()
		else:
			return
	_command_queue.push_back(command)
func give_walk_command(direction: Vector2, speed = false):
	give_command(_walk_behaviour.new(self, direction, speed))
func give_attack_command(direction: Vector2):
	give_command(_attack_behaviour.new(self, direction))
func set_walk_behaviour(command_class):
	_walk_behaviour = command_class
func set_attack_behaviour(command_class):
	_attack_behaviour = command_class
