shader_type canvas_item;

uniform vec2 lens_center_px = vec2(-999.0, -999.0);
uniform float lens_radius_px = 28.0;
uniform vec4 tint_color : source_color = vec4(0.62, 0.20, 0.90, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.78;

varying vec2 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	float d = distance(v_local_pos, lens_center_px);
	if (d <= lens_radius_px) {
		COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * tint_color.rgb * 1.35 + tint_color.rgb * 0.25, tint_strength);
	}
}

