class_name FxCrackOverlay
extends Control
## (1.49.64) RACHADURAS procedurais sobre a carta campeão no momento da
## destruição (referência Hearthstone): linhas serrilhadas que partem de um
## ponto de impacto e correm até as bordas, em 2 estágios — primeiro os
## rasgos principais, depois as ramificações — com miolo "quente" brilhando
## dentro do rasgo escuro. Tudo desenhado por cima da arte da carta.

var _paths: Array = []        # dicionários: {"p": PackedVector2Array, "s": 1|2}
var _stage: int = 0           # 0 = nada, 1 = estágio 1, 2 = rachada por completo


static func ray_to_rect(c: Vector2, ang: float, rs: Vector2) -> Vector2:
	## Ponto onde o raio que sai de C no ângulo ANG cruza a borda do retângulo.
	var d := Vector2(cos(ang), sin(ang))
	var t := 1e9
	if d.x > 0.0001:
		t = minf(t, (rs.x - c.x) / d.x)
	elif d.x < -0.0001:
		t = minf(t, (0.0 - c.x) / d.x)
	if d.y > 0.0001:
		t = minf(t, (rs.y - c.y) / d.y)
	elif d.y < -0.0001:
		t = minf(t, (0.0 - c.y) / d.y)
	if t > 1e8:
		t = 0.0
	return c + d * t


func build(rand: RandomNumberGenerator, rs: Vector2) -> void:
	## Gera 9 rasgos serrilhados saindo do ponto de impacto da carta,
	## mais 5 ramificações curtas que só aparecem no estágio 2.
	_paths.clear()
	var c := rs / 2.0 + Vector2(rand.randf_range(-7, 7), rand.randf_range(-9, 9))
	var total := 9
	for i in total:
		var ang := TAU * float(i) / float(total) + rand.randf_range(-0.25, 0.25)
		var endp := ray_to_rect(c, ang, rs)
		var dir := (endp - c)
		var len := dir.length()
		if len < 4.0:
			continue
		dir /= len
		var perp := dir.orthogonal()
		var pts := PackedVector2Array()
		pts.append(c)
		var segs := 4 + randi() % 3
		for k in range(1, segs):
			var t := float(k) / float(segs)
			var amp := 3.6 * sin(t * PI)          # serrilhado some nas pontas
			var j := rand.randf_range(-amp, amp)
			pts.append(c.lerp(endp, t) + perp * j)
		pts.append(endp)
		_paths.append({"p": pts, "s": 1})
		# ramificação curta no meio do rasgo (estágio 2)
		if i % 2 == 0 and pts.size() > 3:
			var at: Vector2 = pts[2]
			var bang := ang + (PI / 2.6) * (1.0 if i % 4 == 0 else -1.0)
			var bend := ray_to_rect(at, bang, rs)
			var branch := PackedVector2Array()
			branch.append(at)
			branch.append(at.lerp(bend, 0.45) + perp * rand.randf_range(-2.5, 2.5))
			branch.append(at.lerp(bend, 0.8))
			_paths.append({"p": branch, "s": 2})
	_stage = 0
	queue_redraw()


func stage(n: int) -> void:
	_stage = n
	queue_redraw()


func _draw() -> void:
	if _stage <= 0 or _paths.is_empty():
		return
	for entry in _paths:
		var st: int = entry["s"]
		if st > _stage:
			continue
		var pts: PackedVector2Array = entry["p"]
		if pts.size() < 2:
			continue
		var w_dark := 2.6 if st == 1 else 1.7
		var w_hot := 1.1 if st == 1 else 0.8
		# sombra escura do rasgo (a "ferida" na carta)
		draw_polyline(pts, Color(0.05, 0.04, 0.06, 0.92), w_dark)
		# miolo quente brilhando dentro do rasgo
		draw_polyline(pts, Color(1.0, 0.52, 0.22, 0.55), w_hot)
