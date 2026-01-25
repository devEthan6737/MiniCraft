extends CharacterBody2D

var SPEED = 50.0 
var vida = 100
var JUMP_VELOCITY = -300.0
var damage = 1
var can_attack = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var attack_cooldown = 1.0
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var detector_pared = $RayCast2D # Referencia al nuevo nodo

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if player:
		# Calculamos la distancia real entre centros
		var diff_x = player.global_position.x - global_position.x
		var direccion_x = sign(diff_x)
		
		# MARGEN SIMÉTRICO: Prueba con 35 para que se note el espacio
		var margen_parada = 40.0
		
		# Control de movimiento con zona muerta simétrica
		if abs(diff_x) > margen_parada:
			velocity.x = direccion_x * SPEED
		else:
			# Si entramos en el margen, frenamos gradualmente para evitar rebotes
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		# Girar el sprite
		if direccion_x != 0:
			sprite.flip_h = direccion_x < 0
		
		# AJUSTE DEL RAYCAST: Lo reseteamos al centro y lo lanzamos según dirección
		detector_pared.position.x = 0 
		detector_pared.target_position.x = direccion_x * 25

		# SALTO: Solo si es terreno
		if is_on_floor() and detector_pared.is_colliding():
			var col = detector_pared.get_collider()
			if col is TileMap or col is TileMapLayer:
				velocity.y = JUMP_VELOCITY
				anim.play("jump")
		
		# SALTO VERTICAL: Corregido (Si está entre 10 y 50 px de distancia y tú arriba)
		var dist = abs(diff_x)
		if is_on_floor() and dist < 50 and dist > 10 and player.global_position.y < global_position.y - 40:
			velocity.y = JUMP_VELOCITY
			anim.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		anim.play("walk")
	
	move_and_slide()
	
	actualizar_animaciones()
	
	if player and can_attack:
		revisar_contacto_jugador()

func recibir_daño(cantidad):
	vida -= cantidad
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if vida <= 0:
		morir()

func morir():
	queue_free()

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
	
	# Aplicamos el daño al jugador
	if objetivo.has_method("recibir_daño"):
		objetivo.recibir_daño(damage)
	
	# Esperamos el cooldown antes de poder atacar de nuevo
	await get_tree().create_timer(attack_cooldown).timeout
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
