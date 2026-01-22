extends HBoxContainer

var tex_lleno = preload("res://FullHeart.tres")
var tex_medio = preload("res://SlicedHeart.tres")

var vida_max = 20 
var vida_actual = 20

func _ready():
	for c in get_children():
		# Importante para que el flash de color se vea bien
		c.pivot_offset = c.size / 2
	actualizar_interfaz_vida()

func actualizar_interfaz_vida():
	var corazones = get_children()
	for i in range(corazones.size()):
		var slot_corazon = corazones[i]
		var valor_corazon_lleno = (i + 1) * 2
		
		if vida_actual >= valor_corazon_lleno:
			slot_corazon.visible = true
			slot_corazon.texture = tex_lleno
			slot_corazon.modulate = Color(1, 1, 1) # Color normal
		elif vida_actual == valor_corazon_lleno - 1:
			slot_corazon.visible = true
			slot_corazon.texture = tex_medio
			slot_corazon.modulate = Color(1, 1, 1) # Color normal
		else:
			slot_corazon.visible = false

func recibir_danio(cantidad):
	var vida_anterior = vida_actual
	vida_actual = clamp(vida_actual - cantidad, 0, vida_max)
	actualizar_interfaz_vida()
	
	if vida_actual < vida_anterior:
		# Si la vida resultante es PAR, significa que un corazón se ha vaciado del todo
		if int(vida_actual) % 2 == 0:
			temblar_toda_la_barra()
		else:
			# Si es IMPAR, un corazón se ha quedado a la mitad. 
			# Calculamos el índice correcto (0 a 9)
			var indice_corazon = int(ceil(vida_actual / 2.0)) - 1
			temblar_corazon(indice_corazon)

func temblar_corazon(indice):
	var corazones = get_children()
	if indice >= 0 and indice < corazones.size():
		var c = corazones[indice]
		var tween = create_tween()

		# Temblor reducido (2px) para que no se descoloque del contenedor
		for i in range(3):
			tween.tween_property(c, "position:x", 2, 0.05).as_relative()
			tween.tween_property(c, "position:x", -2, 0.05).as_relative()
		
		# Al terminar, devolvemos el color y aseguramos posición 0
		tween.tween_callback(func(): c.position.x)

func temblar_toda_la_barra():
	var tween = create_tween()
	var pos_y_original = position.y
	
	# Temblor de barra sutil
	for i in range(4):
		tween.tween_property(self, "position:y", pos_y_original + 1, 0.04)
		tween.tween_property(self, "position:y", pos_y_original - 1, 0.04)
	
	tween.tween_property(self, "position:y", pos_y_original, 0.04)
