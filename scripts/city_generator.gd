extends Node3D
## City Generator - Creates a suburban neighborhood with visible interiors

const BUILDING_SCALE := 12.0
const TREE_SCALE := 8.0

const MODELS_PATH := "res://assets/models/"

var building_types := [
	"building-type-a", "building-type-b", "building-type-c", "building-type-d",
	"building-type-e", "building-type-f", "building-type-g", "building-type-h",
	"building-type-i", "building-type-j", "building-type-k", "building-type-l"
]

func _ready() -> void:
	add_to_group("city")
	generate_city()

func generate_city() -> void:
	create_ground()
	create_roads()
	create_buildings_with_interiors()
	create_trees()
	create_street_lights()
	print("City generated with interiors!")

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

func create_buildings_with_interiors() -> void:
	var positions := [
		Vector3(-25, 0, -50),
		Vector3(-25, 0, -20),
		Vector3(-25, 0, 10),
		Vector3(-25, 0, 40),
		Vector3(25, 0, -50),
		Vector3(25, 0, -20),
		Vector3(25, 0, 10),
		Vector3(25, 0, 40),
	]
	
	for pos in positions:
		create_building_with_interior(pos)

func create_building_with_interior(pos: Vector3) -> void:
	var building := Node3D.new()
	building.position = pos
	
	var room_width := 10.0
	var room_depth := 8.0
	var wall_height := 4.0
	var wall_thickness := 0.3
	
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.85, 0.82, 0.78)
	
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.55, 0.45, 0.35)
	
	var exterior_mat := StandardMaterial3D.new()
	exterior_mat.albedo_color = Color(0.7, 0.65, 0.6)
	
	# Floor
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(room_width, 0.15, room_depth)
	floor_mesh.mesh = fm
	floor_mesh.position.y = 0.075
	floor_mesh.material_override = floor_mat
	building.add_child(floor_mesh)
	
	# Floor collision
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(room_width, 0.15, room_depth)
	floor_col.shape = floor_shape
	floor_col.position.y = 0.075
	floor_body.add_child(floor_col)
	building.add_child(floor_body)
	
	# Walls
	# Back wall
	create_wall_segment(building, Vector3(0, wall_height/2, -room_depth/2 + wall_thickness/2), 
		Vector3(room_width, wall_height, wall_thickness), exterior_mat)
	
	# Left wall
	create_wall_segment(building, Vector3(-room_width/2 + wall_thickness/2, wall_height/2, 0),
		Vector3(wall_thickness, wall_height, room_depth), exterior_mat)
	
	# Right wall
	create_wall_segment(building, Vector3(room_width/2 - wall_thickness/2, wall_height/2, 0),
		Vector3(wall_thickness, wall_height, room_depth), exterior_mat)
	
	# Front wall with door gap
	var door_width := 1.8
	var door_height := 2.8
	var side_width := (room_width - door_width) / 2
	
	# Left side of front
	create_wall_segment(building, Vector3(-room_width/4 - door_width/4, wall_height/2, room_depth/2 - wall_thickness/2),
		Vector3(side_width, wall_height, wall_thickness), exterior_mat)
	
	# Right side of front
	create_wall_segment(building, Vector3(room_width/4 + door_width/4, wall_height/2, room_depth/2 - wall_thickness/2),
		Vector3(side_width, wall_height, wall_thickness), exterior_mat)
	
	# Above door
	create_wall_segment(building, Vector3(0, wall_height - (wall_height - door_height)/2, room_depth/2 - wall_thickness/2),
		Vector3(door_width + 0.4, wall_height - door_height, wall_thickness), exterior_mat)
	
	# Door frame
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.3, 0.2, 0.15)
	
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.45, 0.3, 0.2)
	
	# Door
	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(door_width - 0.2, door_height - 0.1, 0.1)
	door.mesh = door_mesh
	door.position = Vector3(0, door_height/2, room_depth/2 - 0.1)
	door.material_override = door_mat
	building.add_child(door)
	
	# Add interior furniture
	add_interior_furniture(building, room_width, room_depth)
	
	# Add pitched roof (house-style)
	add_pitched_roof(building, room_width, room_depth, wall_height)
	
	# Add door interaction area
	add_door_area(building, Vector3(0, 0, room_depth/2 + 1))
	
	add_child(building)

