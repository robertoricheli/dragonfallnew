class_name ProfileScreen
extends ScreenBase
## PERFIL do jogador: avatar (quadrado arredondado) + moldura personalizáveis,
## nome editável, XP/nível, rank, troca de fundo e atalhos.

signal open_achievements
signal open_journey
signal open_options

var avatar_panel: Panel
var avatar_ini: Label
var name_edit: LineEdit
var info_lbl: Label
var rank_lbl: Label
var bg_btns := []


func _ready() -> void:
	Profile.ensure()
	_base_setup("PERFIL DO JOGADOR", "user://layout_profile.cfg")
	# avatar
	avatar_panel = Panel.new()
	avatar_panel.position = Vector2(60, 90)
	avatar_panel.size = Vector2(120, 120)
	add_child(avatar_panel)
	avatar_ini = Label.new()
	avatar_ini.add_theme_font_size_override("font_size", 40)
	avatar_ini.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	avatar_ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar_panel.add_child(avatar_ini)
	reg("avatar", avatar_panel, Rect2(60, 90, 120, 120))
	# nome editável
	var nl := _lbl(Vector2(210, 90), Vector2(300, 18), 12, Color(0.8, 0.78, 0.9))
	nl.text = "Nome do jogador:"
	name_edit = LineEdit.new()
	name_edit.text = Profile.player_name()
	name_edit.position = Vector2(210, 112)
	name_edit.size = Vector2(300, 40)
	add_child(name_edit)
	reg("name", name_edit, Rect2(210, 112, 300, 40))
	var bs := _btn(Vector2(520, 112), Vector2(120, 40), "SALVAR", Color(0.2, 0.4, 0.25), 12)
	bs.pressed.connect(func() -> void:
		Profile.data["name"] = name_edit.text.substr(0, 24)
		if Profile.data["name"] == "":
			Profile.data["name"] = "Jogador"
		Profile.save()
		_refresh())
	add_child(bs)
	reg("savename", bs, Rect2(520, 112, 120, 40))
	# xp / nível / rank
	info_lbl = _lbl(Vector2(210, 162), Vector2(430, 20), 13, Color(1, 0.85, 0.4))
	rank_lbl = _lbl(Vector2(210, 186), Vector2(430, 18), 12, Color(0.7, 0.85, 1.0))
	# cores do avatar
	var cl := _lbl(Vector2(60, 224), Vector2(400, 16), 11, Color(0.8, 0.78, 0.9))
	cl.text = "Cor do avatar:"
	for i in Profile.AVATAR_COLORS.size():
		var b := _btn(Vector2(60 + i * 40, 244), Vector2(34, 34), "", Profile.AVATAR_COLORS[i], 10)
		var ii := i
		b.pressed.connect(func() -> void:
			Profile.data["avatar_color"] = ii
			Profile.save()
			_refresh())
		add_child(b)
	# molduras
	var fl := _lbl(Vector2(60, 292), Vector2(400, 16), 11, Color(0.8, 0.78, 0.9))
	fl.text = "Moldura do avatar:"
	for i in Profile.FRAME_STYLES.size():
		var b := _btn(Vector2(60 + i * 90, 312), Vector2(84, 36), Profile.FRAME_STYLES[i]["name"], Color(0.25, 0.24, 0.35), 11)
		var ii := i
		b.pressed.connect(func() -> void:
			Profile.data["avatar_frame"] = ii
			Profile.save()
			_refresh())
		add_child(b)
	# fundos
	var bl := _lbl(Vector2(60, 366), Vector2(500, 16), 11, Color(0.8, 0.78, 0.9))
	bl.text = "TROCAR DE FUNDO (batalha e menus):"
	for i in Profile.BACKGROUNDS.size():
		var b := _btn(Vector2(60 + i * 150, 386), Vector2(140, 40), Profile.BACKGROUNDS[i]["name"], Color(0.2, 0.24, 0.4), 10)
		var ii := i
		b.pressed.connect(func() -> void:
			Profile.data["bg"] = ii
			Profile.save()
			_refresh())
		add_child(b)
		bg_btns.append(b)
	# atalhos
	var b1 := _btn(Vector2(700, 90), Vector2(250, 52), "CONQUISTAS", Color(0.45, 0.35, 0.15), 15)
	b1.pressed.connect(func() -> void: open_achievements.emit())
	add_child(b1)
	reg("ach", b1, Rect2(700, 90, 250, 52))
	var b2 := _btn(Vector2(700, 152), Vector2(250, 52), "JORNADA DO JOGADOR", Color(0.2, 0.4, 0.3), 15)
	b2.pressed.connect(func() -> void: open_journey.emit())
	add_child(b2)
	reg("journey", b2, Rect2(700, 152, 250, 52))
	var b3 := _btn(Vector2(700, 214), Vector2(250, 52), "OPÇÕES", Color(0.25, 0.22, 0.35), 15)
	b3.pressed.connect(func() -> void: open_options.emit())
	add_child(b3)
	reg("opts", b3, Rect2(700, 214, 250, 52))
	var st := _lbl(Vector2(700, 290), Vector2(520, 150), 12, Color(0.75, 0.73, 0.85))
	st.name = "StatsLbl"
	_stats_lbl = st
	_base_finish()
	_refresh()


var _stats_lbl: Label


func _refresh() -> void:
	avatar_ini.text = Profile.initials_of(Profile.player_name())
	var sb := StyleBoxFlat.new()
	sb.bg_color = Profile.avatar_color()
	var fr: Dictionary = Profile.frame_style()
	sb.border_color = fr["color"]
	sb.set_border_width_all(int(fr["w"]))
	sb.set_corner_radius_all(16)
	avatar_panel.add_theme_stylebox_override("panel", sb)
	info_lbl.text = "XP: %d   •   Nível: %d   •   Moedas: %d" % [Profile.data["xp"], Profile.level(), Profile.data["coins"]]
	var rk: Dictionary = Profile.rank_tier()
	if rk.has("need"):
		rank_lbl.text = "RANK: Sem Rank (faltam %d partidas)" % int(rk["need"])
	else:
		rank_lbl.text = "RANK: %s (%.0f%% de vitórias)" % [rk.get("name", ""), rk.get("pct", 0.0)]
	var stt: Dictionary = Profile.data["stats"]
	_stats_lbl.text = "Partidas: %d  |  Vitórias vs IA: %d  |  Abates: %d\nInvocações: %d  |  Ataques: %d  |  Talentos: %d  |  Ultimates: %d\nSequência atual: %d  |  Melhor: %d  |  Vitórias grandes: %d" % [stt["matches"], stt["aiWins"], stt["champKills"], stt["summons"], stt["attacks"], stt["talents"], stt["ultimates"], stt["streak"], stt["bestStreak"], stt["bigWins"]]
	for i in bg_btns.size():
		var bsb: StyleBoxFlat = bg_btns[i].get_theme_stylebox("normal")
		bsb.bg_color = Color(0.2, 0.45, 0.25) if int(Profile.data["bg"]) == i else Color(0.2, 0.24, 0.4)
