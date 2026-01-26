extends StaticBody2D

var inventory = [] # Aquí se guardarán los items de ESTE cofre
var player_near = false

func _ready():
	$KeyPrompt.visible = false
	# Inicializamos el inventario del cofre con 9 slots vacíos
	for i in range(9):
		inventory.append({"item": null, "amount": 0, "atlas": null})

func _on_detector_body_entered(body):
	if body.is_in_group("Player"):
		player_near = true
		$KeyPrompt.visible = true
		body.near_chest = self # Le decimos al player qué cofre tiene cerca

func _on_detector_body_exited(body):
	if body.is_in_group("Player"):
		player_near = false
		$KeyPrompt.visible = false
		body.near_chest = null

func interact():
	print("Abriendo inventario del cofre...")
	# Aquí llamarás a la UI del inventario del cofre
