class_name PesadeloFX
extends Node2D
## (1.49.93) HABILIDADE PESADELO — o campeão recém-invocado abre um vórtice
## sombrio e LANÇA MUITOS FANTASMAS (estilo Boo, arte pintada) + FUMAÇA NEGRA
## em direção ao campo adversário, quase em cone (2,0 s). Cada fantasma voa
## ondulando, chega ao campo inimigo e implode em névoa roxa.
## Ao terminar, a Tela de Combate aplica o efeito no jogador (sem saque livre)
## e liga os fantasmas persistentes sobre o herói afetado.
## Uso: add_child(fx); fx.setup(origem, centro_campo_inimigo)

signal finished

const DUR := 2.0

var _t := 0.0
var _done := false
var _started := false
var _from := Vector2.ZERO
var _dst := Vector2.ZERO
var _dir := Vector2.RIGHT
var _dist := 100.0
var _next_spawn := 0.30
var _spawned := 0

var _aura: Sprite2D
var _ring: Sprite2D
var _smoke: CPUParticles2D
var _wisp: CPUParticles2D
var _ghosts: Array = []
var _pops: Array = []

const GHOST_TEX := [
	preload("res://assets/FANTASMA_PESADELO.png"),
	preload("res://assets/FANTASMA_PESADELO2.png"),
]


func setup(from: Vector2, target: Vector2) -> void:
	_from = from
	_dst = target
	position = Vector2.ZERO
	z_index = 90
	_dir = (target - from).normalized()
	_dist = from.distance_to(target)
	_started = true
	# ---- vórtice sombrio na origem (0 .. 0,35)
	_aura = Sprite2D.new()
	_aura.texture = Vfx.radial("pes_aura", 170, Color(0.30, 0.10, 0.45, 0.75), 0.06)
	_aura.modulate = Color(1, 1, 1, 0)
	_aura.position = from
	add_child(_aura)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("pes_ring", 130, Color(0.65, 0.35, 0.95, 0.85), 0.07)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.position = from
	add_child(_ring)
	# ---- fumaça negra em cone (corpo da baforada sombria)
	_smoke = CPUParticles2D.new()
	_smoke.texture = Vfx.radial("pes_smoke", 64, Color(0.06, 0.04, 0.10, 0.55), 0.04)
	_smoke.emitting = false
	_smoke.amount = 90
	_smoke.lifetime = 0.9
	_smoke.direction = _dir
	_smoke.spread = 20.0
	_smoke.initial_velocity_min = _dist * 0.85
	_smoke.initial_velocity_max = _dist * 1.25
	_smoke.gravity = Vector2(0, -26)
	_smoke.scale_amount_min = 3.0
	_smoke.scale_amount_max = 6.0
	var cs := Curve.new()
	cs.add_point(Vector2(0.0, 0.35))
	cs.add_point(Vector2(0.45, 1.0))
	cs.add_point(Vector2(1.0, 1.5))
	_smoke.scale_amount_curve = cs
	var cg := Gradient.new()
	cg.offsets = [0.0, 0.25, 1.0]
	cg.colors = [Color(0.10, 0.06, 0.16, 0.0), Color(0.08, 0.05, 0.13, 0.85), Color(0.05, 0.03, 0.09, 0.0)]
	_smoke.color_ramp = cg
	add_child(_smoke)
	# ---- fiapos roxos brilhantes na esteira
	_wisp = CPUParticles2D.new()
	_wisp.material = Vfx.add_mat()
	_wisp.texture = Vfx.radial("pes_wisp", 26, Color(0.62, 0.35, 0.95, 0.7), 0.1)
	_wisp.emitting = false
	_wisp.amount = 40
	_wisp.lifetime = 0.6
	_wisp.direction = _dir
	_wisp.spread = 14.0
	_wisp.initial_velocity_min = _dist * 1.0
	_wisp.initial_velocity_max = _dist * 1.5
	_wisp.gravity = Vector2(0, -18)
	_wisp.scale_amount_min = 0.7
	_wisp.scale_amount_max = 1.6
	var cg2 := Gradient.new()
	cg2.offsets = [0.0, 0.3, 1.0]
	cg2.colors = [Color(0.8, 0.5, 1.0, 0.0), Color(0.65, 0.35, 1.0, 0.8), Color(0.4, 0.15, 0.7, 0.0)]
	_wisp.color_ramp = cg2
	add_child(_wisp)
	# ---- kit de implosão no destino (reaproveitado por fantasma)
	for i in 6:
		var pp := Sprite2D.new()
		pp.texture = Vfx.radial("pes_pop", 90, Color(0.55, 0.30, 0.90, 0.8), 0.1)
		pp.material = Vfx.add_mat()
		pp.modulate = Color(1, 1, 1, 0)
		add_child(pp)
		_pops.append({"n": pp, "free_at": -1.0})


