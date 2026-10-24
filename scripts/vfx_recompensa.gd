class_name RecompensaFX
extends Node2D
## (1.49.76) VFX de DESTRUIÇÃO por RECOMPENSA DUPLA (2 s): burst de luz com
## raios em leque (violeta/dourado/branco), ESTRELAS amarelas e roxas subindo
## e o selo "x2" dourado subindo um pouco — identidade da arte de referência.

signal finished

var dur := 2.0
var _star_cache := {}


func setup(at: Vector2) -> void:
	position = at
	z_index = 80
	# núcleo brilhante
	var core := Sprite2D.new()
	core.texture = Vfx.radial("rd_core", 128, Color(1.0, 0.95, 0.75, 0.95), 0.08)
	core.material = Vfx.add_mat()
	core.scale = Vector2(0.25, 0.25)
	add_child(core)
	var tc := create_tween()
	tc.set_parallel(true)
	tc.tween_property(core, "scale", Vector2(1.25, 1.25), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tc.tween_property(core, "modulate:a", 0.0, 0.55)
	# raios em leque para cima
	var cols := [Color(0.72, 0.45, 1.0, 0.85), Color(1.0, 0.8, 0.3, 0.85), Color(1.0, 1.0, 1.0, 0.8), Color(1.0, 0.55, 0.85, 0.85)]
	for i in 14:
		var ang := deg_to_rad(lerpf(-72.0, 72.0, float(i) / 13.0))
		var ry := Sprite2D.new()
		ry.texture = Vfx.radial("rd_ray", 64, cols[i % cols.size()], 0.05)
		ry.material = Vfx.add_mat()
		ry.scale = Vector2(0.05 + 0.012 * (i % 3), 2.2 + 0.5 * (i % 2))
		ry.rotation = ang
		ry.modulate = Color(1, 1, 1, 0)
		add_child(ry)
		var dir := Vector2(sin(ang), -cos(ang))
		var tw := create_tween()
		tw.tween_interval(0.05 * float(i % 5))
		tw.set_parallel(true)
		tw.tween_property(ry, "modulate:a", 0.85, 0.15)
		tw.tween_property(ry, "position", dir * randf_range(30.0, 70.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(ry, "modulate:a", 0.0, 0.45)
	# estrelas subindo (amarelas e roxas, 4 e 5 pontas)
	for i in 12:
		var kind4: bool = i % 2 == 0
		var col: Color = Color(1.0, 0.85, 0.25, 0.95) if (i % 4 < 2) else Color(0.7, 0.4, 1.0, 0.95)
		var st := Sprite2D.new()
		st.texture = _star(int(randf_range(18.0, 44.0)), kind4, col)
		st.material = Vfx.add_mat()
		st.position = Vector2(randf_range(-90.0, 90.0), randf_range(-30.0, 30.0))
		st.modulate = Color(1, 1, 1, 0)
		add_child(st)
		var ts := create_tween()
		ts.tween_interval(randf_range(0.0, 0.9))
		ts.set_parallel(true)
		ts.tween_property(st, "modulate:a", randf_range(0.7, 1.0), 0.15)
		ts.tween_property(st, "position:y", st.position.y - randf_range(50.0, 110.0), randf_range(0.8, 1.3)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ts.tween_property(st, "rotation_degrees", randf_range(-40.0, 40.0), 1.2)
		ts.chain().tween_property(st, "modulate:a", 0.0, 0.35)
	# selo "x2" dourado subindo um pouco
	var lb := Label.new()
	lb.name = "x2_label"
	lb.text = "x2"
	if CardArt.baloo(800) != null:
		lb.add_theme_font_override("font", CardArt.baloo(800))
	lb.add_theme_font_size_override("font_size", 42)
	lb.add_theme_color_override("font_color", Color(1.0, 0.8, 0.25))
	lb.add_theme_color_override("font_outline_color", Color(0.42, 0.15, 0.68))
	lb.add_theme_constant_override("outline_size", 12)
	lb.position = Vector2(-24, -20)
	lb.modulate = Color(1, 1, 1, 0)
	add_child(lb)
	var tl := create_tween()
	tl.tween_interval(0.35)
	tl.set_parallel(true)
	tl.tween_property(lb, "modulate:a", 1.0, 0.2)
	tl.tween_property(lb, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tl.tween_property(lb, "position:y", -56.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tl.chain().tween_property(lb, "modulate:a", 0.0, 0.35)
	lb.scale = Vector2(0.6, 0.6)
	lb.pivot_offset = Vector2(24, 24)
	# fim exato em 2 s
	var tfin := create_tween()
	tfin.tween_interval(dur)
	tfin.tween_callback(func() -> void:
		finished.emit()
		queue_free())


func _star(sz: int, four: bool, col: Color) -> ImageTexture:
	var key := "%d_%s" % [sz, four]
	if _star_cache.has(key):
		return _star_cache[key]
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c := (sz - 1) / 2.0
	if four:
		# sparkle de 4 pontas FINAS e afiadas (identidade da referência)
		for y in sz:
			for x in sz:
				var dx := absf(x - c)
				var dy := absf(y - c)
				var d1 := 1.0 - (dx / (sz * 0.09) + dy / (sz * 0.48))
				var d2 := 1.0 - (dy / (sz * 0.09) + dx / (sz * 0.48))
				var a := clampf(maxf(d1, d2), 0.0, 1.0)
				a = pow(a, 0.65)
				var glow := 0.3 * clampf(1.0 - Vector2(dx, dy).length() / c, 0.0, 1.0)
				a = maxf(a, glow)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a * col.a))
	else:
		# estrela clássica de 5 pontas com bordas RETAS (point-in-polygon)
		var R := sz * 0.48
		var r := R * 0.44
		var pts: Array = []
		for k in 10:
			var rad := R if k % 2 == 0 else r
			var ang := -PI / 2.0 + k * PI / 5.0
			pts.append(Vector2(cos(ang) * rad, sin(ang) * rad))
		for y in sz:
			for x in sz:
				var p := Vector2(x - c, y - c)
				var inside := _pip(p, pts)
				var a := 1.0 if inside else 0.0
				if a == 0.0:
					for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
						if _pip(p + o, pts):
							a = 0.45
							break
				var glow := 0.22 * clampf(1.0 - p.length() / c, 0.0, 1.0)
				a = maxf(a, glow if inside else glow * 0.6)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, clampf(a, 0.0, 1.0) * col.a))
	var tex := ImageTexture.create_from_image(img)
	_star_cache[key] = tex
	return tex


func _pip(p: Vector2, pts: Array) -> bool:
	var inside := false
	var n := pts.size()
	var j := n - 1
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[j]
		if (a.y > p.y) != (b.y > p.y):
			var t := (p.y - a.y) / (b.y - a.y)
			if p.x < a.x + t * (b.x - a.x):
				inside = not inside
		j = i
	return inside