func create_wall_segment(parent: Node3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = size
	wall.mesh = wall_mesh
	wall.position = pos
	wall.material_override = mat
	parent.add_child(wall)
	
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	parent.add_child(body)

func add_pitched_roof(parent: Node3D, width: float, depth: float, wall_height: float) -> void:
	var roof_height := 2.5
	var overhang := 0.8
	
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.45, 0.25, 0.2)  # Brown/terracotta roof
	
	# Create roof using two angled planes (prism shape)
	var roof := Node3D.new()
	roof.position.y = wall_height
	
	# Calculate roof panel dimensions
	var panel_width := sqrt(pow(width/2 + overhang, 2) + pow(roof_height, 2))
	var roof_angle := atan2(roof_height, width/2 + overhang)
	
	# Left roof panel
	var left_panel := MeshInstance3D.new()
	var left_mesh := BoxMesh.new()
	left_mesh.size = Vector3(panel_width, 0.15, depth + overhang * 2)
	left_panel.mesh = left_mesh
	left_panel.rotation.z = roof_angle
	left_panel.position = Vector3(-width/4 - overhang/4, roof_height/2, 0)
	left_panel.material_override = roof_mat
	roof.add_child(left_panel)
	
	# Right roof panel
	var right_panel := MeshInstance3D.new()
	right_panel.mesh = left_mesh
	right_panel.rotation.z = -roof_angle
	right_panel.position = Vector3(width/4 + overhang/4, roof_height/2, 0)
	right_panel.material_override = roof_mat
	roof.add_child(right_panel)
	
	# Gable ends (triangular pieces at front and back)
	var gable_mat := StandardMaterial3D.new()
	gable_mat.albedo_color = Color(0.75, 0.7, 0.65)
	
	# Front gable
	create_gable(roof, Vector3(0, 0, depth/2 + 0.1), width, roof_height, gable_mat)
	
	# Back gable
	create_gable(roof, Vector3(0, 0, -depth/2 - 0.1), width, roof_height, gable_mat)
	
	parent.add_child(roof)

func create_gable(parent: Node3D, pos: Vector3, width: float, height: float, mat: StandardMaterial3D) -> void:
	# Approximate triangle with stacked boxes (Godot doesn't have built-in triangle mesh)
	var steps := 8
	for i in range(steps):
		var step_height := height / steps
		var step_width := width * (1.0 - float(i) / steps)
		
		var block := MeshInstance3D.new()
		var block_mesh := BoxMesh.new()
		block_mesh.size = Vector3(step_width, step_height, 0.2)
		block.mesh = block_mesh
		block.position = pos + Vector3(0, step_height * i + step_height/2, 0)
		block.material_override = mat
		parent.add_child(block)

func add_interior_furniture(building: Node3D, room_w: float, room_d: float) -> void:
	# Desk in corner
	create_desk(building, Vector3(-room_w/2 + 2, 0.15, -room_d/2 + 1.5))
	
	# Chair
	create_chair(building, Vector3(-room_w/2 + 2, 0.15, -room_d/2 + 3))
	
	# Couch
	create_couch(building, Vector3(room_w/2 - 2, 0.15, -room_d/2 + 2))
	
	# Table
	create_table(building, Vector3(0, 0.15, 0))
	
	# Bookshelf
	create_bookshelf(building, Vector3(-room_w/2 + 1, 0.15, 0))
	
	# Rug
	create_rug(building, Vector3(0, 0.16, 0))
	
	# Ceiling light (no ceiling, but light fixture hangs)
	create_hanging_light(building, Vector3(0, 3.5, 0))

func create_desk(parent: Node3D, pos: Vector3) -> void:
	var desk := Node3D.new()
	desk.position = pos
	
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.3, 0.18)
	
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(1.4, 0.06, 0.7)
	top.mesh = tm
	top.position.y = 0.7
	top.material_override = wood
	desk.add_child(top)
	
	# Legs
	for lp in [Vector3(-0.6, 0.35, -0.25), Vector3(0.6, 0.35, -0.25), Vector3(-0.6, 0.35, 0.25), Vector3(0.6, 0.35, 0.25)]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.06, 0.7, 0.06)
		leg.mesh = lm
		leg.position = lp
		leg.material_override = wood
		desk.add_child(leg)
	
	# Computer monitor
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.1, 0.12, 0.15)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.2, 0.4, 0.6)
	screen_mat.emission_energy_multiplier = 0.8
	
	var monitor := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.5, 0.35, 0.04)
	monitor.mesh = mm
	monitor.position = Vector3(0, 0.95, -0.2)
	monitor.material_override = screen_mat
	desk.add_child(monitor)
	
	parent.add_child(desk)

