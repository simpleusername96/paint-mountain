shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform sampler2D paint_mask : filter_linear, repeat_disable;
uniform sampler2D target_mask : filter_nearest, repeat_disable;
uniform vec4 rock_color : source_color = vec4(0.788235, 0.803922, 0.827451, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.556863, 0.584314, 0.623529, 1.0);
uniform vec4 paint_color : source_color = vec4(0.03, 0.38, 1.0, 1.0);

varying float paintable_surface;
varying float upwardness;

void vertex() {
	paintable_surface = COLOR.r;
	upwardness = clamp(NORMAL.y, 0.0, 1.0);
}

void fragment() {
	vec2 texel = vec2(1.0 / 512.0);
	float target = step(0.5, texture(target_mask, UV).r) * paintable_surface;
	float center = texture(paint_mask, UV).r * target;
	float neighbor = max(
		max(texture(paint_mask, UV + vec2(texel.x * 1.5, 0.0)).r, texture(paint_mask, UV - vec2(texel.x * 1.5, 0.0)).r),
		max(texture(paint_mask, UV + vec2(0.0, texel.y * 1.5)).r, texture(paint_mask, UV - vec2(0.0, texel.y * 1.5)).r)
	) * target;
	float painted = smoothstep(0.08, 0.32, center);
	float dark_rim = clamp(smoothstep(0.06, 0.24, neighbor) - painted, 0.0, 1.0);
	float wet_core = smoothstep(0.34, 0.72, center);
	float rock_luma = dot(rock_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 nontarget_rock = mix(rock_color.rgb, vec3(rock_luma), 0.20) * 0.88;
	vec3 classified_rock = mix(nontarget_rock, rock_color.rgb, target);
	vec3 dry_rock = mix(shadow_tint.rgb, classified_rock, 0.35 + 0.65 * upwardness);
	vec3 painted_color = mix(paint_color.rgb * 0.58, paint_color.rgb, painted);
	ALBEDO = mix(dry_rock, painted_color, max(painted, dark_rim));
	ROUGHNESS = mix(0.88, 0.24, painted);
	SPECULAR = mix(0.32, 0.72, wet_core);
	METALLIC = 0.0;
}
