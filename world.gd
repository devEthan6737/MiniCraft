extends Node2D

@onready var terrain = $Terrain
@onready var pantalla_carga = $ChargeLayer
@onready var player = $Player
@onready var timer = $DayNightTimer/Timer
@onready var sky_color = $SkyBackground/ColorRect
@onready var timer_label = $CanvasLayer/HUD/Cooldown
@onready var day_label = $CanvasLayer/HUD/Day
@onready var enemies_label = $CanvasLayer/HUD/Enemies

const CESPED = Vector2i(0, 0)
const HIERBA_V1 = Vector2i(1, 0)
const HIERBA_V2 = Vector2i(2, 0)
const HIERBA_V3 = Vector2i(7, 0)
const HIERBA_V4 = Vector2i(8, 0)
const TIERRA = Vector2i(3, 0)
const PIEDRA = Vector2i(0, 1)
const BEDROCK = Vector2i(2, 2)

const CARBON = Vector2i(1, 1)
const HIERRO = Vector2i(2, 1)
const DIAMANTE = Vector2i(3, 1)
const ORO = Vector2i(0, 2)

const CUESTA_IZQ = Vector2i(4, 0)
const CUESTA_IZQ_H = Vector2i(5, 0)
const CUESTA_IZQ_F = Vector2i(6, 0)

const CUESTA_DER = Vector2i(9, 0)
const CUESTA_DER_H = Vector2i(10, 0)
const CUESTA_DER_F = Vector2i(11, 0)

const TIERRA_DER = Vector2i(14, 0)
const TIERRA_IZQ = Vector2i(13, 0)

const ARBOL = Vector2i(4, 1)
const TRONCO_CORTADO = Vector2i(5, 5)

const ANCHO_MAPA = 500
const PROFUNDIDAD_MAX = 100
var limite_izquierdo = -ANCHO_MAPA / 2.0
var limite_derecho = ANCHO_MAPA / 2.0
const DISTANCIA_GENERACION = 20 # Bloques de margen antes de generar
const BLOQUES_A_AÑADIR = 100

var enemigos_vivos = 0
var es_de_noche = false
var day = 1
var spawnable_enemies_amount = 3

func _ready():
	pantalla_carga.show()
	
	# Desactivamos la física y el movimiento del jugador
	player.set_physics_process(false)
	player.process_mode = PROCESS_MODE_DISABLED
	player.visible = false # Opcional: que no se vea hasta que termine
	
	# Usamos 'call_deferred' o un pequeño timer para asegurar que 
	# la UI se pinte antes de que el procesador se sature generando
	await get_tree().create_timer(0.1).timeout

	generar_mundo()
	# Oculta el cursor del sistema y lo "atrapa" en la ventana
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	timer.timeout.connect(_on_timer_timeout)
	sky_color.color = Color("87ceeb")

func _process(_delta):
	if !timer.is_stopped():
		timer_label.text = formatear_tiempo(timer.time_left)
		day_label.text = "Day " + str(day)
	
	if player:
		# Convertimos la posición global del player a coordenadas de mapa
		var pos_player_mapa = terrain.local_to_map(player.global_position)
		
		# ¿Cerca del borde derecho?
		if pos_player_mapa.x > limite_derecho - DISTANCIA_GENERACION:
			generar_tramo(limite_derecho, limite_derecho + BLOQUES_A_AÑADIR)
			limite_derecho += BLOQUES_A_AÑADIR
			
		# ¿Cerca del borde izquierdo?
		if pos_player_mapa.x < limite_izquierdo + DISTANCIA_GENERACION:
			generar_tramo(limite_izquierdo - BLOQUES_A_AÑADIR, limite_izquierdo)
			limite_izquierdo -= BLOQUES_A_AÑADIR
	
	if es_de_noche and enemigos_vivos <= 0:
		amanecer_rapido()

var noise = FastNoiseLite.new()

