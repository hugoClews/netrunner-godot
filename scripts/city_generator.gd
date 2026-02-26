extends Node3D
## City Generator - Creates a suburban neighborhood using Kenney assets

# Building scale (Kenney models are small, ~1 unit)
const BUILDING_SCALE := 12.0
const TREE_SCALE := 8.0
const FENCE_SCALE := 10.0

# City layout
const GRID_SIZE := 4  # 4x4 blocks
const BLOCK_SIZE := 30.0  # meters per block
const ROAD_WIDTH := 8.0

# Asset paths
const MODELS_PATH := "res://assets/models/"

# Building types available
var building_types := [
	"building-type-a", "building-type-b", "building-type-c", "building-type-d",
	"building-type-e", "building-type-f", "building-type-g", "building-type-h",
	"building-type-i", "building-type-j", "building-type-k", "building-type-l",
	"building-type-m", "building-type-n", "building-type-o", "building-type-p",
	"building-type-q", "building-type-r", "building-type-s", "building-type-t",
	"building-type-u"
]

var prop_types := ["planter", "fence", "fence-low", "tree-large", "tree-small"]

func _ready() -> void:
	add_to_group("city")
	generate_city()

func generate_city() -> void:
	create_ground()
	create_roads()
	create_buildings()
	create_props()
	create_street_lights()
	print("City generated!")

func create_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(GRID_SIZE * BLOCK_SIZE * 2, GRID_SIZE * BLOCK_SIZE * 2)
	ground.mesh = plane
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.35, 0.15)  # Grass green
	material.roughness = 0.9
	ground.material_override = material
	
	# Add collision
	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GRID_SIZE * BLOCK_SIZE * 2, 0.1, GRID_SIZE * BLOCK_SIZE * 2)
	collision.shape = shape
	collision.position.y = -0.05
	static_body.add_child(collision)
	ground.add_child(static_body)
	
	add_child(ground)

func create_roads() -> void:
	var road_material := StandardMaterial3D.new()
	road_material.albedo_color = Color(0.2, 0.2, 0.22)
	road_material.roughness = 0.85
	
	var sidewalk_material := StandardMaterial3D.new()
	sidewalk_material.albedo_color = Color(0.5, 0.5, 0.5)
	sidewalk_material.roughness = 0.9
	
	# Create grid of roads
	var half_grid := GRID_SIZE / 2.0
	
	# Horizontal roads
	for i in range(-int(half_grid), int(half_grid) + 1):
		var z_pos := i * BLOCK_SIZE
		create_road_segment(Vector3(0, 0.01, z_pos), Vector3(GRID_SIZE * BLOCK_SIZE, 0.1, ROAD_WIDTH), road_material)
		# Sidewalks
		create_road_segment(Vector3(0, 0.02, z_pos - ROAD_WIDTH/2 - 1.5), Vector3(GRID_SIZE * BLOCK_SIZE, 0.15, 2), sidewalk_material)
		create_road_segment(Vector3(0, 0.02, z_pos + ROAD_WIDTH/2 + 1.5), Vector3(GRID_SIZE * BLOCK_SIZE, 0.15, 2), sidewalk_material)
	
	# Vertical roads
	for i in range(-int(half_grid), int(half_grid) + 1):
		var x_pos := i * BLOCK_SIZE
		create_road_segment(Vector3(x_pos, 0.01, 0), Vector3(ROAD_WIDTH, 0.1, GRID_SIZE * BLOCK_SIZE), road_material)

