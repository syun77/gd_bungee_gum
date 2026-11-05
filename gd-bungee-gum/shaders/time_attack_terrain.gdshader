shader_type canvas_item;

void fragment() {
	vec3 edge_fill = vec3(121.0, 87.0, 71.0) / 255.0;
	COLOR = vec4(mix(edge_fill, COLOR.rgb, COLOR.a), 1.0);
}
