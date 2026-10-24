class_name ArsenalScreen
extends Control
## ARSENAL: Heróis (lista + imagem ampliada) e Cartas (filtros, páginas,
## zoom navegável e criador de até 5 baralhos de 20 cartas).

signal back_requested

var content: Control
var decks: Array = []
var cur_deck := 0
var deck_page := 0
var filter := "all"
var page := 0
var filtered: Array = []
var page_lbl: Label
var card_ed_sel := ""
var card_ed_zone_rects := {}
var card_ed_cv: CardView = null
var card_ed_card: Dictionary = {}
var card_ed_ecat := ""
var card_ed_zf := 3.2
var card_ed_zoom := 1.0
var card_ed_pan := Vector2.ZERO
var card_ed_cv_base := Vector2.ZERO
var card_ed_hl := {}
var card_ed_handles := {}
var card_ed_world: Control = null
var card_ed_cv_ref: CardView = null
var card_ed_root_ref: Control = null
var card_ed_card_ref: Dictionary = {}
var deck_total_lbl: Label
var name_edit: LineEdit
var zoom_overlay: Control
var zoom_idx := 0
var zoom_list: Array = []
var card_edit_active := false
var card_ed_root: Control = null
var text_ed_open := false
var card_undo: Array = []
var save_flash: Label = null
var _swipe_acc := 0.0
var _swiped := false
var drag_view: CardView = null
var drag_src := ""
var drag_idx := -1
var ed: ScreenEditor
var ed_btn: Button
var title_lbl: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.045, 0.11)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	add_child(bg)
	decks = DeckStore.load_decks()
	var t := Label.new()
	title_lbl = t
	t.text = "ARSENAL"
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(440, 14)
	t.size = Vector2(400, 40)
	add_child(t)
	var bk := _btn(Vector2(30, 16), Vector2(140, 44), "VOLTAR", Color(0.28, 0.25, 0.38), 15)
	bk.pressed.connect(func() -> void: back_requested.emit())
	add_child(bk)
	content = Control.new()
	content.position = Vector2.ZERO
	content.size = Vector2(1280, 720)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	ed_btn = _btn(Vector2(1150, 16), Vector2(110, 40), "EDITOR", Color(0.2, 0.32, 0.3), 13)
	add_child(ed_btn)
	ed = ScreenEditor.new()
	add_child(ed)
	ed.setup({
		"editorbtn": ed_btn,
		"title": title_lbl,
		"voltar_top": bk,
	}, {
		"editorbtn": Rect2(1150, 16, 110, 40),
		"title": Rect2(440, 14, 400, 40),
		"voltar_top": Rect2(30, 16, 140, 44),
	}, "user://layout_arsenal.cfg")
	_show_home()


# ------------------------------------------------------------------ navegação
func _clear_content() -> void:
	for c in content.get_children():
		c.queue_free()


func _show_home() -> void:
	_clear_content()
	var bh := _btn(Vector2(390, 220), Vector2(500, 110), "HERÓIS", Color(0.45, 0.3, 0.12), 32)
	bh.pressed.connect(_show_heroes)
	content.add_child(bh)
	ed.add_group("home_herois", bh, Rect2(390, 220, 500, 110))
	var bc := _btn(Vector2(390, 380), Vector2(500, 110), "CARTAS", Color(0.16, 0.32, 0.5), 32)
	bc.pressed.connect(func() -> void: _show_cards())
	content.add_child(bc)
	ed.add_group("home_cartas", bc, Rect2(390, 380, 500, 110))


func _show_heroes() -> void:
	_clear_content()
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 70)
	scroll.size = Vector2(1200, 590)
	content.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)
	for h in CardDB.HEROES:
		var row := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.11, 0.09, 0.18, 0.92)
		sb.border_color = Color(0.5, 0.42, 0.25)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(10)
		row.add_theme_stylebox_override("panel", sb)
		row.custom_minimum_size = Vector2(1180, 150)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(row)
		var med := Panel.new()
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color.from_hsv(fmod(float(hash(h["id"]) % 360) / 360.0, 1.0), 0.55, 0.35)
		msb.set_corner_radius_all(14)
		msb.border_color = Color(0.95, 0.8, 0.4)
		msb.set_border_width_all(3)
		med.add_theme_stylebox_override("panel", msb)
		med.position = Vector2(16, 15)
		med.size = Vector2(120, 120)
		med.mouse_filter = Control.MOUSE_FILTER_STOP
		med.gui_input.connect(_on_hero_medal.bind(h))
		row.add_child(med)
		var words := String(h["name"]).split(" ")
		var ini := Label.new()
		ini.text = (String(words[0]).left(1) + (String(words[words.size() - 1]).left(1) if words.size() > 1 else "")).to_upper()
		ini.add_theme_font_size_override("font_size", 38)
		ini.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ini.position = Vector2.ZERO
		ini.size = Vector2(120, 120)
		ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		med.add_child(ini)
		var nm := Label.new()
		nm.text = String(h["name"])
		nm.add_theme_font_size_override("font_size", 26)
		nm.add_theme_color_override("font_color", Color(1, 0.96, 0.85))
		nm.position = Vector2(160, 18)
		nm.size = Vector2(600, 34)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(nm)
		var uses := _parse_uses(String(h.get("ult_desc", "")))
		var ul := Label.new()
		ul.text = "Habilidade: %s  —  Usos por partida: %d" % [h.get("ult", ""), uses]
		ul.add_theme_font_size_override("font_size", 16)
		ul.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
		ul.position = Vector2(160, 58)
		ul.size = Vector2(980, 24)
		ul.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ul)
		var ud := Label.new()
		ud.text = String(h.get("ult_desc", ""))
		ud.add_theme_font_size_override("font_size", 13)
		ud.add_theme_color_override("font_color", Color(0.85, 0.83, 0.92))
		ud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ud.clip_text = true
		ud.position = Vector2(160, 88)
		ud.size = Vector2(980, 52)
		ud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ud)
	var bk := _btn(Vector2(560, 670), Vector2(160, 44), "VOLTAR", Color(0.28, 0.25, 0.38), 14)
	bk.pressed.connect(_show_home)
	content.add_child(bk)


