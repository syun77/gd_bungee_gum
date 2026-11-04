shader_type canvas_item;

varying vec4 tint;
uniform float shine : hint_range(0.0, 1.0) = 0.0;
uniform float yaw : hint_range(-0.56, 0.56) = 0.0;

void vertex() {
	tint = COLOR;
}

vec2 face_uv(vec2 uv, vec2 texel, float width, float turn) {
	vec2 point = uv - vec2(0.5);
	point.x /= width;
	// A little perspective distinguishes the near and far edges without tilting the stem.
	point.y *= 1.0 + point.x * turn * 0.18;
	vec2 source = point + vec2(0.5);
	return clamp((floor(source / texel) + vec2(0.5)) * texel, texel * 0.5, vec2(1.0) - texel * 0.5);
}

void fragment() {
	float turn = sin(yaw);
	// Compensate perspective compression: even at maximum yaw the face keeps 94% width.
	float width = max(0.94, mix(1.0, cos(yaw), 0.35));
	vec4 face = texture(TEXTURE, face_uv(UV, TEXTURE_PIXEL_SIZE, width, turn));
	vec4 side = vec4(0.0);
	vec2 depth = vec2(turn * 3.5 * TEXTURE_PIXEL_SIZE.x, 0.0);
	// Extrude behind the face into the existing transparent padding, at most two pixels.
	for (int i = 1; i <= 4; i++) {
		vec4 sample_pixel = texture(TEXTURE, face_uv(UV - depth * (float(i) / 4.0), TEXTURE_PIXEL_SIZE, width, turn));
		if (sample_pixel.a > side.a) {
			side = vec4(sample_pixel.rgb * vec3(0.65, 0.57, 0.65), sample_pixel.a);
		}
	}
	float highlight = smoothstep(0.62, 0.78, face.g)
		* (1.0 - smoothstep(0.30, 0.50, face.r - face.g));
	face.rgb = mix(face.rgb, vec3(1.0, 0.95, 0.86), highlight * shine * 0.45);
	face.rgb *= 1.0 - abs(turn) * 0.07;
	float alpha = face.a + side.a * (1.0 - face.a);
	vec3 color = (face.rgb * face.a + side.rgb * side.a * (1.0 - face.a)) / max(alpha, 0.0001);
	COLOR = tint * vec4(color, alpha);
}
