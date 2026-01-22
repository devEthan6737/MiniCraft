extends HBoxContainer

var slot_seleccionado = 0
var slots = []

func _ready():
	slots = get_children()
	actualizar_seleccion()

func _input(event):
	# Selección con números 1 al 9
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var nuevo_slot = event.keycode - KEY_1
			intentar_seleccionar(nuevo_slot)

	# Selección con rueda del ratón
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cambiar_slot(-1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cambiar_slot(1)

func cambiar_slot(direccion):
	var nuevo = wrapi(slot_seleccionado + direccion, 0, slots.size())
	intentar_seleccionar(nuevo)

func intentar_seleccionar(indice):
	# Si el índice es 5 o más (Slots 6, 7, 8, 9), no dejar seleccionar
	if indice >= 5:
		return
	
	slot_seleccionado = indice
	actualizar_seleccion()

func actualizar_seleccion():
	for i in range(slots.size()):
		var s = slots[i]
		
		if i == slot_seleccionado:
			# Efecto para el SELECCIONADO: Blanco total y un poco más grande
			s.modulate = Color(1.5, 1.5, 1.5) # Efecto de brillo (Bloom)
			s.scale = Vector2(1.01, 1.01)
			s.z_index = 1 # Que se vea por encima de los otros
		else:
			# Efecto para los DISPONIBLES pero no seleccionados: Normal
			s.modulate = Color(0.8, 0.8, 0.8, 1.0)
			s.scale = Vector2(1.0, 1.0)
			s.z_index = 0