func _parse_uses(desc: String) -> int:
	var i := desc.find("Até ")
	if i >= 0:
		var n := desc.substr(i + 4, 1)
		if n.is_valid_int():
			return int(n)
	return 3


func _on_hero_medal(ev: InputEvent, h: Dictionary) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	_zoom_overlay_clear()
	zoom_overlay = Control.new()
	zoom_overlay.position = Vector2.ZERO
	zoom_overlay.size = Vector2(1280, 720)
	zoom_overlay.z_index = 1000
	add_child(zoom_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e2: InputEvent) -> void:
		if e2 is InputEventMouseButton and e2.pressed:
			_zoom_overlay_clear())
	zoom_overlay.add_child(dim)
	var med := Panel.new()
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color.from_hsv(fmod(float(hash(h["id"]) % 360) / 360.0, 1.0), 0.55, 0.4)
	msb.set_corner_radius_all(28)
	msb.border_color = Color(1, 0.88, 0.5)
	msb.set_border_width_all(4)
	med.add_theme_stylebox_override("panel", msb)
	med.position = Vector2(640 - 140, 120)
	med.size = Vector2(280, 280)
	med.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(med)
	var words := String(h["name"]).split(" ")
	var ini := Label.new()
	ini.text = (String(words[0]).left(1) + (String(words[words.size() - 1]).left(1) if words.size() > 1 else "")).to_upper()
	ini.add_theme_font_size_override("font_size", 90)
	ini.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.position = Vector2.ZERO
	ini.size = Vector2(280, 280)
	ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	med.add_child(ini)
	var nm := Label.new()
	nm.text = String(h["name"])
	nm.add_theme_font_size_override("font_size", 30)
	nm.add_theme_color_override("font_color", Color(1, 0.96, 0.85))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(340, 420)
	nm.size = Vector2(600, 40)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(nm)
	var ul := Label.new()
	ul.text = "Habilidade: %s  —  Usos: %d" % [h.get("ult", ""), _parse_uses(String(h.get("ult_desc", "")))]
	ul.add_theme_font_size_override("font_size", 15)
	ul.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	ul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ul.position = Vector2(240, 464)
	ul.size = Vector2(800, 22)
	ul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(ul)
	var ud := Label.new()
	ud.text = String(h.get("ult_desc", ""))
	ud.add_theme_font_size_override("font_size", 13)
	ud.add_theme_color_override("font_color", Color(0.88, 0.86, 0.95))
	ud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ud.position = Vector2(340, 492)
	ud.size = Vector2(600, 60)
	ud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(ud)


func _zoom_overlay_clear() -> void:
	if zoom_overlay != null and is_instance_valid(zoom_overlay):
		zoom_overlay.queue_free()
	zoom_overlay = null
	if card_edit_active:
		card_edit_active = false
		_show_cards()


