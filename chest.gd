extends Area2D

@onready var prompt = $KeyPrompt

# this will connect with the body when is ready
func _ready():
	prompt.visible = false
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

# when we got the body inside the chest
func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.near_chest = self
		prompt.visible = true

# when the body exists the chets
func _on_body_exited(body):
	if body.is_in_group("Player"):
		body.near_chest = null
		prompt.visible = false

# pressing E
func interact():
	print("CHEST ACTION")
	var ui = get_tree().get_first_node_in_group("ChestUI")
	if ui:
		ui.open_chest(self)
