shader_type canvas_item;
render_mode blend_add;
// (1.49.66) REDOMA DE PROTEÇÃO v2 — barreira azul/dourada que GIRA LENTAMENTE,
// com respiração sutil (zoom in/out) e um pequeno escudo azul sutil FIXO no
// centro (substitui a estrela dourada original). Blend aditivo => glow de
// VFX pintado à mão (identidade Super Magic FX), sem lavagem de cor na carta.

uniform sampler2D tex_barreira;
uniform float spin_speed : hint_range(0.0, 1.0) = 0.22;
uniform float breathe_amt : hint_range(0.0, 0.08) = 0.016;
uniform float center_alpha : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	// respiração: zoom in/out MUITO sutil
	float br = 1.0 + breathe_amt * sin(TIME * 1.5);
	vec2 cs = c / br;
	// rotação LENTA do escudo de energia
	float a = TIME * spin_speed;
	vec2 cr = vec2(cs.x * cos(a) - cs.y * sin(a), cs.x * sin(a) + cs.y * cos(a)) + 0.5;
	vec4 bar = texture(tex_barreira, cr);
	float fade = 1.0 - smoothstep(0.94, 1.0, r);
	// centro quase transparente => carta 100% legível por baixo
	float membrane = smoothstep(0.30, 0.88, r);
	float alpha = bar.a * fade * mix(center_alpha, 1.0, membrane);
	vec3 col = bar.rgb;
	// (1.49.69) o escudo central virou camada separada (TextureRect centrado
	// por layout no champion_view) => centragem estrutural, não por UV.
	COLOR = vec4(col, alpha);
}
