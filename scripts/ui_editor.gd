class_name ScreenEditor
extends Control
## Editor de layout genérico (arrastar e soltar) reutilizável em QUALQUER tela.
## Regra do projeto: todo elemento de UI deve ser registrado aqui para ser
## editável — cada elemento é INDIVIDUAL (nunca grupos fundidos).
## (1.49.83) Redimensionamento estilo Photoshop (Ctrl+T): 8 alças arrastáveis
## (cantos + meios das bordas) no elemento SELECIONADO — sem botões -/+.
## Seleção: o MENOR retângulo registrado que contém o clique (permite
## selecionar elementos que ficam sob outras camadas, ex.: banner).
## DELETE exclui, Ctrl+Z desfaz, ESC fecha (salvando automaticamente).

signal group_moved(id)
signal group_resized(id)
signal group_deleted(id)
signal group_undone(id)
signal toggled(active)

var groups := {}
var rects := {}
var defaults := {}
var scales := {}          # id -> Vector2 (escala por eixo)
var hls := {}
var handles := {}         # id -> Array[Panel] (8 alças)
var undo_stack: Array = []
var selected := ""
var drag_id := ""
var drag_off := Vector2.ZERO
var resize_id := ""
var resize_handle := -1
var active := false
var cfg_path := "user://layout.cfg"
var overlay: Control
var save_flash: Label
var bar_rect := Rect2(240, 84, 800, 40)

const HANDLE_SZ := 12.0


func setup(p_groups: Dictionary, p_rects: Dictionary, p_cfg: String) -> void:
	for id in p_groups:
		add_group(String(id), p_groups[id], p_rects[id])
	cfg_path = p_cfg
	_build_overlay()
	_load()


func add_group(id: String, node: Control, rect: Rect2) -> void:
	groups[id] = node
	rects[id] = rect
	defaults[id] = node.position
	scales[id] = Vector2.ONE
	if defaults[id] == Vector2.ZERO:
		node.pivot_offset = rect.position + rect.size / 2.0
	else:
		node.pivot_offset = rect.size / 2.0
	if overlay != null:
		_make_highlight(id)
		_update_highlights()


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1280, 720)
	overlay.visible = false
	add_child(overlay)
	var catch := ColorRect.new()
	catch.color = Color(0, 0, 0, 0.18)
	catch.position = Vector2.ZERO
	catch.size = Vector2(1280, 720)
	catch.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(catch)
	for id in groups:
		_make_highlight(id)
	var bar := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	bsb.border_color = Color(1, 0.85, 0.2)
	bsb.set_border_width_all(2)
	bsb.set_corner_radius_all(10)
	bar.add_theme_stylebox_override("panel", bsb)
	bar.position = bar_rect.position
	bar.size = bar_rect.size
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bar)
	var lbl := Label.new()
	lbl.text = "EDITOR: arraste | alças nos cantos/bordas p/ esticar | DELETE exclui | Ctrl+Z desfaz | ESC sai"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	lbl.position = Vector2(12, 4)
	lbl.size = Vector2(600, 16)
	bar.add_child(lbl)
	save_flash = Label.new()
	save_flash.text = ""
	save_flash.add_theme_font_size_override("font_size", 10)
	save_flash.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	save_flash.position = Vector2(12, 22)
	save_flash.size = Vector2(300, 14)
	bar.add_child(save_flash)
	var b1 := _btn(Vector2(628, 8), Vector2(56, 24), "SALVAR", Color(0.2, 0.4, 0.25))
	b1.pressed.connect(func() -> void:
		_save()
		_flash("SALVO!"))
	bar.add_child(b1)
	var b2 := _btn(Vector2(690, 8), Vector2(62, 24), "RESETAR", Color(0.4, 0.32, 0.18))
	b2.pressed.connect(func() -> void:
		_reset()
		_flash("RESETADO!"))
	bar.add_child(b2)
	var b3 := _btn(Vector2(758, 8), Vector2(40, 24), "SAIR", Color(0.45, 0.2, 0.22))
	b3.pressed.connect(func() -> void: toggle())
	bar.add_child(b3)
	_update_highlights()


func _make_highlight(id: String) -> void:
	var hl := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(1, 0.85, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	hl.add_theme_stylebox_override("panel", sb)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hl)
	hls[id] = hl
	var lb := Label.new()
	lb.text = id
	lb.add_theme_font_size_override("font_size", 9)
	lb.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	lb.position = Vector2(4, 2)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hl.add_child(lb)
	var hs := []
	for k in 8:
		var hd := Panel.new()
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(0.85, 0.9, 1.0)
		hsb.border_color = Color(0.25, 0.45, 0.9)
		hsb.set_border_width_all(2)
		hd.add_theme_stylebox_override("panel", hsb)
		hd.size = Vector2(HANDLE_SZ, HANDLE_SZ)
		hd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hd.visible = false
		overlay.add_child(hd)
		hs.append(hd)
	handles[id] = hs


func _btn(pos: Vector2, sz: Vector2, text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.18)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	b.add_theme_font_size_override("font_size", 9)
	return b