# ------------------------------------------------------------------ cartas
func _show_cards() -> void:
	_clear_content()
	_recompute_filtered()
	var fx := [30, 190, 350, 510]
	var ft := ["TODAS", "CAMPEÕES", "TALENTOS", "REAÇÕES"]
	var fv := ["all", "champion", "talent", "reaction"]
	for k in 4:
		var b := _btn(Vector2(fx[k], 60), Vector2(150, 44), ft[k], Color(0.2, 0.24, 0.4), 14)
		b.pressed.connect(func() -> void:
			filter = fv[k]
			page = 0
			_show_cards())
		content.add_child(b)
		ed.add_group("filtro_%s" % fv[k], b, Rect2(fx[k], 60, 150, 44))
	# grade esquerda: 10 cartas (5 em cima, 5 embaixo)
	for i in 10:
		var idx: int = page * 10 + i
		var slot_pos := Vector2(30 + (i % 5) * 118, 120 + (i / 5) * 162)
		if idx < filtered.size():
			var card: Dictionary = filtered[idx]
			var cv := CardView.new()
			cv.setup(card, false, 1.0)
			cv.hover_enabled = false
			cv.drag_enabled = false
			cv.position = slot_pos
			var ci := idx
			cv.clicked.connect(func(_c: CardView) -> void: _open_browse(ci))
			if (decks[cur_deck]["cards"] as Array).has(String(card["name"])):
				cv.set_dimmed(true)  # já está no baralho: não pode repetir
			cv.drag_enabled = true
			cv.set_meta("src", "grid")
			cv.set_meta("idx", ci)
			cv.drag_started.connect(_on_drag_started)
			cv.drag_ended.connect(_on_drag_ended)
			content.add_child(cv)
		else:
			var empty := Panel.new()
			var esb := StyleBoxFlat.new()
			esb.bg_color = Color(0.1, 0.09, 0.16, 0.6)
			esb.border_color = Color(0.3, 0.28, 0.4)
			esb.set_border_width_all(1)
			esb.set_corner_radius_all(8)
			empty.add_theme_stylebox_override("panel", esb)
			empty.position = slot_pos
			empty.size = Vector2(110, 154)
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(empty)
	var pages: int = maxi(1, ceili(float(filtered.size()) / 10.0))
	var bp := _btn(Vector2(30, 460), Vector2(54, 48), "‹", Color(0.3, 0.28, 0.42), 22)
	ed.add_group("pag_ant", bp, Rect2(30, 460, 54, 48))
	bp.pressed.connect(func() -> void:
		page = maxi(0, page - 1)
		_show_cards())
	content.add_child(bp)
	var bn := _btn(Vector2(94, 460), Vector2(54, 48), "›", Color(0.3, 0.28, 0.42), 22)
	ed.add_group("pag_prox", bn, Rect2(94, 460, 54, 48))
	bn.pressed.connect(func() -> void:
		page = mini(pages - 1, page + 1)
		_show_cards())
	content.add_child(bn)
	page_lbl = Label.new()
	page_lbl.text = "Página %d/%d" % [page + 1, pages]
	page_lbl.add_theme_font_size_override("font_size", 14)
	page_lbl.add_theme_color_override("font_color", Color(0.8, 0.78, 0.9))
	page_lbl.position = Vector2(160, 472)
	page_lbl.size = Vector2(200, 22)
	ed.add_group("pag_lbl", page_lbl, Rect2(160, 472, 200, 22))
	content.add_child(page_lbl)

	# ---- criador de baralho (direita) ----
	name_edit = LineEdit.new()
	name_edit.text = String(decks[cur_deck]["name"])
	name_edit.position = Vector2(660, 60)
	name_edit.size = Vector2(360, 44)
	name_edit.text_changed.connect(func(t: String) -> void:
		decks[cur_deck]["name"] = t
		DeckStore.save_decks(decks))
	content.add_child(name_edit)
	for pg in 2:
		var b := _btn(Vector2(1040 + pg * 100, 60), Vector2(90, 44), "Pág %d" % (pg + 1), Color(0.2, 0.24, 0.4), 13)
		b.pressed.connect(func() -> void:
			deck_page = pg
			_show_cards())
		if pg == deck_page:
			(b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = Color(0.35, 0.55, 0.25)
		content.add_child(b)
	var dcards: Array = decks[cur_deck]["cards"]
	for i in 10:
		var idx: int = deck_page * 10 + i
		var slot_pos := Vector2(660 + (i % 5) * 118, 120 + (i / 5) * 162)
		if idx < dcards.size():
			var defc: Dictionary = _def_by_name(String(dcards[idx]))
			if not defc.is_empty():
				var cv2 := CardView.new()
				cv2.setup(defc, false, 1.0)
				cv2.hover_enabled = false
				cv2.drag_enabled = false
				cv2.position = slot_pos
				var ri := idx
				var di2 := idx
				cv2.clicked.connect(func(_c: CardView) -> void: _open_deck_browse(di2))
				cv2.drag_enabled = true
				cv2.set_meta("src", "deck")
				cv2.set_meta("idx", ri)
				cv2.drag_started.connect(_on_drag_started)
				cv2.drag_ended.connect(_on_drag_ended)
				content.add_child(cv2)
		else:
			var empty2 := Panel.new()
			var esb2 := StyleBoxFlat.new()
			esb2.bg_color = Color(0.1, 0.09, 0.16, 0.6)
			esb2.border_color = Color(0.3, 0.28, 0.4)
			esb2.set_border_width_all(1)
			esb2.set_corner_radius_all(8)
			empty2.add_theme_stylebox_override("panel", esb2)
			empty2.position = slot_pos
			empty2.size = Vector2(110, 154)
			empty2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(empty2)
	deck_total_lbl = Label.new()
	deck_total_lbl.text = "Baralho %d: %d/20 cartas" % [cur_deck + 1, dcards.size()]
	deck_total_lbl.add_theme_font_size_override("font_size", 14)
	deck_total_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	deck_total_lbl.position = Vector2(660, 460)
	deck_total_lbl.size = Vector2(320, 22)
	content.add_child(deck_total_lbl)
	for i in 5:
		var b := _btn(Vector2(660 + i * 90, 500), Vector2(80, 48), str(i + 1), Color(0.32, 0.26, 0.45), 16)
		b.pressed.connect(func() -> void:
			cur_deck = i
			deck_page = 0
			_show_cards())
		if i == cur_deck:
			(b.get_theme_stylebox("normal") as StyleBoxFlat).bg_color = Color(0.35, 0.55, 0.25)
		content.add_child(b)
	var bk := _btn(Vector2(1100, 660), Vector2(150, 48), "VOLTAR", Color(0.28, 0.25, 0.38), 14)
	bk.pressed.connect(_show_home)
	content.add_child(bk)


func _recompute_filtered() -> void:
	filtered = []
	for c in CardDB.playable_defs():
		match filter:
			"champion":
				if c["category"] == "champion":
					filtered.append(c)
			"talent":
				if c["category"] == "talent" and String(c.get("subcategory", "")) != "reaction":
					filtered.append(c)
			"reaction":
				if String(c.get("subcategory", "")) == "reaction":
					filtered.append(c)
			_:
				filtered.append(c)


func _def_by_name(nm: String) -> Dictionary:
	for c in CardDB.playable_defs():
		if c["name"] == nm:
			return c
	return {}


func _open_browse(start_idx: int) -> void:
	zoom_list = filtered.duplicate()
	zoom_idx = start_idx
	_swipe_acc = 0.0
	_swiped = false
	_zoom_overlay_clear()
	zoom_overlay = Control.new()
	zoom_overlay.position = Vector2.ZERO
	zoom_overlay.size = Vector2(1280, 720)
	zoom_overlay.z_index = 1000
	add_child(zoom_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e2: InputEvent) -> void:
		if e2 is InputEventMouseButton and e2.pressed:
			# (1.49.87) com o editor de carta ativo, clicar fora NÃO fecha
			if card_edit_active:
				return
			_zoom_overlay_clear())
	zoom_overlay.add_child(dim)
	_build_browse()


