shader_type particles;

//auto
uniform vec3 chunk_position;
uniform float chunk_size;
uniform float terrain_amplitude;
uniform float instance_rows;
uniform sampler2D map_heightmap;

//manual
uniform sampler2D map_normalmap;
uniform sampler2D sample_terrain; 
uniform sampler2D position_noise;
uniform sampler2D height_noise;

float get_height(vec2 pos) {
	pos /= chunk_size;
	return terrain_amplitude * texture(map_heightmap, pos).r;
}

vec3 get_offset_in_chunk(float index) {
	vec3 pos = vec3(0.0, 0.0, 0.0);
	float ratio = chunk_size / instance_rows;
	pos.z = index;
	pos.x = mod(pos.z, instance_rows) * ratio;
	pos.z = (pos.z - pos.x) / instance_rows * ratio;
	return pos;
}

vec4 get_color(vec2 pos) {
	pos /= chunk_size;
	return texture(sample_terrain, pos).rgba;
}

void start() {
	vec3 pos = chunk_position;
	pos.xz -= 0.5 * chunk_size;
	
	vec3 offset = get_offset_in_chunk(float(INDEX));
	offset.xz += texture(position_noise, offset.xz).r - 0.5;
	
	pos.y += get_height(offset.xz);
	pos += offset;
	float scale = texture(height_noise, pos.xz).r;
	
	
	TRANSFORM[0].xyz = vec3(0.0);
	TRANSFORM[1].xyz = vec3(0.0);
	TRANSFORM[2].xyz = vec3(0.0);
	
	TRANSFORM[3].xyz = pos;
	
	//rotation
	//vec3 noise = texture(map_heightmap, offset.xz * 0.1).rgb;
	
	//TRANSFORM[0][0] = cos(noise.x * 2.0) * scale;
	//TRANSFORM[0][2] = -sin(noise.x * 2.0) * scale;
	//TRANSFORM[2][0] = sin(noise.z * 2.0) * scale;
	//TRANSFORM[2][2] = cos(noise.z * 2.0) * scale;
	
	//scale
	TRANSFORM[0][0] = scale;
	TRANSFORM[1][1] = scale;
	TRANSFORM[2][2] = scale;
	
	COLOR = get_color(offset.xz);
}