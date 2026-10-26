class_name CorromperFX
extends Node2D
## (1.50.4) CORROMPER (Habilidade e Talento) — AURA NEGRA envolvendo o
## campeão escolhido por 1,5 s: dois vórtices roxo-negros contrarrotativos
## ao redor da carta, névoa escura subindo, partículas sendo SUGADAS para o
## peito da carta, pulso de escurecimento na própria carta e um anel rúnico
## sombrio no chão. Contido no slot da carta. Contrato: finished em 1,5 s.
## Uso: add_child(fx); fx.setup(champion_view)

signal finished

const DUR := 1.5

var _t := 0.0
var _done := false
var _started := false

var _view: ChampionView
var _pos := Vector2.ZERO
var _size := Vector2(100, 140)
var _vort1: Sprite2D
var _vort2: Sprite2D
var _ring: Sprite2D
var _core: Sprite2D
var _mist: CPUParticles2D
var _suck: Array = []
var _base_mod: Color = Color(1, 1, 1, 1)


func setup(v: ChampionView) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 91
	_started = true
	# (1.50.5) aura CONCENTRADA NO CENTRO da carta (rect global real)
	_pos = v.get_global_rect().get_center()
	_size = v.size * v.scale
	_base_mod = v.modulate
	# ---- vórtices contrarrotativos
	_vort1 = Sprite2D.new()
	_vort1.texture = Vfx.ring("cor_vort1", 150, Color(0.35, 0.10, 0.50, 0.75), 0.10)
	_vort1.material = Vfx.add_mat()
	_vort1.scale = Vector2(0.9, 1.05)
	_vort1.modulate = Color(1, 1, 1, 0)
	_vort1.position = _pos
	add_child(_vort1)
	_vort2 = Sprite2D.new()
	_vort2.texture = Vfx.ring("cor_vort2", 110, Color(0.15, 0.05, 0.25, 0.8), 0.14)
	_vort2.material = Vfx.add_mat()
	_vort2.scale = Vector2(0.75, 0.9)
	_vort2.modulate = Color(1, 1, 1, 0)
	_vort2.position = _pos
	add_child(_vort2)
	# ---- anel rúnico sombrio no chão
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("cor_ring", 120, Color(0.45, 0.15, 0.60, 0.8), 0.05)
	_ring.material = Vfx.add_mat()
	_ring.scale = Vector2(1.0, 0.32)
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.position = _pos
	_ring.scale = Vector2(0.9, 0.62)
	add_child(_ring)
	# ---- núcleo escuro no peito da carta
	_core = Sprite2D.new()
	_core.texture = Vfx.radial("cor_core", 120, Color(0.10, 0.02, 0.16, 0.8), 0.12)
	_core.material = Vfx.add_mat()
	_core.modulate = Color(1, 1, 1, 0)
	_core.position = _pos
	add_child(_core)
	# ---- névoa escura subindo
	_mist = CPUParticles2D.new()
	_mist.texture = Vfx.radial("cor_mist", 44, Color(0.08, 0.03, 0.12, 0.55), 0.05)
	_mist.emitting = false
	_mist.amount = 26
	_mist.lifetime = 0.8
	_mist.direction = Vector2(0, -1)
	_mist.spread = 40.0
	_mist.initial_velocity_min = 18.0
	_mist.initial_velocity_max = 46.0
	_mist.gravity = Vector2(0, -14)
	_mist.scale_amount_min = 1.0
	_mist.scale_amount_max = 2.2
	_mist.position = _pos + Vector2(0, 10.0)
	add_child(_mist)
	# ---- partículas sugadas para o centro
	for i in 8:
		var p := Sprite2D.new()
		p.texture = Vfx.spark(14, Color(0.55, 0.25, 0.75))
		p.material = Vfx.add_mat()
		p.modulate = Color(1, 1, 1, 0)
		add_child(p)
		_suck.append({"n": p, "a": TAU * float(i) / 8.0, "r0": randf_range(70.0, 95.0)})


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var k: float = clampf(t / 0.25, 0.0, 1.0)
	var outk: float = clampf((t - (DUR - 0.3)) / 0.3, 0.0, 1.0)
	var amp: float = Ease.out_cubic(k) * (1.0 - outk)
	_vort1.modulate = Color(1, 1, 1, amp * (0.65 + 0.2 * sin(t * 9.0)))
	_vort1.rotation += delta * 3.4
	_vort1.scale = Vector2(0.9, 1.05) * (1.0 + 0.06 * sin(t * 7.0))
	_vort2.modulate = Color(1, 1, 1, amp * 0.75)
	_vort2.rotation -= delta * 4.6
	_ring.modulate = Color(1, 1, 1, amp * (0.5 + 0.25 * absf(sin(t * 6.0))))
	_ring.rotation -= delta * 0.8
	_core.modulate = Color(1, 1, 1, amp * (0.5 + 0.3 * sin(t * 12.0)))
	_core.scale = Vector2.ONE * (0.7 + 0.15 * sin(t * 10.0))
	_mist.emitting = t > 0.15 and t < DUR - 0.25
	# carta escurece pulsante (sem mudar tamanho)
	if is_instance_valid(_view):
		_view.modulate = _base_mod.lerp(Color(0.55, 0.45, 0.62, 1.0), amp * 0.55)
	# partículas sugadas
	for p in _suck:
		var n: Sprite2D = p["n"]
		var cyc: float = fmod(t * 0.9 + float(p["a"]) / TAU, 1.0)
		var r: float = lerpf(float(p["r0"]), 6.0, cyc)
		var a: float = float(p["a"]) + cyc * 2.4
		n.position = _pos + Vector2(cos(a) * r, sin(a) * r * 1.2)
		n.modulate = Color(1, 1, 1, sin(cyc * PI) * amp * 0.85)
	if t >= DUR and not _done:
		_done = true
		if is_instance_valid(_view):
			_view.modulate = _base_mod
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv
