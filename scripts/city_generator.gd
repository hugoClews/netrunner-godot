extends Node3D
## City Generator - Creates a suburban neighborhood with Kenney house models

const BUILDING_SCALE := 2.5
const MODELS_PATH := "res://assets/models/"

var building_types := [
	"building-type-a", "building-type-b", "building-type-c", "building-type-d",
	"building-type-e", "building-type-f", "building-type-g", "building-type-h",
	"building-type-i", "building-type-j", "building-type-k", "building-type-l"
]

var loaded_buildings := {}

func _ready() -> void:
	add_to_group("city")
	preload_buildings()
	generate_city()

func preload_buildings() -> void:
	for building_type in building_types:
		var path := MODELS_PATH + building_type + ".glb"
		var scene = load(path)
		if scene:
			loaded_buildings[building_type] = scene
			print("Loaded: ", building_type)
		else:
			print("Failed to load: ", path)

func generate_city() -> void:
	create_ground()
	create_roads()
	create_houses()
	create_trees()
	create_street_lights()
	print("City generated with Kenney houses!")

func create_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.4, 0.2)
	ground.material_override = material
	
	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(200, 0.1, 200)
	collision.shape = shape
	collision.position.y = -0.05
	static_body.add_child(collision)
	ground.add_child(static_body)
	
	add_child(ground)

func create_roads() -> void:
	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.25, 0.25, 0.27)
	
	var sidewalk_mat := StandardMaterial3D.new()
	sidewalk_mat.albedo_color = Color(0.55, 0.55, 0.55)
	
	# Main road
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(12, 0.05, 150)
	road.mesh = road_mesh
	road.position.y = 0.025
	road.material_override = road_mat
	add_child(road)
	
	# Lane markings
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1, 0.9, 0)
	for z in range(-70, 71, 8):
		var line := MeshInstance3D.new()
		var line_mesh := BoxMesh.new()
		line_mesh.size = Vector3(0.3, 0.01, 4)
		line.mesh = line_mesh
		line.position = Vector3(0, 0.06, z)
		line.material_override = line_mat
		add_child(line)
	
	# Sidewalks
	for x in [-8, 8]:
		var sidewalk := MeshInstance3D.new()
		var sw_mesh := BoxMesh.new()
		sw_mesh.size = Vector3(3, 0.12, 150)
		sidewalk.mesh = sw_mesh
		sidewalk.position = Vector3(x, 0.06, 0)
		sidewalk.material_override = sidewalk_mat
		add_child(sidewalk)

func create_houses() -> void:
	var positions := [
		{"pos": Vector3(-25, 0, -50), "rot": 0},
		{"pos": Vector3(-25, 0, -20), "rot": 0},
		{"pos": Vector3(-25, 0, 10), "rot": 0},
		{"pos": Vector3(-25, 0, 40), "rot": 0},
		{"pos": Vector3(25, 0, -50), "rot": PI},
		{"pos": Vector3(25, 0, -20), "rot": PI},
		{"pos": Vector3(25, 0, 10), "rot": PI},
		{"pos": Vector3(25, 0, 40), "rot": PI},
	]
	
	var i := 0
	for data in positions:
		var building_type = building_types[i % building_types.size()]
		create_house(data.pos, data.rot, building_type)
		i += 1

func create_house(pos: Vector3, rot_y: float, building_type: String) -> void:
	if not loaded_buildings.has(building_type):
		print("Building type not loaded: ", building_type)
		return
	
	var house := Node3D.new()
	house.name = "House_" + building_type
	house.position = pos
	house.rotation.y = rot_y
	
	# Instance the GLB model
	var model: Node3D = loaded_buildings[building_type].instantiate()
	model.scale = Vector3(BUILDING_SCALE, BUILDING_SCALE, BUILDING_SCALE)
	house.add_child(model)
	
	# Add collision for the house
	add_house_collision(house, model)
	
	# Add door interaction area (in front of house)
	var door_offset := Vector3(0, 0, 5) if rot_y == 0 else Vector3(0, 0, -5)
	add_door_area(house, door_offset)
	
	add_child(house)

func add_house_collision(house: Node3D, model: Node3D) -> void:
	# Add a simple box collision for the house
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	# Approximate house size after scaling
	shape.size = Vector3(8, 6, 8)
	col.shape = shape
	col.position.y = 3
	body.add_child(col)
	house.add_child(body)

func add_door_area(building: Node3D, local_pos: Vector3) -> void:
	var door := Area3D.new()
	door.name = "Door"
	door.add_to_group("doors")
	
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 3, 2)
	col.shape = shape
	col.position.y = 1.5
	door.add_child(col)
	
	door.position = local_pos
	door.set_meta("building", building)
	
	building.add_child(door)

func create_trees() -> void:
	var tree_positions := [
		Vector3(-40, 0, -40), Vector3(-40, 0, 0), Vector3(-40, 0, 40),
		Vector3(40, 0, -40), Vector3(40, 0, 0), Vector3(40, 0, 40),
		Vector3(-35, 0, -35), Vector3(-35, 0, 25),
		Vector3(35, 0, -25), Vector3(35, 0, 35),
	]
	
	for pos in tree_positions:
		create_tree(pos)

func create_tree(pos: Vector3) -> void:
	# Try to load tree model
	var tree_scene = load(MODELS_PATH + "tree-large.glb")
	if tree_scene:
		var tree: Node3D = tree_scene.instantiate()
		tree.position = pos
		tree.scale = Vector3(3, 3, 3)
		add_child(tree)
	else:
		# Fallback to procedural tree
		create_simple_tree(pos)

func create_simple_tree(pos: Vector3) -> void:
	var tree := Node3D.new()
	tree.position = pos
	
	# Trunk
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.3
	tm.bottom_radius = 0.5
	tm.height = 3
	trunk.mesh = tm
	trunk.position.y = 1.5
	
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.25, 0.15)
	trunk.material_override = trunk_mat
	tree.add_child(trunk)
	
	# Foliage
	var foliage := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 2.5
	fm.height = 4
	foliage.mesh = fm
	foliage.position.y = 4.5
	
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.2, 0.45, 0.2)
	foliage.material_override = leaf_mat
	tree.add_child(foliage)
	
	add_child(tree)

func create_street_lights() -> void:
	for z in range(-60, 61, 30):
		create_street_light(Vector3(-10, 0, z))
		create_street_light(Vector3(10, 0, z))

func create_street_light(pos: Vector3) -> void:
	var light_post := Node3D.new()
	light_post.position = pos
	
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.25, 0.25, 0.25)
	
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.08
	pm.bottom_radius = 0.12
	pm.height = 5
	pole.mesh = pm
	pole.position.y = 2.5
	pole.material_override = pole_mat
	light_post.add_child(pole)
	
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.3
	lamp.mesh = lm
	lamp.position.y = 5.2
	
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1, 0.95, 0.8)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1, 0.9, 0.7)
	lamp_mat.emission_energy_multiplier = 1.5
	lamp.material_override = lamp_mat
	light_post.add_child(lamp)
	
	var light := OmniLight3D.new()
	light.position.y = 5
	light.light_color = Color(1, 0.95, 0.85)
	light.light_energy = 1.0
	light.omni_range = 15
	light_post.add_child(light)
	
	add_child(light_post)
