shader_type spatial;
render_mode cull_disabled, unshaded;

//auto
uniform vec3 character_position;

//manual
uniform float character_radius = 3.0;
uniform sampler2D character_distance_falloff_curve : hint_default_black;
uniform float character_push_strength = 1.0;
uniform vec4 tip_albedo: source_color;


void vertex() {
	float wind_shape = (NODE_POSITION_WORLD.x + NODE_POSITION_WORLD.z);
	float wind_movement = sin(wind_shape + TIME);
	float displacement_affect = (1.0 - UV.y);
	
	vec3 dir_to_character = character_position - MODEL_MATRIX[3].xyz;
	// uncomment the following line to have a horizontal only character push
	//	dir_to_character.y = 0.0;
	float distance_to_character = length(dir_to_character);
	float falloff = 1.0 - smoothstep(0.0, 1.0, distance_to_character/character_radius);
	// Because we operate in vertex space, we need to convert the direction to the character
	// in vertex space. Otherwise, it wouldn't work for rotated blades of grass.
	// comment the next line to observe how the blades are not all facing away from the character.
	dir_to_character = (inverse(MODEL_MATRIX) * vec4(dir_to_character, 0.0)).xyz;
	dir_to_character = normalize(dir_to_character);

	// sample the curve based on how far we are from the character, in normalized coordinates
	float falloff_curve = texture(character_distance_falloff_curve, vec2(falloff)).x;
	// direction to character is inverted because we want to point away from it
	VERTEX += normalize(-dir_to_character) * falloff_curve * character_push_strength * displacement_affect;
	VERTEX.x += displacement_affect * wind_movement * (1.0 - falloff_curve);
	
}

void fragment() {
	float weight = 1.0 - UV.y;
	vec3 color_ramp = mix(COLOR.rgb, tip_albedo.rgb, weight);
	ALBEDO = color_ramp;
}

