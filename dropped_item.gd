extends Node2D

var tiempo = 0.0
var item_type = ""

func _ready() -> void:
	z_index = 10
	# Usamos get_node_or_null para evitar que el juego se cierre si el nodo no está
	var area = get_node_or_null("Item")
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		print("ERROR: No se encontró el nodo Area2D en ", name)

func _process(delta):
	tiempo += delta * 3.0
	# Animación de levitación
	$Sprite2D.position.y = -5.0 + (sin(tiempo) * 2.0)
	$Sprite2D.rotation += delta

func configurar(textura_atlas: Vector2i, source_id: int, nombre_item: String):
	item_type = nombre_item
	$Sprite2D.texture = load("res://sprites001.png")
	$Sprite2D.region_enabled = true
	$Sprite2D.scale = Vector2(0.5, 0.5)
	$Sprite2D.region_rect = Rect2(textura_atlas.x * 16, textura_atlas.y * 16, 16, 16)

@onready var terrain = get_node("../Terrain")
func _on_body_entered(body):
	if body.is_in_group("Player"):
		var hotbar = get_tree().get_first_node_in_group("Hotbar")
		if hotbar:
			var textura_recortada = AtlasTexture.new()
			textura_recortada.atlas = $Sprite2D.texture
			textura_recortada.region = $Sprite2D.region_rect
			
			textura_recortada.set_meta("object_type", item_type)
			
			var exito = hotbar.recolect(textura_recortada, item_type)
			if exito:
				queue_free()