func generar_mundo():
	noise.seed = randi()
	noise.frequency = 0.05
	
	var mapa_alturas = {}

	for x in range(-ANCHO_MAPA / 2.0, ANCHO_MAPA / 2.0):
		# ACTUALIZACIÓN DE LA BARRA AQUÍ DENTRO
		var progreso = float(x + ANCHO_MAPA / 2.0) / ANCHO_MAPA * 100
		
		# Accedemos al ProgressBar que está dentro de ChargeLayer
		# Asegúrate de que la ruta sea correcta (ej: $ChargeLayer/ProgressBar)
		$ChargeLayer/ProgressBar.value = progreso 
		
		# Cada 5 columnas, pausamos un frame para que Godot dibuje la barra
		if x % 5 == 0:
			await get_tree().process_frame

		var altura = int(noise.get_noise_1d(x) * 5)
		mapa_alturas[x] = altura
		
		for y in range(altura - 10, altura):
			terrain.set_cell(Vector2i(x, y), -1)
			
		for y in range(altura, altura + 6):
			terrain.set_cell(Vector2i(x, y), 1, TIERRA)
		for y in range(altura + 6, PROFUNDIDAD_MAX):
			terrain.set_cell(Vector2i(x, y), 1, PIEDRA)
		terrain.set_cell(Vector2i(x, PROFUNDIDAD_MAX), 1, BEDROCK)

	for x in range(-ANCHO_MAPA / 2.0, (ANCHO_MAPA / 2.0) - 1):
		var alt_act = mapa_alturas[x]
		var alt_sig = mapa_alturas[x + 1]
		
		if alt_sig < alt_act:
			# --- SUBIDA (El siguiente está más arriba) ---
			colocar_variacion_cuesta(Vector2i(x, alt_act - 1), "DER")
			terrain.set_cell(Vector2i(x, alt_act), 1, TIERRA_IZQ)
			
		elif alt_sig > alt_act:
			# --- BAJADA (El siguiente está más abajo) ---
			colocar_variacion_cuesta(Vector2i(x, alt_sig - 1), "IZQ")
			terrain.set_cell(Vector2i(x, alt_act + 1), 1, TIERRA_DER)
			
		else:
			# --- PLANO ---
			if terrain.get_cell_atlas_coords(Vector2i(x, alt_act)) == Vector2i(-1, -1) or \
			   terrain.get_cell_atlas_coords(Vector2i(x, alt_act)) == TIERRA:
				terrain.set_cell(Vector2i(x, alt_act), 1, CESPED)
			
			if randf() < 0.08: # Un 8% para que no esté todo lleno
				plantar_arbol(Vector2i(x, alt_act - 1))
			
			elif randf() < 0.4:
				var rand = randf();
				var tipo
				
				if (rand < 0.25):
					tipo = HIERBA_V1
				elif (rand < 0.50):
					tipo = HIERBA_V2
				elif (rand < 0.75):
					tipo = HIERBA_V3
				else:
					tipo = HIERBA_V4
				
				terrain.set_cell(Vector2i(x, alt_act - 1), 1, tipo)
	
	crear_vetas_en_tramo(-ANCHO_MAPA / 2.0, ANCHO_MAPA / 2.0)
	
	# Buscamos la altura del spawn (en x = 0 por ejemplo)
	var spawn_x = 0
	var spawn_y = mapa_alturas[spawn_x] - 2 # 2 bloques por encima del suelo
	
	# Convertimos coordenadas de mapa a posición global (píxeles)
	player.global_position = terrain.map_to_local(Vector2i(spawn_x, spawn_y))
	
	# Reactivamos al jugador
	player.set_physics_process(true)
	player.process_mode = PROCESS_MODE_INHERIT
	player.visible = true
	finalizar_carga()

