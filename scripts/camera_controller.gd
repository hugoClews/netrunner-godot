extends Node3D
## Camera controller for third-person view

@export var zoom_speed := 2.0
@export var min_distance := 5.0
@export var max_distance := 30.0

@onready var camera: Camera3D = $Camera3D

var current_distance := 20.0

func _ready() -> void:
	update_camera_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_distance = max(min_distance, current_distance - zoom_speed)
			update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_distance = min(max_distance, current_distance + zoom_speed)
			update_camera_position()

func update_camera_position() -> void:
	if camera:
		# Position camera behind and above the pivot
		camera.position = Vector3(0, current_distance * 0.5, current_distance * 0.75)
		camera.look_at(Vector3.ZERO, Vector3.UP)
