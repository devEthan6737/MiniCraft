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
@onready var craftmenu = get_node("../CanvasLayer/HUD/CraftingMenu")
var tiempo_actual_minado = 0.0
var bloque_actual_siendo_picado = Vector2i(-1, -1)
var near_chest = null

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		atacar_o_minar()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		resetear_minado()
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		soltar_item_desde_hotbar()
	if event.is_action_pressed("ui_interact") or (event is InputEventKey and event.keycode == KEY_E and event.pressed): # La tecla E
		if near_chest != null:
			near_chest.interact()
		else:
			craftmenu.toggle_menu()

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
const WOOD = Vector2i(7, 4)
const STICK = Vector2i(7, 3)
const GRASS = Vector2i(3, 0)
@onready var item_escena = preload("res://DroppedItem.tscn")
func minar():
	var pos_raton = get_global_mouse_position()
	if global_position.distance_to(pos_raton) > range_minado: return
	
	var pos_mapa = terrain.local_to_map(pos_raton)
	var tile_data = terrain.get_cell_tile_data(pos_mapa)
	
	if tile_data:
		# 1. Extraer datos antes de borrar nada
		var tipo = tile_data.get_custom_data("object_type")
		var atlas_coords = terrain.get_cell_atlas_coords(pos_mapa)
		var source_id = terrain.get_cell_source_id(pos_mapa)
		var item_id = hotbar.dataslots[hotbar.selected_slot]["item"]
		
		# 2. Bloqueo de indestructibles
		if ["baserock", "dirt_bkg", "rock_bkg"].has(tipo):
			print("No es posible picar: ", tipo)
			return
		
		# 3. FILTRO DE HERRAMIENTA (Para minerales)
		# Si es mineral y NO tienes pico, detenemos todo aquí
		print(item_id)
		var es_mineral = [ "rock", "coal", "iron", "gold", "diamond", "furnace" ].has(tipo)
		var tiene_pico = [ "woodenpickaxe", "stonepickaxe", "ironpickaxe" ].has(item_id)
		
		if es_mineral and not tiene_pico:
			print("Necesitas un pico para esto")
			return
		
		# 4. PROCESO DE DROPEO (Basado en tus listas originales)
		if tipo == "tree":
			terrain.set_cell(Vector2i(pos_mapa.x, pos_mapa.y + 1), 1, Vector2i(5, 5))
			for x in range(3):
				soltar_item(Vector2i(pos_mapa.x - 1, pos_mapa.y), STICK, source_id, "stick")
				soltar_item(Vector2i(pos_mapa.x + 1, pos_mapa.y), WOOD, source_id, "wood")
		
		elif tipo == "stump":
			for x in range(2):
				soltar_item(Vector2i(pos_mapa.x - 1, pos_mapa.y), STICK, source_id, "stick")
				soltar_item(Vector2i(pos_mapa.x + 1, pos_mapa.y), WOOD, source_id, "wood")
		
		elif [ "grass", "ramp_v1_left", "ramp_v1_right", "ramp_v2_right", "ramp_v2_left", "ramp_v3_left", "ramp_v3_right", "ramp_filler_v1", "ramp_filler_v2" ].has(tipo):
			soltar_item(Vector2i(pos_mapa.x - 1, pos_mapa.y), GRASS, source_id, "dirt")
		
		elif tipo == "coal":
			soltar_item(pos_mapa, Vector2i(2, 4), source_id, "coal")
		
		elif tipo == "diamond":
			soltar_item(pos_mapa, Vector2i(3, 4), source_id, "diamond")
		
		else:
			# Para roca, tierra y todo lo demás
			soltar_item(pos_mapa, atlas_coords, source_id)
		
		# 5. ELIMINACIÓN Y BACKGROUND
		# Primero gestionamos el fondo o la hierba superior
		if pos_mapa.y >= 3:
			putBackground(pos_mapa, tipo)
		else:
			# Mirar arriba antes de borrar para quitar la hierba decorativa (grassv)
			var data_arriba = terrain.get_cell_tile_data(pos_mapa + Vector2i(0, -1))
			if data_arriba:
				var tipo_arriba = data_arriba.get_custom_data("object_type")
				if tipo_arriba.contains('grassv'):
					terrain.set_cell(pos_mapa + Vector2i(0, -1), -1)
			terrain.set_cell(pos_mapa, -1)

