extends Node2D

var tiempo = 0.0
var item_type = ""

# on ready: i get the item and i put a conector
func _ready() -> void:
	z_index = 10
	var area = get_node_or_null("Item")
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		print("ERROR: No se encontró el nodo Area2D en ", name)

# just this updates the position and rotation
func _process(delta):
	tiempo += delta * 3.0
	$Sprite2D.position.y = -5.0 + (sin(tiempo) * 2.0)
	$Sprite2D.rotation += delta

# setting up the item
func setting(textura_atlas: Vector2i, source_id: int, item_name: String):
	item_type = item_name
	$Sprite2D.texture = load("res://sprites001.png")
	$Sprite2D.region_enabled = true
	$Sprite2D.scale = Vector2(0.5, 0.5)
	$Sprite2D.region_rect = Rect2(textura_atlas.x * 16, textura_atlas.y * 16, 16, 16)

@onready var terrain = get_node("../Terrain")

# when the player touches the item
func _on_body_entered(body):
	if body.is_in_group("Player"):
		var hotbar = get_tree().get_first_node_in_group("Hotbar")
		if hotbar:
			var atlas = AtlasTexture.new()
			atlas.atlas = $Sprite2D.texture
			atlas.region = $Sprite2D.region_rect
			
			# this is metadata
			atlas.set_meta("object_type", item_type)
			
			var success = hotbar.recolect(atlas, item_type)
			if success:
				queue_free()
