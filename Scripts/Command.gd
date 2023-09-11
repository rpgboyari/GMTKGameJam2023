class_name Command
@warning_ignore("unused_private_class_variable")
var _executor

func execute(delta):
	return



class Attack_Basic extends Command:
	var _direction
	func _init(executor, direction):
		_executor = executor
		_direction = direction

	func execute(delta):
		_executor._attack(_direction, self)

class Walk_Basic extends Command:
	var _direction
	func _init(executor, direction):
		_executor = executor
		_direction = direction

	func execute(delta):
		print_debug("walking " + str(_direction) + " with delta of " + str(delta))
		_executor._walk(_direction, delta)

class Walk_Hastened extends Command:
	var _direction
	func _init(executor, direction):
		_executor = executor
		_direction = direction

	func execute(delta):
		_executor._walk(_direction * 2, delta)

class Walk_Feared extends Command:
	var _direction
	func _init(executor, direction):
		_executor = executor
		_direction = direction

	func execute(delta):
		_executor._walk(_direction * -1, delta)
