class_name FortalecerFX
extends Node2D
## (1.49.75) VFX FORTALECER — réplica da arte de referência atual, 100% de cima:
## - BASE no CHÃO: anéis concêntricos VERDES (círculo perfeito, nunca oval),
##   MAIOR que a carta (≈250 px), ABAIXO dela em z-order (under_layer),
##   IMÓVEL no lugar porém animada (anéis pulsando/respirando) por 2 s;
## - LUZES que saem da base e sobem PASSANDO POR DENTRO da carta (fx_layer),
##   como na referência: FEIXES VERTICAIS retos de larguras variadas,
##   CRUZES de energia verdes de vários tamanhos subindo e piscando suave,
##   pontos de luz e uma lavagem de brilho vertical — blend aditivo.
## Duração total: 2,0 s (o +1 de Poder é aplicado no fim, pelo motor).

signal finished

var dur := 2.0
var _under: Node2D
var _over: Node2D
var _rings: Array = []
var _fill: Sprite2D
var _rng := RandomNumberGenerator.new()
var _tex_cache := {}


func setup(at: Vector2, under_parent: Node, over_parent: Node) -> void:
	position = at
	_rng.seed = hash(int(at.x) * 7 + int(at.y)) * 31 + 17
	# ---------- BASE: anéis no chão (abaixo da carta, imóveis) ----------
	_under = Node2D.new()
	_under.position = at
	under_parent.add_child(_under)
	_fill = Sprite2D.new()
	_fill.texture = Vfx.radial("fort_fill", 256, Color(0.3, 1.0, 0.45, 0.35), 0.0)
	_fill.material = Vfx.add_mat()
	_fill.scale = Vector2(0.95, 0.95)
	_fill.modulate = Color(1, 1, 1, 0)
	_under.add_child(_fill)
	for i in 3:
		var rg := Sprite2D.new()
		rg.texture = Vfx.ring("fort_g%d" % i, 256, Color(0.35, 1.0, 0.5, 0.95), 0.05 + 0.03 * i)
		rg.material = Vfx.add_mat()
		rg.scale = Vector2(0.98 - 0.18 * i, 0.98 - 0.18 * i)
		rg.modulate = Color(1, 1, 1, 0)
		_under.add_child(rg)
		_rings.append(rg)
	# ---------- LUZES (cima, atravessam a carta) ----------
	_over = Node2D.new()
	_over.position = at
	over_parent.add_child(_over)
	_lavagem()
	_feixes()
	_cruzes()
	_pontos()
	_run()


# ----------------------------------------------------------------------------
# luzes que sobem da base
# ----------------------------------------------------------------------------

func _lavagem() -> void:
	# lavagem de brilho vertical suave acima da base (como na referência)
	var col := Sprite2D.new()
	col.texture = Vfx.radial("fort_col", 128, Color(0.38, 1.0, 0.5, 0.45), 0.0)
	col.material = Vfx.add_mat()
	col.scale = Vector2(1.5, 1.7)
	col.position = Vector2(0, -42)
	col.modulate = Color(1, 1, 1, 0)
	_over.add_child(col)
	var tw := create_tween()
	tw.tween_property(col, "modulate:a", 0.3, 0.3)
	tw.tween_property(col, "modulate:a", 0.2, 0.7)
	tw.tween_property(col, "modulate:a", 0.3, 0.5)
	tw.tween_property(col, "modulate:a", 0.0, 0.5)