func create_chair(parent: Node3D, pos: Vector3) -> void:
	var chair := Node3D.new()
	chair.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.5, 0.08, 0.5)
	seat.mesh = sm
	seat.position.y = 0.45
	seat.material_override = mat
	chair.add_child(seat)
	
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.5, 0.08)
	back.mesh = bm
	back.position = Vector3(0, 0.73, -0.21)
	back.material_override = mat
	chair.add_child(back)
	
	parent.add_child(chair)

func create_couch(parent: Node3D, pos: Vector3) -> void:
	var couch := Node3D.new()
	couch.position = pos
	couch.rotation.y = PI / 2
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.25, 0.45)
	
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 0.4, 0.75)
	base.mesh = bm
	base.position.y = 0.2
	base.material_override = mat
	couch.add_child(base)
	
	var back := MeshInstance3D.new()
	var backm := BoxMesh.new()
	backm.size = Vector3(1.8, 0.45, 0.18)
	back.mesh = backm
	back.position = Vector3(0, 0.52, -0.28)
	back.material_override = mat
	couch.add_child(back)
	
	parent.add_child(couch)

func create_table(parent: Node3D, pos: Vector3) -> void:
	var table := Node3D.new()
	table.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.38, 0.25)
	
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(1.0, 0.05, 0.6)
	top.mesh = tm
	top.position.y = 0.42
	top.material_override = mat
	table.add_child(top)
	
	for lp in [Vector3(-0.4, 0.2, -0.2), Vector3(0.4, 0.2, -0.2), Vector3(-0.4, 0.2, 0.2), Vector3(0.4, 0.2, 0.2)]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.06, 0.4, 0.06)
		leg.mesh = lm
		leg.position = lp
		leg.material_override = mat
		table.add_child(leg)
	
	parent.add_child(table)

func create_bookshelf(parent: Node3D, pos: Vector3) -> void:
	var shelf := Node3D.new()
	shelf.position = pos
	shelf.rotation.y = PI / 2
	
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.28, 0.15)
	
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.8, 1.8, 0.3)
	frame.mesh = fm
	frame.position.y = 0.9
	frame.material_override = wood
	shelf.add_child(frame)
	
	var book_colors := [Color(0.6, 0.15, 0.15), Color(0.15, 0.35, 0.55), Color(0.15, 0.45, 0.25), Color(0.55, 0.45, 0.15)]
	for row in range(4):
		for col in range(2):
			var book := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.3, 0.32, 0.18)
			book.mesh = bm
			book.position = Vector3(-0.18 + col * 0.36, 0.25 + row * 0.4, 0)
			var bmat := StandardMaterial3D.new()
			bmat.albedo_color = book_colors[(row + col) % book_colors.size()]
			book.material_override = bmat
			shelf.add_child(book)
	
	parent.add_child(shelf)

func create_rug(parent: Node3D, pos: Vector3) -> void:
	var rug := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(3, 0.02, 2)
	rug.mesh = rm
	rug.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.35)
	rug.material_override = mat
	
	parent.add_child(rug)

func create_hanging_light(parent: Node3D, pos: Vector3) -> void:
	var light_node := Node3D.new()
	light_node.position = pos
	
	# Fixture
	var fixture := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.15
	fm.bottom_radius = 0.25
	fm.height = 0.15
	fixture.mesh = fm
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.95, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.95, 0.8)
	mat.emission_energy_multiplier = 2.0
	fixture.material_override = mat
	light_node.add_child(fixture)
	
	# Actual light
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.95, 0.85)
	light.light_energy = 1.2
	light.omni_range = 10
	light.shadow_enabled = true
	light_node.add_child(light)
	
	parent.add_child(light_node)

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
	]
	
	for pos in tree_positions:
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
