extends CharacterBody3D
## Third-person player controller with building entry

const SPEED := 8.0
const SPRINT_SPEED := 14.0
const JUMP_VELOCITY := 6.0
const INTERACTION_DISTANCE := 3.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_sensitivity := 0.002
var is_sprinting := false
var nearby_door: Node3D = null
var is_inside := false
var current_building: Node3D = null

@onready var camera_pivot: Node3D = $CameraPivot
@onready var collision: CollisionShape3D = $CollisionShape3D
var character_mesh: Node3D = null
var interaction_label: Label3D = null

signal entered_building(building: Node3D)
signal exited_building()

func _ready() -> void:
	setup_collision()
	create_character()
	create_interaction_label()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape

func create_interaction_label() -> void:
	interaction_label = Label3D.new()
	interaction_label.text = "Press E to Enter"
	interaction_label.font_size = 32
	interaction_label.position = Vector3(0, 2.5, 0)
	interaction_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interaction_label.visible = false
	interaction_label.modulate = Color(1, 1, 0)
	add_child(interaction_label)

func create_character() -> void:
	character_mesh = Node3D.new()
	character_mesh.name = "CharacterMesh"
	
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.5, 0.8)
	
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.9, 0.75, 0.65)
	
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.15, 0.1, 0.05)
	
	# Body
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
	
	# Arms
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.08
	arm_mesh.height = 0.5
	for x in [-0.35, 0.35]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = body_mat
		arm.position = Vector3(x, 1.1, 0)
		character_mesh.add_child(arm)
	
	# Legs
	var leg_mesh := CapsuleMesh.new()
	leg_mesh.radius = 0.1
	leg_mesh.height = 0.7
	for x in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.material_override = body_mat
		leg.position = Vector3(x, 0.4, 0)
		character_mesh.add_child(leg)
	
	add_child(character_mesh)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/3, PI/4)
	
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse_capture()
	
	# Interact with door
	if event.is_action_pressed("interact"):
		if nearby_door and not is_inside:
			enter_building(nearby_door.get_parent())
		elif is_inside:
			exit_building()

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
	
	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if character_mesh:
			var target_angle := atan2(-direction.x, -direction.z)
			character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, target_angle, 0.15)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	check_nearby_doors()

func check_nearby_doors() -> void:
	nearby_door = null
	var doors := get_tree().get_nodes_in_group("doors")
	
	for door in doors:
		var dist := global_position.distance_to(door.global_position)
		if dist < INTERACTION_DISTANCE:
			nearby_door = door
			break
	
	interaction_label.visible = nearby_door != null and not is_inside
	if is_inside:
		interaction_label.text = "Press E to Exit"
		interaction_label.visible = true

func enter_building(building: Node3D) -> void:
	is_inside = true
	current_building = building
	
	# Find or create interior
	var interior = building.get_node_or_null("Interior")
	if not interior:
		var interior_script := load("res://scripts/building_interior.gd")
		interior = Node3D.new()
		interior.set_script(interior_script)
		interior.name = "Interior"
		interior.position = building.position + Vector3(0, 0.1, 0)
		building.get_parent().add_child(interior)
	
	interior.visible = true
	
	# Teleport player inside
	global_position = interior.global_position + Vector3(0, 0.5, 3)
	
	# Hide exterior buildings
	var city := get_tree().get_first_node_in_group("city")
	if city:
		for child in city.get_children():
			if child != interior and child.has_method("hide"):
				child.visible = false
	
	interior.visible = true
	
	emit_signal("entered_building", building)

func exit_building() -> void:
	if not current_building:
		return
	
	is_inside = false
	
	# Show exterior
	var city := get_tree().get_first_node_in_group("city")
	if city:
		for child in city.get_children():
			child.visible = true
	
	# Hide interior
	var interior = current_building.get_node_or_null("Interior")
	if interior:
		interior.visible = false
	
	# Teleport outside
	global_position = current_building.global_position + Vector3(0, 0.5, 8)
	
	current_building = null
	emit_signal("exited_building")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		toggle_mouse_capture()
