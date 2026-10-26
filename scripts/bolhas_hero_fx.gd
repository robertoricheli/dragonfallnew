class_name BolhasHeroFX
extends Node2D
## (1.50.5) BOLHAS SOBRE O HERÓI — loop de BOLHAS DE SABÃO subindo acima do
## box do avatar do herói afetado (como o loop do PESADELO), enquanto o
## status BOLHAS estiver ativo na mão dele. A Tela de Combate libera este nó
## quando o primeiro campeão com bolhas é invocado (bolhas_ended).
## Uso: add_child(fx); fx.setup(pos_global_topo_do_avatar)

var _t := 0.0
var _started := false
var _next := 0.2
var _glow: Sprite2D
var _bubbles: Array = []


func setup(at: Vector2) -> void:
	position = at
	z_index = 95
	_started = true
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("bolh_glow", 90, Color(0.55, 0.80, 1.0, 0.35), 0.1)
	_glow.material = Vfx.add_mat()
	_glow.scale = Vector2(1.0, 0.8)
	add_child(_glow)
	for i in 3:
		var b := Sprite2D.new()
		b.texture = BolhasFX.bubble_tex()
		b.modulate = Color(1, 1, 1, 0)
		add_child(b)
		_bubbles.append({"n": b, "t0": -1.0, "dx": 0.0, "sc": 0.5, "ph": 0.0})


func _launch(g: Dictionary) -> void:
	g["t0"] = _t
	g["dx"] = randf_range(-14.0, 14.0)
	g["sc"] = randf_range(0.35, 0.6)
	g["ph"] = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	_glow.modulate = Color(1, 1, 1, 0.4 + 0.2 * sin(t * 3.0))
	if t >= _next:
		for g in _bubbles:
			if float(g["t0"]) < 0.0:
				_launch(g)
				break
		_next = t + randf_range(0.5, 0.85)
	for g in _bubbles:
		var n: Sprite2D = g["n"]
		var gt: float = t - float(g["t0"])
		if float(g["t0"]) < 0.0 or gt < 0.0:
			continue
		var CYCLE := 1.6
		if gt >= CYCLE:
			g["t0"] = -1.0
			n.modulate = Color(1, 1, 1, 0)
			continue
		var k: float = gt / CYCLE
		n.position = Vector2(float(g["dx"]) * k + sin(gt * 5.0 + float(g["ph"])) * 4.0, -lerpf(0.0, 46.0, k))
		n.rotation = 0.12 * sin(gt * 4.0 + float(g["ph"]))
		n.scale = Vector2.ONE * float(g["sc"]) * (0.8 + 0.25 * k)
		n.modulate = Color(1, 1, 1, sin(k * PI) * 0.85)
