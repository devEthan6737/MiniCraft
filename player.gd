extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -220.0
var menu_open = false

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

# menu control, animations and movements
func _physics_process(delta: float) -> void:
	# if the menu is open, movement stops
	if menu_open:
		velocity.x = move_toward(velocity.x, 0, SPEED) # brake
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W)) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if Input.is_key_pressed(KEY_S) and is_on_floor(): # i wish i could know what i did
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	update_animations(direction)

var walking = false # is the player walking?

# animations manager
func update_animations(direction):
	# flip sprite
	if direction > 0:
		sprite.flip_h = false
	elif direction < 0:
		sprite.flip_h = true

	if is_on_floor():
		# if we are on floor, i want to forget jumps o falls
		if Input.is_key_pressed(KEY_S):
			anim.play("shift")
		elif abs(velocity.x) > 10:
			# if is not walking
			if anim.current_animation != "walk" and anim.current_animation != "start_walk":
				anim.play("start_walk")
				anim.queue("walk")
		else:
			anim.play("idle")
	else:
		if velocity.y < -50: # more safe
			anim.play("jump")
		elif velocity.y > 50:
			anim.play("jump")

@export var mine_range = 40
@onready var terrain = get_node("../Terrain")
@onready var craftmenu = get_node("../CanvasLayer/HUD/CraftingMenu")

var mining_time = 0.0
var mining_block = Vector2i(-1, -1)
var near_chest = null

# key inputs
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack_or_mine()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		reset_mine()
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		drop_from_hotbar()
	if event.is_action_pressed("ui_interact") or (event is InputEventKey and event.keycode == KEY_E and event.pressed): # La tecla E
		if near_chest != null:
			near_chest.interact()
		else:
			craftmenu.toggle_menu()

# this function help to decide if the player is mining or traying to attack
func attack_or_mine():
	if global_position.distance_to(selector.global_position) > (mine_range + 50):
		return
	
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = selector.global_position
	params.collision_mask = 2 # this is necessary
	
	var results = space.intersect_point(params)
	
	if results.size() > 0:
		var enemy = results[0].collider
		if enemy.has_method("take_damage"):
			var damage = 5 # base damage
			var push = 300.0 # base push
			var item_id = hotbar.dataslots[hotbar.selected_slot]["item"]
			match item_id:
				"woodensword":
					damage = 10
					push = 400.0
				"ironsword":
					damage = 25
					push = 450.0
				"diamondsword":
					damage = 500
					push = 600.0
				_: # other item
					damage = 5
			
			var push_direction = (enemy.global_position - global_position).normalized()
			
			enemy.take_damage(damage, push_direction * push)

			var tween = create_tween()
			tween.tween_property(sprite, "rotation", 0.5 if !sprite.flip_h else -0.5, 0.1)
			tween.tween_property(sprite, "rotation", 0.0, 0.1)
			
			return # if the player attacks, he won't mine

const DIRT_BACKGROUND = Vector2i(12, 0)
const ROCK_BACKGROUND = Vector2i(3, 2)
const WOOD = Vector2i(7, 4)
const STICK = Vector2i(7, 3)
const GRASS = Vector2i(3, 0)

@onready var item_escene = preload("res://DroppedItem.tscn")

