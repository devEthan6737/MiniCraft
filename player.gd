extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -220.0
var menu_open = false

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	# Si el menú está abierto, no procesamos el movimiento ni el salto
	if menu_open:
		velocity.x = move_toward(velocity.x, 0, SPEED) # Frenar suavemente
		move_and_slide()
		return # Saltamos el resto de la función
	
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
	
	# 5. LLAMAMOS A LAS ANIMACIONES
	actualizar_animaciones(direction)

var caminando = false
func actualizar_animaciones(direction):
	# Voltear sprite
	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true

	# --- LA CLAVE ESTÁ AQUÍ ---
	if is_on_floor():
		# Si estamos en el suelo, OLVIDAMOS el salto/caída por completo
		if Input.is_key_pressed(KEY_S):
			anim.play("shift")
		elif abs(velocity.x) > 10:
			# Si NO se está reproduciendo ya la caminata ni la transición
			if anim.current_animation != "walk" and anim.current_animation != "start_walk":
				anim.play("start_walk")
				anim.queue("walk") # Esto pone "walk" en lista de espera automáticamente
		else:
			anim.play("idle")
	else:
		# Solo entramos aquí si is_on_floor() es FALSE
		# Añadimos una pequeña zona muerta para la Y
		if velocity.y < -50: # Solo "salta" si sube con fuerza
			anim.play("jump")
		elif velocity.y > 50:
			anim.play("jump")

@export var range_minado = 40 # Distancia máxima en píxeles
@onready var terrain = get_node("../Terrain") # "../" sube al padre (World) y busca "Terrain"
var tiempo_actual_minado = 0.0
var bloque_actual_siendo_picado = Vector2i(-1, -1)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		atacar_o_minar()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		resetear_minado()
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		soltar_item_desde_hotbar()

func atacar_o_minar():
	# 1. Detección física en el punto del selector (Capa 2: Enemigos)
	var espacio_fisico = get_world_2d().direct_space_state
	var parametros = PhysicsPointQueryParameters2D.new()
	parametros.position = selector.global_position
	parametros.collision_mask = 2 # Asegúrate de que tus enemigos estén en la Layer 2
	
	var resultados = espacio_fisico.intersect_point(parametros)
	
	if resultados.size() > 0:
		var objeto = resultados[0].collider
		if objeto.has_method("recibir_daño"):
			objeto.recibir_daño(100)
			# Animación rápida de golpe
			anim.play("walk") 
			return # No picamos el bloque si golpeamos a alguien

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
		
		if (tipo == 'baserock' || tipo == 'dirt_bkg' || tipo == 'rock_bkg'):
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

func putBackground (_position, type):
	if (type == 'dirt'):
		terrain.set_cell(_position, 1, DIRT_BACKGROUND)
	else:
		terrain.set_cell(_position, 1, ROCK_BACKGROUND)

@onready var selector = get_node("../Cursor") # Ajusta la ruta a tu nodo

func _process(delta):
	if menu_open: return
	actualizar_selector()
	
	# Si mantenemos el clic izquierdo pulsado
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		gestionar_proceso_minado(delta)
	else:
		resetear_minado()
	
	if Input.is_action_just_pressed("ui_undo") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Usamos una pequeña flag para no colocar 60 bloques por segundo
		if Engine.get_frames_drawn() % 10 == 0: # Coloca cada 10 frames si se mantiene
			place()

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

@onready var hotbar = get_tree().get_first_node_in_group("Hotbar")
func actualizar_selector():
	var pos_raton = get_global_mouse_position()
	var pos_mapa = terrain.local_to_map(pos_raton)
	selector.global_position = pos_raton
	
	# --- LÓGICA DE PREVISUALIZACIÓN ---
	var preview_sprite = selector.get_node_or_null("Preview")
	if preview_sprite and hotbar:
		var slot_actual = hotbar.dataslots[hotbar.slot_seleccionado]
		
		if slot_actual["item"] != null:
			preview_sprite.texture = slot_actual["item"].atlas
			preview_sprite.region_enabled = true
			preview_sprite.region_rect = slot_actual["item"].region
			preview_sprite.scale = Vector2(0.5, 0.5)
			preview_sprite.modulate = Color(1, 1, 1, 0.5) # Transparente
			preview_sprite.show()
			
			# Ajustar el selector a la rejilla para ver dónde quedará
			# selector.global_position = terrain.map_to_local(pos_mapa)
		else:
			preview_sprite.hide()

	# Color de rango
	if global_position.distance_to(pos_raton) > range_minado:
		selector.modulate = Color(1, 0, 0, 0.7)
	else:
		selector.modulate = Color(1, 1, 1, 0.9)

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

func place():
	var pos_raton = get_global_mouse_position()
	
	# 1. Verificar distancia
	if global_position.distance_to(pos_raton) > range_minado:
		return
		
	var pos_mapa = terrain.local_to_map(pos_raton)
	var actual = terrain.get_cell_tile_data(pos_mapa)

	if actual:
		var tipo = actual.get_custom_data("object_type")
		# Si es fondo, se puede sustituir
		if tipo == "dirt_bkg" or tipo == "rock_bkg":
			pass
		else:
			return

		
	# 3. Pedir el ítem a la hotbar
	if hotbar:
		var slot = hotbar.dataslots[hotbar.slot_seleccionado]
		if slot["item"] != null and slot["amount"] > 0:
			# Colocamos el bloque en el TileMap
			# Usamos los datos guardados en el AtlasTexture del slot
			var atlas_coords = Vector2i(slot["item"].region.position / 16.0)
			terrain.set_cell(pos_mapa, 1, atlas_coords)
			
			# 4. Restar cantidad
			slot["amount"] -= 1
			
			# 5. Si se acaba, limpiar el slot
			if slot["amount"] <= 0:
				slot["item"] = null
			
			hotbar.actualizar_interfaz_hotbar()

func soltar_item_desde_hotbar():
	if not hotbar: return
	
	var slot = hotbar.dataslots[hotbar.slot_seleccionado]
	
	# Si hay algo que soltar
	if slot["item"] != null and slot["amount"] > 0:
		# 1. Instanciar el ítem en el mundo
		var drop = item_escena.instantiate()
		get_parent().add_child(drop)
		
		# 2. Posicionarlo un poco adelantado al jugador
		drop.global_position = global_position + Vector2(10 * (3 if velocity.x >= 0 else -3), -5)
		
		# 3. Configurarlo (necesitamos sacar atlas_coords del region del slot)
		var atlas_coords = Vector2i(slot["item"].region.position / 16.0)
		drop.configurar(atlas_coords, 0) # El 0 es el source_id por defecto
		
		# 4. Aplicar un impulso físico visual (usando tu lógica de Tween)
		var direccion_suelta = 20 if velocity.x >= 0 else -20
		var destino = drop.global_position + Vector2(direccion_suelta, 5)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(drop, "global_position:x", destino.x, 0.4)
		tween.tween_property(drop, "global_position:y", destino.y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# 5. Restar de la hotbar
		slot["amount"] -= 1
		if slot["amount"] <= 0:
			slot["item"] = null
		
		hotbar.actualizar_interfaz_hotbar()
