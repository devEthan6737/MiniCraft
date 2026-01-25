extends HBoxContainer

var slot_seleccionado = 0
var slots = []

func _ready():
	slots = get_children()
	actualizar_seleccion()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var nuevo_slot = event.keycode - KEY_1
			intentar_seleccionar(nuevo_slot)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cambiar_slot(-1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cambiar_slot(1)

func cambiar_slot(direccion):
	var nuevo = wrapi(slot_seleccionado + direccion, 0, slots.size())
	intentar_seleccionar(nuevo)

func intentar_seleccionar(indice):
	if indice >= 5:
		return
	
	slot_seleccionado = indice
	actualizar_seleccion()

func actualizar_seleccion():
	for i in range(slots.size()):
		var s = slots[i]
		
		if i == slot_seleccionado:
			s.modulate = Color(1.5, 1.5, 1.5)
			s.scale = Vector2(1.01, 1.01)
			s.z_index = 1
		else:
			s.modulate = Color(0.8, 0.8, 0.8, 1.0)
			s.scale = Vector2(1.0, 1.0)
			s.z_index = 0

var dataslots = [
	{ "item": null, "locked": false, "amount": 0 },
	{ "item": null, "locked": false, "amount": 0 },
	{ "item": null, "locked": false, "amount": 0 },
	{ "item": null, "locked": false, "amount": 0 },
	{ "item": null, "locked": false, "amount": 0 },
	{ "item": null, "locked": true, "amount": 0 },
	{ "item": null, "locked": true, "amount": 0 },
	{ "item": null, "locked": true, "amount": 0 },
	{ "item": null, "locked": true, "amount": 0 }
]

func recolect(item_id):
	# Buscar si ya existe el ítem Y tiene espacio para más
	for i in range(dataslots.size()):
		var slot = dataslots[i]
		# Comprobamos: que no esté bloqueado, que tenga el mismo ítem y que no haya llegado a 67
		if not slot["locked"] and slot["item"] != null:
			if slot["item"].region == item_id.region and slot["amount"] < 67:
				slot["amount"] += 1
				actualizar_interfaz_hotbar()
				return true

	# Si no se pudo sumar a ningún slot existente, buscar uno vacío
	for i in range(dataslots.size()):
		if not dataslots[i]["locked"] and dataslots[i]["item"] == null:
			dataslots[i]["item"] = item_id
			dataslots[i]["amount"] = 1
			actualizar_interfaz_hotbar()
			return true
			
	return false # Inventario totalmente lleno

const COORDS_SLOT_NORMAL = Vector2i(1, 6)
const SPRITE_SHEET = preload("res://uisprites.png")
const TILE_SIZE_UI = 64 # El tamaño de tus slots en el atlas

func get_slot_texture(coords: Vector2i) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = SPRITE_SHEET
	atlas.region = Rect2(coords.x * TILE_SIZE_UI, coords.y * TILE_SIZE_UI, TILE_SIZE_UI, TILE_SIZE_UI)
	return atlas

func actualizar_interfaz_hotbar():
	for i in range(dataslots.size()):
		var s = slots[i]
		var data = dataslots[i]
		var icono = s.get_node_or_null("ItemIcon")
		var label = s.get_node_or_null("AmountLabel")
		if data["item"] != null:
			if icono == null:
				icono = TextureRect.new()
				icono.name = "ItemIcon"
				icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				# Ajustamos el icono al tamaño del slot (puedes variar el offset)
				icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
				s.add_child(icono)
				
				var font = load("res://Monocraft-ttf/Monocraft.ttf")
				label = Label.new()
				label.name = "AmountLabel"
				
				label.add_theme_font_override("font", font)
				label.add_theme_font_size_override("font_size", 16)
				label.add_theme_constant_override("outline_size", 3)
				label.add_theme_color_override("font_outline_color", Color.BLACK)
				label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
				label.position.x -= 4
				s.add_child(label)
				icono.texture = data["item"]
				icono.show()

			label.text = str(data["amount"])
			label.show()
		else:
			if icono != null:
				icono.hide()
			if label != null:
				label.hide()

func unlock_next_slot() -> int:
	for i in range(dataslots.size()):
		if dataslots[i]["locked"] == true:
			dataslots[i]["locked"] = false
			# Quitamos la llamada a actualizar_interfaz_hotbar() de aquí
			return i 
	return -1

func unlock_by_day(day: int):
	# Cada 2 días intentamos desbloquear
	if (day % 2 == 0):
		var index = unlock_next_slot()
		if index >= 0 and index < slots.size():
			var slot_node = slots[index]
			#slot_node.texture = get_slot_texture(COORDS_SLOT_NORMAL)
			print("Slot visual modificado: ", index)
