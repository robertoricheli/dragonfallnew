class_name AssassinarFX
extends Node2D
## (1.50.3) HABILIDADE ASSASSINAR — morte especial CONTIDA no espaço da carta
## (regra do dono: nada de crescer nem de ocupar a tela): 0,5 s após a escolha
## (orchestrado pela Tela de Combate), uma ADAGA pintada estilo Hearthstone
## (70 px) materializa sobre a carta, golpeia em diagonal com rastro CONTIDO;
## a carta é CORTADA AO MEIO: as duas metades (textura real, escala real em
## tela) se separam POUCO (<= 8 px), giram leve e esmaecem NO PRÓPRIO lugar;
## então vira 9 pedaços pequenos que voam BAIXO e perto (<= ~30 px do slot)
## com fumaça e anel contidos — impacto igual à destruição padrão, porém
## com o corte da adaga. 2,0 s entre o corte e a destruição total.
## Contrato: finished em 2,5 s. Uso: add_child(fx); fx.setup(champion_view)

signal finished

const DUR := 2.5
const SLASH_AT := 0.5
const SPLIT_AT := 0.62
const SHATTER_AT := 1.5

var _t := 0.0
var _done := false
var _started := false
var _slashed := false
var _split := false
var _shattered := false
var _hit_played := false

var _view: ChampionView
var _pos := Vector2.ZERO
var _size := Vector2(100, 140)
var _vscale := Vector2.ONE
var _face_tex: Texture2D

var _dagger: Sprite2D
var _slash: Sprite2D
var _glint: Sprite2D
var _ring: Sprite2D
var _halves: Array = []
var _shards: Array = []
var _sparks: Array = []
var _smoke: CPUParticles2D

const DAG_TEX := preload("res://assets/ADAGA_ARTE.png")


func setup(v: ChampionView) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 95
	_started = true
	# (1.50.2) tamanho REAL em tela (a view tem scale de layout): a carta
	# NUNCA muda de tamanho durante a morte especial.
	_vscale = v.scale
	_size = v.size * v.scale
	_pos = v.global_position + _size / 2.0
	_face_tex = v._face.texture if v._face != null else null
	Sfx.play("assassinar_mark", _pos.x, 0.8)
	# ---- adaga contida (70 px)
	_dagger = Sprite2D.new()
	_dagger.texture = DAG_TEX
	_dagger.centered = true
	var ds: float = 70.0 / float(DAG_TEX.get_height())
	_dagger.scale = Vector2(ds, ds)
	_dagger.modulate = Color(1, 1, 1, 0)
	_dagger.position = _pos + Vector2(30, -60)
	add_child(_dagger)
	# ---- rastro do corte CONTIDO na carta
	_slash = Sprite2D.new()
	_slash.texture = Vfx.ring("ass2_slash", 150, Color(1.0, 0.35, 0.30, 0.9), 0.05)
	_slash.material = Vfx.add_mat()
	_slash.modulate = Color(1, 1, 1, 0)
	_slash.rotation = -0.7
	_slash.scale = Vector2(0.45, 0.07)
	_slash.position = _pos
	add_child(_slash)
	_glint = Sprite2D.new()
	_glint.texture = Vfx.radial("ass2_glint", 90, Color(1.0, 0.45, 0.40, 0.9), 0.25)
	_glint.material = Vfx.add_mat()
	_glint.modulate = Color(1, 1, 1, 0)
	_glint.position = _pos
	add_child(_glint)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ass2_ring", 110, Color(1.0, 0.35, 0.25, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.position = _pos
	add_child(_ring)
	_smoke = CPUParticles2D.new()
	_smoke.texture = Vfx.radial("ass2_smoke", 40, Color(0.10, 0.08, 0.12, 0.5), 0.05)
	_smoke.emitting = false
	_smoke.amount = 18
	_smoke.lifetime = 0.6
	_smoke.direction = Vector2(0, -1)
	_smoke.spread = 45.0
	_smoke.initial_velocity_min = 12.0
	_smoke.initial_velocity_max = 34.0
	_smoke.gravity = Vector2(0, -10)
	_smoke.scale_amount_min = 0.8
	_smoke.scale_amount_max = 1.6
	_smoke.position = _pos
	add_child(_smoke)