func generar_tramo(desde_x: int, hasta_x: int):
	var mapa_alturas_nuevo = {}

	# 1. Base de relieve, tierra y piedra
	for x in range(desde_x, hasta_x):
		var altura = int(noise.get_noise_1d(x) * 5)
		mapa_alturas_nuevo[x] = altura
		
		# Limpiar aire y generar capas
		for y in range(altura - 10, altura): terrain.set_cell(Vector2i(x, y), -1)
		for y in range(altura, altura + 6): terrain.set_cell(Vector2i(x, y), 1, TIERRA)
		for y in range(altura + 6, PROFUNDIDAD_MAX): terrain.set_cell(Vector2i(x, y), 1, PIEDRA)
		terrain.set_cell(Vector2i(x, PROFUNDIDAD_MAX), 1, BEDROCK)

	# 2. Detalles y Decoración (Cuestas, césped, árboles)
	# Iteramos hasta hasta_x para asegurar que evaluamos la conexión con el siguiente
	for x in range(desde_x, hasta_x):
		var alt_act = mapa_alturas_nuevo[x]
		# Calculamos la altura del siguiente bloque usando el ruido para saber si hay cuesta
		var alt_sig = int(noise.get_noise_1d(x + 1) * 5)
		
		if alt_sig < alt_act:
			# --- SUBIDA ---
			colocar_variacion_cuesta(Vector2i(x, alt_act - 1), "DER")
			terrain.set_cell(Vector2i(x, alt_act), 1, TIERRA_IZQ)
			
		elif alt_sig > alt_act:
			# --- BAJADA ---
			colocar_variacion_cuesta(Vector2i(x, alt_sig - 1), "IZQ")
			terrain.set_cell(Vector2i(x, alt_act + 1), 1, TIERRA_DER)
			
		else:
			# --- PLANO ---
			# Solo ponemos césped si el bloque está vacío o es tierra
			var coords_actuales = terrain.get_cell_atlas_coords(Vector2i(x, alt_act))
			if coords_actuales == Vector2i(-1, -1) or coords_actuales == TIERRA:
				terrain.set_cell(Vector2i(x, alt_act), 1, CESPED)
			
			# Probabilidad de árboles
			if randf() < 0.08:
				plantar_arbol(Vector2i(x, alt_act - 1))
			# Probabilidad de hierba decorativa
			elif randf() < 0.4:
				var rand = randf()
				var tipo_hierba
				if rand < 0.25: tipo_hierba = HIERBA_V1
				elif rand < 0.50: tipo_hierba = HIERBA_V2
				elif rand < 0.75: tipo_hierba = HIERBA_V3
				else: tipo_hierba = HIERBA_V4
				terrain.set_cell(Vector2i(x, alt_act - 1), 1, tipo_hierba)
	
	# 3. Vetas de minerales (Solo en el nuevo tramo)
	crear_vetas_en_tramo(desde_x, hasta_x)

func colocar_variacion_cuesta(pos, lado):
	var r = randf()
	if lado == "IZQ":
		if r < 0.6: terrain.set_cell(pos, 1, CUESTA_IZQ)
		elif r < 0.85: terrain.set_cell(pos, 1, CUESTA_IZQ_H)
		else: terrain.set_cell(pos, 1, CUESTA_IZQ_F)
	else:
		if r < 0.6: terrain.set_cell(pos, 1, CUESTA_DER)
		elif r < 0.85: terrain.set_cell(pos, 1, CUESTA_DER_H)
		else: terrain.set_cell(pos, 1, CUESTA_DER_F)

func crear_vetas_en_tramo(desde_x: int, hasta_x: int):
	# Definimos los minerales y sus configuraciones en un Array para hacerlo limpio
	# [tipo, prof_min, prof_max, probabilidad, min_grupo, max_grupo]
	var configuracion_minerales = [
		[CARBON, 1, 30, 0.02, 4, 9],
		[HIERRO, 20, 70, 0.015, 3, 5],
		[DIAMANTE, 60, 100, 0.005, 2, 4],
		[ORO, 80, 100, 0.008, 1, 2]
	]

	for config in configuracion_minerales:
		var tipo = config[0]
		var p_min = config[1]
		var p_max = config[2]
		var prob = config[3]
		var g_min = config[4]
		var g_max = config[5]

		# SOLO recorremos las columnas nuevas
		for x in range(desde_x, hasta_x):
			for y in range(p_min, p_max):
				# Solo ponemos mineral si hay piedra
				if terrain.get_cell_atlas_coords(Vector2i(x, y)) == PIEDRA:
					if randf() < prob:
						var tamaño_veta = randi_range(g_min, g_max)
						for i in range(tamaño_veta):
							var offset = Vector2i(randi_range(-1, 1), randi_range(-1, 1))
							var pos_veta = Vector2i(x, y) + offset
							# Comprobamos que no se salga de la piedra
							if terrain.get_cell_atlas_coords(pos_veta) == PIEDRA:
								terrain.set_cell(pos_veta, 1, tipo)

func plantar_arbol(pos_suelo: Vector2i):
	var r = randf()
	
	if r < 0.15: 
		# --- OPCIÓN A: Árbol cortado (15% de probabilidad) ---
		terrain.set_cell(pos_suelo, 1, TRONCO_CORTADO)
		
	else:
		# 2. Ponemos la parte superior (3x2)
		# Como el tile mide 3 de ancho, para que el tronco coincida con el centro,
		# debemos desplazar la X en -1 y la Y en -2 (porque mide 2 de alto).
		# IMPORTANTE: Al ser un tile de 3x2, Godot en el TileSet suele 
		# pedir que indiques el tamaño del "atlas_coords". 
		# Si lo tienes configurado como un único Tile grande en el TileSet:
		terrain.set_cell(pos_suelo + Vector2i(0, -1), 1, ARBOL)

