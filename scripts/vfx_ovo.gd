class_name OvoFX
extends Node2D
## (1.49.95) HABILIDADE INVOCAR DRAGÃO — sequencia de 20 FRAMES pintados
## (assets/OVO_SEQ_F01..F20.png, sprite sheet fornecido pelo dono: o ovo
## aparece, racha, choca e vira luz) reproduzida SOMENTE sobre o slot onde o
## FILHOTE DE DRAGÃO vai cair (nada de flash/pilar na tela inteira): cadencia
## variavel (materializa lento -> fissuras acelerando -> choca rapido), com
## polimento local: sombra no chao, anel runico do tamanho do slot, bob
## suave, micro-tremor nas fissuras, clarao CONTIDO no slot, anel de choque
## pequeno, lascas e faiscas locais. Contrato: burst ~1.32 s (invoca o
## Filhote), finished 1.5 s. Uso: add_child(fx); fx.setup(centro_do_slot)

signal burst
signal finished

const DUR := 1.5
const BURST_AT := 1.32
const CELL_H := 256.0
const SCALE := 0.55           # 256 px * 0.55 = 140 px = altura da carta (slot)

## cadencia profissional: instante em que cada frame (0..19) entra
const FRAME_AT := [
	0.00, 0.11, 0.22, 0.33, 0.44,          # 1-5  materializa (lento)
	0.55, 0.65, 0.75, 0.85, 0.95,          # 6-10 fissuras finas
	1.03, 1.10, 1.16, 1.22, 1.27,          # 11-15 fissuras fundas (acelera)
	1.32, 1.37, 1.42, 1.46, 1.50,          # 16-20 choca + luz (rapido)
]

var _t := 0.0
var _done := false
var _bursted := false
var _started := false
var _frame := -1

var _seq: Sprite2D
var _shadow: Sprite2D
var _rune: Sprite2D
var _glow: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _shards: Array = []
var _sparkles: CPUParticles2D

const FRAMES := [
	preload("res://assets/OVO_SEQ_F01.png"), preload("res://assets/OVO_SEQ_F02.png"),
	preload("res://assets/OVO_SEQ_F03.png"), preload("res://assets/OVO_SEQ_F04.png"),
	preload("res://assets/OVO_SEQ_F05.png"), preload("res://assets/OVO_SEQ_F06.png"),
	preload("res://assets/OVO_SEQ_F07.png"), preload("res://assets/OVO_SEQ_F08.png"),
	preload("res://assets/OVO_SEQ_F09.png"), preload("res://assets/OVO_SEQ_F10.png"),
	preload("res://assets/OVO_SEQ_F11.png"), preload("res://assets/OVO_SEQ_F12.png"),
	preload("res://assets/OVO_SEQ_F13.png"), preload("res://assets/OVO_SEQ_F14.png"),
	preload("res://assets/OVO_SEQ_F15.png"), preload("res://assets/OVO_SEQ_F16.png"),
	preload("res://assets/OVO_SEQ_F17.png"), preload("res://assets/OVO_SEQ_F18.png"),
	preload("res://assets/OVO_SEQ_F19.png"), preload("res://assets/OVO_SEQ_F20.png"),
]


