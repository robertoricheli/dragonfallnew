class_name RapidezFX
extends Node2D
## (1.50.6) RAPIDEZ (Habilidade) — animação DIVERTIDA de velocidade (1,5 s),
## 1 s após a carta entrar em campo: agachada de partida com poeira, SEIS
## pós-imagens da carta acendem em ÓRBITA ao redor dela (flipbook de
## movimento), anel de velocidade tracejado girando, raios zig-zag e
## saltinhos elásticos; no final, pose com starburst, confete de faíscas e
## anel de boom — tudo contido ao redor do slot. Contrato: finished em 1,5 s.
## Uso: add_child(fx); fx.setup(champion_view)

signal finished

const DUR := 1.5
const ORBIT_AT := 0.20
const POSE_AT := 1.10

var _t := 0.0
var _done := false
var _started := false
var _pose := false

var _view: ChampionView
var _pos := Vector2.ZERO
var _size := Vector2(100, 140)
var _vscale := Vector2.ONE
var _base_pos := Vector2.ZERO
var _face_tex: Texture2D
var _ghosts: Array = []
var _ring: Sprite2D
var _dash_ring: Sprite2D
var _zigs: Array = []
var _dust: CPUParticles2D
var _burst: Sprite2D
var _confetti: Array = []
var _boom: Sprite2D