func putBackground (_position, type):
	if (type == 'dirt'):
		terrain.set_cell(_position, 1, DIRT_BACKGROUND)
	else:
		terrain.set_cell(_position, 1, ROCK_BACKGROUND)

@onready var selector = get_node("../Cursor") # Ajusta la ruta a tu nodo

func _process(delta):
	actualizar_selector()
	if menu_open: return
	
	# Si mantenemos el clic izquierdo pulsado
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		gestionar_proceso_minado(delta)
	else:
		resetear_minado()
	
	if Input.is_action_just_pressed("ui_undo") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		
		var current_slot_data = hotbar.dataslots[hotbar.selected_slot]
		
		if current_slot_data["item"] != null:
			var item_id = current_slot_data["item"]
			
			if [ "carrotbar", "goldencarrotbar", "health_potion", "big_health_potion" ].has(item_id):
				consume_item(current_slot_data)
				lifebar.update_ui()
			else:
			# Si no es consumible, intentamos colocarlo como bloque
				if Engine.get_frames_drawn() % 10 == 0:
					place()

@onready var lifebar = get_node("../CanvasLayer/HUD/LifeContainer")
func consume_item(slot):
	print("Consumiendo: ", slot["item"])
	
	match slot["item"]:
		"health_potion":
			lifebar.life = min(lifebar.life + 2, lifebar.maxlife)
		"big_health_potion":
			lifebar.life = min(lifebar.life + 4, lifebar.maxlife)
		"carrotbar":
			lifebar.life = min(lifebar.life + 7, lifebar.maxlife)
		"goldencarrotbar":
			lifebar.maxlife = lifebar.maxlife + 1
			lifebar.life = lifebar.maxlife

	# Reducimos la cantidad y actualizamos la UI
	slot["amount"] -= 1
	if slot["amount"] <= 0:
		slot["item"] = null
		slot["atlas"] = null
	
	hotbar.update_hotbar_ui()

func gestionar_proceso_minado(delta):
	var pos_raton = get_global_mouse_position()
	var pos_mapa = terrain.local_to_map(pos_raton)
	
	if pos_mapa != bloque_actual_siendo_picado:
		tiempo_actual_minado = 0.0
		bloque_actual_siendo_picado = pos_mapa
	
	if global_position.distance_to(pos_raton) <= range_minado:
		var tile_data = terrain.get_cell_tile_data(pos_mapa)
		if tile_data:
			# --- LÓGICA DE VELOCIDAD DE MINADO ---
			var multiplicador = 1.0
			var item_id = hotbar.dataslots[hotbar.selected_slot]["item"]
			
			# Si tienes cualquier pico, el tiempo corre el doble de rápido (tarda la mitad)
			if ["woodenpickaxe", "stonepickaxe", "ironpickaxe"].has(item_id):
				multiplicador = 2.0
			
			# Sumamos el tiempo multiplicado
			tiempo_actual_minado += delta * multiplicador
			# -------------------------------------
			
			selector.rotation = randf_range(-0.2, 0.2)
			
			var tiempo_romper = tile_data.get_custom_data("break_time")
			
			if tiempo_actual_minado >= tiempo_romper:
				minar() 
				tiempo_actual_minado = 0.0 
	else:
		resetear_minado()

func resetear_minado():
	tiempo_actual_minado = 0.0
	bloque_actual_siendo_picado = Vector2i(-1, -1)
	selector.rotation = 0 # Quitar vibración