func _flash(txt: String) -> void:
	if save_flash == null:
		return
	save_flash.text = txt
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(func() -> void: save_flash.text = "")


func toggle() -> void:
	active = not active
	overlay.visible = active
	drag_id = ""
	resize_id = ""
	if not active:
		_save()
		_flash("SALVO!")
	toggled.emit(active)
	_update_highlights()


func position_of(id: String) -> Vector2:
	if groups.has(id):
		return (groups[id] as Control).position
	return Vector2.ZERO


func scale_of(id: String) -> float:
	var s: Vector2 = scales.get(id, Vector2.ONE)
	return (s.x + s.y) / 2.0


func _edit_rect(id: String) -> Rect2:
	var base: Rect2 = rects[id]
	if not is_instance_valid(groups.get(id)):
		return Rect2()
	var node: Control = groups[id]
	var sc: Vector2 = scales[id]
	var off: Vector2 = node.position - defaults[id]
	var half := base.size * (Vector2.ONE - sc) / 2.0
	return Rect2(off + base.position + half, base.size * sc)


func _handle_rects(r: Rect2) -> Array:
	var mx := r.position.x
	var my := r.position.y
	var Mx := r.end.x
	var My := r.end.y
	var cx := (mx + Mx) / 2.0
	var cy := (my + My) / 2.0
	var pts := [Vector2(mx, my), Vector2(cx, my), Vector2(Mx, my), Vector2(Mx, cy), Vector2(Mx, My), Vector2(cx, My), Vector2(mx, My), Vector2(mx, cy)]
	var out := []
	for p in pts:
		out.append(Rect2(p - Vector2(HANDLE_SZ / 2.0, HANDLE_SZ / 2.0), Vector2(HANDLE_SZ, HANDLE_SZ)))
	return out


func prune() -> void:
	# (1.49.84) remove grupos cujos nós foram liberados (páginas dinâmicas):
	# evita "previously freed instance" e congelamento.
	var dead := []
	for id in groups:
		if not is_instance_valid(groups[id]):
			dead.append(id)
	for id in dead:
		groups.erase(id)
		rects.erase(id)
		defaults.erase(id)
		scales.erase(id)
		if hls.has(id):
			if is_instance_valid(hls[id]):
				hls[id].queue_free()
			hls.erase(id)
		if handles.has(id):
			for h in handles[id]:
				if is_instance_valid(h):
					h.queue_free()
			handles.erase(id)
		if selected == id:
			selected = ""


func _update_highlights() -> void:
	prune()
	for id in hls:
		var hl: Panel = hls[id]
		var r: Rect2 = _edit_rect(id)
		hl.position = r.position
		hl.size = r.size
		var sb: StyleBoxFlat = hl.get_theme_stylebox("panel")
		if id == selected:
			sb.border_color = Color(1, 0.35, 0.3)
			sb.set_border_width_all(3)
		else:
			sb.border_color = Color(1, 0.85, 0.2, 0.9)
			sb.set_border_width_all(2)
		hl.visible = active and is_instance_valid(groups.get(id)) and (groups[id] as Control).is_visible_in_tree()
		var hs: Array = handles[id]
		var hrects := _handle_rects(r)
		for k in 8:
			hs[k].position = hrects[k].position
			hs[k].visible = active and id == selected


func _snap(id: String) -> Dictionary:
	var node: Control = groups[id]
	if not is_instance_valid(node):
		return {"id": id, "pos": Vector2.ZERO, "scale": Vector2.ONE, "vis": false}
	return {"id": id, "pos": node.position, "scale": scales[id], "vis": node.visible}


func _delete_selected() -> void:
	if selected == "" or not groups.has(selected):
		return
	undo_stack.append(_snap(selected))
	(groups[selected] as Control).visible = false
	group_deleted.emit(selected)
	_update_highlights()


func _undo() -> void:
	if undo_stack.is_empty():
		return
	var e: Dictionary = undo_stack.pop_back()
	var id: String = e["id"]
	var node: Control = groups[id]
	node.position = e["pos"]
	node.visible = e["vis"]
	scales[id] = e["scale"]
	node.scale = scales[id]
	group_undone.emit(id)
	_update_highlights()


func _pick(m: Vector2) -> String:
	# (1.49.83) o MENOR retângulo que contém o clique vence — permite pegar
	# elementos sob outras camadas (ex.: banner dentro do field).
	var best := ""
	var best_area := INF
	for id in groups:
		if not is_instance_valid(groups[id]):
			continue
		if not (groups[id] as Control).is_visible_in_tree():
			continue
		var r := _edit_rect(id)
		if r.has_point(m) and r.get_area() < best_area:
			best_area = r.get_area()
			best = id
	return best