func _build_browse() -> void:
	for c in zoom_overlay.get_children():
		if c.name == "BrowseRoot":
			zoom_overlay.remove_child(c)
			c.free()
	var root := Control.new()
	root.name = "BrowseRoot"
	root.position = Vector2.ZERO
	root.size = Vector2(1280, 720)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(root)
	var card: Dictionary = zoom_list[zoom_idx]
	var cv := CardView.new()
	cv.setup(card, false, 3.2)
	cv.hover_enabled = false
	cv.drag_enabled = false
	cv.position = Vector2(640 - cv.size.x / 2.0, 360 - cv.size.y / 2.0)
	cv.mouse_filter = Control.MOUSE_FILTER_STOP
	if not card_edit_active:
		cv.clicked.connect(func(_c: CardView) -> void:
			if _swiped:
				_swiped = false
				return
			_zoom_overlay_clear())
	root.add_child(cv)
	var be := _btn(Vector2(20, 20), Vector2(190, 44), "EDITOR DE CARTA", Color(0.2, 0.32, 0.3), 12)
	be.pressed.connect(func() -> void:
		card_edit_active = not card_edit_active
		_build_browse())
	root.add_child(be)
	if card_edit_active:
		_build_card_editor(root, cv, card)
	if not card_edit_active:
		var bl := _btn(Vector2(180, 330), Vector2(70, 60), "‹", Color(0.3, 0.28, 0.42), 26)
		bl.pressed.connect(func() -> void: _browse_step(-1))
		root.add_child(bl)
		var br := _btn(Vector2(1030, 330), Vector2(70, 60), "›", Color(0.3, 0.28, 0.42), 26)
		br.pressed.connect(func() -> void: _browse_step(1))
		root.add_child(br)
	var cnt := Label.new()
	cnt.text = "%d / %d" % [zoom_idx + 1, zoom_list.size()]
	cnt.add_theme_font_size_override("font_size", 17)
	cnt.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cnt.position = Vector2(540, 640)
	cnt.size = Vector2(200, 20)
	root.add_child(cnt)


func _browse_step(d: int) -> void:
	if card_edit_active or text_ed_open:
		return  # no editor de cartas não se troca de carta
	if zoom_list.is_empty():
		return
	zoom_idx = (zoom_idx + d + filtered.size()) % filtered.size()
	_build_browse()


func _apply_card_ed_transform(cv: CardView) -> void:
	# (1.49.88) zoom (scroll, no cursor) + pan (arrastar o fundo), como um
	# visualizador de imagens: carta e alças compartilham a mesma transformação
	var z := card_ed_zoom
	if card_ed_world != null and is_instance_valid(card_ed_world):
		card_ed_world.pivot_offset = Vector2.ZERO
		card_ed_world.scale = Vector2(z, z)
		card_ed_world.position = card_ed_pan
	cv.pivot_offset = Vector2.ZERO
	cv.scale = Vector2(z, z)
	cv.position = card_ed_pan + Vector2(card_ed_cv_base.x * z, card_ed_cv_base.y * z)


func _refresh_zone_box(zone: String) -> void:
	# (1.49.87) o box de edição acompanha o texto EM TEMPO REAL
	if card_ed_cv_ref == null or not is_instance_valid(card_ed_cv_ref):
		return
	var L2: Dictionary = CardArt.layout_for(card_ed_card_ref, CardView.CARD_W, CardView.CARD_H)
	var trs: Dictionary = L2.get("text_rects", {})
	if not trs.has(zone) or not card_ed_hl.has(zone):
		return
	var zr: Rect2 = trs[zone]
	var hr := Rect2(card_ed_cv_ref.position.x + zr.position.x * card_ed_zf, card_ed_cv_ref.position.y + zr.position.y * card_ed_zf, zr.size.x * card_ed_zf, zr.size.y * card_ed_zf)
	card_ed_zone_rects[zone] = hr
	var hl: Panel = card_ed_hl[zone]
	hl.position = hr.position
	hl.size = hr.size
	var hs: Array = card_ed_handles.get(zone, [])
	if hs.size() == 8:
		var hr0 := hr
		if hr0.size.x < 46.0:
			hr0.position.x -= (46.0 - hr0.size.x) / 2.0
			hr0.size.x = 46.0
		if hr0.size.y < 26.0:
			hr0.position.y -= (26.0 - hr0.size.y) / 2.0
			hr0.size.y = 26.0
		var c2 := hr0.get_center()
		var pts := [Vector2(hr0.position.x, hr0.position.y), Vector2(c2.x, hr0.position.y), Vector2(hr0.end.x, hr0.position.y), Vector2(hr0.end.x, c2.y), Vector2(hr0.end.x, hr0.end.y), Vector2(c2.x, hr0.end.y), Vector2(hr0.position.x, hr0.end.y), Vector2(hr0.position.x, c2.y)]
		for k in 8:
			(hs[k] as Control).position = pts[k] - Vector2(7, 7)


