extends HBoxContainer

var fullheart = preload("res://FullHeart.tres")
var midheart = preload("res://SlicedHeart.tres")
var maxlife = 20
var life = 20

# on ready we update the UI
func _ready():
	for c in get_children():
		c.pivot_offset = c.size / 2
	update_ui()

# updating UI
# this bar of life detects middle hearts
# even numbers are full hearts
# odd numbers are mid hearts
func update_ui():
	var hearts = get_children()
	for i in range(hearts.size()):
		var heart_slot = hearts[i]
		var full_heart_value = (i + 1) * 2
		
		if life >= full_heart_value:
			heart_slot.visible = true
			heart_slot.texture = fullheart
			heart_slot.modulate = Color(1, 1, 1)
		elif life == full_heart_value - 1:
			heart_slot.visible = true
			heart_slot.texture = midheart
			heart_slot.modulate = Color(1, 1, 1)
		else:
			heart_slot.visible = false

# take damage
func take_damage(cantidad):
	var last_life = life
	life = clamp(life - cantidad, 0, maxlife)
	update_ui()
	
	if life < last_life:
		if int(life) % 2 == 0:
			shake_bar()
		else:
			var heart_index = int(ceil(life / 2.0)) - 1
			shake_heart(heart_index)

# this function is for UI
# this shakes the mid heart a little
func shake_heart(indice):
	var hearts = get_children()
	if indice >= 0 and indice < hearts.size():
		var heart = hearts[indice]
		var tween = create_tween()
		
		for i in range(3):
			tween.tween_property(heart, "position:x", 2, 0.05).as_relative()
			tween.tween_property(heart, "position:x", -2, 0.05).as_relative()
		
		tween.tween_callback(func(): heart.position.x)

# this function is for UI
# this shakes the bar a little
func shake_bar():
	var tween = create_tween()
	var pos_y_original = position.y
	
	for i in range(4):
		tween.tween_property(self, "position:y", pos_y_original + 1, 0.04)
		tween.tween_property(self, "position:y", pos_y_original - 1, 0.04)
	
	tween.tween_property(self, "position:y", pos_y_original, 0.04)
