# this took a long

extends Node2D

@onready var terrain = $Terrain
@onready var loading_screen = $ChargeLayer
@onready var player = $Player
@onready var timer = $DayNightTimer/Timer
@onready var sky_color = $SkyBackground/ColorRect
@onready var timer_label = $CanvasLayer/HUD/Cooldown
@onready var day_label = $CanvasLayer/HUD/Day
@onready var enemies_label = $CanvasLayer/HUD/Enemies

# blocks vectors
const GRASS = Vector2i(0, 0)
const GRASS_V1 = Vector2i(1, 0)
const GRASS_V2 = Vector2i(2, 0)
const GRASS_V3 = Vector2i(7, 0)
const GRASS_V4 = Vector2i(8, 0)
const DIRT = Vector2i(3, 0)
const ROCK = Vector2i(0, 1)
const BEDROCK = Vector2i(2, 2)

const COAL = Vector2i(1, 1)
const IRON = Vector2i(2, 1)
const DIAMOND = Vector2i(3, 1)
const GOLD = Vector2i(0, 2)

const RAMP_IZQ = Vector2i(4, 0)
const RAMP_IZQ_H = Vector2i(5, 0)
const RAMP_IZQ_F = Vector2i(6, 0)

const RAMP_DER = Vector2i(9, 0)
const RAMP_DER_H = Vector2i(10, 0)
const RAMP_DER_F = Vector2i(11, 0)

const DIRT_DER = Vector2i(14, 0)
const DIRT_IZQ = Vector2i(13, 0)

const TREE = Vector2i(4, 1)
const STUMP = Vector2i(5, 5)

const MAP_SIZE = 500
const DEEP_SIZE = 100
var LEFT_LIMIT = -MAP_SIZE / 2.0
var RIGHT_LIMIT = MAP_SIZE / 2.0
const MARGIN_GENERATION = 20
const BLOCKS_EACH_GENERATION = 100

var enemies_alive = 0
var is_night = false
var day = 1
var spawnable_enemies_amount = 3

# enabling physics, player movement & generating world
func _ready():
	loading_screen.show()
	
	player.set_physics_process(false)
	player.process_mode = PROCESS_MODE_DISABLED
	player.visible = false
	
	await get_tree().create_timer(0.1).timeout

	generate_world()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # hidding mouse
	
	timer.timeout.connect(_on_timer_timeout)
	sky_color.color = Color("87ceeb") # sky ;)

# here i manage the timer and i convert the player position in coords
func _process(_delta):
	if !timer.is_stopped():
		timer_label.text = format_time(timer.time_left)
		day_label.text = "Day " + str(day)
	
	if player:
		var player_position = terrain.local_to_map(player.global_position)
		
		if player_position.x > RIGHT_LIMIT - MARGIN_GENERATION:
			generate_stretch(RIGHT_LIMIT, RIGHT_LIMIT + BLOCKS_EACH_GENERATION)
			RIGHT_LIMIT += BLOCKS_EACH_GENERATION
			
		if player_position.x < LEFT_LIMIT + MARGIN_GENERATION:
			generate_stretch(LEFT_LIMIT - BLOCKS_EACH_GENERATION, LEFT_LIMIT)
			LEFT_LIMIT -= BLOCKS_EACH_GENERATION
	
	if is_night and enemies_alive <= 0:
		quick_dawn()

var noise = FastNoiseLite.new()

