extends Control

func _input(event):
	if event.is_action_pressed("ui_crafting") or (event is InputEventKey and event.keycode == KEY_E and event.pressed):
		toggle_menu()

func toggle_menu():
	visible = !visible
	var player = get_tree().get_first_node_in_group("player")
	
	if visible:
		if player: player.menu_open = true
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		actualizar_lista_crafting()
	else:
		if player: player.menu_open = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN # Opcional

const SPRITE_SHEET = preload("res://sprites001.png")
const TILE_SIZE = 16
var recetas = [
	{
		"name": "chest",
		"icon": Vector2i(3, 3),
		"recipe": [
			{
				"id": "wood",
				"vector": Vector2i(7, 4),
			},
			{
				"id": "wood",
				"vector": Vector2i(7, 4),
			},
			null,
			{
				"id": "wood",
				"vector": Vector2i(7, 4),
			},
			{
				"id": "wood",
				"vector": Vector2i(7, 4),
			},
		]
	},
	{
		"name": "furnace",
		"icon": Vector2i(1, 2),
		"recipe": []
	}
]

@onready var lista_items = $VBoxContainer/HBoxContainer/ScrollContainer/VBoxContainer
@onready var receta_escena = preload("res://RecetaUI.tscn") # La escena que creaste en el paso 1

func obtener_icono_atlas(coords: Vector2i) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = SPRITE_SHEET # La imagen grande
	# Definimos el cuadrado: Rect2(X, Y, Ancho, Alto)
	atlas.region = Rect2(coords.x * TILE_SIZE, coords.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	return atlas

func actualizar_lista_crafting():
	# 1. Limpiamos
	for hijo in lista_items.get_children():
		hijo.queue_free()
	
	# 2. Creamos
	for data in recetas:
		var nueva_receta = receta_escena.instantiate()
		
		# IMPORTANTE: Primero lo añadimos al árbol para evitar problemas de jerarquía
		lista_items.add_child(nueva_receta)
		
		# Buscamos los nodos. Si fallan, revisa los nombres en tu escena RecetaUI
		var label_nodo = nueva_receta.get_node_or_null("Label")
		var tex_nodo = nueva_receta.get_node_or_null("TextureRect")
		
		if label_nodo:
			label_nodo.text = data["name"]
		
		if tex_nodo:
			# ERROR CORREGIDO: data["icon"] es un Vector2i, necesitas la textura recortada
			tex_nodo.texture = obtener_icono_atlas(data["icon"])
		
		# Conectamos el click
		nueva_receta.pressed.connect(_on_receta_seleccionada.bind(data))

@onready var res_icono = $VBoxContainer/HBoxContainer/SeccionIzquierda/Resultado/TextureRect/Item
@onready var res_nombre = $VBoxContainer/HBoxContainer/SeccionIzquierda/Resultado/Label

func _on_receta_seleccionada(data):
	print("Seleccionado: ", data["name"])
	
	# Actualizamos el panel de la derecha
	res_nombre.text = data["name"]
	res_icono.texture = obtener_icono_atlas(data["icon"])
	
	# Guardamos la receta seleccionada para saber qué fabricar luego
	receta_actual = data
	
	# Aquí podrías llamar a una función para mostrar los materiales en el GridContainer
	# actualizar_materiales_necesarios(data["price"])

var receta_actual = null