func create_road_segment(pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var road := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	road.mesh = box
	road.material_override = material
	road.position = pos
	add_child(road)

func create_buildings() -> void:
	var half_grid := GRID_SIZE / 2.0
	
	# Place buildings in each block
	for bx in range(-int(half_grid), int(half_grid)):
		for bz in range(-int(half_grid), int(half_grid)):
			var block_center := Vector3(
				(bx + 0.5) * BLOCK_SIZE,
				0,
				(bz + 0.5) * BLOCK_SIZE
			)
			place_building_in_block(block_center)

func place_building_in_block(center: Vector3) -> void:
	# Random building type
	var building_name: String = building_types[randi() % building_types.size()]
	var model_path := MODELS_PATH + building_name + ".glb"
	
	# Try to load the model
	var scene := load(model_path) as PackedScene
	if scene == null:
		print("Failed to load: ", model_path)
		return
	
	var building := scene.instantiate() as Node3D
	
	# Position with slight random offset
	var offset := Vector3(
		randf_range(-3, 3),
		0,
		randf_range(-3, 3)
	)
	building.position = center + offset
	building.scale = Vector3.ONE * BUILDING_SCALE
	
	# Random rotation (0, 90, 180, 270 degrees)
	building.rotation.y = (randi() % 4) * PI / 2
	
	add_child(building)
	
	# Add door for entry
	add_door(building)
	
	# Add driveway
	add_driveway(building.position, building.rotation.y)

func add_door(building: Node3D) -> void:
	# Create door as sibling (not child) to avoid scale issues
	var door := Area3D.new()
	door.name = "Door"
	door.add_to_group("doors")
	
	# Door collision shape
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3, 2)
	col.shape = shape
	col.position.y = 1.5
	door.add_child(col)
	
	# Door visual (simple rectangle)
	var door_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 2.8, 0.2)
	door_mesh.mesh = mesh
	door_mesh.position.y = 1.4
	
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.5, 0.3, 0.15)
	door_mesh.material_override = door_mat
	door.add_child(door_mesh)
	
	# Door frame
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.25, 0.25, 0.25)
	
	# Frame pieces
	var frame_positions := [
		{"pos": Vector3(-0.9, 1.4, 0), "size": Vector3(0.2, 2.8, 0.25)},
		{"pos": Vector3(0.9, 1.4, 0), "size": Vector3(0.2, 2.8, 0.25)},
		{"pos": Vector3(0, 2.9, 0), "size": Vector3(2.0, 0.2, 0.25)}
	]
	for fp in frame_positions:
		var frame := MeshInstance3D.new()
		var frame_mesh := BoxMesh.new()
		frame_mesh.size = fp["size"]
		frame.mesh = frame_mesh
		frame.position = fp["pos"]
		frame.material_override = frame_mat
		door.add_child(frame)
	
	# Position door at front of building (world coordinates)
	# Building rotation affects which side is "front"
	var front_offset := Vector3(0, 0, 8).rotated(Vector3.UP, building.rotation.y)
	door.position = building.position + front_offset
	door.rotation.y = building.rotation.y
	
	# Store reference to building
	door.set_meta("building", building)
	
	# Add to city (same parent as building)
	add_child(door)

func add_driveway(pos: Vector3, rotation: float) -> void:
	var driveway_path := MODELS_PATH + "driveway-short.glb"
	var scene := load(driveway_path) as PackedScene
	if scene == null:
		return
	
	var driveway := scene.instantiate() as Node3D
	driveway.position = pos + Vector3(0, 0, 6).rotated(Vector3.UP, rotation)
	driveway.scale = Vector3.ONE * BUILDING_SCALE
	driveway.rotation.y = rotation
	add_child(driveway)

func create_props() -> void:
	var half_grid := GRID_SIZE / 2.0
	
	# Add trees along the roads
	for i in range(-int(half_grid) * 3, int(half_grid) * 3):
		var x := i * 10.0
		add_tree(Vector3(x, 0, -half_grid * BLOCK_SIZE - 5))
		add_tree(Vector3(x, 0, half_grid * BLOCK_SIZE + 5))
		add_tree(Vector3(-half_grid * BLOCK_SIZE - 5, 0, x))
		add_tree(Vector3(half_grid * BLOCK_SIZE + 5, 0, x))

func add_tree(pos: Vector3) -> void:
	var tree_path := MODELS_PATH + "tree-large.glb"
	var scene := load(tree_path) as PackedScene
	if scene == null:
		return
	
	var tree := scene.instantiate() as Node3D
	tree.position = pos
	tree.scale = Vector3.ONE * TREE_SCALE
	tree.rotation.y = randf() * TAU
	add_child(tree)

func create_street_lights() -> void:
	var half_grid := GRID_SIZE / 2.0
	
	# Lights along main roads
	for i in range(-int(half_grid) * 2, int(half_grid) * 2 + 1):
		var pos := i * 15.0
		add_street_light(Vector3(pos, 0, -ROAD_WIDTH))
		add_street_light(Vector3(pos, 0, ROAD_WIDTH))
		add_street_light(Vector3(-ROAD_WIDTH, 0, pos))
		add_street_light(Vector3(ROAD_WIDTH, 0, pos))

func add_street_light(pos: Vector3) -> void:
	var light_group := Node3D.new()
	light_group.position = pos
	
	# Pole
	var pole := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.15
	cylinder.height = 6.0
	pole.mesh = cylinder
	pole.position.y = 3.0
	
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.3, 0.3, 0.3)
	pole.material_override = pole_mat
	light_group.add_child(pole)
	
	# Lamp
	var lamp := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	lamp.mesh = sphere
	lamp.position.y = 6.2
	
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1, 0.95, 0.8)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1, 0.95, 0.8)
	lamp_mat.emission_energy_multiplier = 2.0
	lamp.material_override = lamp_mat
	light_group.add_child(lamp)
	
	# Actual light
	var omni := OmniLight3D.new()
	omni.position.y = 6.0
	omni.light_color = Color(1, 0.95, 0.85)
	omni.light_energy = 1.5
	omni.omni_range = 15.0
	omni.shadow_enabled = true
	light_group.add_child(omni)
	
	add_child(light_group)
