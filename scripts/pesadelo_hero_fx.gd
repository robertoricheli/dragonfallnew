class_name PesadeloHeroFX
extends Node2D
## (1.49.93) PESADELO SOBRE O HERÓI — animação LOOP simplificada acima da
## moldura do herói afetado: fantasminhas brancos (estilo Boo) escapam do topo
## do avatar subindo e somem, com fiapos de fumaça negra e um brilho roxo
## pulsante — simboliza que o jogador NÃO fará o próximo saque livre.
## Some quando termina o turno do jogador afetado (a Tela de Combate libera
## este nó). Uso: add_child(fx); fx.setup(pos_global_topo_do_avatar)

var _t := 0.0
var _started := false
var _next_ghost := 0.25
var _gi := 0

var _glow: Sprite2D
var _smoke: CPUParticles2D
var _ghosts: Array = []

const GHOST_TEX := [
	preload("res://assets/FANTASMA_PESADELO.png"),
	preload("res://assets/FANTASMA_PESADELO2.png"),
]


func setup(at: Vector2) -> void:
	position = at
	z_index = 95
	_started = true
	# ---- brilho roxo pulsante atrás/above do avatar
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("pesh_glow", 110, Color(0.45, 0.18, 0.70, 0.55), 0.08)
	_glow.material = Vfx.add_mat()
	_glow.scale = Vector2(1.0, 0.8)
	add_child(_glow)
	# ---- fumaça negra subindo do topo do avatar (loop)
	_smoke = CPUParticles2D.new()
	_smoke.texture = Vfx.radial("pesh_smoke", 40, Color(0.05, 0.03, 0.09, 0.5), 0.05)
	_smoke.emitting = true
	_smoke.amount = 26
	_smoke.lifetime = 1.1
	_smoke.direction = Vector2(0, -1)
	_smoke.spread = 22.0
	_smoke.initial_velocity_min = 26.0
	_smoke.initial_velocity_max = 52.0
	_smoke.gravity = Vector2(0, -14)
	_smoke.scale_amount_min = 1.1
	_smoke.scale_amount_max = 2.2
	var cs := Curve.new()
	cs.add_point(Vector2(0.0, 0.4))
	cs.add_point(Vector2(0.5, 1.0))
	cs.add_point(Vector2(1.0, 1.4))
	_smoke.scale_amount_curve = cs
	var cg := Gradient.new()
	cg.offsets = [0.0, 0.3, 1.0]
	cg.colors = [Color(0.08, 0.05, 0.12, 0.0), Color(0.07, 0.04, 0.11, 0.8), Color(0.04, 0.02, 0.08, 0.0)]
	_smoke.color_ramp = cg
	add_child(_smoke)
	# ---- pool de 3 fantasminhas que sobem em ciclos
	for i in 3:
		var g := Sprite2D.new()
		g.texture = GHOST_TEX[i % 2]
		g.material = Vfx.add_mat()
		g.modulate = Color(1, 1, 1, 0)
		add_child(g)
		_ghosts.append({"n": g, "t0": -1.0, "dx": 0.0, "sc": 0.2, "ph": 0.0})


func _launch(g: Dictionary) -> void:
	g["t0"] = _t
	g["dx"] = randf_range(-16.0, 16.0)
	g["sc"] = randf_range(0.15, 0.23)
	g["ph"] = randf_range(0.0, TAU)
	var n: Sprite2D = g["n"]
	n.flip_h = randf() < 0.5


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	_glow.modulate = Color(1, 1, 1, 0.55 + 0.25 * sin(t * 3.4))
	_glow.scale = Vector2(1.0 + 0.08 * sin(t * 3.4 + 1.0), 0.8 + 0.06 * sin(t * 2.7))
	if t >= _next_ghost:
		for g in _ghosts:
			if float(g["t0"]) < 0.0:
				_launch(g)
				break
		_next_ghost = t + randf_range(0.75, 1.15)
	for g in _ghosts:
		var n: Sprite2D = g["n"]
		var gt: float = t - float(g["t0"])
		if float(g["t0"]) < 0.0 or gt < 0.0:
			continue
		var CYCLE := 1.5
		if gt >= CYCLE:
			g["t0"] = -1.0
			n.modulate = Color(1, 1, 1, 0)
			continue
		var k: float = gt / CYCLE
		n.position = Vector2(float(g["dx"]) * k + sin(gt * 6.0 + float(g["ph"])) * 5.0, -lerpf(2.0, 52.0, k))
		n.rotation = 0.10 * sin(gt * 5.0 + float(g["ph"]))
		n.scale = Vector2.ONE * float(g["sc"]) * (0.85 + 0.3 * k)
		n.modulate = Color(0.93, 0.90, 1.06, sin(k * PI) * 0.8)
