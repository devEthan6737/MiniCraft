extends CharacterBody2D

var SPEED = 50.0 
var vida = 100
var JUMP_VELOCITY = -300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") # Cogemos la gravedad del proyecto

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

func _ready():
	anim.play("walk")

func _physics_process(delta):
	# 1. APLICAR GRAVEDAD (Para que no floten)
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0 # Resetear al tocar suelo

	if player:
		var diff_x = player.global_position.x - global_position.x
		var direccion_x = sign(diff_x)
		
		# Movimiento horizontal
		velocity.x = direccion_x * SPEED
		sprite.flip_h = direccion_x < 0

		# --- LÓGICA DE SALTO ---
		# Si está tocando una pared y está en el suelo, ¡que salte!
		if is_on_wall() and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		# Salto extra: Si el jugador está más arriba que él y hay poca distancia X
		if is_on_floor() and abs(diff_x) < 50 and player.global_position.y < global_position.y - 40:
			velocity.y = JUMP_VELOCITY
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 3. MOVER Y DESLIZAR
	move_and_slide()
	# print("e: " + str(position.x) + ":" + str(position.y))

func recibir_daño(cantidad):
	vida -= cantidad
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if vida <= 0:
		morir()

func morir():
	queue_free()
