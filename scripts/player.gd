extends CharacterBody3D
## Third-person player controller with animated character

const SPEED := 8.0
const SPRINT_SPEED := 14.0
const JUMP_VELOCITY := 6.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_sensitivity := 0.002
var is_sprinting := false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var character_model: Node3D = null
@onready var animation_player: AnimationPlayer = null

# Character model path
const CHARACTER_PATH := "res://assets/characters/characterMedium.fbx"
const CHARACTER_SKIN := "res://assets/characters/cyborgFemaleA.png"

func _ready() -> void:
	setup_collision()
	setup_character()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape

func setup_character() -> void:
	# Try to load the character model
	var char_scene := load(CHARACTER_PATH) as PackedScene
	if char_scene:
		character_model = char_scene.instantiate()
		character_model.scale = Vector3(0.01, 0.01, 0.01)  # FBX models are usually huge
		character_model.position.y = -0.9  # Offset to ground
		add_child(character_model)
		
		# Find animation player if exists
		animation_player = character_model.get_node_or_null("AnimationPlayer")
		
		# Try to apply skin texture
		apply_skin()
		
		print("Character model loaded!")
	else:
		# Fallback to capsule
		print("Character model not found, using capsule")
		create_fallback_mesh()

func apply_skin() -> void:
	var skin_tex := load(CHARACTER_SKIN) as Texture2D
	if skin_tex and character_model:
		# Apply texture to all mesh instances
		for child in character_model.get_children():
			if child is MeshInstance3D:
				var mat := StandardMaterial3D.new()
				mat.albedo_texture = skin_tex
				child.material_override = mat

func create_fallback_mesh() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "FallbackMesh"
	
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh_instance.mesh = capsule
	mesh_instance.position.y = 0.9
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 0.9)
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/3, PI/4)
	
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse_capture()

func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Sprint
	is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	var current_speed := SPRINT_SPEED if is_sprinting else SPEED
	
	# Movement direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Rotate character to face movement direction
		if character_model:
			var target_angle := atan2(-direction.x, -direction.z)
			character_model.rotation.y = lerp_angle(character_model.rotation.y, target_angle, 0.15)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		toggle_mouse_capture()
