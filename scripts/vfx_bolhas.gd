class_name BolhasFX
extends Node2D
## (1.50.5) HABILIDADE/CARTA TALENTO BOLHAS — cone de BOLHAS DE SABÃO
## iridescentes que saem do campeão que invocou e voam ondulando até o campo
## do jogador afetado, estourando lá com mini-flashes e gotículas (1,6 s).
## Bolha pintada por código (anel iridescente ciano/rosa + brilho), tudo
## procedural. Contrato: finished em 1,6 s.
## Uso: add_child(fx); fx.setup(origem, centro_campo_alvo)

signal finished

const DUR := 1.6

var _t := 0.0
var _done := false
var _started := false
var _from := Vector2.ZERO
var _dst := Vector2.ZERO
var _dir := Vector2.RIGHT
var _dist := 100.0
var _next := 0.10
var _spawned := 0
var _bubbles: Array = []
var _pops: Array = []
static var _bub_tex: ImageTexture = null


static func bubble_tex() -> ImageTexture:
	if _bub_tex != null:
		return _bub_tex
	var S := 48
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	var R := S / 2.0 - 2.0
	for y in S:
		for x in S:
			var d := Vector2(x - c.x, y - c.y).length() / R
			if d > 1.15:
				continue
			var a := 0.0
			var col := Color(0.75, 0.92, 1.0)
			if d > 0.82 and d <= 1.08:
				# parede da bolha: iridescência ciano->rosa pelo ângulo
				var ang := atan2(y - c.y, x - c.x)
				col = Color(0.70 + 0.25 * sin(ang * 2.0), 0.90, 1.0 - 0.15 * sin(ang * 3.0))
				a = 0.85 * (1.0 - absf(d - 0.95) / 0.13)
			elif d <= 0.82:
				a = 0.10
			# brilho especular no alto-esquerda
			var hd := Vector2(x - c.x * 0.62, y - c.y * 0.62).length() / (R * 0.34)
			if hd < 1.0:
				col = Color(1, 1, 1)
				a = maxf(a, (1.0 - hd) * 0.9)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, clampf(a, 0.0, 1.0)))
	_bub_tex = ImageTexture.create_from_image(img)
	return _bub_tex


func setup(from: Vector2, target: Vector2) -> void:
	_from = from
	_dst = target
	position = Vector2.ZERO
	z_index = 90
	_started = true
	_dir = (target - from).normalized()
	_dist = from.distance_to(target)
	for i in 5:
		var pp := Sprite2D.new()
		pp.texture = Vfx.radial("bol_pop", 60, Color(0.80, 0.95, 1.0, 0.8), 0.12)
		pp.material = Vfx.add_mat()
		pp.modulate = Color(1, 1, 1, 0)
		add_child(pp)
		_pops.append({"n": pp, "free_at": -1.0})


func _spawn() -> void:
	var b := Sprite2D.new()
	b.texture = bubble_tex()
	b.modulate = Color(1, 1, 1, 0)
	add_child(b)
	var perp := _dir.orthogonal()
	_bubbles.append({
		"n": b,
		"pos": _from + perp * randf_range(-14.0, 14.0),
		"vel": (_dir + perp * randf_range(-0.42, 0.42)).normalized() * randf_range(_dist * 0.85, _dist * 1.15),
		"ph": randf_range(0.0, TAU),
		"sc": randf_range(0.5, 1.15),
		"born": _t,
		"life": randf_range(0.75, 1.0),
	})
	_spawned += 1


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	if t >= _next and t < 0.95 and _spawned < 16:
		_spawn()
		if _spawned % 2 == 0:
			_spawn()
		_next += 0.09
	var perp2 := _dir.orthogonal()
	for g in _bubbles:
		var n: Sprite2D = g["n"]
		var gt: float = t - float(g["born"])
		var life: float = float(g["life"])
		if gt < 0.0:
			continue
		if gt >= life + 0.15:
			n.modulate = Color(1, 1, 1, 0)
			continue
		var travel: float = clampf(gt / life, 0.0, 1.0)
		var base: Vector2 = g["pos"] + g["vel"] * minf(gt, life)
		var wob: float = sin(gt * 7.0 + float(g["ph"])) * 14.0 * travel
		n.position = base + perp2 * wob
		var bob: float = 1.0 + 0.08 * sin(gt * 9.0 + float(g["ph"]))
		n.scale = Vector2.ONE * float(g["sc"]) * bob
		n.rotation = 0.15 * sin(gt * 5.0 + float(g["ph"]))
		var ain: float = clampf(gt / 0.12, 0.0, 1.0)
		var aout: float = clampf(1.0 - (gt - life) / 0.15, 0.0, 1.0) if gt > life else 1.0
		n.modulate = Color(1, 1, 1, ain * aout * 0.9)
		if gt >= life and float(g["ph"]) > 0.0:
			for p in _pops:
				if float(p["free_at"]) < 0.0:
					p["free_at"] = t + 0.25
					p["n"].position = n.position
					break
			g["ph"] = -1.0
	for p in _pops:
		var pn: Sprite2D = p["n"]
		var fa: float = float(p["free_at"])
		if fa < 0.0:
			continue
		var pt: float = t - (fa - 0.25)
		var pf: float = clampf(1.0 - pt / 0.25, 0.0, 1.0)
		pn.modulate = Color(1, 1, 1, pf * 0.7)
		pn.scale = Vector2.ONE * (0.4 + (1.0 - pf) * 0.8)
		if pf <= 0.0:
			p["free_at"] = -1.0
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
