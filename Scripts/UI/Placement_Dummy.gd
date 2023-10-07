extends Area2D

var enabled: bool
var overlapping: bool

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	#monitorable = false
	overlapping = false
	disable()

func enable():
	monitoring = true
	visible = true
	enabled = true

func disable():
	monitoring = false
	visible = false
	enabled = false

func _on_body_entered(body):
	overlapping = true
	print_debug(str(self) + " overlapped " + str(body))
	modulate = 0xff3550ff

func _on_body_exited(body):
	print_debug(str(self) + " stopped overlapping " + str(body))
	overlapping = get_overlapping_bodies().size() > 0
	if !overlapping:
		modulate = 0xffffffff
