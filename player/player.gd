extends CharacterBody3D


@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

const SPEED = 0.5
const JUMP_VELOCITY = 4.5

var joy_stick_x : float = 0.0  # -1 =-> 1
var joy_stick_y : float = 0.0  # -1 =-> 1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var direction := (transform.basis * Vector3(joy_stick_x, 0, joy_stick_y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	_set_animation()

	move_and_slide()


func _set_animation():
	if velocity.z > 0.01: animated_sprite_3d.flip_h = false
	elif velocity.z < -0.01: animated_sprite_3d.flip_h = true
	
	if velocity:
		if abs(velocity.z) > abs(velocity.x):  # going more on the top/down
			if velocity.z > 0:
				animated_sprite_3d.play("down")
			else:
				animated_sprite_3d.play("up")
		else:
			animated_sprite_3d.play("left")
	else: 
		animated_sprite_3d.play("idle")

func _on_left_hand_button_pressed(name: String) -> void:
	print('LEFT BUTTON IS PRESSED ', name) # Replace with function body.


func _on_right_hand_button_pressed(name: String) -> void:
	print('RIGHT BUTTON IS PRESSED', name)


func _on_left_hand_input_vector_2_changed(name: String, value: Vector2) -> void:
	print('LEFT: moving joy ',name, ' vector: ', value)
	joy_stick_x = value[0]
	joy_stick_y = value[1]
	


func _on_right_hand_input_vector_2_changed(name: String, value: Vector2) -> void:
	print('RIGHT: moving joy ',name, ' vector: ', value)
