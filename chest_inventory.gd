extends Control

@onready var grid = $Panel/GridContainer
var current_chest = null

# when the player open the chest
func open_chest(chest_object):
	current_chest = chest_object
	visible = true
	get_tree().get_first_node_in_group("Player").menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_slots()

# this updates the chest's slots
func update_slots():
	if not grid or not current_chest: return
	
	var slots_ui = grid.get_children()
	
	for i in range(slots_ui.size()):
		if i >= current_chest.items.size(): break
		
		var slot_data = current_chest.items[i]
		var slot_visual = slots_ui[i]
		
		var texture_rect = slot_visual.get_node_or_null("Item")
		if texture_rect:
			if slot_data["item"] != null:
				texture_rect.texture = slot_data["atlas"]
				texture_rect.show()
			else:
				texture_rect.texture = null
				texture_rect.hide()
		
		var label = slot_visual.get_node_or_null("Label")
		if label:
			if slot_data["item"] != null and slot_data["amount"] >= 1:
				label.text = str(slot_data["amount"])
				label.show()
			else:
				label.text = ""
				label.hide()
			
		var button = slot_visual.get_node_or_null("Button")
		if button:
			if button.pressed.is_connected(_on_slot_clicked):
				button.pressed.disconnect(_on_slot_clicked)
			button.pressed.connect(_on_slot_clicked.bind(i))

# to detect when the player interacts with the chest or wants to exit
func _input(event):
	if not visible: return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_interact"):
		get_viewport().set_input_as_handled()
		close_chest()

# this closes the chest
func close_chest():
	visible = false
	get_tree().get_first_node_in_group("Player").menu_open = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

# when the player clicks on a chest's slot
func _on_slot_clicked(index):
	print("chest slot clicked")
	var player_hotbar = get_tree().get_first_node_in_group("Hotbar")
	if not player_hotbar or not current_chest: return
	
	var hand_slot = player_hotbar.dataslots[player_hotbar.selected_slot]
	var chest_slot = current_chest.items[index]
	
	if hand_slot["item"] != null and chest_slot["item"] == null:
		current_chest.items[index] = hand_slot.duplicate()
		hand_slot["item"] = null
		hand_slot["atlas"] = null
		hand_slot["amount"] = 1
		print("Item guardado en cofre")
	elif hand_slot["item"] == null and chest_slot["item"] != null:
		player_hotbar.dataslots[player_hotbar.selected_slot] = chest_slot.duplicate()
		current_chest.items[index] = { "item": null, "amount": 0, "atlas": null }
		print("Item sacado del cofre")
	elif hand_slot["item"] != null and chest_slot["item"] != null:
		var temp = hand_slot.duplicate()
		player_hotbar.dataslots[player_hotbar.selected_slot] = chest_slot.duplicate()
		current_chest.items[index] = temp
		print("Items swaped")
	
	update_slots()
	player_hotbar.update_hotbar_ui()
