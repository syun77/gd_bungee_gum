shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength = 4.0;
uniform float opacity = 0.3;
uniform float quad_radius = 56.0;
varying vec2 radial_position;

void vertex() {
	radial_position = VERTEX / quad_radius;
}

void fragment() {
	vec2 offset = radial_position;
	float distance_from_center = length(offset);
	float radius = mix(0.04, 0.88, 1.0 - pow(1.0 - progress, 2.0));
	float ring_distance = distance_from_center - radius;
	float band = exp(-pow(ring_distance / 0.085, 2.0));
	float core = exp(-pow(ring_distance / 0.024, 2.0));
	// Stay readable during expansion, then fade smoothly at the outer edge.
	float envelope = smoothstep(0.0, 0.025, progress) * (1.0 - smoothstep(0.45, 1.0, progress));
	vec2 direction = offset / max(distance_from_center, 0.001);
	vec2 sample_uv = clamp(SCREEN_UV - direction * SCREEN_PIXEL_SIZE * strength * band * envelope, SCREEN_PIXEL_SIZE, vec2(1.0) - SCREEN_PIXEL_SIZE);
	vec3 background = texture(screen_texture, sample_uv).rgb;
	vec3 pink_rim = mix(vec3(1.0, 0.32, 0.62), vec3(1.0, 0.94, 0.98), core);
	vec3 rim = mix(background, pink_rim, opacity * (0.45 + 0.55 * core));
	// Apply the annulus once: double masking makes refraction disappear too early.
	COLOR = vec4(rim, envelope * smoothstep(0.001, 0.02, band));
}