func _editor_arrow_keys(ev: InputEvent) -> void:
	# (1.49.85) setas movem a zona de texto selecionada do editor de carta
	if text_ed_open or card_ed_sel == "" or card_ed_root == null or not is_instance_valid(card_ed_root):
		return
	if not (ev is InputEventKey and ev.pressed):
		return
	var step := 10.0 if ev.shift_pressed else 2.0
	var d := Vector2.ZERO
	match ev.keycode:
		KEY_LEFT: d = Vector2(-step, 0)
		KEY_RIGHT: d = Vector2(step, 0)
		KEY_UP: d = Vector2(0, -step)
		KEY_DOWN: d = Vector2(0, step)
	if d == Vector2.ZERO:
		return
	CardArt.bump_offset(card_ed_ecat, card_ed_sel, d / card_ed_zf)
	_build_browse()
	get_viewport().set_input_as_handled()


func _input(ev: InputEvent) -> void:
	_editor_arrow_keys(ev)
	if card_edit_active and ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP or ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var z0 := card_ed_zoom
			var dz := 0.25 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else -0.25
			card_ed_zoom = clampf(card_ed_zoom + dz, 1.0, 4.0)
			# zoom no ponto sob o cursor (como visualizador de imagem)
			var m: Vector2 = ev.global_position
			card_ed_pan = m - (m - card_ed_pan) * (card_ed_zoom / z0)
			if card_ed_zoom == 1.0:
				card_ed_pan = Vector2.ZERO
			if card_ed_cv_ref != null and is_instance_valid(card_ed_cv_ref):
				_apply_card_ed_transform(card_ed_cv_ref)
			get_viewport().set_input_as_handled()
			return
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		if card_edit_active:
			card_edit_active = false
			_build_browse()
			get_viewport().set_input_as_handled()
		elif zoom_overlay != null and is_instance_valid(zoom_overlay):
			_zoom_overlay_clear()
			get_viewport().set_input_as_handled()
	# zoom do Arsenal: setas do teclado e swipe (dedo no celular / arrasto do mouse)
	if zoom_overlay == null or not is_instance_valid(zoom_overlay):
		return
	if card_edit_active and ev is InputEventKey and ev.pressed and ev.keycode == KEY_Z and ev.ctrl_pressed:
		_card_undo()
		get_viewport().set_input_as_handled()
		return
	if card_edit_active or text_ed_open:
		return
	if ev is InputEventKey and ev.pressed:
		if ev.keycode == KEY_LEFT or ev.is_action_pressed("ui_left"):
			_browse_step(-1)
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_RIGHT or ev.is_action_pressed("ui_right"):
			_browse_step(1)
			get_viewport().set_input_as_handled()
	elif ev is InputEventScreenDrag:
		_swipe_acc += ev.relative.x
		if abs(_swipe_acc) > 60.0:
			_swiped = true
			_browse_step(1 if _swipe_acc < 0.0 else -1)
			_swipe_acc = 0.0
	elif ev is InputEventMouseMotion and ev.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_swipe_acc += ev.relative.x
		if abs(_swipe_acc) > 80.0:
			_swiped = true
			_browse_step(1 if _swipe_acc < 0.0 else -1)
			_swipe_acc = 0.0
	elif ev is InputEventMouseButton:
		_swipe_acc = 0.0


func _open_deck_browse(start_idx: int) -> void:
	zoom_list = []
	for nm2 in decks[cur_deck]["cards"]:
		var d2 := _def_by_name(String(nm2))
		if not d2.is_empty():
			zoom_list.append(d2)
	if zoom_list.is_empty():
		return
	zoom_idx = clampi(start_idx, 0, zoom_list.size() - 1)
	_swipe_acc = 0.0
	_swiped = false
	_zoom_overlay_clear()
	zoom_overlay = Control.new()
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.position = Vector2.ZERO
	zoom_overlay.size = Vector2(1280, 720)
	zoom_overlay.z_index = 1000
	add_child(zoom_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e2: InputEvent) -> void:
		if e2 is InputEventMouseButton and e2.pressed:
			card_edit_active = false
			_zoom_overlay_clear()
			_show_cards())
	zoom_overlay.add_child(dim)
	_build_browse()


func _on_drag_started(v: CardView) -> void:
	drag_view = v
	drag_src = String(v.get_meta("src", ""))
	drag_idx = int(v.get_meta("idx", -1))
	v.z_index = 300


func _on_drag_ended(v: CardView) -> void:
	var m := get_global_mouse_position()
	if drag_src == "grid" and m.x >= 600.0:
		var card: Dictionary = filtered[drag_idx] if drag_idx < filtered.size() else {}
		var dc: Array = decks[cur_deck]["cards"]
		if not card.is_empty() and dc.size() < 20 and not dc.has(card["name"]):
			dc.append(card["name"])
			DeckStore.save_decks(decks)
	elif drag_src == "deck" and m.x < 600.0:
		var dc2: Array = decks[cur_deck]["cards"]
		if drag_idx >= 0 and drag_idx < dc2.size():
			dc2.remove_at(drag_idx)
			DeckStore.save_decks(decks)
	drag_view = null
	drag_src = ""
	_show_cards()