func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = GHOST_TEX[_spawned % 2]
	g.material = Vfx.add_mat()
	g.modulate = Color(1, 1, 1, 0)
	g.flip_h = (_spawned % 3) == 1
	add_child(g)
	var perp := _dir.orthogonal()
	var spread_off := perp * randf_range(-0.34, 0.34)
	var vel := (_dir + spread_off * randf_range(0.35, 1.0)).normalized()
	_ghosts.append({
		"n": g,
		"pos": _from + perp * randf_range(-16.0, 16.0) + _dir * randf_range(0.0, 14.0),
		"vel": vel * randf_range(_dist * 0.95, _dist * 1.3),
		"ph": randf_range(0.0, TAU),
		"wob": randf_range(16.0, 34.0),
		"sc": randf_range(0.34, 0.62),
		"born": _t,
		"life": randf_range(0.75, 1.0),
		"rot": randf_range(-0.16, 0.16),
	})
	_spawned += 1


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---------------- vórtice sombrio na origem
	var ak: float = clampf(t / 0.22, 0.0, 1.0)
	var af: float = clampf(1.0 - (t - 0.42) / 0.4, 0.0, 1.0) if t > 0.42 else 1.0
	_aura.modulate = Color(1, 1, 1, ak * af * (0.7 + 0.2 * sin(t * 16.0)))
	_aura.scale = Vector2.ONE * (0.4 + ak * 0.8 + 0.06 * sin(t * 21.0))
	var rk: float = clampf((t - 0.12) / 0.4, 0.0, 1.0)
	_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.85 * af)
	_ring.scale = Vector2.ONE * (0.3 + rk * 1.6)
	# ---------------- emissão do cone sombrio
	if t >= 0.28 and t < 1.62:
		if not _smoke.emitting:
			_smoke.emitting = true
			_wisp.emitting = true
	else:
		_smoke.emitting = false
		_wisp.emitting = false
	# ---------------- fantasmas em enxurrada
	if t >= _next_spawn and t < 1.55 and _spawned < 16:
		_spawn_ghost()
		if _spawned % 2 == 0:
			_spawn_ghost()
		_next_spawn += 0.11
	var perp2 := _dir.orthogonal()
	for g in _ghosts:
		var n: Sprite2D = g["n"]
		var gt: float = t - float(g["born"])
		var life: float = float(g["life"])
		if gt < 0.0:
			continue
		if gt >= life + 0.18:
			n.modulate = Color(1, 1, 1, 0)
			continue
		var travel: float = clampf(gt / life, 0.0, 1.0)
		var base: Vector2 = g["pos"] + g["vel"] * minf(gt, life)
		var wob: float = sin(gt * 9.0 + float(g["ph"])) * float(g["wob"]) * travel
		n.position = base + perp2 * wob
		n.rotation = float(g["rot"]) * sin(gt * 7.0 + float(g["ph"]))
		var bob: float = 1.0 + 0.10 * sin(gt * 12.0 + float(g["ph"]))
		n.scale = Vector2.ONE * float(g["sc"]) * Vector2(bob, 2.0 - bob)
		var ain: float = clampf(gt / 0.14, 0.0, 1.0)
		var aout: float = clampf(1.0 - (gt - life) / 0.18, 0.0, 1.0) if gt > life else 1.0
		n.modulate = Color(0.92, 0.88, 1.05, ain * aout * 0.85)
		# implosão ao chegar no campo inimigo
		if gt >= life and float(g["ph"]) > 0.0:
			for p in _pops:
				if float(p["free_at"]) < 0.0:
					p["free_at"] = t + 0.3
					p["n"].position = n.position
					break
			g["ph"] = -1.0
	for p in _pops:
		var pn: Sprite2D = p["n"]
		var fa: float = float(p["free_at"])
		if fa < 0.0:
			continue
		var pt: float = t - (fa - 0.3)
		var pf: float = clampf(1.0 - pt / 0.3, 0.0, 1.0)
		pn.modulate = Color(1, 1, 1, pf * 0.7)
		pn.scale = Vector2.ONE * (0.4 + (1.0 - pf) * 0.9)
		if pf <= 0.0:
			p["free_at"] = -1.0
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
