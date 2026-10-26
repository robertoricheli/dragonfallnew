class_name OvoFX
extends Node2D
## (1.50.2) HABILIDADE/CARTA TALENTO INVOCAR DRAGÃO — MESMO roteiro/animação,
## agora com TEXTURAS PINTADAS semi-3D estilo Hearthstone (iguais à linguagem
## da BAFORADA VENENOSA): 4 estados (casca teal com escamas e faixas rúnicas
## -> fissuras finas -> fissuras fundas com luz -> casca aberta com miolo de
## luz), recortadas do fundo preto com keying profissional. Roteiro: materializa no SLOT do Filhote com espiral de faíscas e anel
## rúnico, treme cada vez mais forte (squash), racha com clarões, e CHOCA com
## explosão, anel de choque, lascas, PILAR de energia e faíscas — contido no
## slot (<= 112x132 px), 2,0 s; burst em 1,9 s -> o Filhote surge em seguida.
## Uso: add_child(fx); fx.setup(centro_do_slot)

signal burst
signal finished

const DUR := 2.0
const BURST_AT := 1.9
const MAX_W := 112.0
const MAX_H := 132.0
const P2_AT := 0.70
const P3_AT := 0.95
const HATCH_AT := 1.40
const TW := 112
const TH := 140

var _t := 0.0
var _done := false
var _bursted := false
var _started := false
var _state := -1
var _state_at := -1.0
var _scale := 1.0

var _egg_a: Sprite2D
var _egg_b: Sprite2D
var _showing_a := true
var _shadow: Sprite2D
var _rune: Sprite2D
var _glow: Sprite2D
var _rays: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _beam: Sprite2D
var _swirl: Array = []
var _orbit: Array = []
var _shards: Array = []
var _dust: CPUParticles2D
var _sparkles: CPUParticles2D

const TEX_P1 := preload("res://assets/OVO_TEX_P1.png")
const TEX_P2 := preload("res://assets/OVO_TEX_P2.png")
const TEX_P3 := preload("res://assets/OVO_TEX_P3.png")
const TEX_P4 := preload("res://assets/OVO_TEX_P4.png")


static func egg_tex(level: int) -> Texture2D:
	return [TEX_P1, TEX_P2, TEX_P3, TEX_P4][level]


# ------------------------------------------------------------------ setup
func setup(at: Vector2) -> void:
	position = at
	z_index = 86
	_started = true
	_scale = minf(MAX_W / float(TEX_P1.get_width()), MAX_H / float(TEX_P1.get_height()))
	_shadow = Sprite2D.new()
	_shadow.texture = Vfx.radial("ovo5_shadow", 90, Color(0.0, 0.0, 0.0, 0.5), 0.1)
	_shadow.scale = Vector2(1.0, 0.3)
	_shadow.position = Vector2(0, 58)
	_shadow.modulate = Color(1, 1, 1, 0)
	add_child(_shadow)
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("ovo5_rune", 105, Color(0.35, 0.95, 0.75, 0.8), 0.05)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.0, 0.34)
	_rune.position = Vector2(0, 58)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("ovo5_glow", 140, Color(1.0, 0.78, 0.32, 0.65), 0.1)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	_glow.position = Vector2(0, 6)
	add_child(_glow)
	_egg_a = Sprite2D.new()
	_egg_a.texture = egg_tex(0)
	_egg_a.centered = true
	_egg_a.scale = Vector2(_scale, _scale)
	_egg_a.modulate = Color(1, 1, 1, 0)
	add_child(_egg_a)
	_egg_b = Sprite2D.new()
	_egg_b.texture = egg_tex(0)
	_egg_b.centered = true
	_egg_b.scale = Vector2(_scale, _scale)
	_egg_b.modulate = Color(1, 1, 1, 0)
	add_child(_egg_b)
	_rays = Sprite2D.new()
	_rays.texture = Vfx.ring("ovo5_rays", 220, Color(1.0, 0.85, 0.45, 0.8), 0.03)
	_rays.material = Vfx.add_mat()
	_rays.modulate = Color(1, 1, 1, 0)
	add_child(_rays)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("ovo5_flash", 150, Color(1.0, 0.92, 0.60, 0.9), 0.22)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ovo5_ring", 115, Color(1.0, 0.88, 0.50, 0.85), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	_beam = Sprite2D.new()
	_beam.texture = Vfx.radial("ovo5_beam", 110, Color(1.0, 0.88, 0.50, 0.85), 0.12)
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
	for i in 4:
		var o := Sprite2D.new()
		o.texture = Vfx.spark(16, Color(0.55, 0.95, 0.80))
		o.material = Vfx.add_mat()
		o.modulate = Color(1, 1, 1, 0)
		add_child(o)
		_orbit.append({"n": o, "a": TAU * float(i) / 4.0, "r": randf_range(46.0, 62.0)})
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
	_dust.texture = Vfx.radial("ovo5_dust", 36, Color(0.55, 0.45, 0.35, 0.5), 0.05)
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


func _set_state(idx: int) -> void:
	if idx == _state:
		return
	_state = idx
	_state_at = _t
	var tex: Texture2D = egg_tex(idx)
	var incoming: Sprite2D = _egg_b if _showing_a else _egg_a
	incoming.texture = tex
	_showing_a = not _showing_a


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var mk: float = clampf(t / 0.35, 0.0, 1.0)
	if _state < 0:
		_set_state(0)
	var base_a: float = Ease.out_cubic(mk)
	var sc: float = _scale * lerpf(0.55, 1.0, Ease.out_cubic(mk))
	var tremor: float = clampf((t - 0.35) / 1.0, 0.0, 1.0) * (1.0 if t < HATCH_AT else 0.0)
	var jx: float = randf_range(-1, 1) * 3.0 * tremor * tremor
	var jy: float = randf_range(-1, 1) * 2.0 * tremor * tremor
	var squash: float = 1.0 + 0.05 * tremor * sin(t * 32.0)
	for e in [_egg_a, _egg_b]:
		e.scale = Vector2(sc * (2.0 - squash), sc * squash)
		e.rotation = randf_range(-1, 1) * 0.04 * tremor * tremor
		e.position = Vector2(jx, -4.0 + jy + sin(t * 3.1) * 2.0 * mk)
	if t >= HATCH_AT:
		_set_state(3)
	elif t >= P3_AT:
		_set_state(2)
	elif t >= P2_AT:
		_set_state(1)
	var incoming: Sprite2D = _egg_a if _showing_a else _egg_b
	var outgoing: Sprite2D = _egg_b if _showing_a else _egg_a
	var fk: float = base_a if _state == 0 else clampf((t - _state_at) / 0.08, 0.0, 1.0)
	incoming.modulate.a = fk
	outgoing.modulate.a = (1.0 - fk) if _state > 0 else 0.0
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
	var orb_a: float = clampf((t - P3_AT) / 0.2, 0.0, 1.0) * (1.0 if t < HATCH_AT else 0.0)
	for o in _orbit:
		var n2: Sprite2D = o["n"]
		var a2: float = float(o["a"]) + t * 4.5
		n2.position = Vector2(cos(a2) * float(o["r"]), -4.0 + sin(a2) * float(o["r"]) * 0.5)
		n2.modulate = Color(1, 1, 1, orb_a * 0.85)
	_dust.emitting = tremor > 0.3 and t < HATCH_AT
	if t >= P3_AT and t < HATCH_AT + 0.15:
		var rk: float = clampf((t - P3_AT) / 0.2, 0.0, 1.0)
		_rays.modulate = Color(1, 1, 1, rk * (0.45 + 0.35 * absf(sin(t * 18.0))))
		_rays.rotation += delta * 1.6
		_rays.scale = Vector2.ONE * (0.5 + rk * 0.4)
	else:
		_rays.modulate = Color(1, 1, 1, 0)
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