func _process(_d: float) -> void:
	if drag_view != null and is_instance_valid(drag_view):
		drag_view.global_position = get_global_mouse_position() - drag_view.size / 2.0


func _rebuild_card_editor() -> void:
	if card_ed_cv == null or not is_instance_valid(card_ed_cv):
		return
	_build_browse()


func _push_card_undo() -> void:
	card_undo.append(CardArt.snapshot())
	if card_undo.size() > 40:
		card_undo.pop_front()


func _card_undo() -> void:
	if card_undo.is_empty():
		return
	CardArt.restore(card_undo.pop_back())
	_build_browse()


func _build_card_editor(root: Control, cv: CardView, card: Dictionary) -> void:
	# Editor de cartas: trava a navegação; move/escala elementos do TIPO
	# (todas as cartas do tipo) e edita o texto SÓ desta carta.
	var cat: String = String(card.get("category", ""))
	var csub: String = String(card.get("subcategory", ""))
	var ecat: String = "reaction" if csub == "reaction" else cat
	var zf := 3.2
	var L: Dictionary = CardArt.layout_for(card, CardView.CARD_W, CardView.CARD_H)
	card_ed_root = Control.new()
	card_ed_root.position = Vector2.ZERO
	card_ed_root.size = Vector2(1280, 720)
	card_ed_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(card_ed_root)
	card_ed_cv = cv
	card_ed_card = card
	card_ed_ecat = ecat
	card_ed_zf = zf
	card_ed_cv_ref = cv
	card_ed_root_ref = card_ed_root
	card_ed_card_ref = card
	card_ed_hl = {}
	card_ed_handles = {}
	card_ed_world = Control.new()
	card_ed_world.position = Vector2.ZERO
	card_ed_world.size = Vector2(1280, 720)
	card_ed_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_ed_root.add_child(card_ed_world)
	# (1.49.88) área de PAN: arrastar o fundo (zoom > 1) move a carta
	var pcatch := Control.new()
	pcatch.position = Vector2.ZERO
	pcatch.size = Vector2(1280, 720)
	pcatch.mouse_filter = Control.MOUSE_FILTER_STOP
	card_ed_root.add_child(pcatch)
	card_ed_root.move_child(pcatch, 0)
	var pst := {"on": false, "last": Vector2.ZERO}
	pcatch.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			pst["on"] = ev.pressed
			pst["last"] = ev.global_position
		elif ev is InputEventMouseMotion and bool(pst["on"]) and card_ed_zoom > 1.0:
			card_ed_pan += ev.global_position - (pst["last"] as Vector2)
			pst["last"] = ev.global_position
			_apply_card_ed_transform(cv))
	card_ed_cv_base = cv.position
	_apply_card_ed_transform(cv)
	card_ed_zone_rects = {}
	for e in ["gem", "name", "abil", "desc", "tab"]:
		var zr: Rect2 = L.get("text_rects", {}).get(e, L["zones"][e])
		var hr := Rect2(cv.position.x + zr.position.x * zf, cv.position.y + zr.position.y * zf, zr.size.x * zf, zr.size.y * zf)
		card_ed_zone_rects[e] = hr
		var hl := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Color(1, 0.35, 0.3, 0.95) if e == card_ed_sel else Color(1, 0.85, 0.2, 0.95)
		sb.set_border_width_all(3 if e == card_ed_sel else 2)
		hl.add_theme_stylebox_override("panel", sb)
		hl.position = hr.position
		hl.size = hr.size
		hl.mouse_filter = Control.MOUSE_FILTER_STOP
		card_ed_world.add_child(hl)
		card_ed_hl[e] = hl
		var st := {"on": false, "last": Vector2.ZERO, "moved": Vector2.ZERO}
		hl.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				if ev.pressed:
					if ev.double_click:
						# (1.49.87) dois cliques = editar o TEXTO desta zona
						_open_text_editor(card_ed_root_ref, cv, card, e)
						return
					# (1.49.85) clicar em outra zona JA a seleciona (estilo Photoshop)
					if card_ed_sel != e:
						card_ed_sel = e
						_rebuild_card_editor()
						return
					st["on"] = true
					st["last"] = ev.global_position
					st["moved"] = Vector2.ZERO
					_push_card_undo()
				else:
					st["on"] = false
					if (st["moved"] as Vector2).length() > 1.0:
						CardArt.bump_offset(ecat, e, (st["moved"] as Vector2) / zf)
						_build_browse()
			elif ev is InputEventMouseMotion and st["on"]:
				var d: Vector2 = (ev.global_position - (st["last"] as Vector2)) / card_ed_zoom
				st["last"] = ev.global_position
				st["moved"] = (st["moved"] as Vector2) + d
				hl.position += d)
	# (1.49.85) alças estilo Ctrl+T na zona selecionada: arrastar escala o
	# TEXTO dessa zona DESTA carta (sem espelhar em outros textos/cartas)
	if card_ed_sel != "" and card_ed_zone_rects.has(card_ed_sel):
		var hr0: Rect2 = card_ed_zone_rects[card_ed_sel]
		# (1.49.87) alças com afastamento mínimo em zonas pequenas (ex.: selo)
		if hr0.size.x < 46.0:
			hr0.position.x -= (46.0 - hr0.size.x) / 2.0
			hr0.size.x = 46.0
		if hr0.size.y < 26.0:
			hr0.position.y -= (26.0 - hr0.size.y) / 2.0
			hr0.size.y = 26.0
		var zone: String = card_ed_sel
		var center := hr0.get_center()
		var pts := [Vector2(hr0.position.x, hr0.position.y), Vector2(center.x, hr0.position.y), Vector2(hr0.end.x, hr0.position.y), Vector2(hr0.end.x, center.y), Vector2(hr0.end.x, hr0.end.y), Vector2(center.x, hr0.end.y), Vector2(hr0.position.x, hr0.end.y), Vector2(hr0.position.x, center.y)]
		for k in 8:
			var hd := Panel.new()
			var hsb := StyleBoxFlat.new()
			hsb.bg_color = Color(0.85, 0.9, 1.0)
			hsb.border_color = Color(0.25, 0.45, 0.9)
			hsb.set_border_width_all(2)
			hd.add_theme_stylebox_override("panel", hsb)
			hd.size = Vector2(14, 14)
			hd.mouse_filter = Control.MOUSE_FILTER_STOP
			card_ed_world.add_child(hd)
			if not card_ed_handles.has(zone):
				card_ed_handles[zone] = []
			(card_ed_handles[zone] as Array).append(hd)
			hd.position = pts[k] - Vector2(7, 7)
			# (1.49.88) resize LINEAR e natural: o fator é proporcional ao
			# deslocamento em relação ao tamanho do box (nada de explosões)
			var hst := {"on": false, "start": Vector2.ZERO, "z0": 1.0, "w0": 1.0, "hh": 24.0, "hw": 24.0}
			hd.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
					if ev.pressed:
						hst["on"] = true
						hst["start"] = ev.global_position
						hst["z0"] = CardArt.zone_textscale(String(card.get("name", "")), zone)
						hst["w0"] = CardArt.zone_textwidth(String(card.get("name", "")), zone)
						hst["hh"] = maxf(24.0, hr0.size.y)
						hst["hw"] = maxf(24.0, hr0.size.x)
						_push_card_undo()
					else:
						hst["on"] = false
						_build_browse()
				elif ev is InputEventMouseMotion and bool(hst["on"]):
					var dm: Vector2 = (ev.global_position - (hst["start"] as Vector2)) / card_ed_zoom
					var fv := 1.0
					var fh := 1.0
					match k:
						0, 1, 2: fv = 1.0 - dm.y / float(hst["hh"])
						4, 5, 6: fv = 1.0 + dm.y / float(hst["hh"])
					match k:
						2, 4, 3: fh = 1.0 + dm.x / float(hst["hw"])
						0, 6, 7: fh = 1.0 - dm.x / float(hst["hw"])
					fv = clampf(fv, 0.4, 3.0)
					fh = clampf(fh, 0.5, 2.0)
					CardArt.set_zone_textscale(String(card.get("name", "")), zone, float(hst["z0"]) * fv)
					CardArt.set_zone_textwidth(String(card.get("name", "")), zone, float(hst["w0"]) * fh)
					_refresh_zone_box(zone))
	var bt := _btn(Vector2(cv.position.x, cv.position.y - 34), Vector2(160, 30), "TEXTO DESTA CARTA", Color(0.4, 0.32, 0.18), 11)
	bt.pressed.connect(func() -> void:
		_push_card_undo()
		_open_text_editor(root, cv, card, card_ed_sel if card_ed_sel != "" else "desc"))
	card_ed_root.add_child(bt)
	var bsv := _btn(Vector2(cv.position.x + cv.size.x - 110, cv.position.y - 34), Vector2(110, 30), "SALVAR", Color(0.2, 0.4, 0.25), 11)
	bsv.pressed.connect(func() -> void:
		CardArt.save_card_layout()
		if save_flash != null and is_instance_valid(save_flash):
			save_flash.text = "ATUALIZAÇÕES SALVAS!")
	card_ed_root.add_child(bsv)
	# (1.49.87) VOLTAR sai do modo editor (ESC também); clicar fora NÃO sai
	var bvol := _btn(Vector2(cv.position.x + cv.size.x - 230, cv.position.y - 34), Vector2(110, 30), "VOLTAR", Color(0.4, 0.3, 0.3), 11)
	bvol.pressed.connect(func() -> void:
		card_edit_active = false
		_build_browse())
	card_ed_root.add_child(bvol)
	save_flash = Label.new()
	save_flash.add_theme_font_size_override("font_size", 12)
	save_flash.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	save_flash.position = Vector2(cv.position.x + cv.size.x - 230, cv.position.y - 30)
	save_flash.size = Vector2(110, 20)
	card_ed_root.add_child(save_flash)
	var bhint := Label.new()
	bhint.text = "Editor: arraste os elementos | H/V tamanho | Ctrl+Z desfaz | sem trocar de carta"
	bhint.add_theme_font_size_override("font_size", 11)
	bhint.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	bhint.position = Vector2(220, 20)
	bhint.size = Vector2(620, 18)
	card_ed_root.add_child(bhint)


