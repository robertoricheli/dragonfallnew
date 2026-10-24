class_name CardView
extends Control
## Carta (mão/zoom/arsenal/histórico): frente = textura ÚNICA bakeada em alta
## resolução (CardBaker) => miniatura, mão e zoom são cópias exatas.
## Verso = arte VERSO DAS CARTAS. Proporção fixa 5:7. Hover só sobe.

signal drag_started(view)
signal drag_ended(view)
signal clicked(view)

const CARD_W := 110.0
const CARD_H := 154.0   # proporção 5:7
const BACK_W := 110.0
const BACK_H := 154.0
const HOVER_LIFT := 12.0

var card: Dictionary = {}
var face_down := false
var dragging := false
var _pressed := false
var _press_global := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var _slot_pos := Vector2.ZERO
var _base_rotation := 0.0
var hover_enabled := true
var drag_enabled := true
var zoom_factor := 1.0
var in_flight := false
var _slot_tw: Tween
var _hl: Panel
var _face: TextureRect
var _baker_conn := false


func _init() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	size = Vector2(CARD_W, CARD_H)
	pivot_offset = size / 2.0
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(card_data: Dictionary, is_face_down := false, zf: float = 1.0) -> void:
	card = card_data
	face_down = is_face_down
	zoom_factor = zf
	tooltip_text = ""  # sem caixa de texto ao passar o mouse
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var zf := zoom_factor
	var w: float = CARD_W * zf
	var h: float = CARD_H * zf
	size = Vector2(w, h)
	custom_minimum_size = Vector2(w, h)
	pivot_offset = size / 2.0
	if face_down:
		var vtex: Texture2D = CardArt.verso()
		if vtex != null:
			var vart := TextureRect.new()
			vart.texture = vtex
			vart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			vart.stretch_mode = TextureRect.STRETCH_SCALE
			vart.position = Vector2.ZERO
			vart.size = Vector2(w, h)
			vart.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(vart)
		else:
			var bp := ColorRect.new()
			bp.color = Color(0.16, 0.11, 0.26)
			bp.position = Vector2.ZERO
			bp.size = Vector2(w, h)
			bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(bp)
		return
	# FRENTE: textura bakeada única (idêntica em todos os tamanhos)
	_face = TextureRect.new()
	_face.texture = null
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.position = Vector2.ZERO
	_face.size = Vector2(w, h)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_hl = Panel.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0, 0, 0, 0)
	hsb.set_border_width_all(0)
	hsb.set_corner_radius_all(int(8 * zf))
	_hl.add_theme_stylebox_override("panel", hsb)
	_hl.position = Vector2.ZERO
	_hl.size = Vector2(w, h)
	_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hl)
	_apply_face()


func _apply_face() -> void:
	var pw: int = int(card.get("current_power", card.get("power", 0)))
	var t: ImageTexture = Baker.request(card, pw)
	if t != null:
		_face.texture = t
	elif _face.texture == null:
		var fr: Texture2D = CardArt.frame(String(card.get("category", "")), String(card.get("subcategory", "")))
		if fr != null:
			_face.texture = fr  # placeholder até o bake chegar
	if not _baker_conn:
		_baker_conn = true
		Baker.baked.connect(_on_baked)


func _on_baked(k: String) -> void:
	if k == Baker.key_of(card, int(card.get("current_power", card.get("power", 0)))):
		var t: ImageTexture = Baker.cached(card, int(card.get("current_power", card.get("power", 0))))
		if t != null:
			_face.texture = t


func _exit_tree() -> void:
	if _baker_conn:
		Baker.baked.disconnect(_on_baked)
		_baker_conn = false


func set_slot_target(pos: Vector2, rot_deg: float = 0.0) -> void:
	_slot_pos = pos
	_base_rotation = rot_deg
	if not dragging and not in_flight:
		if _slot_tw != null and _slot_tw.is_valid():
			_slot_tw.kill()
		_slot_tw = create_tween()
		_slot_tw.set_parallel(true)
		_slot_tw.tween_property(self, "position", pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_slot_tw.tween_property(self, "rotation_degrees", rot_deg, 0.28)


func snap_to_slot() -> void:
	position = _slot_pos
	rotation_degrees = _base_rotation


func set_highlight(on: bool) -> void:
	if face_down or _hl == null:
		return
	var sb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
	if on:
		sb.border_color = Color(1, 0.85, 0.4, 0.95)
		sb.set_border_width_all(3)
		sb.shadow_color = Color(1, 0.85, 0.4, 0.5)
		sb.shadow_size = 10
	else:
		sb.set_border_width_all(0)
		sb.shadow_size = 0


func set_dimmed(on: bool) -> void:
	modulate = Color(0.35, 0.35, 0.42) if on else Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if face_down:
		return
	if event is InputEventMouseMotion:
		if _pressed and drag_enabled and not dragging:
			if (get_global_mouse_position() - _press_global).length() > 8.0:
				dragging = true
				_drag_offset = _press_global - global_position
				rotation_degrees = 2.0
				z_index = 100
				set_highlight(true)
				drag_started.emit(self)
		elif not _pressed and hover_enabled:
			# estilo Hearthstone: só sobe um pouco, SEM mudar cor/tamanho/brilho
			position = _slot_pos + Vector2(0, -HOVER_LIFT)
			z_index = 30
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_press_global = get_global_mouse_position()
		else:
			var was_drag := dragging
			_pressed = false
			if was_drag:
				dragging = false
				z_index = 10
				drag_ended.emit(self)
			else:
				clicked.emit(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		if not dragging and not _pressed and hover_enabled:
			position = _slot_pos
			rotation_degrees = _base_rotation
			z_index = 0


func end_drag_return() -> void:
	dragging = false
	rotation_degrees = _base_rotation
	z_index = 0
	set_highlight(false)
	set_slot_target(_slot_pos, _base_rotation)


func abort_drag() -> void:
	dragging = false
	_pressed = false
	rotation_degrees = _base_rotation
	z_index = 0
	set_highlight(false)
	position = _slot_pos
