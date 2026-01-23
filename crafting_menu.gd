extends Control

func _input(event):
	if event.is_action_pressed("ui_crafting") or (event is InputEventKey and event.keycode == KEY_E and event.pressed):
		toggle_menu()

func toggle_menu():
	visible = !visible
	var player = get_tree().get_first_node_in_group("player")
	
	if visible:
		if player: player.menu_open = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if player: player.menu_open = false
		# Input.mouse_mode = Input.MOUSE_MODE_HIDDEN # Opcional
