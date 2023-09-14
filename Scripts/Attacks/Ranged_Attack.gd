class_name Ranged_Attack extends Attack

@export var projectile: PackedScene
@export var animation_frame_count: int
@export var projectile_ground_offset: int

@onready var _frames_to_wait = animation_frame_count * Global_Constants.PHYS_FRAMES_TO_ANIM_FRAMES
var _frames_waited
var _projectile_direction
var _projectile_index = 0
@onready var _instantiated_projectiles: Array[Projectile] = [
		projectile.instantiate(), projectile.instantiate(),
		projectile.instantiate(), projectile.instantiate()]

func _ready():
	for projectile in _instantiated_projectiles:
		_setup_projectile.call_deferred(projectile)

func _physics_process(delta):
	if _mid_attack:
		if _canceled_attack:
			_end_attack()
			return
		_frames_waited += 1
		if _frames_waited >= _frames_to_wait:
			_end_attack()
			_fire_projectile()
	elif _buffered_attack:
		_begin_attack()

func _begin_attack():
	super()
	_frames_waited = 0
	_projectile_direction = _buffered_direction

func _fire_projectile():
	_instantiated_projectiles[_projectile_index].fire(global_position, _projectile_direction)
	_projectile_index = (_projectile_index + 1) % _instantiated_projectiles.size()

func _correct_direction_for_offset():
#	_projectile_direction += global_position
#	_projectile_direction -= (global_position - projectile_ground_offset)
	_projectile_direction -= Vector2(0, projectile_ground_offset)

func _setup_projectile(projectile):
	projectile.disable()
	projectile.collision_layer = collision_layer
	projectile.collision_mask = collision_mask
	projectile.damage = damage
	projectile.ground_offset = projectile_ground_offset
	SignalBus.projectile_constructed.emit(projectile)