func _apply_resize(m: Vector2) -> void:
	var id := resize_id
	var base: Rect2 = rects[id]
	var node: Control = groups[id]
	var r := _edit_rect(id)
	var left := r.position.x
	var top := r.position.y
	var right := r.end.x
	var bottom := r.end.y
	match resize_handle:
		0:
			left = m.x
			top = m.y
		1:
			top = m.y
		2:
			right = m.x
			top = m.y
		3:
			right = m.x
		4:
			right = m.x
			bottom = m.y
		5:
			bottom = m.y
		6:
			left = m.x
			bottom = m.y
		7:
			left = m.x
	var w := maxf(24.0, right - left)
	var hgt := maxf(16.0, bottom - top)
	var sc := Vector2(w / base.size.x, hgt / base.size.y)
	sc.x = clampf(sc.x, 0.3, 3.0)
	sc.y = clampf(sc.y, 0.3, 3.0)
	# ancora a borda oposta: recalcula posição do nó pelo retângulo desenhado
	var drawn_w := base.size.x * sc.x
	var drawn_h := base.size.y * sc.y
	var nx := left if resize_handle in [0, 6, 7] else (right - drawn_w if resize_handle in [2, 3, 4] else left - (drawn_w - (right - left)) / 2.0)
	var ny := top if resize_handle in [0, 1, 2] else (bottom - drawn_h if resize_handle in [4, 5, 6] else top - (drawn_h - (bottom - top)) / 2.0)
	scales[id] = sc
	node.scale = sc
	node.position = defaults[id] + (Vector2(nx, ny) - base.position - (base.size * (Vector2.ONE - sc)) / 2.0)
	group_resized.emit(id)
	_update_highlights()


func _input(ev: InputEvent) -> void:
	if not active:
		return
	if ev is InputEventKey and ev.pressed:
		if ev.keycode == KEY_ESCAPE:
			toggle()
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_DELETE and selected != "":
			_delete_selected()
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_Z and ev.ctrl_pressed:
			_undo()
			get_viewport().set_input_as_handled()
		elif selected != "" and groups.has(selected) and is_instance_valid(groups[selected]):
			# (1.49.85) setas do teclado movem o elemento selecionado
			var step := 10.0 if ev.shift_pressed else 2.0
			var d := Vector2.ZERO
			match ev.keycode:
				KEY_LEFT: d = Vector2(-step, 0)
				KEY_RIGHT: d = Vector2(step, 0)
				KEY_UP: d = Vector2(0, -step)
				KEY_DOWN: d = Vector2(0, step)
			if d != Vector2.ZERO:
				(groups[selected] as Control).position += d
				group_moved.emit(selected)
				_update_highlights()
				get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			var m: Vector2 = ev.global_position
			if bar_rect.has_point(m):
				return
			# alças do selecionado primeiro
			if selected != "" and handles.has(selected):
				var hrects := _handle_rects(_edit_rect(selected))
				for k in 8:
					if hrects[k].has_point(m):
						resize_id = selected
						resize_handle = k
						undo_stack.append(_snap(selected))
						get_viewport().set_input_as_handled()
						return
			var pick := _pick(m)
			if pick != "":
				drag_id = pick
				selected = pick
				undo_stack.append(_snap(pick))
				drag_off = m - (groups[pick] as Control).position
				get_viewport().set_input_as_handled()
				_update_highlights()
		else:
			if bar_rect.has_point(ev.global_position):
				return  # (1.49.84) deixa o release chegar nos botões da barra
			drag_id = ""
			resize_id = ""
			get_viewport().set_input_as_handled()
	elif ev is InputEventMouseMotion:
		if resize_id != "":
			_apply_resize(ev.global_position)
			get_viewport().set_input_as_handled()
		elif drag_id != "":
			(groups[drag_id] as Control).position = ev.global_position - drag_off
			group_moved.emit(drag_id)
			_update_highlights()
			get_viewport().set_input_as_handled()


func _save() -> void:
	prune()
	var cf := ConfigFile.new()
	for id in groups:
		var node: Control = groups[id]
		if not is_instance_valid(node):
			continue
		cf.set_value("layout", id + "_pos", node.position - defaults[id])
		cf.set_value("layout", id + "_scale", scales[id])
		cf.set_value("layout", id + "_vis", node.visible)
	cf.save(cfg_path)


func _load() -> void:
	if not FileAccess.file_exists(cfg_path):
		return
	var cf := ConfigFile.new()
	if cf.load(cfg_path) != OK:
		return
	for id in groups:
		var node: Control = groups[id]
		if cf.has_section_key("layout", id + "_pos"):
			node.position = defaults[id] + cf.get_value("layout", id + "_pos")
		if cf.has_section_key("layout", id + "_scale"):
			var sv = cf.get_value("layout", id + "_scale")
			if sv is Vector2:
				scales[id] = sv
			else:
				scales[id] = Vector2(float(sv), float(sv))
			node.scale = scales[id]
		if cf.has_section_key("layout", id + "_vis"):
			node.visible = bool(cf.get_value("layout", id + "_vis"))
	_update_highlights()


func _reset() -> void:
	if FileAccess.file_exists(cfg_path):
		var d := DirAccess.open("user://")
		if d != null:
			d.remove(cfg_path.get_file())
	undo_stack.clear()
	selected = ""
	for id in groups:
		var node: Control = groups[id]
		node.position = defaults[id]
		node.visible = true
		scales[id] = Vector2.ONE
		node.scale = Vector2.ONE
		group_undone.emit(id)
	_update_highlights()
