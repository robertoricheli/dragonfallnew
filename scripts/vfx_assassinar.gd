class_name AssassinarFX
extends Node2D
## (1.49.99) HABILIDADE ASSASSINAR — morte ESPECIAL de destruição: 0,5 s após
## a escolha do alvo, uma ADAGA espectral pintada (ADAGA_ARTE.png) materializa
## sobre a carta, paira e golpeia em diagonal (0,5->0,62 s) com rastro de
## corte; a carta é CORTADA AO MEIO (duas metades com a textura real da carta
## se separam, giram e caem) e então se DESFAZ em vários pedaços (9 estilhaços
## da própria textura + fumaça), num total de 2,0 s entre o corte e a
## destruição completa (regra do dono). Contrato: finished em 2,5 s.
## Uso: add_child(fx); fx.setup(champion_view)

signal finished

const DUR := 2.5
const SLASH_AT := 0.5
const SPLIT_AT := 0.62
const SHATTER_AT := 1.6

var _t := 0.0
var _done := false
var _started := false
var _slashed := false
var _split := false
var _shattered := false

var _view: ChampionView
var _pos := Vector2.ZERO
var _size := Vector2(100, 140)
var _face_tex: Texture2D

var _dagger: Sprite2D
var _slash: Sprite2D
var _glint: Sprite2D
var _halves: Array = []
var _shards: Array = []
var _smoke: CPUParticles2D

const DAG_TEX := preload("res://assets/ADAGA_ARTE.png")


func setup(v: ChampionView) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 95
	_started = true
	_pos = v.global_position + v.size / 2.0
	_size = v.size
	_face_tex = v._face.texture if v._face != null else null
	Sfx.play("assassinar_mark", _pos.x, 0.9)
	# ---- adaga espectral
	_dagger = Sprite2D.new()
	_dagger.texture = DAG_TEX
	_dagger.centered = true
	var ds: float = 110.0 / float(DAG_TEX.get_height())
	_dagger.scale = Vector2(ds, ds)
	_dagger.modulate = Color(1, 1, 1, 0)
	_dagger.position = _pos + Vector2(46, -86)
	add_child(_dagger)
	# ---- rastro do corte (diagonal)
	_slash = Sprite2D.new()
	_slash.texture = Vfx.ring("ass_slash", 190, Color(1.0, 0.35, 0.30, 0.9), 0.04)
	_slash.material = Vfx.add_mat()
	_slash.modulate = Color(1, 1, 1, 0)
	_slash.rotation = -0.7
	_slash.scale = Vector2(1.0, 0.12)
	_slash.position = _pos
	add_child(_slash)
	_glint = Sprite2D.new()
	_glint.texture = Vfx.radial("ass_glint", 130, Color(1.0, 0.45, 0.40, 0.9), 0.25)
	_glint.material = Vfx.add_mat()
	_glint.modulate = Color(1, 1, 1, 0)
	_glint.position = _pos
	add_child(_glint)
	# ---- fumaça do despedaçamento
	_smoke = CPUParticles2D.new()
	_smoke.texture = Vfx.radial("ass_smoke", 46, Color(0.10, 0.08, 0.12, 0.5), 0.05)
	_smoke.emitting = false
	_smoke.amount = 26
	_smoke.lifetime = 0.8
	_smoke.direction = Vector2(0, -1)
	_smoke.spread = 60.0
	_smoke.initial_velocity_min = 16.0
	_smoke.initial_velocity_max = 48.0
	_smoke.gravity = Vector2(0, -12)
	_smoke.scale_amount_min = 1.0
	_smoke.scale_amount_max = 2.4
	_smoke.position = _pos
	add_child(_smoke)


