extends Control

@onready var grid = $Panel/GridContainer
var current_chest = null # Referencia al cofre físico que abrimos

func open_chest(chest_object):
	current_chest = chest_object
	visible = true
	get_tree().get_first_node_in_group("Player").menu_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_slots()

func update_slots():
	if not grid or not current_chest: return
	
	var slots_ui = grid.get_children()
	
	for i in range(slots_ui.size()):
		if i >= current_chest.items.size(): break
		
		var slot_data = current_chest.items[i]
		var slot_visual = slots_ui[i] # El contenedor del slot (Panel/Rect)
		
		# 1. ACTUALIZAR ICONO
		var texture_rect = slot_visual.get_node_or_null("Item")
		if texture_rect:
			if slot_data["item"] != null:
				texture_rect.texture = slot_data["atlas"]
				texture_rect.show()
			else:
				texture_rect.texture = null
				texture_rect.hide()
		
		# 2. ACTUALIZAR CANTIDAD (LABEL) - MOVIDO FUERA DEL IF TEXTURE PARA SEGURIDAD
		var label = slot_visual.get_node_or_null("Label")
		if label:
			if slot_data["item"] != null and slot_data["amount"] >= 1:
				label.text = str(slot_data["amount"])
				label.show() # Asegúrate de que se vea
			else:
				label.text = ""
				label.hide() # Ocultar si es 1 o está vacío

		# 3. ACTUALIZAR BOTÓN
		var button = slot_visual.get_node_or_null("Button")
		if button:
			if button.pressed.is_connected(_on_slot_clicked):
				button.pressed.disconnect(_on_slot_clicked)
			button.pressed.connect(_on_slot_clicked.bind(i))

func _input(event):
	# Solo procesamos si el menú es visible
	if not visible: return

	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_interact"):
		# Usamos set_input_as_handled() para que el juego no crea que 
		# seguimos pulsando la E fuera del menú.
		get_viewport().set_input_as_handled()
		close_chest()

func close_chest():
	visible = false
	get_tree().get_first_node_in_group("Player").menu_open = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_slot_clicked(index):
	print("booton")
	var player_hotbar = get_tree().get_first_node_in_group("Hotbar")
	if not player_hotbar or not current_chest: return
	
	# Slot seleccionado en la Hotbar del jugador
	var hand_slot = player_hotbar.dataslots[player_hotbar.selected_slot]
	# Slot clicado en el cofre
	var chest_slot = current_chest.items[index]
	
	# CASO A: Meter item al cofre (Tienes algo en mano, el slot del cofre está vacío)
	if hand_slot["item"] != null and chest_slot["item"] == null:
		current_chest.items[index] = hand_slot.duplicate()
		# Vaciamos la mano
		hand_slot["item"] = null
		hand_slot["atlas"] = null
		hand_slot["amount"] = 1
		print("Item guardado en cofre")

	# CASO B: Sacar item del cofre (Mano vacía, el cofre tiene algo)
	elif hand_slot["item"] == null and chest_slot["item"] != null:
		# Pasamos los datos a la mano
		player_hotbar.dataslots[player_hotbar.selected_slot] = chest_slot.duplicate()
		# Vaciamos el cofre
		current_chest.items[index] = { "item": null, "amount": 0, "atlas": null }
		print("Item sacado del cofre")
		
	# CASO C: Intercambiar (Ambos tienen algo)
	elif hand_slot["item"] != null and chest_slot["item"] != null:
		var temp = hand_slot.duplicate()
		player_hotbar.dataslots[player_hotbar.selected_slot] = chest_slot.duplicate()
		current_chest.items[index] = temp
		print("Items intercambiados")

	# Actualizamos ambas UIs para ver los cambios
	update_slots()
	player_hotbar.update_hotbar_ui()
