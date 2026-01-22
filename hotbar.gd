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
	{ "item": null, "locked": false },
	{ "item": null, "locked": false },
	{ "item": null, "locked": false },
	{ "item": null, "locked": false },
	{ "item": null, "locked": false },
	{ "item": null, "locked": true },
	{ "item": null, "locked": true },
	{ "item": null, "locked": true },
	{ "item": null, "locked": true }
]

func recolect(item_id):
	# Recorremos los slots buscando uno que no esté bloqueado y esté vacío
	for i in range(dataslots.size()):
		if not dataslots[i]["locked"] and dataslots[i]["item"] == null:
			dataslots[i]["item"] = item_id
			actualizar_interfaz_hotbar() # Función para dibujar el item en pantalla
			return true # Recogido con éxito
			
	return false # No hay espacio o todos están bloqueados

func actualizar_interfaz_hotbar():
	for i in range(dataslots.size()):
		# Obtenemos el nodo visual del slot (el Panel/TextureRect que ya tienes)
		var s = slots[i]
		var data = dataslots[i]
		
		# Buscamos si ya existe un icono dentro del slot
		var icono = s.get_node_or_null("IconoItem")
		
		if data["item"] != null:
			# Si no existe el nodo del icono, lo creamos dinámicamente
			if icono == null:
				icono = TextureRect.new()
				icono.name = "IconoItem"
				icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				# Ajustamos el icono al tamaño del slot (puedes variar el offset)
				icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
				s.add_child(icono)
			
			# Asignamos la textura del bloque (item_id debe ser una Texture)
			icono.texture = data["item"]
			icono.show()
		else:
			# Si el slot está vacío y existe el nodo, lo ocultamos
			if icono != null:
				icono.hide()
