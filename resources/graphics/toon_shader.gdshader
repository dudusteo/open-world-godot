shader_type spatial;
render_mode ambient_light_disabled;

uniform sampler2D base_texture: source_color; 
uniform float shade_threshold : hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform vec4 shade_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float shade_softness : hint_range(0.0, 1.0, 0.001) = 0.01;

void vertex() {
}

void fragment() {
}

void light() {
	float ratio = dot(NORMAL, LIGHT);
	vec4 base = texture(base_texture, UV).rgba;
	vec4 shade = base * shade_color.rgba;
	float shade_value = smoothstep(shade_threshold - shade_softness ,shade_threshold + shade_softness, ratio);
	
	vec4 diffuse = mix(shade, base, shade_value);
	
	DIFFUSE_LIGHT = diffuse.rgb;
}

