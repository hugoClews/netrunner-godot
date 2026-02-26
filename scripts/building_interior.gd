extends Node3D
## Building interior scene with furniture

const FURNITURE_PATH := "res://assets/models/"

var room_size := Vector3(12, 4, 10)  # Width, Height, Depth
var furniture_items := []

func _ready() -> void:
	create_interior()

func create_interior() -> void:
	# Floor
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(room_size.x, 0.1, room_size.z)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = 0.05
	
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.6, 0.5, 0.4)  # Wood floor
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	
	# Add floor collision
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(room_size.x, 0.1, room_size.z)
	floor_col.shape = floor_shape
	floor_col.position.y = 0.05
	floor_body.add_child(floor_col)
	add_child(floor_body)
	
	# Ceiling
	var ceiling := MeshInstance3D.new()
	ceiling.mesh = floor_box
	ceiling.position.y = room_size.y
	var ceiling_mat := StandardMaterial3D.new()
	ceiling_mat.albedo_color = Color(0.9, 0.9, 0.85)
	ceiling.material_override = ceiling_mat
	add_child(ceiling)
	
	# Walls
	create_walls()
	
	# Furniture
	create_furniture()
	
	# Lighting
	create_lighting()

func create_walls() -> void:
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.85, 0.85, 0.8)
	
	var wall_thickness := 0.2
	
	# Back wall
	create_wall(Vector3(0, room_size.y/2, -room_size.z/2), Vector3(room_size.x, room_size.y, wall_thickness), wall_mat)
	
	# Left wall
	create_wall(Vector3(-room_size.x/2, room_size.y/2, 0), Vector3(wall_thickness, room_size.y, room_size.z), wall_mat)
	
	# Right wall
	create_wall(Vector3(room_size.x/2, room_size.y/2, 0), Vector3(wall_thickness, room_size.y, room_size.z), wall_mat)
	
	# Front wall with door gap
	var door_width := 1.5
	var door_height := 2.5
	
	# Left part of front wall
	var left_width := (room_size.x - door_width) / 2
	create_wall(Vector3(-room_size.x/4 - door_width/4, room_size.y/2, room_size.z/2), Vector3(left_width, room_size.y, wall_thickness), wall_mat)
	
	# Right part of front wall
	create_wall(Vector3(room_size.x/4 + door_width/4, room_size.y/2, room_size.z/2), Vector3(left_width, room_size.y, wall_thickness), wall_mat)
	
	# Above door
	create_wall(Vector3(0, room_size.y - (room_size.y - door_height)/2, room_size.z/2), Vector3(door_width, room_size.y - door_height, wall_thickness), wall_mat)

func create_wall(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = size
	wall.mesh = wall_mesh
	wall.position = pos
	wall.material_override = mat
	add_child(wall)
	
	# Collision
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	add_child(body)

func create_furniture() -> void:
	# Desk
	create_desk(Vector3(-3, 0, -3))
	
	# Chair
	create_chair(Vector3(-3, 0, -1.5))
	
	# Couch
	create_couch(Vector3(3, 0, -2))
	
	# Table
	create_table(Vector3(0, 0, 2))
	
	# Computer on desk
	create_computer(Vector3(-3, 0.8, -3))
	
	# Bookshelf
	create_bookshelf(Vector3(-5, 0, -4))

func create_desk(pos: Vector3) -> void:
	var desk := Node3D.new()
	desk.position = pos
	
	# Desktop
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(1.5, 0.05, 0.8)
	top.mesh = top_mesh
	top.position.y = 0.75
	
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.25, 0.15)
	top.material_override = wood_mat
	desk.add_child(top)
	
	# Legs
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.05, 0.73, 0.05)
	var leg_positions := [Vector3(-0.7, 0.365, -0.35), Vector3(0.7, 0.365, -0.35), Vector3(-0.7, 0.365, 0.35), Vector3(0.7, 0.365, 0.35)]
	for leg_pos in leg_positions:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.position = leg_pos
		leg.material_override = wood_mat
		desk.add_child(leg)
	
	add_child(desk)
	add_furniture_collision(pos + Vector3(0, 0.4, 0), Vector3(1.5, 0.8, 0.8))

func create_chair(pos: Vector3) -> void:
	var chair := Node3D.new()
	chair.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	
	# Seat
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.5, 0.08, 0.5)
	seat.mesh = seat_mesh
	seat.position.y = 0.45
	seat.material_override = mat
	chair.add_child(seat)
	
	# Back
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.5, 0.5, 0.08)
	back.mesh = back_mesh
	back.position = Vector3(0, 0.7, -0.21)
	back.material_override = mat
	chair.add_child(back)
	
	add_child(chair)
	add_furniture_collision(pos + Vector3(0, 0.4, 0), Vector3(0.5, 0.8, 0.5))

