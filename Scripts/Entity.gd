class_name Entity extends CharacterBody2D

signal damaged(damage, _hp)

enum ANIMATION_STATE {WALKING, ATTACKING, IDLE}
enum TEAM {HERO, VILLAIN}

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack: Attack = $Attack

const _MAX_COMMANDS_QUEUED = 1
const _DAMAGE_GRACE_TIME = 2

@export var max_hp: int
@export var damage: int
@export var walk_speed: int
@export var is_ranged: bool
@export var team: TEAM
@export var attack_sounds: Array
@export var hurt_sounds: Array
@export var death_sounds: Array

var walk_behaviour = Command.Walk_Basic
var attack_behaviour = Command.Attack_Basic

var _busy = false
var _command_queue: Array[Command]
var _animation_state: ANIMATION_STATE
var _damage_source_graces: Dictionary = {}
var _hp

func _physics_process(delta):
	if _busy: return
	var command_to_process = _command_queue.pop_front()
	if command_to_process:
		command_to_process.execute(delta)
	else:
		if _animation_state == ANIMATION_STATE.IDLE: return
		animator.play("idle")
		_animation_state = ANIMATION_STATE.IDLE

func _ready():
	_hp = max_hp
	motion_mode = MOTION_MODE_FLOATING
	attack.damage = damage
	attack.attack_finished.connect(_on_attack_finished)
	match team:
		TEAM.HERO:
			attack.collision_layer = 0b10
			attack.collision_mask = 0b10
		TEAM.VILLAIN:
			attack.collision_layer = 0b01
			attack.collision_mask = 0b01

func _attack(direction, attack_id):
	#animator.flip_h = direction.x < 0 #facing left
	transform.get_scale().x = -1 if direction.x < 0 else 1
	animator.play("attacking")
	_animation_state = ANIMATION_STATE.ATTACKING
	_play_random_sound(attack_sounds)
	_busy = true
	attack.start(direction, attack_id)
	#await get_tree().create_timer(attack_time).timeout
	#animator.stop()
	#_animation_state = ANIMATION_STATE.IDLE
func _walk(direction, delta):
	#animator.flip_h = direction.x < 0 #facing left
	transform.get_scale().x = -1 if direction.x < 0 else 1
	if _animation_state != ANIMATION_STATE.WALKING:
		animator.play("walking")
		_animation_state = ANIMATION_STATE.WALKING
	velocity = direction * walk_speed
	move_and_slide()

func _die():
	print_debug(str(self) + " dying")
	
	attack.cancel()
	animator.play("idle")
	_busy = true
	_play_random_sound(death_sounds)
	audio_player.finished.connect(queue_free)
	
	while true:
		self.visible = false
		await get_tree().create_timer(0.1).timeout
		self.visible = true
		await get_tree().create_timer(0.1).timeout

func _play_random_sound(sound_effects):
	if sound_effects.is_empty():
		return
	var to_play = sound_effects.pick_random()
	audio_player.stop()
	audio_player.stream = to_play
	audio_player.play()

func _on_attack_finished():
	animator.play("idle")
	_animation_state = ANIMATION_STATE.IDLE
	_busy = false

#func _on_body_entered(body):
#	print_debug(str(body) + "'s weapon hit " + str(self))
#	if body.has_method("get_damage"):
#		take_damage(body.get_damage)
	
func take_damage(damage, source):
	if _damage_source_graces.has(source):
		return
	_damage_source_graces[source] = true
	print_debug(str(self) + " taking " + str(damage) + " damage")
	_play_random_sound(hurt_sounds)
	_hp -= damage
	if _hp <= 0:
		_die()
	damaged.emit(damage, _hp)
	
	for i in 3:
		self.visible = false
		await get_tree().create_timer(0.1).timeout
		self.visible = true
		await get_tree().create_timer(0.1).timeout
	
	await get_tree().create_timer(_DAMAGE_GRACE_TIME).timeout
	_damage_source_graces.erase(source)
#func get_damage():
#	return weapon.damage

func give_command(command: Command):
	assert(!(_command_queue.size() > _MAX_COMMANDS_QUEUED))
	if _command_queue.size() == _MAX_COMMANDS_QUEUED:
		#_command_queue.pop_front()
		return
	_command_queue.push_back(command)

#func spam_command(command: Command):
#	for i in _MAX_COMMANDS_QUEUED:
#		give_command(command)