# this function uses an algorythm whose author I forgot...
func generate_world():
	noise.seed = randi()
	noise.frequency = 0.05
	
	var map = {}

	for x in range(-MAP_SIZE / 2.0, MAP_SIZE / 2.0):
		var progress = float(x + MAP_SIZE / 2.0) / MAP_SIZE * 100 # progress bar is real, some devs are lazy
		$ChargeLayer/ProgressBar.value = progress
		
		if x % 5 == 0:
			await get_tree().process_frame

		var height = int(noise.get_noise_1d(x) * 5)
		map[x] = height
		
		for y in range(height - 10, height):
			terrain.set_cell(Vector2i(x, y), -1)
			
		for y in range(height, height + 6):
			terrain.set_cell(Vector2i(x, y), 1, DIRT)
		for y in range(height + 6, DEEP_SIZE):
			terrain.set_cell(Vector2i(x, y), 1, ROCK)
		terrain.set_cell(Vector2i(x, DEEP_SIZE), 1, BEDROCK)

	for x in range(-MAP_SIZE / 2.0, (MAP_SIZE / 2.0) - 1):
		var alt_act = map[x]
		var alt_sig = map[x + 1]
		
		if alt_sig < alt_act:
			place_ramp(Vector2i(x, alt_act - 1), "DER")
			terrain.set_cell(Vector2i(x, alt_act), 1, DIRT_IZQ)
			
		elif alt_sig > alt_act:
			place_ramp(Vector2i(x, alt_sig - 1), "IZQ")
			terrain.set_cell(Vector2i(x, alt_act + 1), 1, DIRT_DER)
			
		else:
			if terrain.get_cell_atlas_coords(Vector2i(x, alt_act)) == Vector2i(-1, -1) or \
			   terrain.get_cell_atlas_coords(Vector2i(x, alt_act)) == DIRT:
				terrain.set_cell(Vector2i(x, alt_act), 1, GRASS)
			
			if randf() < 0.08:
				set_tree(Vector2i(x, alt_act - 1))
			
			elif randf() < 0.4:
				var rand = randf();
				var type
				
				if (rand < 0.25):
					type = GRASS_V1
				elif (rand < 0.50):
					type = GRASS_V2
				elif (rand < 0.75):
					type = GRASS_V3
				else:
					type = GRASS_V4
				
				terrain.set_cell(Vector2i(x, alt_act - 1), 1, type)
	
	create_veins(-MAP_SIZE / 2.0, MAP_SIZE / 2.0)
	
	var spawn_x = 0
	var spawn_y = map[spawn_x] - 2
	
	player.global_position = terrain.map_to_local(Vector2i(spawn_x, spawn_y))
	
	# enabling player
	player.set_physics_process(true)
	player.process_mode = PROCESS_MODE_INHERIT
	player.visible = true
	end_load()

# when the player is close of map limits, this function generates more map
func generate_stretch(from: int, to: int):
	var map = {}

	for x in range(from, to):
		var height = int(noise.get_noise_1d(x) * 5)
		map[x] = height
		
		# clear air
		for y in range(height - 10, height): terrain.set_cell(Vector2i(x, y), -1)
		for y in range(height, height + 6): terrain.set_cell(Vector2i(x, y), 1, DIRT)
		for y in range(height + 6, DEEP_SIZE): terrain.set_cell(Vector2i(x, y), 1, ROCK)
		terrain.set_cell(Vector2i(x, DEEP_SIZE), 1, BEDROCK)
	
	for x in range(from, to):
		var alt_act = map[x]
		var alt_sig = int(noise.get_noise_1d(x + 1) * 5)
		
		if alt_sig < alt_act:
			place_ramp(Vector2i(x, alt_act - 1), "DER")
			terrain.set_cell(Vector2i(x, alt_act), 1, DIRT_IZQ)
		elif alt_sig > alt_act:
			place_ramp(Vector2i(x, alt_sig - 1), "IZQ")
			terrain.set_cell(Vector2i(x, alt_act + 1), 1, DIRT_DER)
		else:
			var coords = terrain.get_cell_atlas_coords(Vector2i(x, alt_act))
			if coords == Vector2i(-1, -1) or coords == DIRT:
				terrain.set_cell(Vector2i(x, alt_act), 1, GRASS)
			
			if randf() < 0.08:
				set_tree(Vector2i(x, alt_act - 1))
			elif randf() < 0.4:
				var rand = randf()
				var type
				if rand < 0.25: type = GRASS_V1
				elif rand < 0.50: type = GRASS_V2
				elif rand < 0.75: type = GRASS_V3
				else: type = GRASS_V4
				terrain.set_cell(Vector2i(x, alt_act - 1), 1, type)
	
	create_veins(from, to)

# here i put ramps of grass
func place_ramp(position, side):
	var r = randf()
	if side == "IZQ":
		if r < 0.6: terrain.set_cell(position, 1, RAMP_IZQ)
		elif r < 0.85: terrain.set_cell(position, 1, RAMP_IZQ_H)
		else: terrain.set_cell(position, 1, RAMP_IZQ_F)
	else:
		if r < 0.6: terrain.set_cell(position, 1, RAMP_DER)
		elif r < 0.85: terrain.set_cell(position, 1, RAMP_DER_H)
		else: terrain.set_cell(position, 1, RAMP_DER_F)