func finalizar_carga():
	# Podemos hacer un efecto de "fade out" para que sea más pro
	var tween = create_tween()
	tween.tween_property(pantalla_carga.get_node("ColorRect"), "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): pantalla_carga.hide())

@onready var hotbar = $CanvasLayer/HUD/Hotbar
@onready var contenedor_vida = $CanvasLayer/HUD/LifeContainer

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		contenedor_vida.recibir_danio(1)

func _on_timer_timeout():
	hacerse_de_noche()

func hacerse_de_noche():
	es_de_noche = true
	enemigos_vivos = spawnable_enemies_amount
	# Tween para cambiar el color a azul oscuro/negro en 2 segundos
	var tween = create_tween()
	tween.tween_property(sky_color, "color", Color("0a0a2a"), 2.0)
	enemies_label.text = str(enemigos_vivos) + " Enemies remaining"
	spawn_enemigos(spawnable_enemies_amount)

func spawn_enemigos(cantidad):
	for i in range(cantidad):
		await get_tree().create_timer(1).timeout

		var nuevo_enemigo = preload("res://Enemy.tscn").instantiate()
		
		var spawn_x_pixels = 0.0
		var intento_exitoso = false
		
		for intento in range(5):
			var lado = 1 if randf() > 0.5 else -1
			# Añadimos i * 20 para que cada enemigo de la tanda 
			# busque un punto X ligeramente distinto y no se pisen
			var offset = (randf_range(250, 400) + (i * 20)) * lado 
			var posible_x = player.global_position.x + offset
			
			var min_x_px = limite_izquierdo * 16.0
			var max_x_px = limite_derecho * 16.0
			
			if posible_x > min_x_px and posible_x < max_x_px:
				spawn_x_pixels = posible_x
				intento_exitoso = true
				break
		
		if not intento_exitoso:
			spawn_x_pixels = player.global_position.x + (i * 30) # Separación de emergencia
		
		var pos_mapa_x = terrain.local_to_map(Vector2(spawn_x_pixels, 0)).x
		var suelo_y = encontrar_suelo_en_x(pos_mapa_x)
		
		# --- CAMBIO AQUÍ: Aparecen 2 bloques por encima (suelo_y - 2) ---
		# Así caen con gravedad y evitamos que se fusionen con el césped
		nuevo_enemigo.global_position = terrain.map_to_local(Vector2i(pos_mapa_x, suelo_y - 2))
		
		# Evitamos que el nombre de la señal sea genérico para evitar errores de conexión
		if not nuevo_enemigo.tree_exited.is_connected(_on_enemigo_muerto):
			nuevo_enemigo.tree_exited.connect(_on_enemigo_muerto)
			
		add_child(nuevo_enemigo)
		print("Enemy spawned: " + str(pos_mapa_x) + ":" + str(suelo_y))

# Función auxiliar para encontrar donde hay bloques
func encontrar_suelo_en_x(x_mapa: int) -> int:
	# Escaneamos desde el cielo hacia abajo hasta encontrar algo que no sea aire (-1)
	for y in range(-50, PROFUNDIDAD_MAX):
		if terrain.get_cell_source_id(Vector2i(x_mapa, y)) != -1:
			return y
	return 0 # Por si acaso no encuentra nada

func _on_enemigo_muerto():
	enemigos_vivos -= 1
	enemies_label.text = str(enemigos_vivos) + " Enemies remaining"

func amanecer_rapido():
	es_de_noche = false
	enemies_label.text = ""
	day += 1
	spawnable_enemies_amount = spawnable_enemies_amount + day
	var tween = create_tween()
	# Vuelve al azul claro rápido (en 1 segundo)
	tween.tween_property(sky_color, "color", Color("87ceeb"), 1.0)
	
	# Reiniciar el cooldown de 5 minutos
	timer.start()
	
	hotbar.unlock_by_day(day)

func formatear_tiempo(segundos_totales: float) -> String:
	# Calculamos minutos y segundos usando división entera y resto
	var minutos : int = int(segundos_totales) / 60
	var segundos : int = int(segundos_totales) % 60
	
	# El formato "%02d" asegura que siempre haya 2 dígitos (ej: 05:01 en vez de 5:1)
	return "%02d:%02d" % [minutos, segundos]
