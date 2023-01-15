shader_type spatial;
render_mode unshaded;
// auto
uniform float terrain_amplitude = 100.0;

// manual
uniform sampler2D albedo: filter_nearest, repeat_enable; 
uniform sampler2D heightmap: filter_nearest, repeat_disable;
uniform sampler2D normalmap;

uniform float shade_threshold : hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform vec4 shade_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float shade_softness : hint_range(0.0, 1.0, 0.001) = 0.01;

void vertex() {
    VERTEX.y += texture(heightmap, UV).r * terrain_amplitude;
}

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	//ALBEDO = vec3(0.0);
}

void light() {
	//vec3 normal = texture(normalmap, UV).rgb * vec3(2.0, 2.0, 1.0) - vec3(1.0, 1.0, 1.0);
	//float ratio = dot(normal, LIGHT);
	
 	//vec4 base = texture(albedo, UV).rgba;
	//vec4 shade = base * shade_color.rgba;
	
	//float shade_value = smoothstep(shade_threshold - shade_softness ,shade_threshold + shade_softness, ratio);
	
	//vec4 diffuse = mix(shade, base, shade_value);
	
	//DIFFUSE_LIGHT = diffuse.rgb;
}
