class_name Command
@warning_ignore("unused_private_class_variable")
var _executor

func execute(delta):
	return



class Attack_Command extends Command:
	var _direction
	func _init(executor, direction):
		_executor = executor
		_direction = direction

	func execute(delta):
		_executor._attack(_direction, self)

class Walk_Command extends Command:
	var _direction
	func _init(executor, direction):
		_executor = executor
		_direction = direction
		
	func execute(delta):
		_executor._walk(_direction, delta)

class Walk_Hastened extends Walk_Command:
	func execute(delta):
		_executor._walk(_direction * 2, delta)

class Walk_Feared extends Walk_Command:
	func execute(delta):
		_executor._walk(_direction * -1, delta)