func _mk_part(rect: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _face_tex
	s.region_enabled = true
	s.region_rect = rect
	s.centered = false
	s.offset = -rect.size / 2.0
	s.position = _pos - _size / 2.0 + rect.position * (_size / Vector2(_face_tex.get_width(), _face_tex.get_height())) + (rect.size / 2.0) * (_size / Vector2(_face_tex.get_width(), _face_tex.get_height()))
	# escala real em tela da carta (nunca cresce)
	s.scale = Vector2(_size.x / float(_face_tex.get_width()), _size.y / float(_face_tex.get_height()))
	s.modulate = Color(1, 1, 1, 0)
	add_child(s)
	return s


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ============ 0 .. 0.5: adaga materializa pairando DENTRO do slot
	var mk: float = clampf(t / 0.3, 0.0, 1.0)
	if t < SLASH_AT:
		_dagger.modulate = Color(1, 1, 1, Ease.out_cubic(mk))
		_dagger.position = _pos + Vector2(30, -60 + sin(t * 9.0) * 2.0)
		_dagger.rotation = 0.10 * sin(t * 6.0)
	# ============ 0.5 .. 0.62: golpe diagonal CONTIDO
	elif t < SPLIT_AT:
		var gk: float = (t - SLASH_AT) / (SPLIT_AT - SLASH_AT)
		_dagger.modulate = Color(1, 1, 1, 1.0)
		_dagger.position = _pos + Vector2(lerpf(30, -26, gk), lerpf(-60, 46, Ease.in_sq(gk)))
		_dagger.rotation = lerpf(0.0, -0.7, gk)
		if not _slashed:
			_slashed = true
			Sfx.play("assassinar_slash", _pos.x, 1.0)
		_slash.modulate = Color(1, 1, 1, gk * 0.85)
		_slash.scale = Vector2(0.30 + gk * 0.30, 0.06)
		_glint.modulate = Color(1, 1, 1, gk * 0.55)
	# ============ 0.62 .. 1.5: CORTADA AO MEIO no próprio lugar
	if t >= SPLIT_AT and not _split:
		_split = true
		Sfx.play("assassinar_split", _pos.x, 0.9)
		if is_instance_valid(_view):
			_view.visible = false
		if _face_tex != null:
			var wpx: float = float(_face_tex.get_width())
			var hpx: float = float(_face_tex.get_height())
			var top := _mk_part(Rect2(0, 0, wpx, hpx / 2.0))
			var bot := _mk_part(Rect2(0, hpx / 2.0, wpx, hpx / 2.0))
			top.modulate = Color(1, 1, 1, 1)
			bot.modulate = Color(1, 1, 1, 1)
			_halves.append({"n": top, "rot": -0.14, "dx": -5.0, "dy": -4.0})
			_halves.append({"n": bot, "rot": 0.12, "dx": 4.0, "dy": 3.0})
		_dagger.modulate = Color(1, 1, 1, 0)
	if _split and t < SHATTER_AT:
		var hk: float = (t - SPLIT_AT) / (SHATTER_AT - SPLIT_AT)
		for h in _halves:
			var n: Sprite2D = h["n"]
			n.modulate = Color(1, 1, 1, 1.0 - 0.35 * hk)
			n.rotation = float(h["rot"]) * Ease.in_sq(hk)
			n.position += Vector2(float(h["dx"]) * delta, float(h["dy"]) * delta)
		_slash.modulate = Color(1, 1, 1, maxf(0.0, 0.85 - (t - SLASH_AT) * 2.0))
		_glint.modulate = Color(1, 1, 1, maxf(0.0, 0.55 - (t - SLASH_AT) * 1.6))
	# ============ 1.5 .. 2.5: pedaços PEQUENOS e PERTO + fumaça/anel contidos
	if t >= SHATTER_AT and not _shattered:
		_shattered = true
		Sfx.play("assassinar_shatter", _pos.x, 0.9)
		_smoke.emitting = true
		for h in _halves:
			(h["n"] as Sprite2D).modulate = Color(1, 1, 1, 0)
		if _face_tex != null:
			var wpx2: float = float(_face_tex.get_width())
			var hpx2: float = float(_face_tex.get_height())
			for gy in 3:
				for gx in 3:
					var rect := Rect2(wpx2 / 3.0 * gx, hpx2 / 3.0 * gy, wpx2 / 3.0, hpx2 / 3.0)
					var sh := _mk_part(rect)
					sh.modulate = Color(1, 1, 1, 1)
					_shards.append({
						"n": sh,
						"dir": Vector2(randf_range(-0.6, 0.6), randf_range(-0.7, 0.1)).normalized(),
						"sp": randf_range(22.0, 46.0),
						"rot": randf_range(-4.0, 4.0),
					})
		for i in 6:
			var sp := Sprite2D.new()
			sp.texture = Vfx.spark(int(randf_range(10, 16)), Color(0.95, 0.45, 0.35))
			sp.material = Vfx.add_mat()
			sp.modulate = Color(1, 1, 1, 0.9)
			sp.position = _pos + Vector2(randf_range(-24, 24), randf_range(-40, 40))
			add_child(sp)
			_sparks.append({"n": sp, "dir": Vector2(randf_range(-1, 1), randf_range(-1, 0.2)).normalized(), "sp": randf_range(30.0, 70.0)})
	if _shattered:
		var sk: float = (t - SHATTER_AT) / (DUR - SHATTER_AT)
		for sd in _shards:
			var n2: Sprite2D = sd["n"]
			n2.rotation += float(sd["rot"]) * delta
			n2.position += (sd["dir"] * float(sd["sp"]) + Vector2(0, 120.0 * sk)) * delta
			n2.modulate = Color(1, 1, 1, clampf(1.0 - sk * 1.1, 0.0, 1.0))
		for sp in _sparks:
			var n3: Sprite2D = sp["n"]
			n3.position += sp["dir"] * float(sp["sp"]) * delta
			n3.modulate = Color(1, 1, 1, clampf(1.0 - sk * 1.4, 0.0, 1.0) * 0.9)
		var rk: float = clampf((t - SHATTER_AT) / 0.18, 0.0, 1.0)
		var rf: float = clampf(1.0 - (t - SHATTER_AT - 0.18) / 0.22, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, rk * rf * 0.8)
		_ring.scale = Vector2(0.3 + rk * 0.45, 0.36 + rk * 0.54)
	if t >= DUR and not _done:
		_done = true
		if is_instance_valid(_view):
			_view.queue_free()
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv

	static func in_sq(x: float) -> float:
		return x * x
