extends Control

var current_furnace = null

# this var defines order
@onready var slot_nodes = [
	$Panel/GridContainer/Slot1, 
	$Panel/GridContainer/Slot2, 
	$Panel/GridContainer/Slot3
]

# to open the furnace
func open_furnace(furnace_obj):
	current_furnace = furnace_obj
	visible = true
	get_tree().get_first_node_in_group("Player").menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_slots()

# this updates the three slots
func update_slots():
	if not current_furnace: return
	for i in range(slot_nodes.size()):
		var data = current_furnace.items[i]
		var slot = slot_nodes[i]
		
		var texture_rect = slot.get_node("Item")
		var label = slot.get_node("Label")
		var button = slot.get_node("Button")
		
		if data["item"] != null:
			texture_rect.texture = data["atlas"]
			texture_rect.show()
			label.text = str(data["amount"])
		else:
			texture_rect.hide()
			label.text = ""
			
		if not button.pressed.is_connected(_on_slot_clicked):
			button.pressed.connect(_on_slot_clicked.bind(i))

# when a slot is clicked
func _on_slot_clicked(index):
	var player_hotbar = get_tree().get_first_node_in_group("Hotbar")
	if not player_hotbar or not current_furnace: return
	
	var hand = player_hotbar.dataslots[player_hotbar.selected_slot]
	var furnace_slot = current_furnace.items[index]
	
	if index == 2:
		if furnace_slot["item"] != null:
			var success = player_hotbar.recolect(furnace_slot["atlas"], furnace_slot["item"])
			
			if success:
				current_furnace.items[index] = {"item": null, "amount": 0, "atlas": null}
				update_slots()
			else:
				print("Inventory full")
		return

	# swaping between slot1 & slot2
	if hand["item"] != null and furnace_slot["item"] == null:
		current_furnace.items[index] = hand.duplicate()
		hand["item"] = null
		hand["atlas"] = null
		hand["amount"] = 0
	elif hand["item"] == null and furnace_slot["item"] != null:
		player_hotbar.dataslots[player_hotbar.selected_slot] = furnace_slot.duplicate()
		current_furnace.items[index] = {"item": null, "amount": 0, "atlas": null}
	elif hand["item"] != null and furnace_slot["item"] != null:
		var temp = hand.duplicate()
		player_hotbar.dataslots[player_hotbar.selected_slot] = furnace_slot.duplicate()
		current_furnace.items[index] = temp
	
	update_slots.call_deferred()
	player_hotbar.update_hotbar_ui.call_deferred()

# detecting E -> to close UI
func _input(event):
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_interact")):
		get_viewport().set_input_as_handled()
		visible = false
		get_tree().get_first_node_in_group("Player").menu_open = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
