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
		"name": "Chest",
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
		"name": "Furnace",
		"icon": Vector2i(1, 2),
		"recipe": [
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			null,
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			null,
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			}
		]
	},
	{
		"name": "Wooden Pickaxe",
		"icon": Vector2i(4, 6),
		"recipe": [
			{
				"id": "wood",
				"vector": Vector2i(7, 4)
			},
			{
				"id": "wood",
				"vector": Vector2i(7, 4)
			},
			{
				"id": "wood",
				"vector": Vector2i(7, 4)
			},
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null,
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null
		]
	},
	{
		"name": "Stone Pickaxe",
		"icon": Vector2i(3, 6),
		"recipe": [
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			{
				"id": "rock",
				"vector": Vector2i(0, 1)
			},
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null,
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null
		]
	},
	{
		"name": "Iron Pickaxe",
		"icon": Vector2i(2, 6),
		"recipe": [
			{
				"id": "iron",
				"vector": Vector2i(4, 5)
			},
			{
				"id": "iron",
				"vector": Vector2i(4, 5)
			},
			{
				"id": "iron",
				"vector": Vector2i(4, 5)
			},
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null,
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null
		]
	},
	{
		"name": "Wooden Sword",
		"icon": Vector2i(4, 7),
		"recipe": [
			null,
			{
				"id": "wood",
				"vector": Vector2i(7, 4)
			},
			null,
			null,
			{
				"id": "wood",
				"vector": Vector2i(7, 4)
			},
			null,
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null
		]
	},
	{
		"name": "Iron Sword",
		"icon": Vector2i(3, 7),
		"recipe": [
			null,
			{
				"id": "iron",
				"vector": Vector2i(4, 5)
			},
			null,
			null,
			{
				"id": "iron",
				"vector": Vector2i(4, 5)
			},
			null,
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null
		]
	},
	{
		"name": "Diamond Sword",
		"icon": Vector2i(2, 7),
		"recipe": [
			null,
			{
				"id": "diamond",
				"vector": Vector2i(3, 4)
			},
			null,
			null,
			{
				"id": "diamond",
				"vector": Vector2i(3, 4)
			},
			null,
			null,
			{
				"id": "stick",
				"vector": Vector2i(7, 3)
			},
			null
		]
	},
	{
		"name": "Golden Carrot Bar",
		"icon": Vector2i(6, 6),
		"recipe": [
			null,
			{
				"id": "carrotbar",
				"vector": Vector2i(6, 5)
			},
			null,
			null,
			{
				"id": "gold",
				"vector": Vector2i(3, 5)
			}
		]
	},
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
@onready var gridContainer = $VBoxContainer/HBoxContainer/SeccionIzquierda/GridContainer

func _on_receta_seleccionada(data):
	print("Seleccionado: ", data["name"])
	
	# 1. Actualizamos el panel de "Resultado" (el de la derecha)
	res_nombre.text = data["name"]
	res_icono.texture = obtener_icono_atlas(data["icon"])
	
	# 2. Guardamos la receta actual
	receta_actual = data
	
	# 3. Dibujamos la receta en el GridContainer
	actualizar_grid_receta(data["recipe"])

func actualizar_grid_receta(receta_array: Array):
	var slots = gridContainer.get_children()
	
	# Recorremos todos los slots del GridContainer (los 9 cuadros)
	for i in range(slots.size()):
		var actualSlot = slots[i]
		var item_rect = actualSlot.get_node_or_null("Item") # Buscamos el TextureRect "Item"
		
		if not item_rect: continue # Si el slot no tiene el nodo "Item", saltamos
		
		# Verificamos si la receta tiene algo en esta posición (i)
		# y si no nos hemos pasado del tamaño del array de la receta
		if i < receta_array.size() and receta_array[i] != null:
			var material_data = receta_array[i]
			# Usamos tu función de atlas con el "vector" guardado en la receta
			item_rect.texture = obtener_icono_atlas(material_data["vector"])
			item_rect.visible = true
		else:
			# Si la posición es null o la receta es más corta, limpiamos el slot
			item_rect.texture = null

var receta_actual = null
