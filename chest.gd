extends Area2D

@onready var prompt = $KeyPrompt # O el nombre que tenga tu nodo de texto

func _ready():
	prompt.visible = false
	# Usamos 'self' porque el script ya está en el Area2D
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.near_chest = self
		prompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		body.near_chest = null
		prompt.visible = false

func interact():
	print("interactuando")
	var ui = get_tree().get_first_node_in_group("ChestUI")
	if ui:
		ui.open_chest(self)
