class_name AcelerarFX
extends Node2D
## (1.50.3) ACELERAÇÃO (Talento) — animação DIVERTIDA de velocidade (1,5 s),
## 1 s após a carta entrar em campo (orquestrado pela Tela de Combate):
## a carta dá DASHES curtinhos com PÓS-IMAGENS translúcidas dela mesma
## (zig-zag no próprio slot), linhas de velocidade coloridas rasgam ao redor,
## poeira cartoon nos pés, um BOOM sônico com anel duplo no dash final e
## sparkles de "turbo" no assentamento. Tudo CONTIDO no slot da carta.
## Contrato: finished em 1,5 s. Uso: add_child(fx); fx.setup(champion_view)

signal finished

const DUR := 1.5
const DASH1 := 0.25
const DASH2 := 0.60
const DASH3 := 0.95

var _t := 0.0
var _done := false
var _started := false
var _d1 := false
var _d2 := false
var _d3 := false

var _view: ChampionView
var _base := Vector2.ZERO
var _size := Vector2(100, 140)
var _vscale := Vector2.ONE
var _face_tex: Texture2D
var _ghosts: Array = []
var _streaks: Array = []
var _dust: CPUParticles2D
var _boom: Sprite2D
var _boom2: Sprite2D
var _sparkles: CPUParticles2D


func setup(v: ChampionView) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 92
	_started = true
	_vscale = v.scale
	_size = v.size * v.scale
	_base = v.global_position + _size / 2.0
	_face_tex = v._face.texture if v._face != null else null
	# ---- pós-imagens da carta (dash)
	for i in 3:
		var g := Sprite2D.new()
		if _face_tex != null:
			g.texture = _face_tex
		g.centered = true
		g.scale = _vscale
		g.modulate = Color(0.6, 0.9, 1.0, 0)
		g.position = _base
		add_child(g)
		_ghosts.append(g)
	# ---- linhas de velocidade
	for i in 6:
		var st := Sprite2D.new()
		st.texture = Vfx.radial("ace_streak", 70, Color(0.45, 0.85, 1.0, 0.8), 0.12)
		st.material = Vfx.add_mat()
		st.scale = Vector2(1.6 + randf() * 1.2, 0.10)
		st.modulate = Color(1, 1, 1, 0)
		add_child(st)
		_streaks.append({"n": st, "dy": randf_range(-52.0, 52.0), "ph": randf_range(0.0, 1.0)})
	# ---- poeira cartoon na base
	_dust = CPUParticles2D.new()
	_dust.texture = Vfx.radial("ace_dust", 40, Color(0.85, 0.80, 0.70, 0.5), 0.05)
	_dust.emitting = false
	_dust.amount = 24
	_dust.lifetime = 0.5
	_dust.direction = Vector2(0, -1)
	_dust.spread = 70.0
	_dust.initial_velocity_min = 30.0
	_dust.initial_velocity_max = 80.0
	_dust.gravity = Vector2(0, 90)
	_dust.scale_amount_min = 0.8
	_dust.scale_amount_max = 1.8
	_dust.position = _base + Vector2(0, _size.y / 2.0 - 6.0)
	add_child(_dust)
	# ---- boom sônico (anel duplo)
	_boom = Sprite2D.new()
	_boom.texture = Vfx.ring("ace_boom", 130, Color(0.55, 0.90, 1.0, 0.9), 0.06)
	_boom.material = Vfx.add_mat()
	_boom.modulate = Color(1, 1, 1, 0)
	_boom.position = _base
	add_child(_boom)
	_boom2 = Sprite2D.new()
	_boom2.texture = Vfx.ring("ace_boom2", 130, Color(1.0, 0.85, 0.40, 0.85), 0.05)
	_boom2.material = Vfx.add_mat()
	_boom2.modulate = Color(1, 1, 1, 0)
	_boom2.position = _base
	add_child(_boom2)
	_sparkles = CPUParticles2D.new()
	_sparkles.texture = Vfx.spark(16, Color(0.60, 0.90, 1.0))
	_sparkles.material = Vfx.add_mat()
	_sparkles.emitting = false
	_sparkles.amount = 20
	_sparkles.lifetime = 0.45
	_sparkles.explosiveness = 0.8
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 40.0
	_sparkles.initial_velocity_max = 110.0
	_sparkles.gravity = Vector2(0, 160)
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.0
	_sparkles.position = _base
	add_child(_sparkles)


func _dash(at_k: float, dirx: float) -> void:
	# pós-imagens escalonadas + squash da view + poeira
	for i in _ghosts.size():
		var g: Sprite2D = _ghosts[i]
		var off := dirx * (10.0 + 9.0 * float(i))
		g.position = _base + Vector2(off, 0)
		g.modulate = Color(0.6, 0.9, 1.0, 0.38 - 0.10 * float(i))
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.28 + 0.06 * float(i))
	if is_instance_valid(_view):
		var tw2 := _view.create_tween()
		tw2.tween_property(_view, "scale", _vscale * Vector2(1.07, 0.94), 0.07)
		tw2.tween_property(_view, "scale", _vscale, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_dust.emitting = true


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	if t >= DASH1 and not _d1:
		_d1 = true
		_dash(t, -1.0)
	if t >= DASH2 and not _d2:
		_d2 = true
		_dash(t, 1.0)
	if t >= DASH3 and not _d3:
		_d3 = true
		_dash(t, -1.0)
	# linhas de velocidade rasgam durante os dashes
	var act: float = 0.0
	if (t > DASH1 and t < DASH1 + 0.3) or (t > DASH2 and t < DASH2 + 0.3) or (t > DASH3 and t < DASH3 + 0.3):
		act = 1.0
	for st in _streaks:
		var n: Sprite2D = st["n"]
		var k: float = fmod(t * 3.0 + float(st["ph"]), 1.0)
		n.position = _base + Vector2(lerpf(90.0, -90.0, k), float(st["dy"]))
		n.modulate = Color(1, 1, 1, act * sin(k * PI) * 0.7)
	# boom sônico no dash final
	if t >= DASH3 + 0.10:
		var bk: float = clampf((t - DASH3 - 0.10) / 0.16, 0.0, 1.0)
		var bf: float = clampf(1.0 - (t - DASH3 - 0.26) / 0.24, 0.0, 1.0)
		_boom.modulate = Color(1, 1, 1, bk * bf * 0.85)
		_boom.scale = Vector2(0.4 + bk * 0.75, 0.5 + bk * 0.9)
		_boom2.modulate = Color(1, 1, 1, bk * bf * 0.7)
		_boom2.scale = Vector2(0.3 + bk * 0.55, 0.36 + bk * 0.66)
		if not _sparkles.emitting:
			_sparkles.emitting = true
			_sparkles.restart()
	if t > DASH3 + 0.5:
		_dust.emitting = false
	if t >= DUR and not _done:
		_done = true
		if is_instance_valid(_view):
			_view.scale = _vscale
		finished.emit()
		queue_free()
