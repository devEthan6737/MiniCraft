extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -220.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W)) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if Input.is_key_pressed(KEY_S) and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

@export var range_minado = 40 # Distancia máxima en píxeles
@onready var terrain = get_node("../Terrain") # "../" sube al padre (World) y busca "Terrain"
var tiempo_actual_minado = 0.0
var bloque_actual_siendo_picado = Vector2i(-1, -1)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		resetear_minado()

const DIRT_BACKGROUND = Vector2i(12, 0)
const ROCK_BACKGROUND = Vector2i(3, 2)
@onready var item_escena = preload("res://DroppedItem.tscn")
func minar():
	var pos_raton = get_global_mouse_position()
	
	# Comprobar distancia (opcional pero recomendado para DAM)
	if global_position.distance_to(pos_raton) > range_minado:
		return

	var pos_mapa = terrain.local_to_map(pos_raton)
	
	# Obtenemos los datos del tile en esa posición
	var tile_data = terrain.get_cell_tile_data(pos_mapa)
	
	if tile_data:
		# Leemos el Custom Data que configuramos en el TileSet
		var tipo = tile_data.get_custom_data("object_type")
		
		if (tipo == 'baserock'):
			print("No es posible picar: ", tipo)
			return
		else:
			print("Picado: ", tipo)
			
			var atlas_coords = terrain.get_cell_atlas_coords(pos_mapa)
			var source_id = terrain.get_cell_source_id(pos_mapa)
			
			soltar_item(pos_mapa, atlas_coords, source_id)
			
			# Eliminamos el bloque
			if (pos_mapa.y >= 6):
				putBackground(pos_mapa, tipo)
			elif (pos_mapa.y >= 3):
				putBackground(pos_mapa, tipo)
			else:
				tile_data = terrain.get_cell_tile_data(pos_mapa + Vector2i(0, -1))
				if (tile_data):
					tipo = tile_data.get_custom_data("object_type")
					if (tipo.contains('grassv')):
						terrain.set_cell(pos_mapa + Vector2i(0, -1), -1)
				terrain.set_cell(pos_mapa, -1)

func putBackground (position, type):
	if (type == "rock_bkp" || type == "dirt_bkg"):
		return
	
	if (type == 'dirt'):
		terrain.set_cell(position, 1, DIRT_BACKGROUND)
	else:
		terrain.set_cell(position, 1, ROCK_BACKGROUND)

@onready var selector = get_node("../Cursor") # Ajusta la ruta a tu nodo

func _process(delta):
	actualizar_selector()
	
	# Si mantenemos el clic izquierdo pulsado
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		gestionar_proceso_minado(delta)
	else:
		resetear_minado()

func gestionar_proceso_minado(delta):
	var pos_raton = get_global_mouse_position()
	var pos_mapa = terrain.local_to_map(pos_raton)
	
	# Si cambiamos de bloque mientras picamos, reiniciamos el tiempo
	if pos_mapa != bloque_actual_siendo_picado:
		tiempo_actual_minado = 0.0
		bloque_actual_siendo_picado = pos_mapa
	
	# Si estamos en rango y hay un bloque
	if global_position.distance_to(pos_raton) <= range_minado:
		var tile_data = terrain.get_cell_tile_data(pos_mapa)
		if tile_data:
			tiempo_actual_minado += delta
			
			# EFECTO VISUAL: Hacer que el cursor vibre un poco al picar
			selector.rotation = randf_range(-0.2, 0.2)
			
			# Si hemos llegado al tiempo necesario
			tile_data = terrain.get_cell_tile_data(pos_mapa)
			var tipo = tile_data.get_custom_data("break_time")
			if tiempo_actual_minado >= tipo:
				minar() # Llamamos a tu función original que borra el bloque
				tiempo_actual_minado = 0.0 # Reset para el siguiente bloque
	else:
		resetear_minado()

func resetear_minado():
	tiempo_actual_minado = 0.0
	bloque_actual_siendo_picado = Vector2i(-1, -1)
	selector.rotation = 0 # Quitar vibración

func actualizar_selector():
	var pos_raton = get_global_mouse_position()
	
	# 1. Movimiento libre: El sprite sigue al ratón exactamente
	selector.global_position = pos_raton
	
	# 2. Lógica de distancia (sigue siendo igual)
	if global_position.distance_to(pos_raton) > range_minado:
		selector.modulate = Color(1, 0, 0, 0.7) # Rojo si está lejos
	else:
		selector.modulate = Color(1, 1, 1, 0.9) # Blanco si está cerca

func soltar_item(pos_mapa, atlas_coords, source_id):
	var nuevo_item = item_escena.instantiate()
	
	# Lo añadimos a la escena "World" (el padre del player)
	get_parent().add_child(nuevo_item)
	
	# Lo posicionamos donde estaba el bloque
	nuevo_item.global_position = terrain.map_to_local(pos_mapa)
	
	# Le pasamos la imagen que debe tener
	nuevo_item.configurar(atlas_coords, source_id)
	
	# --- ANIMACIÓN DE CAÍDA (Tween) ---
	# Hacemos que "salte" un poco al salir y luego caiga
	var destino = nuevo_item.global_position + Vector2(randf_range(-20, 20), 10)
	var tween = create_tween().set_parallel(true)
	
	# Salto en arco
	tween.tween_property(nuevo_item, "global_position:x", destino.x, 0.5)
	tween.tween_property(nuevo_item, "global_position:y", destino.y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
