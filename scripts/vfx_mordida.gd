class_name MordidaFX
extends Node2D
## (1.49.96) MORDIDA VENENOSA — animação vinda do VÍDEO do dono ("MORDIDA
## VENENOSA", 40 frames recortados do fundo branco com keying profissional):
## a MANDÍBULA VENENOSA verde aparece SOBRE O CAMPEÃO ALVO (0,5 s após a
## seleção, orquestrado pela Tela de Combate), morde com respingos e some em
## névoa — tamanho 120 px de largura, MENOR que as cartas em campo (140 px).
## Polimento local contido: brilho tóxico pulsante sob o alvo, anel de
## impacto e gotas de veneno no instante da mordida (~55% do vídeo) e poça
## que esmaece. DURAÇÃO do vídeo: 1.33 s. Contrato: finished -> resolve.
## Uso: add_child(fx); fx.setup(centro_do_alvo)

signal finished

const DUR := 1.33
const N_FRAMES := 40
const WIDTH := 120.0         # px em campo (< 140 da carta)
const BITE_AT := 0.73        # ~55%: instante da mordida (acertos locais)

var _t := 0.0
var _done := false
var _started := false
var _frame := -1
var _scale := 1.0
var _hit_played := false

var _seq: Sprite2D
var _glow: Sprite2D
var _ring: Sprite2D
var _pool: Sprite2D
var _drips: Array = []

var _frames: Array = []


func _init() -> void:
	for i in N_FRAMES:
		_frames.append(load("res://assets/MORDIDA_VENENOSA_F%02d.png" % (i + 1)))


func setup(at: Vector2) -> void:
	position = at
	z_index = 89
	_started = true
	var tex: Texture2D = _frames[0]
	_scale = WIDTH / float(tex.get_width())
	# ---- brilho tóxico sob o alvo
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("mord3_glow", 120, Color(0.35, 0.95, 0.18, 0.5), 0.09)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	_glow.position = Vector2(0, 8)
	add_child(_glow)
	# ---- o vídeo em frames
	_seq = Sprite2D.new()
	_seq.texture = _frames[0]
	_seq.centered = true
	_seq.scale = Vector2(_scale, _scale)
	_seq.modulate = Color(1, 1, 1, 0)
	add_child(_seq)
	# ---- anel de impacto da mordida
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("mord3_ring", 100, Color(0.55, 1.0, 0.30, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	# ---- poça de veneno que esmaece
	_pool = Sprite2D.new()
	_pool.texture = Vfx.radial("mord3_pool", 100, Color(0.30, 0.80, 0.12, 0.5), 0.1)
	_pool.material = Vfx.add_mat()
	_pool.scale = Vector2(1.0, 0.3)
	_pool.modulate = Color(1, 1, 1, 0)
	_pool.position = Vector2(0, 52)
	add_child(_pool)
	# ---- gotas de veneno no impacto
	for i in 6:
		var sp := Sprite2D.new()
		sp.texture = Vfx.spark(16, Color(0.55, 1.0, 0.30))
		sp.material = Vfx.add_mat()
		sp.modulate = Color(1, 1, 1, 0)
		add_child(sp)
		_drips.append({
			"n": sp,
			"dir": Vector2(randf_range(-1, 1), randf_range(-0.9, 0.2)).normalized(),
			"sp": randf_range(70.0, 150.0),
			"sc": randf_range(0.5, 1.1),
		})


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var k: float = clampf(t / DUR, 0.0, 1.0)
	var idx := mini(N_FRAMES - 1, int(k * N_FRAMES))
	if idx != _frame:
		_frame = idx
		_seq.texture = _frames[idx]
	# entrada/saída suave + pulsinho de "respiração" tóxica
	var mk: float = clampf(t / 0.15, 0.0, 1.0)
	var outk: float = clampf((t - (DUR - 0.15)) / 0.15, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, Ease.out_cubic(mk) * (1.0 - outk))
	var sc: float = _scale * lerpf(0.85, 1.0, Ease.out_cubic(mk)) * (1.0 + 0.02 * sin(t * 16.0))
	_seq.scale = Vector2(sc, sc)
	_seq.position = Vector2(0, sin(t * 6.0) * 1.2)
	# glow tóxico acompanha a presença
	_glow.modulate = Color(1, 1, 1, Ease.out_cubic(mk) * (1.0 - outk) * (0.45 + 0.2 * sin(t * 12.0)))
	# ---- acertos no instante da mordida
	if t >= BITE_AT:
		if not _hit_played:
			_hit_played = true
			Sfx.play("mordida_hit", position.x, 1.0)
		var ik: float = clampf((t - BITE_AT) / 0.12, 0.0, 1.0)
		var iff: float = clampf(1.0 - (t - BITE_AT - 0.12) / 0.18, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, ik * iff * 0.8)
		_ring.scale = Vector2(1.0, 0.6) * (0.3 + ik * 0.8)
		for d in _drips:
			var n: Sprite2D = d["n"]
			var st: float = t - BITE_AT
			var life := 0.4
			if st > life:
				n.modulate = Color(1, 1, 1, 0)
				continue
			n.position = d["dir"] * d["sp"] * st + Vector2(0, 200.0 * st * st)
			n.scale = Vector2.ONE * d["sc"]
			n.modulate = Color(1, 1, 1, clampf(1.0 - st / life, 0.0, 1.0))
	var pk: float = clampf((t - BITE_AT) / 0.25, 0.0, 1.0) * clampf(1.0 - (t - BITE_AT - 0.25) / 0.3, 0.0, 1.0)
	_pool.modulate = Color(1, 1, 1, pk * 0.6)
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv
