extends CharacterBody2D

# global vars
var SPEED = 50.0 
var life = 100
var JUMP_VELOCITY = -300.0
var damage = 1
var can_attack = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var push = Vector2.ZERO
var push_friction = 800.0

@onready var attack_cooldown = 1.0
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var detector_pared = $RayCast2D

# AI movility
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if push.length() > 10:
		velocity.x = push.x
		push = push.move_toward(Vector2.ZERO, push_friction * delta)
	
	elif player:
		var diff_x = player.global_position.x - global_position.x
		var direccion_x = sign(diff_x)
		var margin_stop = 40.0
		
		if abs(diff_x) > margin_stop:
			velocity.x = direccion_x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		if direccion_x != 0:
			sprite.flip_h = direccion_x < 0
		
		detector_pared.target_position.x = direccion_x * 25
		if is_on_floor():
			var dist = abs(diff_x)
			var col_pared = detector_pared.is_colliding()
			var jugador_arriba = player.global_position.y < global_position.y - 40
			
			if (col_pared and (detector_pared.get_collider() is TileMap or detector_pared.get_collider() is TileMapLayer)) or (dist < 50 and dist > 10 and jugador_arriba):
				velocity.y = JUMP_VELOCITY
				anim.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	update_animations()
	
	if player and can_attack:
		check_player_contact()

# this function modify the enemy's life
func take_damage(amount, push_vector = Vector2.ZERO):
	life -= amount
	push = push_vector

	if is_on_floor():
		velocity.y = -100 
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if life <= 0:
		die()

# this function deletes the enemy and drops items
func die():
	var rand = randf()
	var item_position
	var item = ""
	
	if rand > 0.95:
		item = "carrotbar"
		item_position = Vector2i(6, 5)
	elif rand > 0.80:
		item = "big_health_potion"
		item_position = Vector2i(6, 7)
	elif rand > 0.60:
		item = "health_potion"
		item_position = Vector2i(5, 7)
	
	if item_position:
		spawn_dropped_item(global_position, item_position, 1, item)
	queue_free()

@onready var scene = preload("res://DroppedItem.tscn")

# here i spawn new items
func spawn_dropped_item(pos_global, atlas_coords, _source_id, item_name):
	var new_item = scene.instantiate()
	get_parent().add_child(new_item)
	
	new_item.global_position = pos_global
	new_item.setting(atlas_coords, 1, item_name)
	
	var tween = create_tween()
	var jump = pos_global + Vector2(randf_range(-20, 20), -30)
	var floor = jump + Vector2(0, 30)
	
	tween.tween_property(new_item, "global_position", jump, 0.2).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(new_item, "global_position", floor, 0.4).set_ease(Tween.EASE_OUT)

# checks if the player is in contact with the enemy
func check_player_contact():
	var bodies = $AreaAtaque.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("Player"):
			if (anim.current_animation == "idle"):
				anim.play("transition")
				anim.queue("attack")
			else:
				anim.play("attack")
			attack(body)
			break

# this functions make possible the attack to the player
func attack(target):
	can_attack = false
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	if not is_inside_tree():
		return

	await get_tree().create_timer(attack_cooldown).timeout
	
	if is_inside_tree():
		can_attack = true

# this updates animations
func update_animations():
	if anim.current_animation == "attack" or anim.current_animation == "transition":
		return
	
	if not is_on_floor():
		if anim.current_animation != "jump":
			launch_logic_animation("jump")
	else:
		if abs(velocity.x) > 1:
			if anim.current_animation != "walk":
				launch_logic_animation("walk")
		else:
			if anim.current_animation != "idle":
				launch_logic_animation("idle")

# the same as the last but here y just select transitions between animations
func launch_logic_animation(animation):
	if anim.current_animation == "idle" and animation != "idle":
		anim.play("transition")
		anim.queue(animation)
	elif ["attack", "jump", "walk"].has(anim.current_animation) and animation == "idle":
		anim.play("transition")
		anim.queue("idle")
	else:
		anim.play(animation)