# mine function
# this remove tiles from the set
# and drops them
func mine():
	var mouse = get_global_mouse_position()
	if global_position.distance_to(mouse) > mine_range: return
	
	var map = terrain.local_to_map(mouse)
	var tile_data = terrain.get_cell_tile_data(map)
	
	if tile_data:
		var type = tile_data.get_custom_data("object_type")
		var atlas_coords = terrain.get_cell_atlas_coords(map)
		var source_id = terrain.get_cell_source_id(map)
		var item_id = hotbar.dataslots[hotbar.selected_slot]["item"]
		
		# filtering
		if ["baserock", "dirt_bkg", "rock_bkg"].has(type):
			print("Cannot mine ", type)
			return
		
		var is_mineral = [ "rock", "coal", "iron", "gold", "diamond", "furnace" ].has(type)
		var has_pickaxe = [ "woodenpickaxe", "stonepickaxe", "ironpickaxe" ].has(item_id)
		
		if is_mineral and not has_pickaxe:
			print("Pickaxe required")
			return
		
		# droping
		if type == "tree":
			terrain.set_cell(Vector2i(map.x, map.y + 1), 1, Vector2i(5, 5))
			for x in range(3):
				drop(Vector2i(map.x - 1, map.y), STICK, source_id, "stick")
				drop(Vector2i(map.x + 1, map.y), WOOD, source_id, "wood")
		
		elif type == "stump":
			for x in range(2):
				drop(Vector2i(map.x - 1, map.y), STICK, source_id, "stick")
				drop(Vector2i(map.x + 1, map.y), WOOD, source_id, "wood")
		
		# im sorry about this condition...
		elif [ "grass", "ramp_v1_left", "ramp_v1_right", "ramp_v2_right", "ramp_v2_left", "ramp_v3_left", "ramp_v3_right", "ramp_filler_v1", "ramp_filler_v2" ].has(type):
			drop(Vector2i(map.x - 1, map.y), GRASS, source_id, "dirt")
		
		elif type == "coal":
			drop(map, Vector2i(2, 4), source_id, "coal")
		
		elif type == "diamond":
			drop(map, Vector2i(3, 4), source_id, "diamond")
		
		else:
			drop(map, atlas_coords, source_id)
		
		if map.y >= 3:
			putBackground(map, type)
		else:
			var above = terrain.get_cell_tile_data(map + Vector2i(0, -1))
			if above:
				var above_type = above.get_custom_data("object_type")
				if above_type.contains('grassv'):
					terrain.set_cell(map + Vector2i(0, -1), -1)
			terrain.set_cell(map, -1)

# swaping tiles between background
func putBackground (_position, type):
	if (type == 'dirt'):
		terrain.set_cell(_position, 1, DIRT_BACKGROUND)
	else:
		terrain.set_cell(_position, 1, ROCK_BACKGROUND)

@onready var selector = get_node("../Cursor")

# updating cursor, managing menu, clicks, consuming items and placing items
func _process(delta):
	update_cursor()
	if menu_open: return
	
	# handging right click
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		manage_mine_process(delta)
	else:
		reset_mine()
	
	if Input.is_action_just_pressed("ui_undo") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		
		var current_slot_data = hotbar.dataslots[hotbar.selected_slot]
		
		if current_slot_data["item"] != null:
			var item_id = current_slot_data["item"]
			
			if [ "carrotbar", "goldencarrotbar", "health_potion", "big_health_potion" ].has(item_id):
				consume_item(current_slot_data)
				lifebar.update_ui()
			else:
				if Engine.get_frames_drawn() % 10 == 0:
					place()

@onready var lifebar = get_node("../CanvasLayer/HUD/LifeContainer")

# this consume health items in exchange for life
func consume_item(slot):
	print("Consuming: ", slot["item"])
	
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
	
	slot["amount"] -= 1
	if slot["amount"] <= 0:
		slot["item"] = null
		slot["atlas"] = null
	
	hotbar.update_hotbar_ui()

# here we manage the timeout
func manage_mine_process(delta):
	var mouse = get_global_mouse_position()
	var map = terrain.local_to_map(mouse)
	
	if map != mining_block:
		mining_time = 0.0
		mining_block = map
	
	if global_position.distance_to(mouse) <= mine_range:
		var tile_data = terrain.get_cell_tile_data(map)
		if tile_data:
			var multiplicator = 1.0
			var item_id = hotbar.dataslots[hotbar.selected_slot]["item"]
			
			# any pickaxe multiplicates x2
			if ["woodenpickaxe", "stonepickaxe", "ironpickaxe"].has(item_id):
				multiplicator = 2.0
			
			mining_time += delta * multiplicator
			
			selector.rotation = randf_range(-0.2, 0.2)
			
			var take_time = tile_data.get_custom_data("break_time")
			
			if mining_time >= take_time:
				mine() 
				mining_time = 0.0 
	else:
		reset_mine()

# this resets the mine cooldown
func reset_mine():
	mining_time = 0.0
	mining_block = Vector2i(-1, -1)
	selector.rotation = 0

@onready var hotbar = get_tree().get_first_node_in_group("Hotbar")

