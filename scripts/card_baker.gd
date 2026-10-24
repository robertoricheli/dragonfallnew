extends Node
## CardBaker (autoload "Baker"): renderiza cada carta UMA única vez em alta
## resolução (440×616, via SubViewport/GPU) e fornece essa textura para TODAS
## as instâncias (miniatura, mão, campo, zoom, histórico) => cópias exatas.
## Cache invalidado por CardArt.version (edições de layout/texto no editor).

signal baked(key: String)

const W := 440
const H := 616

var cache := {}
var pend := {}
var fails := {}
var order := []


func key_of(card: Dictionary, power: int) -> String:
	return "%s|%d|%d" % [String(card.get("name", "")), power, CardArt.version]


func cached(card: Dictionary, power: int) -> ImageTexture:
	return cache.get(key_of(card, power))


func request(card: Dictionary, power: int) -> ImageTexture:
	var k := key_of(card, power)
	if DisplayServer.get_name() == "headless":
		return cache.get(k)  # sem GPU: mantém placeholder
	if cache.has(k):
		return cache[k]
	if not pend.has(k):
		pend[k] = [card.duplicate(true), power]
		order.append(k)
	return null


func _process(_d: float) -> void:
	var n := 0
	while order.size() > 0 and n < 2:
		_bake(order.pop_front())
		n += 1


func _bake(k: String) -> void:
	if cache.has(k):
		baked.emit(k)
		return
	if not pend.has(k):
		return
	var e: Array = pend[k]
	pend.erase(k)
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var face := _build_face(e[0], int(e[1]))
	vp.add_child(face)
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = null
	if vp.get_texture() != null:
		img = vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		# renderer indisponível (headless): tenta 1x, depois mantém placeholder
		fails[k] = int(fails.get(k, 0)) + 1
		if int(fails[k]) < 2:
			pend[k] = e
			order.append(k)
			return
		cache[k] = null
		baked.emit(k)
		return
	var tex := ImageTexture.create_from_image(img)
	cache[k] = tex
	baked.emit(k)


