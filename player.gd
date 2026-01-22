extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -220.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W)) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if Input.is_key_pressed(KEY_S) and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
