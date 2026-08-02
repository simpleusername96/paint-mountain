shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D paint_mask : filter_linear, repeat_disable;
uniform vec4 rock_color : source_color = vec4(0.36, 0.38, 0.42, 1.0);
uniform vec4 paint_color : source_color = vec4(0.03, 0.38, 1.0, 1.0);

void fragment() {
	float paint_amount = texture(paint_mask, UV).r;
	float paint_mix = smoothstep(0.08, 0.32, paint_amount);
	ALBEDO = mix(rock_color.rgb, paint_color.rgb, paint_mix);
	ROUGHNESS = mix(0.92, 0.27, paint_mix);
	METALLIC = mix(0.0, 0.12, paint_mix);
}
