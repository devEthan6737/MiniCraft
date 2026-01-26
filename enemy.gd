extends CharacterBody2D

var SPEED = 50.0 
var vida = 100
var JUMP_VELOCITY = -300.0
var damage = 1
var can_attack = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var empuje_actual = Vector2.ZERO
var friccion_empuje = 800.0

@onready var attack_cooldown = 1.0
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var detector_pared = $RayCast2D # Referencia al nuevo nodo

func _physics_process(delta):
	# 1. Aplicar gravedad siempre
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# 2. LÓGICA DE EMPUJE (Knockback)
	# Si el empuje es mayor a 10, el zombie pierde el control y sale volando
	if empuje_actual.length() > 10:
		velocity.x = empuje_actual.x
		# La fricción va frenando el empuje poco a poco
		empuje_actual = empuje_actual.move_toward(Vector2.ZERO, friccion_empuje * delta)
	
	# 3. LÓGICA DE MOVIMIENTO (IA)
	# Solo se ejecuta si NO está siendo empujado con fuerza
	elif player:
		var diff_x = player.global_position.x - global_position.x
		var direccion_x = sign(diff_x)
		var margen_parada = 40.0
		
		if abs(diff_x) > margen_parada:
			velocity.x = direccion_x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		if direccion_x != 0:
			sprite.flip_h = direccion_x < 0
		
		# Salto por pared o por posición del jugador
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

	# 4. Mover al personaje
	move_and_slide()
	
	actualizar_animaciones()
	
	if player and can_attack:
		revisar_contacto_jugador()

func recibir_daño(cantidad, vector_empuje = Vector2.ZERO):
	vida -= cantidad
	
	# Aplicamos el empuje
	empuje_actual = vector_empuje
	# Un pequeño salto extra hacia arriba hace que el empuje quede más "profesional"
	if is_on_floor():
		velocity.y = -100 
	
	# Efecto visual
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if vida <= 0:
		morir()

func morir():
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
func spawn_dropped_item(pos_global, atlas_coords, _source_id, item_name):
	var new_item = scene.instantiate()
	get_parent().add_child(new_item)
	
	new_item.global_position = pos_global
	
	# Usamos la función configurar que ya teníamos
	# El tercer parámetro es el nombre que usará el crafteo ("health_potion")
	new_item.configurar(atlas_coords, 1, item_name)
	
	# Opcional: Un pequeño salto físico para que se vea que "cae" del enemigo
	var tween = create_tween()
	var jump = pos_global + Vector2(randf_range(-20, 20), -30)
	var floor = jump + Vector2(0, 30)
	
	tween.tween_property(new_item, "global_position", jump, 0.2).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(new_item, "global_position", floor, 0.4).set_ease(Tween.EASE_OUT)

func revisar_contacto_jugador():
	# Obtenemos los cuerpos que están dentro del Area2D del enemigo
	var cuerpos = $AreaAtaque.get_overlapping_bodies()
	
	for cuerpo in cuerpos:
		if cuerpo.is_in_group("Player"):
			if (anim.current_animation == "idle"):
				anim.play("transition")
				anim.queue("attack")
			else:
				anim.play("attack")
			atacar(cuerpo)
			break

func atacar(objetivo):
	can_attack = false
	
	# 1. Aplicamos el daño al jugador
	if objetivo.has_method("recibir_daño"):
		objetivo.recibir_daño(damage)
	
	# 2. SEGURIDAD: Si el jugador ha muerto y la escena se está recargando, 
	# el enemigo ya no estará en el árbol. Salimos de la función para evitar el crash.
	if not is_inside_tree():
		return

	# 3. Esperamos el cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	
	# 4. Volvemos a comprobar después del tiempo por si el nivel cambió mientras esperábamos
	if is_inside_tree():
		can_attack = true

func actualizar_animaciones():
	if anim.current_animation == "attack" or anim.current_animation == "transition":
		return
	
	if not is_on_floor():
		if anim.current_animation != "jump":
			# Si venimos de estar quietos, pasamos por transición
			lanzar_animacion_con_logica("jump")
	else:
		if abs(velocity.x) > 1:
			if anim.current_animation != "walk":
				lanzar_animacion_con_logica("walk")
		else:
			if anim.current_animation != "idle":
				lanzar_animacion_con_logica("idle")

func lanzar_animacion_con_logica(nombre_nueva_anim):
	if anim.current_animation == "idle" and nombre_nueva_anim != "idle":
		anim.play("transition")
		anim.queue(nombre_nueva_anim)
	elif ["attack", "jump", "walk"].has(anim.current_animation) and nombre_nueva_anim == "idle":
		anim.play("transition")
		anim.queue("idle")
	else:
		anim.play(nombre_nueva_anim)