# this updates the cursor
func update_cursor():
	var mouse = get_global_mouse_position()
	selector.global_position = mouse
	
	var preview_sprite = selector.get_node_or_null("Preview")
	if preview_sprite and hotbar:
		var slot = hotbar.dataslots[hotbar.selected_slot]
		
		if slot["atlas"] != null:
			preview_sprite.texture = slot["atlas"].atlas
			preview_sprite.region_enabled = true
			preview_sprite.region_rect = slot["atlas"].region
			preview_sprite.scale = Vector2(0.5, 0.5)
			preview_sprite.modulate = Color(1, 1, 1, 0.5)
			preview_sprite.show()
		else:
			preview_sprite.hide()
	
	# cursor color
	if global_position.distance_to(mouse) > mine_range:
		selector.modulate = Color(1, 0, 0, 0.7)
	else:
		selector.modulate = Color(1, 1, 1, 0.9)

# this drops items on the floor form the hotbar or tilesheets
func drop(map, atlas_coords, source_id, meta_type = null):
	var new_item = item_escene.instantiate()
	
	get_parent().add_child(new_item)
	
	new_item.global_position = terrain.map_to_local(map)
	
	var tile_data = terrain.get_cell_tile_data(map)
	var type = ""
	if meta_type:
		type = meta_type
	elif tile_data:
		type = tile_data.get_custom_data("object_type")
	
	print("item dropped type: ", type)
	new_item.setting(atlas_coords, source_id, type)
	
	var destination = new_item.global_position + Vector2(randf_range(-20, 20), 10)
	var tween = create_tween().set_parallel(true)
	
	# Salto en arco
	tween.tween_property(new_item, "global_position:x", destination.x, 0.5)
	tween.tween_property(new_item, "global_position:y", destination.y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# this function places items from the hotbar to the tileset
func place():
	var mouse = get_global_mouse_position()
	
	if global_position.distance_to(mouse) > mine_range:
		return
		
	var map = terrain.local_to_map(mouse)
	var actual = terrain.get_cell_tile_data(map)

	if actual:
		var type = actual.get_custom_data("object_type")
		if type == "dirt_bkg" or type == "rock_bkg":
			pass
		else:
			return
	
	
	# requesting item from the hotbar
	if hotbar:
		var slot = hotbar.dataslots[hotbar.selected_slot]
		if slot["atlas"] != null and slot["amount"] > 0:
			var atlas_coords = Vector2i(slot["atlas"].region.position / 16.0)
			
			if slot["item"] == "chest" || slot["item"] == "furnace":
				spawn_chest_object(map, slot["item"])
			else:
				terrain.set_cell(map, 1, atlas_coords)
			
			slot["amount"] -= 1
			
			if slot["amount"] <= 0:
				slot["atlas"] = null
			
			hotbar.update_hotbar_ui()

# droping on floor from hotbar
func drop_from_hotbar():
	if not hotbar: return
	
	var slot = hotbar.dataslots[hotbar.selected_slot]
	
	if slot["atlas"] != null and slot["amount"] > 0:
		var _drop = item_escene.instantiate()
		get_parent().add_child(_drop)
		
		_drop.global_position = global_position + Vector2(10 * (3 if velocity.x >= 0 else -3), -5)
		
		var atlas_coords = Vector2i(slot["atlas"].region.position / 16.0)
		_drop.setting(atlas_coords, 0, slot["item"])
		
		var direction = 20 if velocity.x >= 0 else -20
		var destination = _drop.global_position + Vector2(direction, 5)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(_drop, "global_position:x", destination.x, 0.4)
		tween.tween_property(_drop, "global_position:y", destination.y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		slot["amount"] -= 1
		if slot["amount"] <= 0:
			slot["atlas"] = null
		
		hotbar.update_hotbar_ui()

@onready var life_container = get_node("../CanvasLayer/HUD/LifeContainer")

func take_damage(amount):
	life_container.take_damage(amount)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if life_container.life <= 0:
		die()

# scene gets reset
func die():
	get_tree().reload_current_scene()

@onready var chest_scene = preload("res://Chest.tscn")
@onready var furnace_scene = preload("res://Furnace.tscn")

# this spawns furnaces or chests
func spawn_chest_object(map_pos, type):
	var new_chest = chest_scene.instantiate() if type == "chest" else furnace_scene.instantiate()
	new_chest.global_position = terrain.map_to_local(map_pos)
	get_parent().add_child(new_chest)
