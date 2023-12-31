class_name Melee_Attack extends Attack

@export var frames: Array[Array]

var _current_frame: int = 0
var _phys_frames_waited: int = 0
var _current_attack_id

func _ready():
	body_entered.connect(_on_body_entered)
	for child in get_children():
		if child.name.begins_with("f"):
			var frame_number = child.name.unicode_at(1) - 48
			var second_digit = child.name.unicode_at(2)
			if second_digit != 45:
				frame_number = frame_number * 10 + second_digit - 48
			while !(frame_number < frames.size()):
				frames.append([])
			frames[frame_number].append(child)

func _physics_process(delta):
	if _mid_attack:
		if _canceled_attack:
			_end_attack()
			return
		_phys_frames_waited += 1
		if _phys_frames_waited < Global_Constants.PHYS_FRAMES_TO_ANIM_FRAMES:
			return
		if _current_frame + 1 >= frames.size():
			_end_attack()
			return
		_disable_frame(_current_frame)
		_current_frame += 1
		_enable_frame(_current_frame)
		_phys_frames_waited = 0
	elif _buffered_attack:
		_begin_attack()

func _enable_frame(frame_index):
	for area_box in frames[frame_index]:
		area_box.set_deferred("disabled", false)

func _disable_frame(frame_index):
	for area_box in frames[frame_index]:
		area_box.set_deferred("disabled", true)

func _begin_attack():
	super()
	_current_frame = 0
	_phys_frames_waited = 0
	_current_attack_id = _buffered_attack_id
	_enable_frame(_current_frame)

func _end_attack():
	super()
	_disable_frame(_current_frame)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage, _current_attack_id)#.get_rid().get_id())
