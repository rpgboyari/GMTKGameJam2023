class_name Projectile extends Weapon

func _ready():
	super()
	attack_time = 999

func _physics_process(delta):
	if !attack_timer.is_stopped():
		position += attack_direction * projectile_speed * delta

func _on_body_entered(body):
	super(body)
	_on_attack_end()
