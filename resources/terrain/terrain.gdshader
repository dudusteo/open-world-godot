shader_type spatial;
render_mode unshaded;
// auto
uniform float terrain_amplitude = 100.0;
uniform vec2 mesh_size;
uniform float chunk_size;
uniform vec2 chunk_position;
// manual
uniform sampler2D albedo: repeat_enable; 
uniform sampler2D heightmap;
uniform sampler2D normalmap;

uniform float shade_threshold : hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform vec4 shade_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float shade_softness : hint_range(0.0, 1.0, 0.001) = 0.01;

vec2 get_UV(vec2 uv) {
	vec2 chunk_pos = chunk_position + mesh_size / 2.0;
	chunk_pos /= mesh_size;
	return chunk_pos + uv * (chunk_size / mesh_size.x);
}

void vertex() {
	VERTEX.y += texture(heightmap, get_UV(UV)).r * terrain_amplitude;
}

void fragment() {
	ALBEDO = texture(albedo, get_UV(UV)).rgb;
}

void light() {
	vec3 normal = texture(normalmap, UV).rgb * vec3(2.0, 2.0, 1.0) - vec3(1.0, 1.0, 1.0);
	float ratio = dot(normal, LIGHT);
	
 	vec4 base = texture(albedo, UV).rgba;
	vec4 shade = base * shade_color.rgba;
	
	float shade_value = smoothstep(shade_threshold - shade_softness ,shade_threshold + shade_softness, ratio);
	
	vec4 diffuse = mix(shade, base, shade_value);
	
	//DIFFUSE_LIGHT = diffuse.rgb;
}
