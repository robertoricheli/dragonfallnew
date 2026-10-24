class_name NotesScreen
extends ScreenBase
## NOTAS: versão atual do jogo + as 10 últimas atualizações (regra do manual).


func _ready() -> void:
	_base_setup("NOTAS DA VERSÃO", "user://layout_notes.cfg")
	var vl := _lbl(Vector2(60, 76), Vector2(600, 26), 18, Color(0.6, 1.0, 0.7))
	vl.text = "Versão atual: %s" % GameVersion.CURRENT
	reg("ver", vl, Rect2(60, 76, 600, 26))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 112)
	scroll.size = Vector2(1160, 570)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	reg("scroll", scroll, Rect2(60, 112, 1160, 570))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)
	var notes: Array = GameVersion.NOTES.duplicate()
	for e in notes.slice(0, mini(10, notes.size())):
		var hd := Label.new()
		hd.text = "v%s  —  %s" % [e["ver"], e["data"]]
		hd.add_theme_font_size_override("font_size", 16)
		hd.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
		vb.add_child(hd)
		for m in e["mudancas"]:
			var ln := Label.new()
			ln.text = "•  " + String(m)
			ln.add_theme_font_size_override("font_size", 12)
			ln.add_theme_color_override("font_color", Color(0.85, 0.83, 0.92))
			ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ln.custom_minimum_size = Vector2(1120, 0)
			vb.add_child(ln)
	_base_finish()
