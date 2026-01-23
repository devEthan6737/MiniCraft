extends CharacterBody2D

var SPEED = 50.0 # Más lento que el jugador para que puedas escapar
var vida = 100
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D

func _ready():
	anim.play("walk")

func _physics_process(_delta):
	if player:
		# Calculamos la dirección hacia el jugador
		var direccion = (player.global_position - global_position).normalized()
		velocity = direccion * SPEED
		
		# Girar el sprite
		sprite.flip_h = velocity.x < 0
		
		move_and_slide()

# Función para que el enemigo reciba daño
func recibir_daño(cantidad):
	vida -= cantidad
	# Efecto visual rápido (parpadeo rojo)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	print(vida)
	if vida <= 0:
		morir()

func morir():
	# Antes de borrarlo, podemos soltar algún ítem o partículas
	queue_free() # Esto avisará al World (tree_exited) para el ciclo día/noche
