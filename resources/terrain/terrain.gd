extends Node3D

@export_category("Chunk System")
@export_group("Chunk Settings")
@export var chunk_size: int = 8
@export var chunk_render_distance: int = 3
@export var terrain_amplitude: float = 100.0
@export_group("Foliage")
@export var foliage_state: bool = true
@export var player: CharacterBody3D
@export var grass_mesh: ArrayMesh
@export var grass_mesh_LOD: ArrayMesh
@export var particle_material: ShaderMaterial
@export var spatial_material: ShaderMaterial
@export var density: float = 1.0
@export_group("Terrain")
@export var terrain_state: bool = true
@export var _spatial_material: ShaderMaterial
@export_group("Tree")
@export var tree_state: bool = true
@export var tree_scene: PackedScene
@export var _density: float = 1.0

var _chunk_vertices: int
var _seed = 0
var _populated_chunks = []

func _ready():
	_chunk_vertices = chunk_size + 1
	create_chunks(chunk_render_distance * 2)
	
func generate_noise(user_seed: int, id: int) -> FastNoiseLite:
	var noise_map = FastNoiseLite.new()
	noise_map.seed = rand_from_seed(user_seed + id)[0]
	noise_map.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_map.fractal_octaves = 4
	noise_map.frequency = 1.0 / 20.0
	return noise_map

func create_chunks(number_of_chunks: int):
	var center = get_closest_chunk_center(player.position)
	var array_of_chunks = get_chunks_positions(number_of_chunks, center)
	for chunk_pos in array_of_chunks:
		if(chunk_pos not in _populated_chunks):
			_populated_chunks.append(chunk_pos)
			
			# Generate noise
			var height_noise = generate_noise(_seed, _populated_chunks.size())
			var height_noise_image = height_noise.get_seamless_image(_chunk_vertices, _chunk_vertices)
			height_noise_image.convert(Image.FORMAT_RF)
			var height_noise_texture = ImageTexture.create_from_image(height_noise_image)
			
			var chunk_base = StaticBody3D.new()
			chunk_base.position = chunk_pos
			
			chunk_base.add_child(create_chunk_collision(height_noise_image))
			chunk_base.add_child(create_chunk_mesh(height_noise_texture))
			chunk_base.add_child(create_chunk_foliage(chunk_pos, height_noise_texture))
			chunk_base.add_child(create_chunk_trees(height_noise_image))
			add_child(chunk_base, true)
			pass

func create_chunk_collision(height_noise_image: Image):
	# Configure
	var col_shape = CollisionShape3D.new()
	var hm_shape = HeightMapShape3D.new()
	col_shape.shape = hm_shape
	
	var _width = height_noise_image.get_width()
	var _height = height_noise_image.get_height()
	
	var chunk_to_image_ratio = float(_chunk_vertices) / _width
	col_shape.scale = Vector3(chunk_to_image_ratio, 1.0, chunk_to_image_ratio)
	
	var data = height_noise_image.get_data().to_float32_array()
	for i in range(0, data.size()):
			data[i] *= terrain_amplitude
			
	hm_shape.map_width = _width
	hm_shape.map_depth = _height 
	hm_shape.map_data = data

	return col_shape

func create_chunk_trees(height_noise_image: Image) -> Node3D:
	var root = Node3D.new()
	var tree = tree_scene.instantiate()
	
	var tree_base = MultiMeshInstance3D.new()
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tree.find_child("Tree Base").mesh
	mm.instance_count = chunk_size * chunk_size
	
	for y in range(chunk_size * _density):
		for x in range(chunk_size * _density):
			var t_height = height_noise_image.get_pixelv(Vector2(x / _density, y / _density)).r * terrain_amplitude
			var t_transform = Transform3D()
			t_transform = t_transform.translated(Vector3(- 0.5 * chunk_size + x / _density, t_height, - 0.5 * chunk_size + y / _density))
			mm.set_instance_transform(x + y * chunk_size, t_transform)

	tree_base.multimesh = mm
	root.add_child(tree_base)
	return root
	
