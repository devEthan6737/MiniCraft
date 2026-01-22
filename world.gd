extends Node2D

@onready var terrain = $Terrain

# --- COORDENADAS DEL ATLAS ---
const CESPED = Vector2i(0, 0)
const HIERBA_V1 = Vector2i(1, 0)
const HIERBA_V2 = Vector2i(2, 0)
const TIERRA = Vector2i(3, 0)
const PIEDRA = Vector2i(0, 1)
const BEDROCK = Vector2i(2, 2)

# --- MINERALES ---
const CARBON = Vector2i(1, 1)
const HIERRO = Vector2i(2, 1)
const DIAMANTE = Vector2i(3, 1)
const ORO = Vector2i(0, 2)

# --- CUESTAS (NUEVO) ---
# Subir de derecha a izquierda (Llamémosla Cuesta Izquierda)
const CUESTA_IZQ = Vector2i(4, 0)
const CUESTA_IZQ_H = Vector2i(5, 0)
const CUESTA_IZQ_F = Vector2i(6, 0)

# Subir de izquierda a derecha (Llamémosla Cuesta Derecha)
const CUESTA_DER = Vector2i(9, 0)
const CUESTA_DER_H = Vector2i(10, 0)
const CUESTA_DER_F = Vector2i(11, 0)

const ANCHO_MAPA = 100
const PROFUNDIDAD_MAX = 100

func _ready():
	generar_mundo()

func generar_mundo():
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	
	var mapa_alturas = {}

	# 1. PASO: Calcular alturas y limpiar el cielo
	for x in range(-ANCHO_MAPA / 2, ANCHO_MAPA / 2):
		var altura = int(noise.get_noise_1d(x) * 5)
		mapa_alturas[x] = altura
		
		# Limpiamos el aire por encima (importante para que no queden bloques flotando)
		for y in range(altura - 10, altura):
			terrain.set_cell(Vector2i(x, y), -1)
			
		# Rellenamos de tierra/piedra sólida
		for y in range(altura, altura + 6):
			terrain.set_cell(Vector2i(x, y), 1, TIERRA)
		for y in range(altura + 6, PROFUNDIDAD_MAX):
			terrain.set_cell(Vector2i(x, y), 1, PIEDRA)
		terrain.set_cell(Vector2i(x, PROFUNDIDAD_MAX), 1, BEDROCK)

	# 2. PASO: Post-procesado de Cuestas y Césped
	for x in range(-ANCHO_MAPA / 2, (ANCHO_MAPA / 2) - 1):
		var alt_act = mapa_alturas[x]
		var alt_sig = mapa_alturas[x + 1]
		
		if alt_sig < alt_act:
			# --- SUBIDA (El siguiente está más arriba) ---
			# Ponemos césped en el bloque actual
			# terrain.set_cell(Vector2i(x, alt_act), 1, TIERRA)
			# Ponemos la rampa DER justo a la derecha, al mismo nivel Y (alt_act)
			# Esto conecta el suelo bajo con el muro alto
			colocar_variacion_cuesta(Vector2i(x, alt_act - 1), "DER")
			# Y debajo de la rampa ponemos tierra para que no haya huecos
			# terrain.set_cell(Vector2i(x + 1, alt_act), 1, TIERRA)
			
		elif alt_sig > alt_act:
			# --- BAJADA (El siguiente está más abajo) ---
			# Ponemos la rampa IZQ en la posición actual, pero bajándola un nivel (+1)
			# para que apoye en el suelo de abajo
			colocar_variacion_cuesta(Vector2i(x, alt_sig - 1), "IZQ")
			# Aseguramos césped en el bloque de destino (abajo)
			#terrain.set_cell(Vector2i(x + 1, alt_sig), 1, CESPED)
			# Y tierra debajo de la rampa
			#terrain.set_cell(Vector2i(x, alt_sig + 1), 1, TIERRA)
			
		else:
			# --- PLANO (Si no hay cambio de altura en la siguiente celda) ---
			# Solo ponemos césped si no hay ya una rampa puesta por el paso anterior
			if terrain.get_cell_atlas_coords(Vector2i(x, alt_act)) == Vector2i(-1, -1) or \
			   terrain.get_cell_atlas_coords(Vector2i(x, alt_act)) == TIERRA:
				terrain.set_cell(Vector2i(x, alt_act), 1, CESPED)
				
			if randf() < 0.2:
				var tipo = HIERBA_V1 if randf() < 0.5 else HIERBA_V2
				terrain.set_cell(Vector2i(x, alt_act - 1), 1, tipo)

	# 3. GENERACIÓN DE VETAS
	crear_vetas(CARBON, 1, 30, 0.02, 4, 9)
	crear_vetas(HIERRO, 20, 70, 0.015, 3, 5)
	crear_vetas(DIAMANTE, 60, 100, 0.005, 2, 4)
	crear_vetas(ORO, 80, 100, 0.008, 1, 2)

# Función para elegir aleatoriamente si la cuesta tiene hierba o flores
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

# [El resto de funciones crear_vetas e _input se mantienen igual...]

# Función auxiliar para crear grupos de minerales
func crear_vetas(tipo_bloque, prof_min, prof_max, probabilidad, min_grupo, max_grupo):
	for x in range(-ANCHO_MAPA / 2, ANCHO_MAPA / 2):
		for y in range(prof_min, prof_max):
			# Si el bloque actual es PIEDRA y tenemos suerte...
			if terrain.get_cell_atlas_coords(Vector2i(x, y)) == PIEDRA and randf() < probabilidad:
				# Generamos un grupo aleatorio
				var tamaño_veta = randi_range(min_grupo, max_grupo)
				for i in range(tamaño_veta):
					var offset = Vector2i(randi_range(-1, 1), randi_range(-1, 1))
					var pos_veta = Vector2i(x, y) + offset
					# Solo sustituimos si hay piedra (para no romper el césped o bedrock)
					if terrain.get_cell_atlas_coords(pos_veta) == PIEDRA:
						terrain.set_cell(pos_veta, 1, tipo_bloque)

@onready var hotbar = $CanvasLayer/HUD/Hotbar
@onready var contenedor_vida = $CanvasLayer/HUD/LifeContainer

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		contenedor_vida.recibir_danio(1)
