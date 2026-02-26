extends CharacterBody3D
## Third-person player controller

const SPEED := 8.0
const SPRINT_SPEED := 14.0
const JUMP_VELOCITY := 6.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_sensitivity := 0.002
var is_sprinting := false

@onready var camera_pivot: Node3D = $CameraPivot
@onready var collision: CollisionShape3D = $CollisionShape3D
var character_mesh: Node3D = null

func _ready() -> void:
	setup_collision()
	create_character()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape

func create_character() -> void:
	# Create a simple humanoid character from primitives
	character_mesh = Node3D.new()
	character_mesh.name = "CharacterMesh"
	
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.5, 0.8)  # Blue body
	
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.9, 0.75, 0.65)  # Skin tone
	
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.15, 0.1, 0.05)  # Dark hair
	
	# Body (torso)
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.25
	torso_mesh.height = 0.7
	torso.mesh = torso_mesh
	torso.material_override = body_mat
	torso.position = Vector3(0, 1.1, 0)
	character_mesh.add_child(torso)
	
	# Head
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	head.mesh = head_mesh
	head.material_override = skin_mat
	head.position = Vector3(0, 1.65, 0)
	character_mesh.add_child(head)
	
	# Hair
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.19
	hair_mesh.height = 0.2
	hair.mesh = hair_mesh
	hair.material_override = hair_mat
	hair.position = Vector3(0, 1.75, 0)
	character_mesh.add_child(hair)
	
	# Left arm
	var left_arm := MeshInstance3D.new()
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.08
	arm_mesh.height = 0.5
	left_arm.mesh = arm_mesh
	left_arm.material_override = body_mat
	left_arm.position = Vector3(-0.35, 1.1, 0)
	character_mesh.add_child(left_arm)
	
	# Right arm
	var right_arm := MeshInstance3D.new()
	right_arm.mesh = arm_mesh
	right_arm.material_override = body_mat
	right_arm.position = Vector3(0.35, 1.1, 0)
	character_mesh.add_child(right_arm)
	
	# Left leg
	var left_leg := MeshInstance3D.new()
	var leg_mesh := CapsuleMesh.new()
	leg_mesh.radius = 0.1
	leg_mesh.height = 0.7
	left_leg.mesh = leg_mesh
	left_leg.material_override = body_mat
	left_leg.position = Vector3(-0.15, 0.4, 0)
	character_mesh.add_child(left_leg)
	
	# Right leg
	var right_leg := MeshInstance3D.new()
	right_leg.mesh = leg_mesh
	right_leg.material_override = body_mat
	right_leg.position = Vector3(0.15, 0.4, 0)
	character_mesh.add_child(right_leg)
	
	add_child(character_mesh)

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
		if character_mesh:
			var target_angle := atan2(-direction.x, -direction.z)
			character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, target_angle, 0.15)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		toggle_mouse_capture()