func _lbl(fs: int, col: Color, r: Rect2) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", maxi(2, fs))
	l.add_theme_color_override("font_color", col)
	l.position = r.position
	l.size = r.size
	l.clip_text = false  # (1.49.88) texto redimensionado pode vazar da zona
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_face(card: Dictionary, power: int) -> Control:
	var c := Control.new()
	c.position = Vector2.ZERO
	c.size = Vector2(W, H)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cat: String = String(card.get("category", ""))
	var sub: String = String(card.get("subcategory", ""))
	var s: float = W / 110.0
	var win := ColorRect.new()
	win.color = Color(0.09, 0.09, 0.13, 1.0)
	var wz: Rect2 = CardArt.Z_ART
	win.position = Vector2(wz.position.x * s + 2, wz.position.y * s + 2)
	win.size = Vector2(wz.size.x * s - 4, wz.size.y * s - 4)
	win.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(win)
	var ftex: Texture2D = CardArt.frame(cat, sub)
	if ftex != null:
		var fr := TextureRect.new()
		fr.texture = ftex
		fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fr.stretch_mode = TextureRect.STRETCH_SCALE
		fr.position = Vector2.ZERO
		fr.size = Vector2(W, H)
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(fr)
	var L: Dictionary = CardArt.layout_for(card, 110.0, 154.0)
	var z: Dictionary = L["zones"]
	var R := func(r: Rect2) -> Rect2:
		return Rect2(r.position * s, r.size * s)
	var white := Color(1, 1, 1)
	var dark := Color(0.13, 0.13, 0.16)
	var darkd := Color(0.16, 0.16, 0.2)
	var lp := _lbl(int(L["pow_fs"]) * s, white, R.call(z["gem"]))
	if CardArt.font_for(int(L.get("desc_font", 0)), 800) != null:
		lp.add_theme_font_override("font", CardArt.font_for(int(L.get("desc_font", 0)), 800))
	lp.text = str(power)
	c.add_child(lp)
	var ln := _lbl(int(L["name_fs"]) * s, white if cat == "champion" else dark, R.call(z["name"]))
	var f800n: Font = CardArt.font_for(int(L.get("desc_font", 0)), 800)
	if f800n != null:
		var kx: float = float(L.get("name_kx", 1.0))
		if kx < 0.995:
			# nome comprido: fonte GRANDE porem condensada p/ caber na barra
			var fv := FontVariation.new()
			fv.base_font = f800n
			fv.variation_transform = Transform2D(Vector2(kx, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
			ln.add_theme_font_override("font", fv)
		else:
			ln.add_theme_font_override("font", f800n)
	ln.scale.x = float(L.get("zw_name", 1.0))
	ln.pivot_offset = ln.size / 2.0
	ln.text = String(L["name_text"])
	ln.clip_text = false  # nome maior: acentos não podem ser cortados pela barra
	c.add_child(ln)
	if cat == "champion":
		var la := _lbl(int(L["abil_fs"]) * s, white, R.call(z["abil"]))
		if CardArt.font_for(int(L.get("desc_font", 0)), 800) != null:
			la.add_theme_font_override("font", CardArt.font_for(int(L.get("desc_font", 0)), 800))
		la.scale.x = float(L.get("zw_abil", 1.0))
		la.pivot_offset = la.size / 2.0
		la.text = String(L["abil_text"])
		c.add_child(la)
	# (sem título de habilidade em TALENTO/REAÇÃO: redundante com o selo)
	var ld := DescDraw.new()
	var dr: Rect2 = R.call(z["desc"])
	ld.position = dr.position
	ld.size = dr.size
	ld.lines = L["desc_lines"]
	ld.fs = int(L["desc_fs"]) * s
	ld.col = darkd
	ld.center = bool(L.get("desc_center", true))
	ld.line_h = float(L.get("desc_lh", 0.88))
	ld.fn = CardArt.font_for(int(L.get("desc_font", 0)), 600)
	ld.fb = CardArt.font_for(int(L.get("desc_font", 0)), 800)
	c.add_child(ld)
	var ttxt: String = "Campeão" if cat == "champion" else ("Reação" if sub == "reaction" else "Talento")
	var ltb := _lbl(int(L["tab_fs"]) * s, white if cat == "champion" else dark, R.call(z["tab"]))
	if CardArt.font_for(int(L.get("desc_font", 0)), 800) != null:
		ltb.add_theme_font_override("font", CardArt.font_for(int(L.get("desc_font", 0)), 800))
	ltb.scale.x = float(L.get("zw_tab", 1.0))
	ltb.pivot_offset = ltb.size / 2.0
	ltb.text = ttxt
	c.add_child(ltb)
	return c


class DescDraw extends Control:
	## (1.49.83) descrição com segmentos em NEGRITO (**...**), quebras de linha
	## explícitas, alinhamento central opcional e fonte trocável.
	var lines: Array = []
	var fn: Font = null
	var fb: Font = null
	var fs: int = 12
	var col: Color = Color.BLACK
	var center: bool = true
	var line_h: float = 0.88

	func _segs(line: String) -> Array:
		var out: Array = []
		var parts := line.split("**")
		for k in parts.size():
			if String(parts[k]) == "":
				continue
			out.append([String(parts[k]), k % 2 == 1])
		return out

	func _draw() -> void:
		if fn == null or lines.is_empty():
			return
		var lh: float = fn.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).y * line_h
		var y0: float = (size.y - lh * lines.size()) / 2.0 + lh * 0.82
		for i in lines.size():
			var segs: Array = _segs(String(lines[i]))
			var total := 0.0
			for sg in segs:
				var f: Font = fb if bool(sg[1]) else fn
				total += f.get_string_size(String(sg[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
			var x := (size.x - total) / 2.0 if center else 2.0
			for sg in segs:
				var f2: Font = fb if bool(sg[1]) else fn
				draw_string(f2, Vector2(x, y0 + lh * i), String(sg[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, col)
				x += f2.get_string_size(String(sg[0]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
