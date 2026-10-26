class_name OvoFX
extends Node2D
## (1.50.6) INVOCAR DRAGÃO (Habilidade + Talento) — sequencia de 67 frames do
## VÍDEO do dono ("FILHOTE DE DRAGÃO": só o ovo chocando), recortada do fundo
## branco com keying profissional + vinheta/janela central. MESMO roteiro:
## materializa no SLOT do Filhote (<= 112x132 px, nunca sobre outra carta),
## com sombra, anel rúnico, brilho, espiral de faíscas, tremor, e no CHOCO:
## clarão contido, anel de choque, lascas, PILAR de energia e faíscas.
## SOM atual mantido (crackle no nascimento + hatch no burst). 2,0 s;
## burst em 1,9 s -> o Filhote surge em seguida. Uso: fx.setup(centro_slot)

signal burst
signal finished

const DUR := 2.0
const BURST_AT := 1.9
const MAX_W := 112.0
const MAX_H := 132.0
const N_FRAMES := 67
const HATCH_AT := 1.40

var _t := 0.0
var _done := false
var _bursted := false
var _started := false
var _frame := -1
var _scale := 1.0

var _seq: Sprite2D
var _shadow: Sprite2D
var _rune: Sprite2D
var _glow: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _beam: Sprite2D
var _swirl: Array = []
var _shards: Array = []
var _dust: CPUParticles2D
var _sparkles: CPUParticles2D

var _frames: Array = []


func _init() -> void:
	for i in N_FRAMES:
		_frames.append(load("res://assets/OVO2_F%02d.png" % (i + 1)))


