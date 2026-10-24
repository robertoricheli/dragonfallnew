class_name ScreenBase
extends Control
## Base das telas de meta (perfil/conquistas/jornada/notas/etc.):
## fundo, título, VOLTAR, botão EDITOR + ScreenEditor registrado (regra:
## TODA tela do jogo tem editor).

signal back_requested

var ed: ScreenEditor
var groups := {}
var rects := {}
var title_lbl: Label
var voltar_btn: Button
var ed_btn: Button
var cfg_name := "user://layout_screen.cfg"


func _base_setup(title: String, cfg: String) -> void:
	cfg_name = cfg
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.12)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280, 720)
	add_child(bg)
	title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.position = Vector2(440, 14)
	title_lbl.size = Vector2(400, 40)
	add_child(title_lbl)
	voltar_btn = _btn(Vector2(30, 16), Vector2(140, 44), "VOLTAR", Color(0.28, 0.25, 0.38), 15)
	add_child(voltar_btn)
	ed_btn = _btn(Vector2(1150, 16), Vector2(110, 40), "EDITOR", Color(0.2, 0.32, 0.3), 13)
	add_child(ed_btn)
	reg("title", title_lbl, Rect2(440, 14, 400, 40))
	reg("voltar", voltar_btn, Rect2(30, 16, 140, 44))
	reg("editorbtn", ed_btn, Rect2(1150, 16, 110, 40))


func reg(id: String, node: Control, rect: Rect2) -> void:
	groups[id] = node
	rects[id] = rect


func _base_finish() -> void:
	ed = ScreenEditor.new()
	add_child(ed)
	ed.setup(groups, rects, cfg_name)
	ed_btn.pressed.connect(func() -> void: ed.toggle())
	voltar_btn.pressed.connect(func() -> void: back_requested.emit())


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
	var dis := sb.duplicate() as StyleBoxFlat
	dis.bg_color = Color(0.16, 0.15, 0.2)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Color(0.96, 0.94, 0.9))
	b.add_theme_font_size_override("font_size", fs)
	return b


func _lbl(pos: Vector2, sz: Vector2, fs: int, col: Color, center := false) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	l.size = sz
	l.clip_text = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	add_child(l)
	return l
