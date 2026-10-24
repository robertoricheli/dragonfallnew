class_name AchievementsScreen
extends ScreenBase
## CONQUISTAS: famílias portadas do jogo original, 5 níveis cada,
## com progresso, moedas e claim automático.


func _ready() -> void:
	Profile.ensure()
	Profile.claim_achievements()
	_base_setup("CONQUISTAS", "user://layout_ach.cfg")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 80)
	scroll.size = Vector2(1160, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	reg("scroll", scroll, Rect2(60, 80, 1160, 600))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)
	for fam in Profile.ACH_FAMILIES:
		var states: Array = Profile.achievement_state(fam)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vb.add_child(row)
		var head := VBoxContainer.new()
		head.custom_minimum_size = Vector2(300, 60)
		row.add_child(head)
		var hn := Label.new()
		hn.text = String(fam["name"])
		hn.add_theme_font_size_override("font_size", 16)
		hn.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
		head.add_child(hn)
		var hp := Label.new()
		hp.text = "Progresso: %d / %d" % [states[0]["value"], states[4]["goal"]]
		hp.add_theme_font_size_override("font_size", 11)
		hp.add_theme_color_override("font_color", Color(0.75, 0.73, 0.85))
		head.add_child(hp)
		for a in states:
			var chip := Panel.new()
			var sb := StyleBoxFlat.new()
			var done: bool = a["done"]
			sb.bg_color = Color(0.25, 0.45, 0.25) if done else Color(0.16, 0.15, 0.22)
			sb.border_color = Color(1, 0.85, 0.4) if done else Color(0.35, 0.33, 0.45)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(8)
			chip.add_theme_stylebox_override("panel", sb)
			chip.custom_minimum_size = Vector2(150, 60)
			row.add_child(chip)
			var t1 := Label.new()
			t1.text = "Nível %d: %d" % [a["tier"], a["goal"]]
			t1.add_theme_font_size_override("font_size", 11)
			t1.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
			t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			t1.position = Vector2(0, 8)
			t1.size = Vector2(150, 16)
			chip.add_child(t1)
			var t2 := Label.new()
			t2.text = ("+%d moedas" % a["coins"]) if not done else "CONCLUÍDO +%d" % a["coins"]
			t2.add_theme_font_size_override("font_size", 10)
			t2.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7) if done else Color(0.6, 0.58, 0.7))
			t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			t2.position = Vector2(0, 30)
			t2.size = Vector2(150, 16)
			chip.add_child(t2)
	_base_finish()