func setup(at: Vector2) -> void:
	position = at
	z_index = 86
	_started = true
	var tex: Texture2D = _frames[0]
	_scale = minf(MAX_W / float(tex.get_width()), MAX_H / float(tex.get_height()))
	_shadow = Sprite2D.new()
	_shadow.texture = Vfx.radial("ovo6_shadow", 90, Color(0.0, 0.0, 0.0, 0.5), 0.1)
	_shadow.scale = Vector2(1.0, 0.3)
	_shadow.position = Vector2(0, 58)
	_shadow.modulate = Color(1, 1, 1, 0)
	add_child(_shadow)
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("ovo6_rune", 105, Color(0.35, 0.95, 0.75, 0.8), 0.05)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.0, 0.34)
	_rune.position = Vector2(0, 58)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("ovo6_glow", 140, Color(1.0, 0.78, 0.32, 0.65), 0.1)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	_glow.position = Vector2(0, 6)
	add_child(_glow)
	_seq = Sprite2D.new()
	_seq.texture = _frames[0]
	_seq.centered = true
	_seq.scale = Vector2(_scale, _scale)
	_seq.modulate = Color(1, 1, 1, 0)
	add_child(_seq)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("ovo6_flash", 150, Color(1.0, 0.92, 0.60, 0.9), 0.22)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ovo6_ring", 115, Color(1.0, 0.88, 0.50, 0.85), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	_beam = Sprite2D.new()
	_beam.texture = Vfx.radial("ovo6_beam", 110, Color(1.0, 0.88, 0.50, 0.85), 0.12)
	_beam.material = Vfx.add_mat()
	_beam.scale = Vector2(0.6, 0.1)
	_beam.modulate = Color(1, 1, 1, 0)
	add_child(_beam)
	for i in 6:
		var s := Sprite2D.new()
		s.texture = Vfx.spark(24, Color(1.0, 0.85, 0.45))
		s.material = Vfx.add_mat()
		s.modulate = Color(1, 1, 1, 0)
		add_child(s)
		_swirl.append({"n": s, "a": TAU * float(i) / 6.0})
	for i in 8:
		var sh := Sprite2D.new()
		sh.texture = Vfx.spark(18, Color(0.55, 0.95, 0.80))
		sh.material = Vfx.add_mat()
		sh.modulate = Color(1, 1, 1, 0)
		add_child(sh)
		_shards.append({
			"n": sh,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, -0.1)).normalized(),
			"sp": randf_range(70.0, 130.0),
			"rot": randf_range(-10.0, 10.0),
			"sc": randf_range(0.7, 1.4),
		})
	_dust = CPUParticles2D.new()
	_dust.texture = Vfx.radial("ovo6_dust", 36, Color(0.55, 0.45, 0.35, 0.5), 0.05)
	_dust.emitting = false
	_dust.amount = 20
	_dust.lifetime = 0.55
	_dust.direction = Vector2(0, -1)
	_dust.spread = 55.0
	_dust.initial_velocity_min = 18.0
	_dust.initial_velocity_max = 50.0
	_dust.gravity = Vector2(0, 70)
	_dust.scale_amount_min = 0.7
	_dust.scale_amount_max = 1.6
	_dust.position = Vector2(0, 54)
	add_child(_dust)
	_sparkles = CPUParticles2D.new()
	_sparkles.texture = Vfx.spark(20, Color(1.0, 0.88, 0.50))
	_sparkles.material = Vfx.add_mat()
	_sparkles.emitting = false
	_sparkles.amount = 30
	_sparkles.lifetime = 0.6
	_sparkles.explosiveness = 0.9
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 50.0
	_sparkles.initial_velocity_max = 130.0
	_sparkles.gravity = Vector2(0, 200)
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.2
	add_child(_sparkles)


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
	var mk: float = clampf(t / 0.3, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, Ease.out_cubic(mk))
	var tremor: float = clampf((t - 0.35) / 1.0, 0.0, 1.0) * (1.0 if t < HATCH_AT else 0.0)
	var sc: float = _scale * lerpf(0.7, 1.0, Ease.out_cubic(mk)) * (1.0 + 0.02 * tremor * sin(t * 30.0))
	_seq.scale = Vector2(sc, sc)
	_seq.position = Vector2(randf_range(-1, 1) * 2.4 * tremor * tremor, -4.0 + randf_range(-1, 1) * 1.6 * tremor * tremor + sin(t * 3.1) * 2.0 * mk)
	_shadow.modulate = Color(1, 1, 1, mk * 0.75)
	_rune.modulate = Color(1, 1, 1, (sin(mk * PI) * 0.7 if t < 0.8 else 0.25 + 0.4 * tremor * absf(sin(t * 12.0))))
	_rune.rotation += delta * 0.9
	_glow.modulate = Color(1, 1, 1, mk * (0.3 + 0.15 * sin(t * 10.0)) + 0.45 * tremor)
	for s in _swirl:
		var n: Sprite2D = s["n"]
		var a: float = float(s["a"]) + t * 7.0
		var r: float = lerpf(80.0, 24.0, mk)
		n.position = Vector2(cos(a) * r, -4.0 + sin(a) * r * 0.45)
		n.modulate = Color(1, 1, 1, sin(mk * PI) * 0.9)
	_dust.emitting = tremor > 0.3 and t < HATCH_AT
	if t >= HATCH_AT:
		var hk: float = clampf((t - HATCH_AT) / 0.22, 0.0, 1.0)
		var hf: float = clampf(1.0 - (t - HATCH_AT - 0.22) / 0.3, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, hk * hf * 0.9)
		_flash.scale = Vector2.ONE * (0.5 + hk * 0.8)
		_ring.modulate = Color(1, 1, 1, hk * hf * 0.85)
		_ring.scale = Vector2(0.35 + hk * 0.9, 0.14 + hk * 0.36)
		_beam.modulate = Color(1, 1, 1, hk * clampf(1.0 - (t - BURST_AT) / 0.15, 0.0, 1.0) * 0.85)
		_beam.scale = Vector2(0.6 + 0.2 * sin(t * 30.0), lerpf(0.1, 3.4, Ease.out_cubic(hk)))
		_beam.position = Vector2(0, lerpf(16.0, -120.0, Ease.out_cubic(hk)))
		if not _sparkles.emitting:
			_sparkles.emitting = true
			_sparkles.restart()
		for sh in _shards:
			var n3: Sprite2D = sh["n"]
			var st: float = t - HATCH_AT
			var life := 0.5
			if st > life:
				n3.modulate = Color(1, 1, 1, 0)
				continue
			n3.position = Vector2(0, -4) + sh["dir"] * sh["sp"] * st + Vector2(0, 150.0 * st * st)
			n3.rotation = sh["rot"] * st
			n3.scale = Vector2.ONE * sh["sc"]
			n3.modulate = Color(1, 1, 1, clampf(1.0 - st / life, 0.0, 1.0))
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