@onready var hotbar = get_tree().get_first_node_in_group("Hotbar")
func actualizar_selector():
	var pos_raton = get_global_mouse_position()
	selector.global_position = pos_raton
	
	# --- LÓGICA DE PREVISUALIZACIÓN ---
	var preview_sprite = selector.get_node_or_null("Preview")
	if preview_sprite and hotbar:
		var slot_actual = hotbar.dataslots[hotbar.selected_slot]
		
		if slot_actual["atlas"] != null:
			preview_sprite.texture = slot_actual["atlas"].atlas
			preview_sprite.region_enabled = true
			preview_sprite.region_rect = slot_actual["atlas"].region
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

func soltar_item(pos_mapa, atlas_coords, source_id, meta_type = null):
	var nuevo_item = item_escena.instantiate()
	
	# Lo añadimos a la escena "World" (el padre del player)
	get_parent().add_child(nuevo_item)
	
	# Lo posicionamos donde estaba el bloque
	nuevo_item.global_position = terrain.map_to_local(pos_mapa)
	
	var tile_data = terrain.get_cell_tile_data(pos_mapa)
	var tipo_string = ""
	if meta_type:
		tipo_string = meta_type
	elif tile_data:
		tipo_string = tile_data.get_custom_data("object_type")

	print("soltar tipo: ", tipo_string)
	# Le pasamos la imagen que debe tener
	nuevo_item.configurar(atlas_coords, source_id, tipo_string)
	
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
		var slot = hotbar.dataslots[hotbar.selected_slot]
		if slot["atlas"] != null and slot["amount"] > 0:
			# Colocamos el bloque en el TileMap
			# Usamos los datos guardados en el AtlasTexture del slot
			var atlas_coords = Vector2i(slot["atlas"].region.position / 16.0)
			
			if slot["item"] == "chest":
				spawn_chest_object(pos_mapa)
			else:
				terrain.set_cell(pos_mapa, 1, atlas_coords)
			
			# 4. Restar cantidad
			slot["amount"] -= 1
			
			# 5. Si se acaba, limpiar el slot
			if slot["amount"] <= 0:
				slot["atlas"] = null
			
			hotbar.update_hotbar_ui()

func soltar_item_desde_hotbar():
	if not hotbar: return
	
	var slot = hotbar.dataslots[hotbar.selected_slot]
	
	# Si hay algo que soltar
	if slot["atlas"] != null and slot["amount"] > 0:
		# 1. Instanciar el ítem en el mundo
		var drop = item_escena.instantiate()
		get_parent().add_child(drop)
		
		# 2. Posicionarlo un poco adelantado al jugador
		drop.global_position = global_position + Vector2(10 * (3 if velocity.x >= 0 else -3), -5)
		
		# 3. Configurarlo (necesitamos sacar atlas_coords del region del slot)
		var atlas_coords = Vector2i(slot["atlas"].region.position / 16.0)
		drop.configurar(atlas_coords, 0, slot["item"]) # El 0 es el source_id por defecto
		
		# 4. Aplicar un impulso físico visual (usando tu lógica de Tween)
		var direccion_suelta = 20 if velocity.x >= 0 else -20
		var destino = drop.global_position + Vector2(direccion_suelta, 5)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(drop, "global_position:x", destino.x, 0.4)
		tween.tween_property(drop, "global_position:y", destino.y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# 5. Restar de la hotbar
		slot["amount"] -= 1
		if slot["amount"] <= 0:
			slot["atlas"] = null
		
		hotbar.update_hotbar_ui()

@onready var life_container = get_node("../CanvasLayer/HUD/LifeContainer")

func recibir_daño(cantidad):
	# 1. Llamamos a tu script de la interfaz para que reste vida y tiemble
	life_container.recibir_danio(cantidad)
	
	# 2. Efecto visual en el sprite del jugador
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# 3. Comprobamos si el jugador ha muerto usando la vida del LifeContainer
	if life_container.life <= 0:
		morir()

func morir():
	# Puedes cambiar esto por una animación de muerte o pantalla de Game Over
	get_tree().reload_current_scene()

@onready var chest_scene = preload("res://Chest.tscn")
func spawn_chest_object(map_pos):
	var new_chest = chest_scene.instantiate()
	new_chest.global_position = terrain.map_to_local(map_pos)
	get_parent().add_child(new_chest)
