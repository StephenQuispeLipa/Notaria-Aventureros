shader_type canvas_item;

uniform vec2 lens_center_px = vec2(-999.0, -999.0);
uniform float lens_radius_px = 28.0;
uniform vec2 viewport_size = vec2(570.0, 320.0);

void fragment() {
	vec2 screen_px = SCREEN_UV * viewport_size;
	float d = distance(screen_px, lens_center_px);
	if (d > lens_radius_px) {
		discard;
	}
}
