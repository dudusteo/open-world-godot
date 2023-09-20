shader_type fog;

uniform vec3 fog_color : source_color;
uniform float fog_near_cutoff;
uniform float fog_far_cutoff;

void fog() {
    ALBEDO = fog_color;
    float dist = distance(UVW, vec3(0.5));
    

	DENSITY = smoothstep(fog_near_cutoff, fog_far_cutoff, dist);
	
   
}