func create_couch(pos: Vector3) -> void:
	var couch := Node3D.new()
	couch.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.35, 0.5)
	
	# Base
	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(2, 0.4, 0.8)
	base.mesh = base_mesh
	base.position.y = 0.2
	base.material_override = mat
	couch.add_child(base)
	
	# Back
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(2, 0.5, 0.2)
	back.mesh = back_mesh
	back.position = Vector3(0, 0.55, -0.3)
	back.material_override = mat
	couch.add_child(back)
	
	# Armrests
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.15, 0.3, 0.8)
	for x in [-0.925, 0.925]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.position = Vector3(x, 0.45, 0)
		arm.material_override = mat
		couch.add_child(arm)
	
	add_child(couch)
	add_furniture_collision(pos + Vector3(0, 0.4, 0), Vector3(2, 0.8, 0.8))

func create_table(pos: Vector3) -> void:
	var table := Node3D.new()
	table.position = pos
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.35, 0.2)
	
	# Top
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(1.2, 0.05, 0.6)
	top.mesh = top_mesh
	top.position.y = 0.45
	top.material_override = mat
	table.add_child(top)
	
	# Legs
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.08, 0.43, 0.08)
	for lp in [Vector3(-0.5, 0.215, -0.2), Vector3(0.5, 0.215, -0.2), Vector3(-0.5, 0.215, 0.2), Vector3(0.5, 0.215, 0.2)]:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.position = lp
		leg.material_override = mat
		table.add_child(leg)
	
	add_child(table)
	add_furniture_collision(pos + Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 0.6))

func create_computer(pos: Vector3) -> void:
	var computer := Node3D.new()
	computer.position = pos
	
	# Monitor
	var monitor := MeshInstance3D.new()
	var mon_mesh := BoxMesh.new()
	mon_mesh.size = Vector3(0.5, 0.35, 0.05)
	monitor.mesh = mon_mesh
	monitor.position.y = 0.25
	
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.1, 0.15, 0.2)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.3, 0.5)
	screen_mat.emission_energy_multiplier = 0.5
	monitor.material_override = screen_mat
	computer.add_child(monitor)
	
	# Stand
	var stand := MeshInstance3D.new()
	var stand_mesh := BoxMesh.new()
	stand_mesh.size = Vector3(0.1, 0.1, 0.1)
	stand.mesh = stand_mesh
	stand.position.y = 0.05
	var black_mat := StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.1, 0.1, 0.1)
	stand.material_override = black_mat
	computer.add_child(stand)
	
	# Keyboard
	var kb := MeshInstance3D.new()
	var kb_mesh := BoxMesh.new()
	kb_mesh.size = Vector3(0.35, 0.02, 0.12)
	kb.mesh = kb_mesh
	kb.position = Vector3(0, 0.01, 0.25)
	kb.material_override = black_mat
	computer.add_child(kb)
	
	add_child(computer)

func create_bookshelf(pos: Vector3) -> void:
	var shelf := Node3D.new()
	shelf.position = pos
	
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	
	# Frame
	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1, 2, 0.3)
	frame.mesh = frame_mesh
	frame.position.y = 1
	frame.material_override = wood_mat
	shelf.add_child(frame)
	
	# Books (colored blocks)
	var book_colors := [Color(0.6, 0.2, 0.2), Color(0.2, 0.4, 0.6), Color(0.2, 0.5, 0.3), Color(0.5, 0.4, 0.2)]
	for row in range(4):
		for col in range(3):
			var book := MeshInstance3D.new()
			var book_mesh := BoxMesh.new()
			book_mesh.size = Vector3(0.25, 0.35, 0.2)
			book.mesh = book_mesh
			book.position = Vector3(-0.3 + col * 0.3, 0.3 + row * 0.45, 0)
			var book_mat := StandardMaterial3D.new()
			book_mat.albedo_color = book_colors[(row + col) % book_colors.size()]
			book.material_override = book_mat
			shelf.add_child(book)
	
	add_child(shelf)
	add_furniture_collision(pos + Vector3(0, 1, 0), Vector3(1, 2, 0.3))

func add_furniture_collision(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	add_child(body)

func create_lighting() -> void:
	# Ceiling light
	var light := OmniLight3D.new()
	light.position = Vector3(0, room_size.y - 0.5, 0)
	light.light_color = Color(1, 0.95, 0.9)
	light.light_energy = 1.5
	light.omni_range = 12
	light.shadow_enabled = true
	add_child(light)
	
	# Light fixture mesh
	var fixture := MeshInstance3D.new()
	var fix_mesh := CylinderMesh.new()
	fix_mesh.top_radius = 0.3
	fix_mesh.bottom_radius = 0.4
	fix_mesh.height = 0.15
	fixture.mesh = fix_mesh
	fixture.position = Vector3(0, room_size.y - 0.1, 0)
	var light_mat := StandardMaterial3D.new()
	light_mat.albedo_color = Color(1, 1, 0.9)
	light_mat.emission_enabled = true
	light_mat.emission = Color(1, 0.95, 0.85)
	light_mat.emission_energy_multiplier = 1.5
	fixture.material_override = light_mat
	add_child(fixture)
