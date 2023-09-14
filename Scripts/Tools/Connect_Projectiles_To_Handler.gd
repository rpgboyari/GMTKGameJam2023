@tool
extends EditorScript

var _handler

func _run():
	print_debug("running Connect_Projectiles_To_Handler EditorScript")
	_handler = null
	var projectile_users = _search_branches(get_scene())
	assert(_handler, "no projectile handlers")
	for projectile_user in projectile_users:
		print_debug("connecting " + str(projectile_user) + " to " + str(_handler))
		assert(_handler.has_method("receive_projectile"))
		print_debug("does _handler have method receive_projectile? " + str(_handler.has_method("receive_projectile")))
		_handler.receive_projectile(_handler)
		projectile_user.send_projectile.connect(_handler.receive_projectile)
	print_debug("finished running Connect_Projectiles_To_Handler EditorScript")

func _search_branches(node):
	var projectile_users = []
	for child in node.get_children():
		if child.has_signal("send_projectile"):
			print_debug("child " + str(child) + " found with signal \'send_projectile\'")
			projectile_users.append(child)
		elif child.has_method("receive_projectile"):
			assert(!_handler, "to many projectile handlers")
			print_debug("child " + str(child) + " found with method \'receive_projectile\'")
			_handler = child
		projectile_users.append_array(_search_branches(child))
	return projectile_users
