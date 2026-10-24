class_name VfxCongelar
extends Node2D
## (1.49.87) VFX CONGELAR / ZERO ABSOLUTO: coluna de luz + anel de gelo no
## chão (ref. img 3) e burst de cristais (ref. img 4) sobre o campeão alvo.

signal finished

var dur := 1.4


func setup(at: Vector2) -> void:
	position = at
	z_index = 85
	# anel no chão + coluna de luz (arte de referência 3)
	var anel := Sprite2D.new()
	anel.texture = load("res://assets/VFX_GELO_ANEL.png")
	anel.material = Vfx.add_mat()
	anel.scale = Vector2(0.55, 0.55)
	anel.position = Vector2(0, -30)
	anel.modulate = Color(1, 1, 1, 0)
	add_child(anel)
	var ta := create_tween()
	ta.set_parallel(true)
	ta.tween_property(anel, "modulate:a", 0.95, 0.25)
	ta.tween_property(anel, "scale", Vector2(0.62, 0.62), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ta.chain().tween_interval(0.5)
	ta.chain().tween_property(anel, "modulate:a", 0.0, 0.45)
	# burst de cristais (arte de referência 4)
	var bu := Sprite2D.new()
	bu.texture = load("res://assets/VFX_GELO_BURST.png")
	bu.material = Vfx.add_mat()
	bu.scale = Vector2(0.25, 0.25)
	bu.modulate = Color(1, 1, 1, 0)
	add_child(bu)
	var tb := create_tween()
	tb.set_parallel(true)
	tb.tween_property(bu, "modulate:a", 1.0, 0.12)
	tb.tween_property(bu, "scale", Vector2(0.62, 0.62), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tb.chain().tween_interval(0.35)
	tb.chain().tween_property(bu, "modulate:a", 0.0, 0.4)
	# estilhaços de gelo voando
	for i in 10:
		var sh := Sprite2D.new()
		sh.texture = Vfx.spark(int(randf_range(10, 18)), Color(0.8, 0.95, 1.0, 0.95))
		sh.material = Vfx.add_mat()
		add_child(sh)
		var ang := TAU * float(i) / 10.0 + randf_range(-0.2, 0.2)
		var ts := create_tween()
		ts.set_parallel(true)
		ts.tween_property(sh, "position", Vector2(cos(ang), sin(ang) * 0.7) * randf_range(45.0, 90.0), randf_range(0.4, 0.7)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ts.tween_property(sh, "modulate:a", 0.0, randf_range(0.5, 0.8))
		ts.chain().tween_callback(sh.queue_free)
	# flocos subindo devagar
	for i in 8:
		var fl := Sprite2D.new()
		fl.texture = Vfx.spark(int(randf_range(6, 10)), Color(1.0, 1.0, 1.0, 0.85))
		fl.material = Vfx.add_mat()
		fl.position = Vector2(randf_range(-50.0, 50.0), randf_range(-20.0, 30.0))
		fl.modulate = Color(1, 1, 1, 0)
		add_child(fl)
		var tf := create_tween()
		tf.tween_interval(randf_range(0.0, 0.5))
		tf.set_parallel(true)
		tf.tween_property(fl, "modulate:a", 0.8, 0.15)
		tf.tween_property(fl, "position:y", fl.position.y - randf_range(40.0, 80.0), randf_range(0.7, 1.1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tf.chain().tween_property(fl, "modulate:a", 0.0, 0.3)
	var tfin := create_tween()
	tfin.tween_interval(dur)
	tfin.tween_callback(func() -> void:
		finished.emit()
		queue_free())
