shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.05, 1.0) = 0.22;

void fragment() {
	vec2 d = abs(UV - vec2(0.5)) * 2.0;
	float edge_dist = max(d.x, d.y);
	float vig = smoothstep(1.0 - softness, 1.0, edge_dist);
	COLOR = vec4(vignette_color.rgb, vig * vignette_color.a * intensity);
}

