shader_type spatial;
render_mode unshaded;

uniform sampler2D paint_mask : filter_linear, repeat_disable;
uniform vec4 rock_color : source_color = vec4(0.5, 0.52, 0.56, 1.0);
uniform vec4 paint_color : source_color = vec4(0.03, 0.38, 1.0, 1.0);

varying float terrain_height;

void vertex() {
	terrain_height = VERTEX.y;
}

void fragment() {
	float paint_amount = texture(paint_mask, UV).r;
	float paint_mix = smoothstep(0.08, 0.32, paint_amount);
	vec2 facet_cell = floor(UV * vec2(56.0, 38.0));
	float facet_noise = fract(sin(dot(facet_cell, vec2(12.9898, 78.233))) * 43758.5453);
	float height_light = clamp(terrain_height / 85.0, 0.0, 1.0);
	float rock_shade = 0.88 + height_light * 0.1 + (facet_noise - 0.5) * 0.07;
	vec3 rock = rock_color.rgb * rock_shade;
	ALBEDO = mix(rock, paint_color.rgb, paint_mix);
	ROUGHNESS = mix(0.92, 0.27, paint_mix);
	METALLIC = mix(0.0, 0.12, paint_mix);
}
