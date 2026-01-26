extends Control

@onready var button = $VBoxContainer/HBoxContainer/SeccionIzquierda/Result/TextureRect/Item/Button

# this connects the button when is already
func _ready() -> void:
	button.pressed.connect(_on_button_craft_pressed_general)

# toggling the UI menu
func toggle_menu():
	visible = !visible
	var player = get_tree().get_first_node_in_group("player")
	
	if visible:
		if player: player.menu_open = true
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_crafting_list()
	else:
		if player: player.menu_open = false
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

const SPRITE_SHEET = preload("res://sprites001.png")
const TILE_SIZE = 16

# now, recipes :)
var recipes = [
	{
		"name": "Chest",
		"id": "chest",
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
			null, # null means that the slot is empty
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
		"id": "furnace",
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
		"id": "woodenpickaxe",
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
		"id": "stonepickaxe",
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
		"id": "ironpickaxe",
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
		"id": "woodensword",
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
		"id": "ironsword",
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
		"id": "diamondsword",
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
		"id": "goldencarrotbar",
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

@onready var list_items = $VBoxContainer/HBoxContainer/ScrollContainer/VBoxContainer
@onready var recipe_scene = preload("res://RecetaUI.tscn")

# this creates an atlas sheet and gets the specific sprite
func get_atlas_icon(coords: Vector2i) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = SPRITE_SHEET
	atlas.region = Rect2(coords.x * TILE_SIZE, coords.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	return atlas

# hoping that this updates the list, idk
func update_crafting_list():
	for child in list_items.get_children():
		child.queue_free()
	
	for data in recipes:
		var new_recipe = recipe_scene.instantiate()
		
		# i need to add it first
		list_items.add_child(new_recipe)
		
		var node_label = new_recipe.get_node_or_null("Label")
		var node_text = new_recipe.get_node_or_null("TextureRect")
		
		if node_label:
			node_label.text = data["name"]
		
		if node_text:
			node_text.texture = get_atlas_icon(data["icon"])
		
		new_recipe.pressed.connect(_on_selected_recipe.bind(data))

@onready var res_icon = $VBoxContainer/HBoxContainer/SeccionIzquierda/Result/TextureRect/Item
@onready var res_name = $VBoxContainer/HBoxContainer/SeccionIzquierda/Result/Label
@onready var gridContainer = $VBoxContainer/HBoxContainer/SeccionIzquierda/GridContainer

# when the recipe is selected
func _on_selected_recipe(data):
	print("Selected: ", data["name"])
	
	res_name.text = data["name"]
	res_icon.texture = get_atlas_icon(data["icon"])
	
	actual_recipe = data
	
	update_recipe_grid(data["recipe"])

# this update the grid slots
func update_recipe_grid(recipes_array: Array):
	var slots = gridContainer.get_children()
	
	for i in range(slots.size()):
		var actualSlot = slots[i]
		var item_rect = actualSlot.get_node_or_null("Item")
		
		if not item_rect: continue
		
		if i < recipes_array.size() and recipes_array[i] != null:
			var material_data = recipes_array[i]
			item_rect.texture = get_atlas_icon(material_data["vector"])
			item_rect.visible = true
		else:
			item_rect.texture = null

var actual_recipe = null
@onready var hotbar = get_tree().get_first_node_in_group("Hotbar")

# this function craft recipes put on the first param
func craft(recipe):
	if hotbar.space_remaining() <= 0:
		return
	
	if has_ingredients(recipe["recipe"]):
		consume_ingredients(recipe["recipe"])
	
		var result_texture = get_atlas_icon(recipe["icon"])
		
		# this sends the texture directly to the hotbar
		hotbar.recolect(result_texture, recipe["id"].to_lower()) 
		
		print("Crafted: ", recipe["name"])
		update_crafting_list() 
	else:
		print("there's not enough materials")

# to check if the player has the required materials
func has_ingredients(recipe_array: Array) -> bool:
	var recipe_cont = {}
	for slot_data in recipe_array:
		if slot_data != null:
			var id_item = slot_data["id"]
			recipe_cont[id_item] = recipe_cont.get(id_item, 0) + 1
	
	for id in recipe_cont:
		var required_amount = recipe_cont[id]
		var current_amount = 0
		
		for slot in hotbar.dataslots:
			if slot["item"] != null:
				print("a: " + slot["item"], " - id: " + id)
				if slot["item"] == id:
					current_amount += slot["amount"]
		
		if current_amount < required_amount:
			print("Material missing: ", id, " (Player has: ", current_amount, "/", required_amount, ")")
			return false
			
	return true

# this consume the ingredients from the hotbar and updates the UI
func consume_ingredients(recipe_array: Array):
	var required_items = {}
	for slot_data in recipe_array:
		if slot_data != null:
			var item_id = slot_data["id"]
			required_items[item_id] = required_items.get(item_id, 0) + 1
	
	for item_id in required_items:
		var remaining = required_items[item_id]
		
		for slot in hotbar.dataslots:
			if remaining <= 0: break 
			
			if slot["item"] != null and slot["item"] == item_id:
				if slot["amount"] >= remaining:
					slot["amount"] -= remaining
					remaining = 0
				else:
					remaining -= slot["amount"]
					slot["amount"] = 0
				
				if slot["amount"] <= 0:
					slot["item"] = null
					slot["atlas"] = null
	
	hotbar.update_hotbar_ui()

# when the craft button is clicked
func _on_button_craft_pressed_general():
	if actual_recipe != null:
		print("Trying the craft: ", actual_recipe["name"])
		craft(actual_recipe)
	else:
		print("Any recipe selected")