func _feixes() -> void:
	# feixes VERTICAIS retos de larguras variadas subindo da base
	var xs := [-66.0, -43.0, -21.0, 0.0, 20.0, 42.0, 64.0]
	for i in xs.size():
		var bw := int(_rng.randf_range(5.0, 13.0))
		var bh := int(_rng.randf_range(220.0, 320.0))
		var bm := Sprite2D.new()
		bm.name = "fx_beam"
		bm.texture = _beam(bw, bh)
		bm.material = Vfx.add_mat()
		bm.position = Vector2(xs[i] + _rng.randf_range(-4.0, 4.0), 40.0 - bh * 0.30)
		bm.modulate = Color(1, 1, 1, 0)
		_over.add_child(bm)
		var tw := create_tween()
		tw.tween_interval(_rng.randf_range(0.0, 0.7))
		tw.set_parallel(true)
		tw.tween_property(bm, "modulate:a", _rng.randf_range(0.5, 0.9), 0.18)
		tw.tween_property(bm, "position:y", bm.position.y - _rng.randf_range(35.0, 77.0), _rng.randf_range(1.0, 1.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.chain().tween_property(bm, "modulate:a", 0.0, 0.3)


func _cruzes() -> void:
	# cruzes de energia verdes de vários tamanhos subindo (assinatura da arte)
	for i in 12:
		var sz := int(_rng.randf_range(16.0, 46.0))
		var cr := Sprite2D.new()
		cr.name = "fx_cross"
		cr.texture = _cross(sz)
		cr.material = Vfx.add_mat()
		cr.position = Vector2(_rng.randf_range(-98.0, 98.0), _rng.randf_range(-147.0, 28.0))
		cr.modulate = Color(1, 1, 1, 0)
		_over.add_child(cr)
		var tw := create_tween()
		tw.tween_interval(_rng.randf_range(0.0, 1.1))
		tw.set_parallel(true)
		tw.tween_property(cr, "modulate:a", _rng.randf_range(0.6, 1.0), 0.15)
		tw.tween_property(cr, "position:y", cr.position.y - _rng.randf_range(21.0, 56.0), _rng.randf_range(0.8, 1.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.chain().tween_property(cr, "modulate:a", 0.0, 0.3)
		# piscar suave de energia enquanto vive
		var tf := create_tween()
		tf.tween_interval(_rng.randf_range(0.0, 0.8))
		tf.set_loops(3)
		tf.tween_property(cr, "scale", Vector2(1.08, 1.08), 0.25).set_trans(Tween.TRANS_SINE)
		tf.tween_property(cr, "scale", Vector2(0.96, 0.96), 0.25).set_trans(Tween.TRANS_SINE)


func _pontos() -> void:
	# pontos de luz espalhados subindo devagar
	for i in 12:
		var dot := Sprite2D.new()
		dot.name = "fx_dot"
		dot.texture = Vfx.spark(int(_rng.randi_range(8, 14)), Color(0.55, 1.0, 0.65, 0.9))
		dot.material = Vfx.add_mat()
		dot.scale = Vector2(0.5, 0.5)
		dot.position = Vector2(_rng.randf_range(-84.0, 84.0), _rng.randf_range(-98.0, 28.0))
		dot.modulate = Color(1, 1, 1, 0)
		_over.add_child(dot)
		var tw := create_tween()
		tw.tween_interval(_rng.randf_range(0.0, 1.2))
		tw.set_parallel(true)
		tw.tween_property(dot, "modulate:a", _rng.randf_range(0.5, 0.9), 0.15)
		tw.tween_property(dot, "position:y", dot.position.y - _rng.randf_range(21.0, 49.0), _rng.randf_range(0.7, 1.3)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(dot, "modulate:a", 0.0, 0.25)


# ----------------------------------------------------------------------------
# base: animada porém IMÓVEL no lugar
# ----------------------------------------------------------------------------

func _run() -> void:
	var ti := create_tween()
	ti.set_parallel(true)
	ti.tween_property(_fill, "modulate:a", 0.5, 0.3)
	for i in _rings.size():
		ti.tween_property(_rings[i], "modulate:a", 0.9 - 0.15 * i, 0.25 + 0.1 * i)
	# anéis respirando (posição nunca muda)
	for i in _rings.size():
		var tp := create_tween()
		tp.set_loops(2)
		tp.tween_property(_rings[i], "scale", _rings[i].scale * 1.05, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tp.tween_property(_rings[i], "scale", _rings[i].scale, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var tfill := create_tween()
	tfill.set_loops(2)
	tfill.tween_property(_fill, "modulate:a", 0.65, 0.5).set_trans(Tween.TRANS_SINE)
	tfill.tween_property(_fill, "modulate:a", 0.45, 0.5).set_trans(Tween.TRANS_SINE)
	# apagada no fim
	var tf := create_tween()
	tf.tween_interval(dur - 0.4)
	tf.set_parallel(true)
	tf.tween_property(_fill, "modulate:a", 0.0, 0.4)
	for rg in _rings:
		tf.tween_property(rg, "modulate:a", 0.0, 0.4)
	# fim exato em 2 s
	var tfin := create_tween()
	tfin.tween_interval(dur)
	tfin.tween_callback(func() -> void:
		finished.emit()
		if is_instance_valid(_under):
			_under.queue_free()
		if is_instance_valid(_over):
			_over.queue_free()
		queue_free())


# ----------------------------------------------------------------------------
# texturas procedurais: feixe vertical e cruz de energia
# ----------------------------------------------------------------------------

func _beam(bw: int, bh: int) -> ImageTexture:
	var key := "beam%d_%d" % [bw, bh]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	for x in bw:
		var fx := absf(x - (bw - 1) / 2.0) / maxf(1.0, (bw - 1) / 2.0)
		var core := 1.0 - smoothstep(0.15, 1.0, fx)
		for y in bh:
			var fy := float(y) / float(bh - 1)
			var ends := smoothstep(0.0, 0.15, fy) * (1.0 - smoothstep(0.85, 1.0, fy))
			var a := core * ends
			img.set_pixel(x, y, Color(0.55, 1.0, 0.62, a))
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


func _cross(sz: int) -> ImageTexture:
	var key := "cross%d" % sz
	if _tex_cache.has(key):
		return _tex_cache[key]
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c := (sz - 1) / 2.0
	var arm := sz * 0.14
	var len := sz * 0.40
	for y in sz:
		for x in sz:
			var dx := absf(x - c)
			var dy := absf(y - c)
			var d1 := maxf(dx - arm, dy - len)
			var d2 := maxf(dy - arm, dx - len)
			var dist := maxf(0.0, minf(d1, d2))
			var a := 1.0 - smoothstep(0.0, 2.0, dist)
			var glow := 0.35 * clampf(1.0 - dist / (sz * 0.28), 0.0, 1.0)
			a = maxf(a, glow)
			img.set_pixel(x, y, Color(0.45, 1.0, 0.55, a))
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex
