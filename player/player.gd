extends CharacterBody3D


@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

const SPEED = 0.5
const JUMP_VELOCITY = 4.5

var joy_stick_x : float = 0.0  # -1 =-> 1
var joy_stick_y : float = 0.0  # -1 =-> 1

var camera: XRCamera3D = null

func set_camera(camera: XRCamera3D):
	print('Setting camera ', camera)
	self.camera = camera


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
	#var direction := (transform.basis * Vector3(joy_stick_x, 0, joy_stick_y)).normalized()
	var direction := _get_movement_direction()  # / camera
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	_set_animation()

	_look_at_camera()

	move_and_slide()


func _get_movement_direction() -> Vector3:
	# Récupérer la base de la caméra pour transformer le mouvement
	var camera_basis := camera.global_transform.basis

	# La direction avant/arrière de la caméra (projetée sur le sol)
	var forward := -camera_basis.z
	forward.y = 0  # On garde le mouvement au sol
	forward = forward.normalized()

	# La direction droite/gauche de la caméra
	var right := camera_basis.x
	right.y = 0  # On garde le mouvement au sol
	right = right.normalized()

	# Calculer le vecteur direction avec l'entrée du joystick
	var movement := (right * joy_stick_x + forward * joy_stick_y).normalized()
	return movement
	

func _set_animation():  # relative to the camera
	if camera:
		# Transformer le mouvement dans l'espace de la caméra
		var camera_basis := camera.global_transform.basis
		var local_velocity := camera_basis.inverse() * velocity
		
		# Déterminer la direction dominante du mouvement
		if local_velocity.length() > 0.01:
			if abs(local_velocity.z) > abs(local_velocity.x):  # Mouvement avant/arrière dominant
				if local_velocity.z < 0:
					animated_sprite_3d.play("up")  # Avance vers la caméra
				else:
					animated_sprite_3d.play("down")    # Recule (caméra derrière)
			else:  # Mouvement gauche/droite dominant
				if local_velocity.x < 0:
					animated_sprite_3d.play("left")
					animated_sprite_3d.flip_h = false
				else:
					# animated_sprite_3d.play("right")
					animated_sprite_3d.play("left")
					animated_sprite_3d.flip_h = true
					
		else:
			animated_sprite_3d.play("idle")  # Aucun mouvement


func _look_at_camera():
	if camera:
		# Obtenir la direction entre le sprite et la caméra
		var direction = (camera.global_transform.origin - animated_sprite_3d.global_transform.origin).normalized()
		
		# On garde uniquement la rotation horizontale (Y)
		direction.y = 0  # Ignore la hauteur pour éviter que le sprite se penche
		
		# Appliquer la rotation pour faire face à la caméra
		animated_sprite_3d.look_at(animated_sprite_3d.global_transform.origin + direction, Vector3.UP)


func _on_left_hand_input_vector_2_changed(name: String, value: Vector2) -> void:
	print('LEFT: moving joy ',name, ' vector: ', value)
	joy_stick_x = value[0]
	joy_stick_y = value[1]
	


func _on_right_hand_input_vector_2_changed(name: String, value: Vector2) -> void:
	print('RIGHT: moving joy ',name, ' vector: ', value)
