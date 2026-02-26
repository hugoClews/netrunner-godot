extends Node3D
## Camera controller with third-person and interior first-person modes

@export var zoom_speed := 2.0
@export var min_distance := 5.0
@export var max_distance := 30.0
@export var mouse_sensitivity := 0.003

@onready var camera: Camera3D = $Camera3D

var current_distance := 20.0
var interior_mode := false
var camera_rotation := Vector2.ZERO

func _ready() -> void:
	update_camera_position()

func _input(event: InputEvent) -> void:
	# Toggle interior/exterior mode with V key
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		interior_mode = !interior_mode
		update_camera_mode()
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if interior_mode:
				# No zoom in interior mode
				pass
			else:
				current_distance = max(min_distance, current_distance - zoom_speed)
				update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not interior_mode:
				current_distance = min(max_distance, current_distance + zoom_speed)
				update_camera_position()
	
	# Mouse look in interior mode
	if interior_mode and event is InputEventMouseMotion:
		camera_rotation.x -= event.relative.y * mouse_sensitivity
		camera_rotation.x = clamp(camera_rotation.x, -PI/2.2, PI/2.2)
		camera_rotation.y -= event.relative.x * mouse_sensitivity
		update_interior_camera()

func update_camera_mode() -> void:
	if interior_mode:
		# First-person mode - camera at eye level
		camera.position = Vector3.ZERO
		camera.rotation = Vector3.ZERO
		camera_rotation = Vector2.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("Interior mode: ON (V to toggle, ESC to release mouse)")
	else:
		# Third-person mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		update_camera_position()
		print("Interior mode: OFF")

func update_camera_position() -> void:
	if camera and not interior_mode:
		# Position camera behind and above the pivot
		camera.position = Vector3(0, current_distance * 0.5, current_distance * 0.75)
		camera.look_at(Vector3.ZERO, Vector3.UP)

func update_interior_camera() -> void:
	if camera and interior_mode:
		camera.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0)
