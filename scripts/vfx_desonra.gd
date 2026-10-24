class_name DesonraFX
extends Node2D
## (1.49.78) VFX de DESTRUIÇÃO do campeão com status SEM HONRA (2 s), 100%
## procedural (nada de recortes): clarão nuclear roxo, anel de choque duplo,
## pétalas de energia voando, FUMAÇA volumétrica suave em camadas, brasas
## subindo e, NO FIM da fumaça, a CAVEIRA vetorial roxa flutuando.

signal finished

var dur := 2.0
var _pet_cache := {}


func setup(at: Vector2) -> void:
	position = at
	z_index = 80
	# 1) clarão nuclear
	var flash := Sprite2D.new()
	flash.texture = Vfx.radial("dh2_flash", 160, Color(0.98, 0.85, 1.0, 0.95), 0.08)
	flash.material = Vfx.add_mat()
	flash.scale = Vector2(0.25, 0.25)
	add_child(flash)
	var tf := create_tween()
	tf.set_parallel(true)
	tf.tween_property(flash, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tf.tween_property(flash, "modulate:a", 0.0, 0.42)
	# 2) anel de choque duplo
	for i in 2:
		var ring := Sprite2D.new()
		ring.texture = Vfx.ring("dh2_ring%d" % i, 256, Color(0.82, 0.4, 1.0, 0.95), 0.09 + 0.05 * i)
		ring.material = Vfx.add_mat()
		ring.scale = Vector2(0.15, 0.15)
		add_child(ring)
		var tr := create_tween()
		tr.tween_interval(0.08 * i)
		tr.set_parallel(true)
		tr.tween_property(ring, "scale", Vector2(1.5 + 0.35 * i, 1.5 + 0.35 * i), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tr.tween_property(ring, "modulate:a", 0.0, 0.6)
	# 3) pétalas de energia roxa voando com rotação
	for i in 12:
		var p := Sprite2D.new()
		p.texture = _petal(int(randf_range(26, 46)))
		p.material = Vfx.add_mat()
		p.rotation = randf_range(0, TAU)
		add_child(p)
		var ang := TAU * float(i) / 12.0 + randf_range(-0.18, 0.18)
		var dist := randf_range(55.0, 105.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", Vector2(cos(ang), sin(ang)) * dist, randf_range(0.45, 0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "rotation", p.rotation + randf_range(-2.0, 2.0), 0.8)
		tw.tween_property(p, "modulate:a", 0.0, randf_range(0.6, 0.95))
	# 4) fumaça volumétrica suave (camadas grandes, subindo e girando devagar)
	for i in 9:
		var sm := Sprite2D.new()
		sm.texture = Vfx.radial("dh2_smoke", 128, Color(0.62, 0.42, 0.78, 0.42), 0.0)
		sm.material = Vfx.add_mat()
		sm.scale = Vector2(0.35, 0.35)
		sm.position = Vector2(randf_range(-26.0, 26.0), randf_range(-6.0, 18.0))
		sm.modulate = Color(1, 1, 1, 0)
		add_child(sm)
		var ts := create_tween()
		ts.tween_interval(randf_range(0.1, 0.55))
		ts.set_parallel(true)
		ts.tween_property(sm, "modulate:a", randf_range(0.5, 0.8), 0.3)
		ts.tween_property(sm, "position:y", sm.position.y - randf_range(45.0, 95.0), randf_range(1.0, 1.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ts.tween_property(sm, "scale", Vector2(randf_range(0.9, 1.4), randf_range(0.9, 1.4)), randf_range(1.0, 1.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ts.tween_property(sm, "rotation", randf_range(-1.2, 1.2), 1.4)
		ts.chain().tween_property(sm, "modulate:a", 0.0, 0.45)
	# 5) brasas subindo
	for i in 10:
		var em := Sprite2D.new()
		em.texture = Vfx.spark(int(randf_range(8, 14)), Color(0.95, 0.6, 1.0, 0.95))
		em.material = Vfx.add_mat()
		em.position = Vector2(randf_range(-40.0, 40.0), randf_range(-10.0, 20.0))
		em.modulate = Color(1, 1, 1, 0)
		add_child(em)
		var te := create_tween()
		te.tween_interval(randf_range(0.0, 0.8))
		te.set_parallel(true)
		te.tween_property(em, "modulate:a", randf_range(0.6, 1.0), 0.12)
		te.tween_property(em, "position:y", em.position.y - randf_range(60.0, 120.0), randf_range(0.7, 1.2)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		te.chain().tween_property(em, "modulate:a", 0.0, 0.3)
	# 6) caveira vetorial NO FIM da fumaça
	var sk := Sprite2D.new()
	sk.texture = load("res://assets/ICO_CAVEIRA.svg")
	sk.material = Vfx.add_mat()
	sk.scale = Vector2(0.30, 0.30)
	sk.position = Vector2(0, -30)
	sk.modulate = Color(1, 1, 1, 0)
	add_child(sk)
	var tk := create_tween()
	tk.tween_interval(1.15)
	tk.set_parallel(true)
	tk.tween_property(sk, "modulate:a", 1.0, 0.3)
	tk.tween_property(sk, "scale", Vector2(0.36, 0.36), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tk.tween_property(sk, "position:y", -44.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tk.chain().tween_property(sk, "modulate:a", 0.0, 0.3)
	# fim exato em 2 s
	var tfin := create_tween()
	tfin.tween_interval(dur)
	tfin.tween_callback(func() -> void:
		finished.emit()
		queue_free())


func _petal(sz: int) -> ImageTexture:
	var key := "pet%d" % sz
	if _pet_cache.has(key):
		return _pet_cache[key]
	var img := Image.create(sz, int(sz * 0.62), false, Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var u := (x - w / 2.0) / (w / 2.0)
			var v := (y - h / 2.0) / (h / 2.0)
			# pétala: elipse afinada nas pontas (formato de folha)
			var d := sqrt(u * u + v * v * 2.2)
			var a := clampf(1.0 - smoothstep(0.55, 1.0, d), 0.0, 1.0)
			a *= 0.85
			img.set_pixel(x, y, Color(0.78, 0.35, 1.0, a))
	var tex := ImageTexture.create_from_image(img)
	_pet_cache[key] = tex
	return tex
