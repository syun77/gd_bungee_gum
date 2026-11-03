shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float strength = 3.0;
uniform float opacity = 0.3;

void fragment() {
	vec2 offset = UV * 2.0 - 1.0;
	float distance_from_center = length(offset);
	float radius = mix(0.04, 0.88, 1.0 - pow(1.0 - progress, 2.0));
	float band = exp(-pow((distance_from_center - radius) / 0.065, 2.0));
	float envelope = smoothstep(0.0, 0.06, progress) * pow(1.0 - progress, 2.0);
	vec2 direction = offset / max(distance_from_center, 0.001);
	vec2 sample_uv = clamp(SCREEN_UV - direction * SCREEN_PIXEL_SIZE * strength * band * envelope, SCREEN_PIXEL_SIZE, vec2(1.0) - SCREEN_PIXEL_SIZE);
	vec3 background = texture(screen_texture, sample_uv).rgb;
	vec3 rim = mix(background, vec3(1.0, 0.68, 0.85), opacity * band * envelope);
	COLOR = vec4(rim, band * envelope);
}
