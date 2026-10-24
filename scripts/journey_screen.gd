class_name JourneyScreen
extends ScreenBase
## JORNADA DO JOGADOR: níveis 1–62 (heróis por nível, +4 moedas nos demais),
## portada do jogo original.


func _ready() -> void:
	Profile.ensure()
	Profile.claim_journey()
	_base_setup("JORNADA DO JOGADOR", "user://layout_journey.cfg")
	var lv := Profile.level()
	var hl := _lbl(Vector2(60, 76), Vector2(600, 24), 16, Color(1, 0.88, 0.5))
	hl.text = "Nível atual: %d   •   XP: %d" % [lv, Profile.data["xp"]]
	reg("head", hl, Rect2(60, 76, 600, 24))
	var bar := ColorRect.new()
	bar.color = Color(0.15, 0.14, 0.2)
	bar.position = Vector2(60, 106)
	bar.size = Vector2(500, 14)
	add_child(bar)
	var fill := ColorRect.new()
	fill.color = Color(0.35, 0.75, 0.4)
	fill.position = Vector2(60, 106)
	fill.size = Vector2(500 * Profile.level_progress(), 14)
	add_child(fill)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 136)
	scroll.size = Vector2(1160, 550)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	reg("scroll", scroll, Rect2(60, 136, 1160, 550))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)
	for i in Profile.JOURNEY_MAX_LEVEL:
		var n: int = i + 1
		var row := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.35, 0.25) if n == lv else Color(0.13, 0.12, 0.18)
		sb.border_color = Color(1, 0.85, 0.4) if n <= lv else Color(0.3, 0.28, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		row.add_theme_stylebox_override("panel", sb)
		row.custom_minimum_size = Vector2(1140, 30)
		vb.add_child(row)
		var t := Label.new()
		t.text = "Nível %2d — %s%s" % [n, Profile.journey_reward(n), ("  ◀ VOCÊ" if n == lv else ("  ✓" if n < lv else ""))]
		t.add_theme_font_size_override("font_size", 12)
		t.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
		t.position = Vector2(12, 5)
		t.size = Vector2(1120, 20)
		row.add_child(t)
	_base_finish()