func _mk_part(rect: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = _face_tex
	s.region_enabled = true
	s.region_rect = rect
	s.centered = false
	# (1.50.0) Sprite2D não tem pivot_offset: o origin vira o CENTRO da região
	# via offset negativo — rotação das metades/pedaços ao redor do próprio centro.
	s.offset = -rect.size / 2.0
	s.position = _pos - _size / 2.0 + rect.position + rect.size / 2.0
	# (1.50.1) a textura baked é maior que a carta em campo: escala as partes
	# para o TAMANHO REAL da carta (a carta NÃO cresce durante a morte).
	s.scale = Vector2(_size.x / float(_face_tex.get_width()), _size.y / float(_face_tex.get_height()))
	s.modulate = Color(1, 1, 1, 0)
	add_child(s)
	return s


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ============ 0 .. 0.5: adaga materializa e paira
	var mk: float = clampf(t / 0.3, 0.0, 1.0)
	var hover: float = sin(t * 9.0) * 3.0
	if t < SLASH_AT:
		_dagger.modulate = Color(1, 1, 1, Ease.out_cubic(mk))
		_dagger.position = _pos + Vector2(46, -86 + hover)
		_dagger.rotation = 0.12 * sin(t * 6.0)
	# ============ 0.5 .. 0.62: o GOLPE em diagonal
	elif t < SPLIT_AT:
		var gk: float = (t - SLASH_AT) / (SPLIT_AT - SLASH_AT)
		_dagger.modulate = Color(1, 1, 1, 1.0)
		_dagger.position = _pos + Vector2(lerpf(46, -40, gk), lerpf(-86, 66, Ease.in_sq(gk)))
		_dagger.rotation = lerpf(0.0, -0.7, gk)
		if not _slashed:
			_slashed = true
			Sfx.play("assassinar_slash", _pos.x, 1.0)
		_slash.modulate = Color(1, 1, 1, gk * 0.9)
		_slash.scale = Vector2(0.4 + gk * 0.9, 0.10)
		_glint.modulate = Color(1, 1, 1, gk * 0.7)
	# ============ 0.62 .. 1.6: carta CORTADA AO MEIO (metades caem)
	if t >= SPLIT_AT and not _split:
		_split = true
		Sfx.play("assassinar_split", _pos.x, 1.0)
		if is_instance_valid(_view):
			_view.visible = false
		if _face_tex != null:
			var half := _size.y / 2.0
			var tw2: Texture2D = _face_tex
			var wpx: float = float(tw2.get_width())
			var hpx: float = float(tw2.get_height())
			var top := _mk_part(Rect2(0, 0, wpx, hpx / 2.0))
			var bot := _mk_part(Rect2(0, hpx / 2.0, wpx, hpx / 2.0))
			_halves.append({"n": top, "rot": -0.35, "dx": -7.0, "dy": -5.0, "fall": 90.0})
			_halves.append({"n": bot, "rot": 0.30, "dx": 6.0, "dy": 4.0, "fall": 130.0})
		_dagger.modulate = Color(1, 1, 1, 0)
	if _split and t < SHATTER_AT:
		var hk: float = (t - SPLIT_AT) / (SHATTER_AT - SPLIT_AT)
		for h in _halves:
			var n: Sprite2D = h["n"]
			n.modulate = Color(1, 1, 1, 1.0 - 0.25 * hk)
			n.rotation = float(h["rot"]) * Ease.in_sq(hk)
			n.position += Vector2(float(h["dx"]) * delta, (float(h["dy"]) + float(h["fall"]) * hk) * delta)
		_slash.modulate = Color(1, 1, 1, maxf(0.0, 0.9 - (t - SLASH_AT) * 2.2))
		_glint.modulate = Color(1, 1, 1, maxf(0.0, 0.7 - (t - SLASH_AT) * 2.0))
	# ============ 1.6 .. 2.5: DESFAZ em várias partes
	if t >= SHATTER_AT and not _shattered:
		_shattered = true
		Sfx.play("assassinar_shatter", _pos.x, 1.0)
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
						"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, 0.2)).normalized(),
						"sp": randf_range(60.0, 150.0),
						"rot": randf_range(-7.0, 7.0),
					})
	if _shattered:
		var sk: float = (t - SHATTER_AT) / (DUR - SHATTER_AT)
		for sd in _shards:
			var n2: Sprite2D = sd["n"]
			n2.rotation += float(sd["rot"]) * delta
			n2.position += (sd["dir"] * float(sd["sp"]) + Vector2(0, 220.0 * sk)) * delta
			n2.modulate = Color(1, 1, 1, clampf(1.0 - sk, 0.0, 1.0))
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