func setup(at: Vector2) -> void:
	position = at
	z_index = 86
	_started = true
	# ---- sombra contida no slot
	_shadow = Sprite2D.new()
	_shadow.texture = Vfx.radial("ovo2_shadow", 90, Color(0.0, 0.0, 0.0, 0.5), 0.1)
	_shadow.scale = Vector2(1.0, 0.3)
	_shadow.position = Vector2(0, 62)
	_shadow.modulate = Color(1, 1, 1, 0)
	add_child(_shadow)
	# ---- anel rúnico do tamanho do slot
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("ovo2_rune", 110, Color(0.35, 0.95, 0.75, 0.8), 0.05)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.0, 0.34)
	_rune.position = Vector2(0, 62)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	# ---- brilho local sob o ovo
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("ovo2_glow", 130, Color(1.0, 0.75, 0.30, 0.6), 0.1)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	_glow.position = Vector2(0, 10)
	add_child(_glow)
	# ---- a sequencia de 20 frames
	_seq = Sprite2D.new()
	_seq.texture = FRAMES[0]
	_seq.centered = true
	_seq.scale = Vector2(SCALE, SCALE)
	_seq.modulate = Color(1, 1, 1, 0)
	_seq.position = Vector2(0, -4)
	add_child(_seq)
	# ---- clarão CONTIDO no slot (choco)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("ovo2_flash", 150, Color(1.0, 0.92, 0.60, 0.85), 0.22)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	# ---- anel de choque pequeno (choco)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ovo2_ring", 120, Color(1.0, 0.88, 0.50, 0.85), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	# ---- lascas locais voando no choco
	for i in 6:
		var sh := Sprite2D.new()
		sh.texture = Vfx.spark(16, Color(0.95, 0.75, 0.40))
		sh.material = Vfx.add_mat()
		sh.modulate = Color(1, 1, 1, 0)
		add_child(sh)
		_shards.append({
			"n": sh,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, -0.1)).normalized(),
			"sp": randf_range(60.0, 110.0),
			"sc": randf_range(0.7, 1.3),
		})
	# ---- faiscas douradas contidas
	_sparkles = CPUParticles2D.new()
	_sparkles.texture = Vfx.spark(18, Color(1.0, 0.88, 0.50))
	_sparkles.material = Vfx.add_mat()
	_sparkles.emitting = false
	_sparkles.amount = 26
	_sparkles.lifetime = 0.5
	_sparkles.explosiveness = 0.9
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 40.0
	_sparkles.initial_velocity_max = 110.0
	_sparkles.gravity = Vector2(0, 180)
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.1
	add_child(_sparkles)


func _frame_index(t: float) -> int:
	var idx := 0
	for i in FRAME_AT.size():
		if t >= FRAME_AT[i]:
			idx = i
	return idx


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ================= frames da sequencia
	var idx := _frame_index(t)
	if idx != _frame:
		_frame = idx
		_seq.texture = FRAMES[idx]
	# entrada suave do ovo (fade + scale-in) + bob
	var mk: float = clampf(t / 0.30, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, Ease.out_cubic(mk))
	var sc: float = SCALE * lerpf(0.72, 1.0, Ease.out_cubic(mk))
	# micro-tremor nas fissuras (frames 6..15)
	var tremor: float = clampf((t - 0.5) / 0.6, 0.0, 1.0) * (1.0 if t < 1.25 else 0.0)
	var jx: float = randf_range(-1, 1) * 1.6 * tremor
	var jy: float = randf_range(-1, 1) * 1.1 * tremor
	_seq.scale = Vector2(sc, sc)
	_seq.position = Vector2(jx, -4.0 + jy + sin(t * 3.2) * 2.0 * mk)
	# ================= chão: sombra + anel + brilho (tudo local)
	_shadow.modulate = Color(1, 1, 1, mk * 0.75)
	_rune.modulate = Color(1, 1, 1, sin(mk * PI) * 0.7 if t < 0.75 else 0.25 + 0.35 * tremor * absf(sin(t * 12.0)))
	_rune.rotation += delta * 0.9
	_glow.modulate = Color(1, 1, 1, mk * (0.30 + 0.15 * sin(t * 10.0)) + 0.35 * tremor)
	# ================= choco contido (BURST_AT)
	if t >= BURST_AT:
		var hk: float = clampf((t - BURST_AT) / 0.16, 0.0, 1.0)
		var hf: float = clampf(1.0 - (t - BURST_AT - 0.16) / 0.18, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, hk * hf * 0.85)
		_flash.scale = Vector2.ONE * (0.5 + hk * 0.7)
		_ring.modulate = Color(1, 1, 1, hk * hf * 0.8)
		_ring.scale = Vector2(0.35 + hk * 0.85, 0.14 + hk * 0.34)
		if not _sparkles.emitting:
			_sparkles.emitting = true
			_sparkles.restart()
		for sh in _shards:
			var n: Sprite2D = sh["n"]
			var st: float = t - BURST_AT
			var life := 0.4
			if st > life:
				n.modulate = Color(1, 1, 1, 0)
				continue
			n.position = Vector2(0, -4) + sh["dir"] * sh["sp"] * st + Vector2(0, 130.0 * st * st)
			n.scale = Vector2.ONE * sh["sc"]
			n.modulate = Color(1, 1, 1, clampf(1.0 - st / life, 0.0, 1.0))
	if t >= BURST_AT and not _bursted:
		_bursted = true
		burst.emit()
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv
