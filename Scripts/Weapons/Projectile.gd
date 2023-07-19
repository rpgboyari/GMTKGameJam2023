class_name Projectile extends Weapon

@export var projectile_speed: int

func _ready():
	super()
	attack_time = 999

func _physics_process(delta):
	if !attack_timer.is_stopped():
		position += attack_direction * projectile_speed * delta

func _on_body_entered(body):
	super(body)
	attack_end()