func _open_text_editor(root: Control, cv: CardView, card: Dictionary, zone: String = "desc") -> void:
	# (1.49.87) edita SOMENTE o texto da zona selecionada
	text_ed_open = true
	var modal := Control.new()
	modal.position = Vector2.ZERO
	modal.size = Vector2(1280, 720)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(modal)
	var pn := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	sb.border_color = Color(1, 0.85, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	pn.add_theme_stylebox_override("panel", sb)
	pn.position = Vector2(60, 60)
	pn.size = Vector2(430, 300 if zone == "desc" else 240)
	pn.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.add_child(pn)
	var nomes := {"gem": "PODER", "name": "NOME", "abil": "HABILIDADE", "desc": "DESCRIÇÃO", "tab": "SELO"}
	var lt := Label.new()
	lt.text = "Editar texto: %s (somente desta carta)" % nomes.get(zone, zone)
	lt.add_theme_font_size_override("font_size", 13)
	lt.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	lt.position = Vector2(15, 12)
	lt.size = Vector2(400, 20)
	pn.add_child(lt)
	var ov0: Dictionary = CardArt.text_overrides.get(String(card.get("name", "")), {})
	var cur: String = ""
	if zone == "name":
		cur = String(ov0.get("name", card.get("name", "")))
	elif zone == "desc":
		cur = String(ov0.get("desc", String(card.get("ability_desc", ""))))
	elif zone == "abil":
		cur = String(ov0.get("abil_txt", _default_abil_text(card)))
	elif zone == "tab":
		cur = String(ov0.get("tab_txt", _default_tab_text(card)))
	var te := TextEdit.new()
	te.text = cur
	te.position = Vector2(15, 40)
	te.size = Vector2(400, 120 if zone == "desc" else 44)
	pn.add_child(te)
	var y0 := 170 if zone == "desc" else 96
	var font_id := [int(ov0.get("font", 0))]
	var FN := ["Baloo", "Fredoka", "Heavy"]
	var lhv := [float(ov0.get("lh", 1.12))]
	if zone == "desc":
		var bneg := _btn(Vector2(15, y0), Vector2(120, 34), "NEGRITO", Color(0.3, 0.3, 0.42), 11)
		bneg.pressed.connect(func() -> void:
			var sel := te.get_selected_text()
			if sel.is_empty():
				sel = te.text
				te.select_all()
			te.delete_selection()
			te.insert_text_at_caret("**" + sel + "**"))
		pn.add_child(bneg)
		var ccent := CheckBox.new()
		ccent.name = "ccent"
		ccent.text = "CENTRALIZAR"
		ccent.button_pressed = bool(ov0.get("center", true))
		ccent.add_theme_font_size_override("font_size", 12)
		ccent.position = Vector2(15, y0 + 42)
		ccent.size = Vector2(140, 30)
		pn.add_child(ccent)
		var blh1 := _btn(Vector2(300, y0), Vector2(40, 34), "L-", Color(0.3, 0.3, 0.42), 11)
		var blh2 := _btn(Vector2(346, y0), Vector2(40, 34), "L+", Color(0.3, 0.3, 0.42), 11)
		var llh := Label.new()
		llh.text = "entrelinha %.2f" % lhv[0]
		llh.add_theme_font_size_override("font_size", 10)
		llh.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
		llh.position = Vector2(296, y0 + 40)
		llh.size = Vector2(110, 16)
		pn.add_child(llh)
		blh1.pressed.connect(func() -> void:
			lhv[0] = clampf(lhv[0] - 0.08, 0.8, 2.0)
			llh.text = "entrelinha %.2f" % lhv[0])
		blh2.pressed.connect(func() -> void:
			lhv[0] = clampf(lhv[0] + 0.08, 0.8, 2.0)
			llh.text = "entrelinha %.2f" % lhv[0])
		pn.add_child(blh1)
		pn.add_child(blh2)
	var bfont := _btn(Vector2(160, y0), Vector2(130, 34), "FONTE: " + FN[font_id[0]], Color(0.25, 0.35, 0.45), 11)
	bfont.pressed.connect(func() -> void:
		font_id[0] = (font_id[0] + 1) % FN.size()
		bfont.text = "FONTE: " + FN[font_id[0]])
	pn.add_child(bfont)
	var okb := _btn(Vector2(15, y0 + 86), Vector2(160, 44), "APLICAR", Color(0.18, 0.42, 0.24), 13)
	okb.pressed.connect(func() -> void:
		var cname: String = String(card.get("name", ""))
		CardArt.set_zone_text(cname, zone, te.text)
		CardArt.set_text_style(cname, font_id[0], bool(ov0.get("center", true)) if zone != "desc" else (pn.get_node_or_null("ccent") as CheckBox).button_pressed, lhv[0])
		text_ed_open = false
		modal.queue_free()
		_build_browse())
	pn.add_child(okb)
	var cb := _btn(Vector2(185, y0 + 86), Vector2(160, 44), "CANCELAR", Color(0.45, 0.2, 0.22), 13)
	cb.pressed.connect(func() -> void:
		text_ed_open = false
		modal.queue_free())
	pn.add_child(cb)


func _default_abil_text(card: Dictionary) -> String:
	var at: String = String(card.get("ability_type", ""))
	var tipo: String = "Constante" if at == "constant" else ("Instantânea" if at == "instant" else "")
	return ("%s (%s)" % [card.get("ability_name", ""), tipo]) if tipo != "" else String(card.get("ability_name", ""))


func _default_tab_text(card: Dictionary) -> String:
	var sub: String = String(card.get("subcategory", ""))
	return "Campeão" if String(card.get("category", "")) == "champion" else ("Reação" if sub == "reaction" else "Talento")


func _btn(pos: Vector2, sz: Vector2, text: String, bg: Color, fs: int) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.16)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9))
	b.add_theme_font_size_override("font_size", fs)
	return b