func create_chunk_foliage(center_of_chunk: Vector3, height_noise_texture: ImageTexture) -> GPUParticles3D:
	# configure
	var chunk_foliage = GPUParticles3D.new()
	chunk_foliage.visibility_aabb = AABB(-0.5 * Vector3(chunk_size, 0.0, chunk_size), Vector3(chunk_size, chunk_size, chunk_size))
	chunk_foliage.amount = pow(chunk_size * density, 2.0)
	chunk_foliage.lifetime = 0.01
	chunk_foliage.explosiveness = 1.0
	chunk_foliage.interpolate = false
	chunk_foliage.fract_delta = false
	# Mesh
	chunk_foliage.draw_pass_1 = grass_mesh_LOD
	# Particle Material
	var shader_mat = particle_material.duplicate()
	shader_mat.set_shader_parameter("chunk_position", center_of_chunk)
	shader_mat.set_shader_parameter("chunk_size", chunk_size)
	shader_mat.set_shader_parameter("map_heightmap", height_noise_texture)
	shader_mat.set_shader_parameter("terrain_amplitude", terrain_amplitude)
	shader_mat.set_shader_parameter("instance_rows", chunk_size * density)
	chunk_foliage.process_material = shader_mat
	# Spatial Material
	shader_mat = spatial_material.duplicate()
	shader_mat.set_shader_parameter("character_position", player.position)
	chunk_foliage.material_override = shader_mat
	return chunk_foliage

func create_chunk_mesh(height_noise_texture: ImageTexture) -> MeshInstance3D: 
	# Configure
	var chunk_terrain = MeshInstance3D.new()
	# Mesh
	var plane_mesh = PlaneMesh.new()
	
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.custom_aabb = AABB(-0.5 * Vector3(chunk_size, 0.0, chunk_size), Vector3(chunk_size, chunk_size, chunk_size))
	plane_mesh.subdivide_width = height_noise_texture.get_width() - 2
	plane_mesh.subdivide_depth = height_noise_texture.get_height() - 2
	chunk_terrain.mesh = plane_mesh
	# Material
	var shader_mat = _spatial_material.duplicate()
	shader_mat.set_shader_parameter("terrain_amplitude", terrain_amplitude)
	shader_mat.set_shader_parameter("heightmap", height_noise_texture)
	chunk_terrain.material_override = shader_mat
	return chunk_terrain
	
func get_chunks_positions(number_of_chunks: int, center: Vector3):
	var array_of_chunks = []
	var isOdd = number_of_chunks % 2
	for x in number_of_chunks:
		for z in number_of_chunks:
			var t_chunk_pos = Vector3(center.x + (x - number_of_chunks / 2.0) * chunk_size, 0.0, center.z + (z - number_of_chunks / 2.0) * chunk_size)
			if(not isOdd):
				t_chunk_pos += 0.5 * Vector3(chunk_size, 0.0, chunk_size)
				array_of_chunks.append(t_chunk_pos)
	return array_of_chunks
	
func get_closest_chunk_center(entity_position: Vector3):
	var _chunk_size = Vector3(chunk_size, chunk_size, chunk_size)
	var chunk_indices = entity_position / _chunk_size
	chunk_indices = chunk_indices.round()
	
	var closest_chunk_center = chunk_indices * _chunk_size
	
	return closest_chunk_center
	
func _process(_delta):
	create_chunks(chunk_render_distance * 2)
	for chunk in get_children(): 
		for child in chunk.get_children():
			if(child is GPUParticles3D):
				child.material_override.set_shader_parameter("character_position", player.position)
				child.visible = foliage_state
			if(child is MeshInstance3D):
				child.visible = terrain_state
			if(child is Node3D && child.get_child_count() > 0):
				child.visible = tree_state
	pass
#	var chunks_for_deletion = []
#	var chunks_for_calculation = []
#	var child_count = get_child_count()
#	for child_index in child_count:
#		var child = get_child(child_index)
#		if(child is GPUParticles3D):
#			if(player.position.distance_to(child.position) > chunk_render_distance * chunk_size):
#				chunks_for_deletion.append(child)
#			elif(player.position.distance_to(child.position) > chunk_render_distance * chunk_size / 3.0):
#				chunks_for_calculation.append(child.position)
#				child.draw_pass_1 = grass_mesh_LOD
#			else:
#				chunks_for_calculation.append(child.position)
#				child.material_override.set_shader_parameter("character_position", player.position)
#
#	var center = get_closest_chunk_center(player.position)
#	var chunks_for_creation = get_chunks_positions(chunk_render_distance * 2, center)
#
#	for new_chunk_pos in chunks_for_creation:
#		if(player.position.distance_to(new_chunk_pos) < chunk_render_distance * chunk_size):
#			var hit = false;
#			for exist_chunk_pos in chunks_for_calculation:
#				if(new_chunk_pos == exist_chunk_pos):
#					hit = true;
#					break
#			if(not hit):
#				create_chunk_foliage(new_chunk_pos)
#
#	for chunk in chunks_for_deletion:
#		remove_child(chunk)
