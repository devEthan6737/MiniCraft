extends HBoxContainer

var tex_lleno = preload("res://FullHeart.tres")
var tex_medio = preload("res://SlicedHeart.tres")

var maxlife = 20
var life = 20

func _ready():
	for c in get_children():
		c.pivot_offset = c.size / 2
	update_ui()

func update_ui():
	var corazones = get_children()
	for i in range(corazones.size()):
		var slot_corazon = corazones[i]
		var valor_corazon_lleno = (i + 1) * 2
		
		if life >= valor_corazon_lleno:
			slot_corazon.visible = true
			slot_corazon.texture = tex_lleno
			slot_corazon.modulate = Color(1, 1, 1)
		elif life == valor_corazon_lleno - 1:
			slot_corazon.visible = true
			slot_corazon.texture = tex_medio
			slot_corazon.modulate = Color(1, 1, 1)
		else:
			slot_corazon.visible = false

func recibir_danio(cantidad):
	var vida_anterior = life
	life = clamp(life - cantidad, 0, maxlife)
	update_ui()
	
	if life < vida_anterior:
		if int(life) % 2 == 0:
			temblar_toda_la_barra()
		else:
			var indice_corazon = int(ceil(life / 2.0)) - 1
			temblar_corazon(indice_corazon)

func temblar_corazon(indice):
	var corazones = get_children()
	if indice >= 0 and indice < corazones.size():
		var c = corazones[indice]
		var tween = create_tween()

		for i in range(3):
			tween.tween_property(c, "position:x", 2, 0.05).as_relative()
			tween.tween_property(c, "position:x", -2, 0.05).as_relative()
		
		tween.tween_callback(func(): c.position.x)

func temblar_toda_la_barra():
	var tween = create_tween()
	var pos_y_original = position.y
	
	for i in range(4):
		tween.tween_property(self, "position:y", pos_y_original + 1, 0.04)
		tween.tween_property(self, "position:y", pos_y_original - 1, 0.04)
	
	tween.tween_property(self, "position:y", pos_y_original, 0.04)
