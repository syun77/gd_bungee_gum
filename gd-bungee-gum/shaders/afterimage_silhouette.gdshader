shader_type canvas_item;
render_mode unshaded;

varying vec4 silhouette_color;

void vertex() {
	silhouette_color = COLOR;
}

void fragment() {
	float source_alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(silhouette_color.rgb, source_alpha * silhouette_color.a);
}
