extends Node3D

var xr_interface: XRInterface

@onready var environment : Environment = $WorldEnvironment.environment

@onready var right_hand: XRController3D = $XROrigin3D/RightHand
@onready var left_hand: XRController3D = $XROrigin3D/LeftHand
@onready var worlds: Node3D = $"worlds"	

var grabbing := false
var last_yaw: float  # Stocke l'angle Y précédent
var last_left_hand_transform: Transform3D

# Are grip button pressed
var right_grip = false
var left_grip = false

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true

		# Set our default value for our AR toggle
		$ARToggle.on = xr_interface.environment_blend_mode != XRInterface.XR_ENV_BLEND_MODE_OPAQUE
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		
	$"worlds/world-1/Player".set_camera($XROrigin3D/XRCamera3D)
	
	# Initialiser l'angle Y
	last_yaw = get_yaw_from_transform(left_hand.global_transform)
	# Initialiser la position de la main gauche
	last_left_hand_transform = left_hand.global_transform

func switch_to_ar() -> bool:
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
		elif XRInterface.XR_ENV_BLEND_MODE_ADDITIVE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ADDITIVE
		else:
			return false
	else:
		return false

	get_viewport().transparent_bg = true
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	return true

func switch_to_vr() -> bool:
	if xr_interface:
		var modes = xr_interface.get_supported_environment_blend_modes()
		if XRInterface.XR_ENV_BLEND_MODE_OPAQUE in modes:
			xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_OPAQUE
		else:
			return false
	else:
		return false

	get_viewport().transparent_bg = false
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	return true

func _on_detector_toggled(is_on):
	if is_on:
		if !switch_to_ar():
			$ARToggle.on = false
	else:
		if !switch_to_vr():
			$ARToggle.on = true


###### Grab => world move
func _process(delta):
	# Vérifier si les deux mains maintiennent "grab"

	if left_grip:
		if !grabbing:
			# Début du déplacement, enregistrer l'angle Y initial
			grabbing = true
			last_yaw = get_yaw_from_transform(left_hand.global_transform)
			last_left_hand_transform = left_hand.global_transform
		else:
			# --- Rotation Y relative ---
			# Calcul de la différence de rotation sur Y
			var current_yaw = get_yaw_from_transform(left_hand.global_transform)
			var yaw_delta = current_yaw - last_yaw
			last_yaw = current_yaw

			# Apply on the Y rotation, in the inverse order
			worlds.rotate_y(-yaw_delta)

			### And translate
			var movement_delta = left_hand.global_transform.origin - last_left_hand_transform.origin
			worlds.global_transform.origin += 2 * movement_delta  # Appliquer le déplacement
			
			# Mettre à jour la position précédente
			last_left_hand_transform = left_hand.global_transform
	else:
		grabbing = false  # Arrêter la rotation si on lâche

# Fonction pour extraire uniquement la rotation en Y (yaw) d'un Transform3D
func get_yaw_from_transform(transform: Transform3D) -> float:
	var basis = transform.basis
	var yaw = atan2(basis.x.z, basis.z.z)  # Calcul de l'angle Y en radians
	return yaw

func _on_left_hand_button_pressed(name: String) -> void:
	print('LEFT BUTTON IS PRESSED ', name) # Replace with function body.
	if name == 'grip_click':
		left_grip = true

func _on_right_hand_button_pressed(name: String) -> void:
	print('RIGHT BUTTON IS PRESSED', name)
	if name == 'grip_click':
		right_grip = true

func _on_left_hand_button_released(name: String) -> void:
	print('LEFT BUTTON IS RELEASED ', name) # Replace with function body.
	if name == 'grip_click':
		left_grip = false

func _on_right_hand_button_released(name: String) -> void:
	print('RIGHT BUTTON IS RELEASED', name)
	if name == 'grip_click':
		right_grip = false
