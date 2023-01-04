extends Node3D

@export_category("Chunk System")
@export var chunk_size: int = 8
@export var chunk_render_distance: int = 3
@export var terrain_amplitude: float = 100.0
@export_group("Foliage")
@export var player: CharacterBody3D
@export var grass_mesh: ArrayMesh
@export var grass_mesh_LOD: ArrayMesh
@export var particle_material: ShaderMaterial
@export var spatial_material: ShaderMaterial
@export var density: float = 1.0
@export_group("Terrain")
@export var mesh_size: Vector2
@export var _spatial_material: ShaderMaterial

var img = Image.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	img.load("res://resources/terrain/map/rolling_hills_height_map.png")
		
	create_terrain()
	create_collision()
	create_foliage(chunk_render_distance * 2)
	
func create_collision():
	# Configure
	var static_body = StaticBody3D.new()
	add_child(static_body)
	var col_shape = CollisionShape3D.new()
	static_body.add_child(col_shape)
	var hm_shape = HeightMapShape3D.new()
	col_shape.shape = hm_shape
	var mesh_to_image_ratio = mesh_size.x / img.get_width()
	col_shape.scale = Vector3(mesh_to_image_ratio, 1.0, mesh_to_image_ratio)
	
	var _width = img.get_width()
	var _height = img.get_height()
	
	var data = []
	for y in range(_height):
		for x in range(_width):
			var height_value = img.get_pixel(x, y).r * terrain_amplitude
			data.append(height_value)
			
	hm_shape.map_width = _width
	hm_shape.map_depth = _height
	hm_shape.map_data = data
	
func create_terrain():
	var array_of_chunks = get_chunks_positions(mesh_size.x / chunk_size, Vector3(0.0, 0.0, 0.0))
	
	for chunk_pos in array_of_chunks:
		create_mesh(chunk_pos)

func create_mesh(center_of_chunk: Vector3):
	var mesh_to_chunk_ratio = mesh_size.x / chunk_size
	# Configure
	var chunk_terrain = MeshInstance3D.new()
	add_child(chunk_terrain)
	chunk_terrain.position = center_of_chunk
	# Mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.custom_aabb = AABB(-0.5 * Vector3(chunk_size, 0.0, chunk_size), Vector3(chunk_size, chunk_size, chunk_size))
	plane_mesh.subdivide_width = (img.get_width() - 1) / mesh_to_chunk_ratio
	plane_mesh.subdivide_depth = (img.get_height() - 1) / mesh_to_chunk_ratio
	chunk_terrain.mesh = plane_mesh
	# Material
	var shader_mat = _spatial_material.duplicate()
	shader_mat.set_shader_parameter("terrain_amplitude", terrain_amplitude)
	shader_mat.set_shader_parameter("mesh_size", mesh_size)
	shader_mat.set_shader_parameter("chunk_size", chunk_size)
	shader_mat.set_shader_parameter("chunk_position", Vector2(center_of_chunk.x - 0.5 * chunk_size, center_of_chunk.z - 0.5 * chunk_size))
	chunk_terrain.material_override = shader_mat

func create_foliage(number_of_chunks: int):
	var center = get_closest_chunk_center(player.position)
	var array_of_chunks = get_chunks_positions(number_of_chunks, center)
	
	for chunk_pos in array_of_chunks:
		create_chunk_foliage(chunk_pos)

func get_chunks_positions(number_of_chunks: int, center: Vector3):
	var array_of_chunks = []
	var isOdd = number_of_chunks % 2
	for x in number_of_chunks:
		for z in number_of_chunks:
			var t_chunk_pos = Vector3(center.x + (x - number_of_chunks / 2) * chunk_size, 0.0, center.z + (z - number_of_chunks / 2) * chunk_size)
			if(not isOdd):
				t_chunk_pos += 0.5 * Vector3(chunk_size, 0.0, chunk_size)
			if ((abs(mesh_size.x / 2) > abs(t_chunk_pos.x)) && 
				(abs(mesh_size.y / 2) > abs(t_chunk_pos.z))):
				array_of_chunks.append(t_chunk_pos)
	return array_of_chunks
	
func get_closest_chunk_center(entity_position: Vector3):
	var _chunk_size = Vector3(chunk_size, chunk_size, chunk_size)
	var chunk_indices = entity_position / _chunk_size
	chunk_indices = chunk_indices.round()
	
	var closest_chunk_center = chunk_indices * _chunk_size
	
	return closest_chunk_center
	
func create_chunk_foliage(center_of_chunk: Vector3):
	# configure
	var chunk_foliage = GPUParticles3D.new()
	add_child(chunk_foliage)
	chunk_foliage.position = center_of_chunk
	chunk_foliage.visibility_aabb = AABB(-0.5 * Vector3(chunk_size, 0.0, chunk_size), Vector3(chunk_size, chunk_size, chunk_size))
	chunk_foliage.amount = pow(chunk_size * density, 2.0)
	chunk_foliage.lifetime = 0.01
	chunk_foliage.explosiveness = 1.0
	chunk_foliage.interpolate = false
	chunk_foliage.fract_delta = false
	# Mesh
	chunk_foliage.draw_pass_1 = grass_mesh
	# Particle Material
	var shader_mat = particle_material.duplicate()
	shader_mat.set_shader_parameter("chunk_position", center_of_chunk)
	shader_mat.set_shader_parameter("chunk_size", chunk_size)
	shader_mat.set_shader_parameter("map_size", mesh_size)
	shader_mat.set_shader_parameter("terrain_amplitude", terrain_amplitude)
	shader_mat.set_shader_parameter("instance_rows", chunk_size * density)
	chunk_foliage.process_material = shader_mat
	# Spatial Material
	shader_mat = spatial_material.duplicate()
	shader_mat.set_shader_parameter("character_position", player.position)
	chunk_foliage.material_override = shader_mat
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var chunks_for_deletion = []
	var chunks_for_calculation = []
	var child_count = get_child_count()
	for child_index in child_count:
		var child = get_child(child_index)
		if(child is GPUParticles3D):
			if(player.position.distance_to(child.position) > chunk_render_distance * chunk_size):
				chunks_for_deletion.append(child)
			elif(player.position.distance_to(child.position) > chunk_render_distance * chunk_size / 3.0):
				chunks_for_calculation.append(child.position)
				child.draw_pass_1 = grass_mesh_LOD
			else:
				chunks_for_calculation.append(child.position)
				child.material_override.set_shader_parameter("character_position", player.position)
	
	var center = get_closest_chunk_center(player.position)
	var chunks_for_creation = get_chunks_positions(chunk_render_distance * 2, center)
	
	for new_chunk_pos in chunks_for_creation:
		if(player.position.distance_to(new_chunk_pos) < chunk_render_distance * chunk_size):
			var hit = false;
			for exist_chunk_pos in chunks_for_calculation:
				if(new_chunk_pos == exist_chunk_pos):
					hit = true;
					break
			if(not hit):
				create_chunk_foliage(new_chunk_pos)
				
	for chunk in chunks_for_deletion:
		remove_child(chunk)
