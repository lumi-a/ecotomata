shader_type spatial;

uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.5, 0.8);
uniform float wave_speed = 0.1;
uniform float wave_strength = 0.2;
uniform sampler2D noise_texture;

void fragment() {
	// Create wave effect using UV coordinates and time
	vec2 uv = UV;
	uv.x += TIME * wave_speed;
	
	// Sample noise texture for wave height
	float noise = texture(noise_texture, uv).r;
	
	// Apply wave displacement
	float wave = noise * wave_strength;
	
	// Final color with transparency
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	
	// Add fresnel effect for more realistic water look
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
	ALPHA *= fresnel + 0.5;
	
	// Add some roughness and metallic properties
	ROUGHNESS = 0.1;
	METALLIC = 0.3;
}