func setup(v: ChampionView) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 92
	_started = true
	_vscale = v.scale
	_base_pos = v.position
	_size = v.size * v.scale
	_pos = v.get_global_rect().get_center()
	_face_tex = v._face.texture if v._face != null else null
	# ---- 6 pós-imagens em órbita
	for i in 6:
		var g := Sprite2D.new()
		if _face_tex != null:
			g.texture = _face_tex
		g.centered = true
		g.scale = _vscale * 0.92
		g.modulate = Color(0.55, 0.85, 1.0, 0)
		var a := TAU * float(i) / 6.0
		g.position = _pos + Vector2(cos(a) * 74.0, sin(a) * 46.0)
		add_child(g)
		_ghosts.append({"n": g, "i": i})
	# ---- anel de velocidade tracejado
	_dash_ring = Sprite2D.new()
	_dash_ring.texture = Vfx.ring("rap_dash", 170, Color(0.45, 0.85, 1.0, 0.8), 0.045)
	_dash_ring.material = Vfx.add_mat()
	_dash_ring.scale = Vector2(1.0, 0.62)
	_dash_ring.modulate = Color(1, 1, 1, 0)
	_dash_ring.position = _pos
	add_child(_dash_ring)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("rap_ring", 130, Color(1.0, 0.90, 0.40, 0.85), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.position = _pos
	add_child(_ring)
	# ---- raios zig-zag
	for i in 5:
		var z := Sprite2D.new()
		z.texture = Vfx.spark(26, Color(1.0, 0.95, 0.55))
		z.material = Vfx.add_mat()
		z.modulate = Color(1, 1, 1, 0)
		z.scale = Vector2(1.6, 0.35)
		add_child(z)
		_zigs.append({"n": z, "a": TAU * float(i) / 5.0 + 0.4})
	# ---- poeira de partida
	_dust = CPUParticles2D.new()
	_dust.texture = Vfx.radial("rap_dust", 40, Color(0.85, 0.80, 0.70, 0.5), 0.05)
	_dust.emitting = false
	_dust.amount = 22
	_dust.lifetime = 0.5
	_dust.direction = Vector2(0, -1)
	_dust.spread = 75.0
	_dust.initial_velocity_min = 26.0
	_dust.initial_velocity_max = 70.0
	_dust.gravity = Vector2(0, 90)
	_dust.scale_amount_min = 0.8
	_dust.scale_amount_max = 1.7
	_dust.position = _pos + Vector2(0, _size.y / 2.0 - 6.0)
	add_child(_dust)
	# ---- starburst + boom + confete da pose final
	_burst = Sprite2D.new()
	_burst.texture = Vfx.radial("rap_burst", 170, Color(1.0, 0.95, 0.60, 0.9), 0.18)
	_burst.material = Vfx.add_mat()
	_burst.modulate = Color(1, 1, 1, 0)
	_burst.position = _pos
	add_child(_burst)
	_boom = Sprite2D.new()
	_boom.texture = Vfx.ring("rap_boom", 150, Color(0.55, 0.90, 1.0, 0.9), 0.06)
	_boom.material = Vfx.add_mat()
	_boom.modulate = Color(1, 1, 1, 0)
	_boom.position = _pos
	add_child(_boom)
	for i in 10:
		var c := Sprite2D.new()
		c.texture = Vfx.spark(int(randf_range(10, 18)), [Color(1.0, 0.85, 0.35), Color(0.45, 0.85, 1.0), Color(1.0, 0.55, 0.75)][i % 3])
		c.material = Vfx.add_mat()
		c.modulate = Color(1, 1, 1, 0)
		add_child(c)
		_confetti.append({
			"n": c,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, -0.1)).normalized(),
			"sp": randf_range(60.0, 130.0),
			"rot": randf_range(-8.0, 8.0),
		})


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---- partida: agachada + poeira
	if t < ORBIT_AT:
		if is_instance_valid(_view):
			_view.scale = _vscale * Vector2(1.06, 0.92)
		_dust.emitting = t > 0.06
	# ---- órbita de pós-imagens + anel + zig-zags + saltinhos
	elif t < POSE_AT:
		_dust.emitting = false
		if is_instance_valid(_view):
			var hop := absf(sin((t - ORBIT_AT) * 10.0)) * 5.0
			_view.scale = _vscale
			_view.position = _base_pos + Vector2(0, -hop)
		var oi := int((t - ORBIT_AT) / 0.15) % 6
		for g in _ghosts:
			var n: Sprite2D = g["n"]
			n.modulate = Color(0.55, 0.85, 1.0, 0.34 if int(g["i"]) == oi else 0.0)
		_dash_ring.modulate = Color(1, 1, 1, 0.55 + 0.2 * sin(t * 20.0))
		_dash_ring.rotation += delta * 6.5
		for z in _zigs:
			var n2: Sprite2D = z["n"]
			var a: float = float(z["a"]) + t * 5.0
			n2.position = _pos + Vector2(cos(a) * 62.0, sin(a) * 40.0)
			n2.rotation = a + PI / 2
			n2.modulate = Color(1, 1, 1, 0.5 + 0.4 * sin(t * 26.0 + a))
	# ---- pose final: starburst + boom + confete
	else:
		if not _pose:
			_pose = true
			for g in _ghosts:
				(g["n"] as Sprite2D).modulate = Color(0.55, 0.85, 1.0, 0)
			_dash_ring.modulate = Color(1, 1, 1, 0)
			for z in _zigs:
				(z["n"] as Sprite2D).modulate = Color(1, 1, 1, 0)
			if is_instance_valid(_view):
				_view.position = _base_pos
				var tw := _view.create_tween()
				tw.tween_property(_view, "scale", _vscale * 1.10, 0.08)
				tw.tween_property(_view, "scale", _vscale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		var pk: float = clampf((t - POSE_AT) / 0.14, 0.0, 1.0)
		var pf: float = clampf(1.0 - (t - POSE_AT - 0.14) / 0.24, 0.0, 1.0)
		_burst.modulate = Color(1, 1, 1, pk * pf * 0.85)
		_burst.scale = Vector2.ONE * (0.5 + pk * 0.7)
		_boom.modulate = Color(1, 1, 1, pk * pf * 0.8)
		_boom.scale = Vector2(0.4 + pk * 0.8, 0.5 + pk * 0.9)
		var ck: float = (t - POSE_AT) / (DUR - POSE_AT)
		for c in _confetti:
			var n3: Sprite2D = c["n"]
			n3.position = _pos + c["dir"] * c["sp"] * ck + Vector2(0, 90.0 * ck * ck)
			n3.rotation = c["rot"] * ck
			n3.modulate = Color(1, 1, 1, clampf(1.0 - ck, 0.0, 1.0) * 0.9)
	if t >= DUR and not _done:
		_done = true
		if is_instance_valid(_view):
			_view.scale = _vscale
			_view.position = _base_pos
		finished.emit()
		queue_free()