# this function generates veins of minerals
func create_veins(from: int, to: int):
	var settings = [
		[COAL, 1, 30, 0.02, 4, 9],
		[IRON, 20, 70, 0.015, 3, 5],
		[DIAMOND, 60, 100, 0.005, 2, 4],
		[GOLD, 80, 100, 0.008, 1, 2]
	]

	for config in settings:
		var type = config[0]
		var p_min = config[1]
		var p_max = config[2]
		var prob = config[3]
		var g_min = config[4]
		var g_max = config[5]

		for x in range(from, to):
			for y in range(p_min, p_max):
				if terrain.get_cell_atlas_coords(Vector2i(x, y)) == ROCK:
					if randf() < prob:
						var size = randi_range(g_min, g_max)
						for i in range(size):
							var offset = Vector2i(randi_range(-1, 1), randi_range(-1, 1))
							var position = Vector2i(x, y) + offset
							if terrain.get_cell_atlas_coords(position) == ROCK:
								terrain.set_cell(position, 1, type)

# this is to plant trees
func set_tree(position: Vector2i):
	var r = randf()
	
	if r < 0.15: 
		terrain.set_cell(position, 1, STUMP)
	else:
		terrain.set_cell(position + Vector2i(0, -1), 1, TREE)

# load screen fade out
func end_load():
	var tween = create_tween()
	tween.tween_property(loading_screen.get_node("ColorRect"), "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): loading_screen.hide())

@onready var hotbar = $CanvasLayer/HUD/Hotbar
@onready var contenedor_vida = $CanvasLayer/HUD/LifeContainer

# when cooldown ends
func _on_timer_timeout():
	get_dark()

# get dark and spawn enemies
func get_dark():
	is_night = true
	enemies_alive = spawnable_enemies_amount
	var tween = create_tween()
	tween.tween_property(sky_color, "color", Color("0a0a2a"), 2.0)
	enemies_label.text = str(enemies_alive) + " Enemies remaining"
	spawn_enemies(spawnable_enemies_amount)

# enemies spawner algorythm
func spawn_enemies(amount):
	for i in range(amount):
		await get_tree().create_timer(1).timeout
		
		var new_enemy = preload("res://Enemy.tscn").instantiate()
		var spawn_x_pixels = 0.0
		var success_intent = false
		
		for intent in range(5):
			var side = 1 if randf() > 0.5 else -1
			var offset = (randf_range(250, 400) + (i * 20)) * side
			var posible_x = player.global_position.x + offset
			var min_x_px = LEFT_LIMIT * 16.0
			var max_x_px = RIGHT_LIMIT * 16.0
			
			if posible_x > min_x_px and posible_x < max_x_px:
				spawn_x_pixels = posible_x
				success_intent = true
				break
		
		if not success_intent:
			spawn_x_pixels = player.global_position.x + (i * 30) # emergency separation
		
		var pos_map_x = terrain.local_to_map(Vector2(spawn_x_pixels, 0)).x
		var floor_y = find_floor(pos_map_x)
		
		new_enemy.global_position = terrain.map_to_local(Vector2i(pos_map_x, floor_y - 2))
		
		if not new_enemy.tree_exited.is_connected(_on_enemy_death):
			new_enemy.tree_exited.connect(_on_enemy_death)
			
		add_child(new_enemy)
		print("Enemy spawned: " + str(pos_map_x) + ":" + str(floor_y))

# auxiliar function to find new tiles
func find_floor(x_map: int) -> int:
	for y in range(-50, DEEP_SIZE):
		if terrain.get_cell_source_id(Vector2i(x_map, y)) != -1:
			return y
	return 0 # for safe

# when a enemy dies
func _on_enemy_death():
	enemies_alive -= 1
	enemies_label.text = str(enemies_alive) + " Enemies remaining"

# on dawn, when the night ends
func quick_dawn():
	is_night = false
	enemies_label.text = ""
	day += 1
	
	if day >= 11:
		player.die()

	spawnable_enemies_amount = spawnable_enemies_amount + day
	var tween = create_tween()
	tween.tween_property(sky_color, "color", Color("87ceeb"), 1.0)
	
	timer.start()
	hotbar.unlock_by_day(day)

func format_time(total_seconds: float) -> String:
	var minutes : int = int(total_seconds) / 60
	var seconds : int = int(total_seconds) % 60
	
	return "%02d:%02d" % [minutes, seconds]
