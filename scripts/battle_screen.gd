class_name BattleScreen
extends Control
## Tela de batalha — mesmo layout do jogo Dragonfall (GitHub):
## - Mão do jogador embaixo (4 cartas iniciais), mão da IA em cima (versos).
## - Botões COMPRAR / PASSAR VEZ no lado esquerdo; OPÇÕES no canto superior esquerdo.
## - Campo central retangular dividido em 2 (IA em cima, jogador embaixo),
##   com banner central "SUA VEZ / VEZ DO ADVERSÁRIO".
## - Invocação por arrastar a carta da mão para o seu campo.
## - Campeões surgem no CENTRO da sua metade (junto ao banner) e a linha
##   se reajusta sempre centralizada, permanecendo na mesma linha.

signal exit_to_menu
signal restart_requested

const W := 1280.0
const H := 720.0
const FIELD_X := 168.0
const FIELD_Y := 155.0
const FIELD_W := 940.0
const FIELD_H := 410.0
const FIELD_CX := FIELD_X + FIELD_W / 2.0        # 716
const BANNER_Y := 335.0
const AI_ROW_CY := 246.0                          # centro da linha da IA
const PL_ROW_CY := 473.0                          # centro da linha do jogador
## (1.49.64) Altura da "queda pesada": o voo termina este valor ACIMA do slot
## e a carta chega CAINDO na vertical (sem deslizamento no campo).
const DROP_H := 26.0
const HAND_Y := 560.0
const CHAMP_W := 100.0
const CHAMP_H := 140.0
const DROP_RECT := Rect2(FIELD_X, BANNER_Y + 20.0, FIELD_W, FIELD_Y + FIELD_H - BANNER_Y - 20.0)

var state: GameState
var match_opts := {}
var ai_step_delay := 2.0
var input_locked := true
var drag_view: CardView = null
var drag_champ: ChampionView = null
var _hover_target: ChampionView = null
var _pending_talent_slot := -1
var zoom_overlay: Control = null
var history_overlay: Control = null
var fx_layer: Control
var ai_running := false
var _last_destroy_ms := 0

# editor de layout (arrastar e soltar) — genérico
var ed: ScreenEditor

var grp_field: Control
var grp_buy: Control
var grp_pass: Control
var grp_options: Control
var hero_groups: Array = []
var btn_editor: Button
var act_panel: Panel
var hand_y := 580.0
var ai_hand_y := -12.0
var hand_p_scale := 1.0
var btn_ult: Button
var timer_panel: Panel
var clock_hand: ColorRect
var timer_label: Label
var turn_timer := 70.0
var hand_ai_scale := 1.0
var field_extras: Array = [[], []]
var extra_views := {}   # uid -> view de Talento/Reação no campo (origem da Bola de Fogo)

# views
var hand_views: Array = [{}, {}]     # [pi] -> {uid: CardView}
var champ_views := {}                # uid -> ChampionView
var _toast_count := 0

var bg_rect: ColorRect
var field_panel: Panel
var ai_half: Panel
var pl_half: Panel
var drop_glow: Panel
var banner: Panel
var banner_label: Label
var msg_log: Array = []
var btn_draw: Button
var btn_pass: Button
var btn_options: Button
var pips: Array = []
var vp_labels: Array = []
var name_labels: Array = []
var hand_layer: Control
var champ_layer: Control
## (1.49.73) Camada SOB as cartas e SOBRE o campo: bases de VFX de "chão"
## (ex.: domo do Fortalecer), para a base aparecer abaixo da carta.
var under_layer: Control
var toast_layer: Control
var options_overlay: Control
var gameover_overlay: Control
var gameover_title: Label
var gameover_sub: Label
var actions_label: Label
## (1.49.76) uid => estilo de animação de destruição especial pendente.
var _death_style := {}
## (1.49.80) uid => morte SEM HONRA pendente (espera a animação gatilho acabar).
var _pending_desonra := {}
## (1.49.79) uid do Talento => ticks em que a animação dele terminou (a carta
## Talento só some 0,5 s depois disso, e nunca antes de 2 s em campo).
var _talent_anim_until := {}
# (1.49.93) PESADELO: loop de fantasmas sobre a moldura do herói afetado;
# some quando termina o turno do jogador sob o efeito.
var _pesadelo_hero_node: Node2D = null
var _pesadelo_hero_pi := -1
var _pesadelo_turn_seen := false
var _pesadelo_running := {}   # (1.49.94) uid -> cone em andamento (anti-duplicata)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_match()


# ----------------------------------------------------------------------------
# Construção da UI
# ----------------------------------------------------------------------------

func _build_ui() -> void:
	var tex: Texture2D = null
	var bgp: String = Profile.bg_path()
	if bgp != "" and ResourceLoader.exists(bgp):
		tex = load(bgp)
	elif ResourceLoader.exists("res://assets/bg_battle.jpg"):
		tex = load("res://assets/bg_battle.jpg")
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.position = Vector2.ZERO
		tr.size = Vector2(1280, 720)
		add_child(tr)
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.30)
		shade.position = Vector2.ZERO
		shade.size = Vector2(1280, 720)
		add_child(shade)
	else:
		bg_rect = ColorRect.new()
		bg_rect.color = Color(0.07, 0.05, 0.12)
		bg_rect.position = Vector2.ZERO
		bg_rect.size = Vector2(1280, 720)
		add_child(bg_rect)

	# ---- Grupo do campo (criado antes p/ ficar ABAIXO do banner e das cartas) ----
	grp_field = Control.new()
	grp_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grp_field)

	# ---- Campo central (estilo Hearthstone: retângulo dividido em 2) ----
	field_panel = _panel(Rect2(FIELD_X, FIELD_Y, FIELD_W, FIELD_H), Color(0.10, 0.08, 0.17, 0.9), Color(0.55, 0.45, 0.25), 1, 12)
	grp_field.add_child(field_panel)
	ai_half = _panel(Rect2(FIELD_X + 4, FIELD_Y + 4, FIELD_W - 8, (BANNER_Y - FIELD_Y) - 2), Color(0.20, 0.10, 0.13, 0.55), Color(0.45, 0.25, 0.3, 0.7), 1, 8)
	grp_field.add_child(ai_half)
	pl_half = _panel(Rect2(FIELD_X + 4, BANNER_Y + 40, FIELD_W - 8, FIELD_Y + FIELD_H - BANNER_Y - 44), Color(0.10, 0.16, 0.24, 0.55), Color(0.28, 0.42, 0.55, 0.7), 1, 8)
	grp_field.add_child(pl_half)

	drop_glow = _panel(Rect2(FIELD_X + 4, BANNER_Y + 50, FIELD_W - 8, FIELD_Y + FIELD_H - BANNER_Y - 54), Color(0.3, 0.9, 0.4, 0.12), Color(0.4, 1.0, 0.5, 0.8), 2, 8)
	drop_glow.visible = false
	drop_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grp_field.add_child(drop_glow)

	# ---- Banner central (turno) ----
	# (1.49.83) banner MAIS FINO (32 px, borda 1) e sem contador de turnos
	banner = _panel(Rect2(FIELD_CX - 190, BANNER_Y + 6, 380, 32), Color(0.09, 0.07, 0.15, 0.97), Color(0.85, 0.68, 0.3), 1, 8)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.pivot_offset = Vector2(190, 16)
	add_child(banner)
	banner_label = Label.new()
	banner_label.text = "SUA VEZ"
	banner_label.add_theme_font_size_override("font_size", 15)
	banner_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	banner_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	banner_label.add_theme_constant_override("outline_size", 4)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.position = Vector2(0, 3)
	banner_label.size = Vector2(380, 26)
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_label)


	# ---- Coluna esquerda: comprar / ações / passar ----
	btn_draw = _styled_button(Rect2(16, 240, 140, 66), "COMPRAR CARTA\n--", Color(0.16, 0.32, 0.5))
	btn_draw.pressed.connect(_on_draw_pressed)
	add_child(btn_draw)

	act_panel = _panel(Rect2(1124, 10, 140, 58), Color(0.1, 0.08, 0.16, 0.95), Color(0.5, 0.42, 0.25), 1, 8)
	add_child(act_panel)
	actions_label = Label.new()
	actions_label.text = "AÇÕES"
	actions_label.add_theme_font_size_override("font_size", 10)
	actions_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	actions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions_label.position = Vector2(0, 4)
	actions_label.size = Vector2(140, 16)
	act_panel.add_child(actions_label)
	for i in 3:
		var pip := Panel.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.9, 0.75, 0.3)
		psb.set_corner_radius_all(8)
		pip.add_theme_stylebox_override("panel", psb)
		pip.position = Vector2(28 + i * 30, 28)
		pip.size = Vector2(16, 16)
		act_panel.add_child(pip)
		pips.append(pip)

	timer_panel = _panel(Rect2(1124, 76, 140, 64), Color(0.1, 0.08, 0.16, 0.95), Color(0.5, 0.42, 0.25), 1, 8)
	add_child(timer_panel)
	var clock := Panel.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.12, 0.1, 0.2)
	csb.border_color = Color(0.9, 0.8, 0.5)
	csb.set_border_width_all(2)
	csb.set_corner_radius_all(20)
	clock.add_theme_stylebox_override("panel", csb)
	clock.position = Vector2(12, 12)
	clock.size = Vector2(40, 40)
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_panel.add_child(clock)
	clock_hand = ColorRect.new()
	clock_hand.color = Color(1, 0.9, 0.6)
	clock_hand.size = Vector2(3, 15)
	clock_hand.position = Vector2(30.5, 17)
	clock_hand.pivot_offset = Vector2(1.5, 15)
	clock_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_panel.add_child(clock_hand)
	var cdot := ColorRect.new()
	cdot.color = Color(1, 0.9, 0.6)
	cdot.size = Vector2(5, 5)
	cdot.position = Vector2(30, 30)
	cdot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_panel.add_child(cdot)
	timer_label = Label.new()
	timer_label.text = "70"
	timer_label.add_theme_font_size_override("font_size", 26)
	timer_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	timer_label.position = Vector2(62, 14)
	timer_label.size = Vector2(70, 36)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_panel.add_child(timer_label)

	btn_ult = _styled_button(Rect2(1124, 240, 140, 66), "ULTIMATE", Color(0.45, 0.3, 0.1))
	btn_ult.pressed.connect(_on_ult_pressed)
	add_child(btn_ult)

	btn_pass = _styled_button(Rect2(16, 330, 140, 58), "PASSAR\nA VEZ", Color(0.45, 0.2, 0.22))
	btn_pass.pressed.connect(_on_pass_pressed)
	add_child(btn_pass)


	# ---- Opções (canto superior esquerdo) ----
	btn_options = _styled_button(Rect2(12, 10, 112, 42), "OPÇÕES", Color(0.25, 0.22, 0.35))
	btn_options.pressed.connect(_on_options_pressed)
	add_child(btn_options)
	btn_editor = _styled_button(Rect2(12, 58, 112, 42), "EDITOR", Color(0.2, 0.32, 0.3))
	add_child(btn_editor)

	# ---- Heróis / PV / decks ----
	vp_labels = [null, null]
	name_labels = [null, null]
	_build_hero_blocks()

	# ---- Layers de cartas ----
	# (1.49.73) under_layer: depois do campo, ANTES das cartas => bases de VFX
	# ficam visíveis no chão, abaixo dos campeões.
	under_layer = Control.new()
	under_layer.position = Vector2.ZERO
	under_layer.size = Vector2(1280, 720)
	under_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(under_layer)
	champ_layer = Control.new()
	champ_layer.position = Vector2.ZERO
	champ_layer.size = Vector2(1280, 720)
	champ_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(champ_layer)
	hand_layer = Control.new()
	hand_layer.position = Vector2.ZERO
	hand_layer.size = Vector2(1280, 720)
	hand_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_layer)
	toast_layer = Control.new()
	toast_layer.position = Vector2.ZERO
	toast_layer.size = Vector2(1280, 720)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)
	fx_layer = Control.new()
	fx_layer.position = Vector2.ZERO
	fx_layer.size = Vector2(1280, 720)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx_layer)

	# ---- grupos arrastáveis (editor de layout) ----
	grp_buy = Control.new()
	grp_buy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grp_buy)
	for ln in [btn_draw]:
		_reparent(ln, grp_buy)
	grp_pass = Control.new()
	grp_pass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grp_pass)
	_reparent(btn_pass, grp_pass)
	grp_options = Control.new()
	grp_options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grp_options)
	_reparent(btn_options, grp_options)
	# REGRA DO PROJETO: todo elemento de UI da batalha (atual ou futuro)
	# deve ser registrado no editor de layout para ser editável.
	var hand_p_node := Control.new()
	hand_p_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_p_node)
	var hand_ai_node := Control.new()
	hand_ai_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_ai_node)
	var groups := {
		"field": grp_field,
		"banner": banner,
		"buy": grp_buy,
		"pass": grp_pass,
		"options": grp_options,
		"editorbtn": btn_editor,
		"actions": act_panel,
		"timer": timer_panel,
		"ult": btn_ult,
		"hero0": hero_groups[0],
		"hero1": hero_groups[1],
		"hand_p": hand_p_node,
		"hand_ai": hand_ai_node,
	}
	var rects := {
		"field": Rect2(FIELD_X, FIELD_Y, FIELD_W, FIELD_H),
		"banner": Rect2(FIELD_CX - 190, BANNER_Y + 6, 380, 32),
		"buy": Rect2(12, 236, 148, 70),
		"pass": Rect2(12, 326, 148, 62),
		"options": Rect2(12, 10, 112, 42),
		"editorbtn": Rect2(12, 58, 112, 42),
		"actions": Rect2(1124, 10, 140, 58),
		"timer": Rect2(1124, 76, 140, 64),
		"ult": Rect2(1124, 240, 140, 66),
		"hero0": Rect2(940, 636, 340, 70),
		"hero1": Rect2(16, 636, 300, 70),
		"hand_p": Rect2(170, hand_y - 20, 900, 175),
		"hand_ai": Rect2(180, ai_hand_y, 860, 150),
	}

	_build_overlays()

	ed = ScreenEditor.new()
	add_child(ed)
	ed.setup(groups, rects, "user://layout_battle.cfg")
	ed.group_moved.connect(_on_editor_changed)
	ed.group_resized.connect(_on_editor_changed)
	ed.group_undone.connect(_on_editor_changed)
	ed.toggled.connect(_on_editor_toggled)
	btn_editor.pressed.connect(func() -> void: ed.toggle())


var hero_meds: Array = []


func _build_hero_blocks() -> void:
	# serão preenchidos após _start_match conhecer os heróis; positions fixas:
	for pi in 2:
		# IA = canto inferior ESQUERDO | Jogador = canto inferior DIREITO
		var left: bool = pi == 1
		var y := 636.0
		var medal := Panel.new()
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color(0.3, 0.22, 0.45)
		msb.set_corner_radius_all(12)  # quadrado arredondado
		msb.border_color = Color(0.85, 0.7, 0.35)
		msb.set_border_width_all(2)
		medal.add_theme_stylebox_override("panel", msb)
		medal.position = Vector2(16 if left else 1200, y)
		medal.size = Vector2(64, 64)
		medal.gui_input.connect(_on_medal_input.bind(pi))
		add_child(medal)
		var initials := Label.new()
		initials.name = "Initials"
		initials.text = "?"
		initials.add_theme_font_size_override("font_size", 20)
		initials.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
		initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initials.position = Vector2.ZERO
		initials.size = Vector2(64, 64)
		medal.add_child(initials)
		var tx: float = 88 if left else 980
		var align := HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		var nm := Label.new()
		nm.text = "..."
		nm.add_theme_font_size_override("font_size", 13)
		nm.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		nm.horizontal_alignment = align
		nm.position = Vector2(tx, y + 4)
		nm.size = Vector2(210, 18)
		add_child(nm)
		var vp := Label.new()
		vp.text = "PV 0/15"
		vp.add_theme_font_size_override("font_size", 16)
		vp.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		vp.horizontal_alignment = align
		vp.position = Vector2(tx, y + 26)
		vp.size = Vector2(210, 22)
		add_child(vp)
		name_labels[pi] = nm
		vp_labels[pi] = vp
		var g := Control.new()
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(g)
		for wn in [medal, nm, vp]:
			var wp: Vector2 = wn.position
			remove_child(wn)
			g.add_child(wn)
			wn.position = wp
		hero_groups.append(g)
		hero_meds.append({"medal": medal, "initials": initials})


func _build_overlays() -> void:
	# Opções
	options_overlay = Control.new()
	options_overlay.position = Vector2.ZERO
	options_overlay.size = Vector2(1280, 720)
	options_overlay.visible = false
	add_child(options_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	options_overlay.add_child(dim)
	var panel := _panel_local(Vector2(490, 180), Vector2(300, 320), Color(0.11, 0.09, 0.18, 0.98), Color(0.85, 0.68, 0.3), 2, 12)
	options_overlay.add_child(panel)
	var title := Label.new()
	title.text = "OPÇÕES"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 18)
	title.size = Vector2(300, 30)
	panel.add_child(title)
	var b1 := _styled_button_local(Vector2(50, 70), Vector2(200, 44), "CONTINUAR", Color(0.2, 0.35, 0.25))
	b1.pressed.connect(func(): options_overlay.visible = false)
	panel.add_child(b1)
	var b2 := _styled_button_local(Vector2(50, 126), Vector2(200, 44), "REINICIAR PARTIDA", Color(0.4, 0.32, 0.18))
	b2.pressed.connect(func():
		options_overlay.visible = false
		restart_requested.emit())
	panel.add_child(b2)
	var b3 := _styled_button_local(Vector2(50, 182), Vector2(200, 44), "SAIR PARA O MENU", Color(0.45, 0.2, 0.22))
	b3.pressed.connect(func():
		options_overlay.visible = false
		exit_to_menu.emit())
	panel.add_child(b3)

	# Game over
	gameover_overlay = Control.new()
	gameover_overlay.position = Vector2.ZERO
	gameover_overlay.size = Vector2(1280, 720)
	gameover_overlay.visible = false
	add_child(gameover_overlay)
	var dim2 := ColorRect.new()
	dim2.color = Color(0, 0, 0, 0.65)
	dim2.position = Vector2.ZERO
	dim2.size = Vector2(1280, 720)
	gameover_overlay.add_child(dim2)
	var panel2 := _panel_local(Vector2(440, 190), Vector2(400, 300), Color(0.1, 0.08, 0.16, 0.98), Color(0.85, 0.68, 0.3), 2, 14)
	gameover_overlay.add_child(panel2)
	gameover_title = Label.new()
	gameover_title.text = "VITÓRIA!"
	gameover_title.add_theme_font_size_override("font_size", 34)
	gameover_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_title.position = Vector2(0, 30)
	gameover_title.size = Vector2(400, 44)
	panel2.add_child(gameover_title)
	gameover_sub = Label.new()
	gameover_sub.add_theme_font_size_override("font_size", 13)
	gameover_sub.add_theme_color_override("font_color", Color(0.85, 0.82, 0.9))
	gameover_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameover_sub.position = Vector2(0, 86)
	gameover_sub.size = Vector2(400, 40)
	panel2.add_child(gameover_sub)
	var g1 := _styled_button_local(Vector2(90, 150), Vector2(220, 46), "JOGAR NOVAMENTE", Color(0.2, 0.4, 0.25))
	g1.pressed.connect(func(): restart_requested.emit())
	panel2.add_child(g1)
	var g2 := _styled_button_local(Vector2(90, 210), Vector2(220, 46), "MENU PRINCIPAL", Color(0.3, 0.26, 0.45))
	g2.pressed.connect(func(): exit_to_menu.emit())
	panel2.add_child(g2)


func _panel(r: Rect2, bg: Color, border: Color, bw: int, radius: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel", sb)
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _panel_local(pos: Vector2, sz: Vector2, bg: Color, border: Color, bw: int, radius: int) -> Panel:
	return _panel(Rect2(pos, sz), bg, border, bw, radius)


func _styled_button(r: Rect2, text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = r.position
	b.size = r.size
	_style_button(b, bg)
	return b


func _styled_button_local(pos: Vector2, sz: Vector2, text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	_style_button(b, bg)
	return b


func _style_button(b: Button, bg: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bg.lightened(0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	var hov := sb.duplicate() as StyleBoxFlat
	hov.bg_color = bg.lightened(0.18)
	var dis := sb.duplicate() as StyleBoxFlat
	dis.bg_color = Color(0.16, 0.15, 0.2)
	dis.border_color = Color(0.25, 0.24, 0.3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", hov)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.44, 0.5))
	b.add_theme_font_size_override("font_size", 13)


# ----------------------------------------------------------------------------
# Partida
# ----------------------------------------------------------------------------

func _start_match() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hero_a: Dictionary = {}
	var hid: String = String(match_opts.get("hero_id", ""))
	if hid != "":
		for h in CardDB.HEROES:
			if String(h["id"]) == hid:
				hero_a = h
	if hero_a.is_empty():
		hero_a = CardDB.random_hero(rng)
	var hero_b: Dictionary = CardDB.random_hero(rng)
	while hero_b["id"] == hero_a["id"]:
		hero_b = CardDB.random_hero(rng)
	state = GameState.new()
	_clear_pesadelo_hero()
	state.log_msg.connect(_on_log)
	state.card_drawn.connect(_on_card_drawn)
	state.hand_changed.connect(_on_hand_changed)
	state.champion_summoned.connect(_on_champion_summoned)
	state.champion_destroyed.connect(_on_champion_destroyed)
	state.champion_morphed.connect(_on_champion_morphed)
	state.attack_done.connect(_on_attack_done)
	state.vp_changed.connect(_on_vp_changed)
	state.actions_changed.connect(_on_actions_changed)
	state.turn_started.connect(_on_turn_started)
	state.game_over.connect(_on_game_over)
	state.field_changed.connect(_on_field_changed)
	state.talent_played.connect(_on_talent_played)
	state.sync_views.connect(_on_sync_views)
	state.ultimate_used.connect(_on_ultimate_used)
	state.fx_fire.connect(_on_fx_fire)
	state.fx_fortalecer.connect(_on_fx_fortalecer)
	state.fx_roubo.connect(_on_fx_roubo)
	state.fx_forja.connect(_on_fx_forja)
	state.fx_congelar.connect(_on_fx_congelar)
	state.fx_mordida.connect(_on_fx_mordida)
	state.fx_baforada.connect(_on_fx_baforada)
	state.fx_enabled = true
	state.destroy_style.connect(_on_destroy_style)
	state.targeting_started.connect(_on_targeting_started)
	state.targeting_ended.connect(_on_targeting_ended)
	state.setup(hero_a, hero_b, match_opts)
	_fill_hero_info(hero_a, hero_b)
	_refresh_all()


func _fill_hero_info(hero_a: Dictionary, hero_b: Dictionary) -> void:
	for pi in 2:
		var hero: Dictionary = hero_a if pi == 0 else hero_b
		var med: Dictionary = hero_meds[pi]
		var nm: String = hero.get("name", "?")
		var words := nm.split(" ")
		var ini := String(words[0]).left(1)
		if words.size() > 1:
			ini += String(words[words.size() - 1]).left(1)
		med["initials"].text = ini.to_upper()
		var hcol := Color.from_hsv(fmod(float(hash(hero.get("id", "x")) % 360) / 360.0, 1.0), 0.55, 0.55)
		(med["medal"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = hcol.darkened(0.35)
		name_labels[pi].text = nm if pi == 1 else nm + "  (Você)"


func _refresh_all() -> void:
	_on_vp_changed(0)
	_on_vp_changed(1)
	_on_actions_changed(0)
	_refresh_counts()


func _refresh_counts() -> void:
	if state == null:
		return
	btn_draw.text = "COMPRAR CARTA\n%d" % state.players[0]["deck"].size()


# ----------------------------------------------------------------------------
# Sinais do estado -> visual
# ----------------------------------------------------------------------------

func _on_log(text: String) -> void:
	_push_msg(text)


func _push_msg(text: String) -> void:
	# registros internos apenas — nenhum texto aparece na tela
	msg_log.append(text)
	if msg_log.size() > 5:
		msg_log.pop_front()


func _spawn_toast(text: String) -> void:
	_push_msg(text)


func _on_card_drawn(pi: int, card: Dictionary, animated: bool) -> void:
	if animated:
		Sfx.play("draw", 1180.0 if pi == 0 else 100.0, 0.6)
	var v := CardView.new()
	v.setup(card, pi == 1)
	v.drag_started.connect(_on_card_drag_started)
	v.drag_ended.connect(_on_card_drag_ended)
	v.clicked.connect(_on_card_clicked)
	hand_layer.add_child(v)
	hand_views[pi][int(card["uid"])] = v
	if not animated:
		v.set_meta("snap", true)  # cartas iniciais: entram direto, sem voo
		return
	# saque/compra: jogador entra pela LATERAL DIREITA (região central),
	# IA pela LATERAL ESQUERDA (região central); voo fluido de 1,5 s
	v.in_flight = true
	v.z_index = 200
	if pi == 0:
		v.position = Vector2(W + 80, H / 2.0 - CardView.CARD_H / 2.0)
	else:
		v.position = Vector2(-80 - CardView.CARD_W, H / 2.0 - CardView.CARD_H / 2.0)
	_draw_flight(v, pi)


func _draw_flight(v: CardView, pi: int) -> void:
	await get_tree().process_frame  # aguarda o hand_changed definir o slot
	if not is_instance_valid(v) or not v.in_flight:
		return
	await _fly_card(v, v._slot_pos, 1.5, 60.0 if pi == 0 else 50.0)
	if is_instance_valid(v) and v.in_flight:
		v.in_flight = false
		v.z_index = 0
		v.set_slot_target(v._slot_pos, v._base_rotation)


func _on_hand_changed(pi: int) -> void:
	var hand: Array = state.players[pi]["hand"]
	var alive := {}
	for c in hand:
		alive[int(c["uid"])] = c
	# remover views que saíram da mão
	for uid in hand_views[pi].keys():
		if not alive.has(int(uid)):
			var v: CardView = hand_views[pi][uid]
			hand_views[pi].erase(uid)
			_animate_view_exit(v)
	# criar views faltantes (ex.: carta roubada)
	for c in hand:
		if not hand_views[pi].has(int(c["uid"])):
			var v := CardView.new()
			v.setup(c, pi == 1)
			v.drag_started.connect(_on_card_drag_started)
			v.drag_ended.connect(_on_card_drag_ended)
			v.clicked.connect(_on_card_clicked)
			v.position = Vector2(FIELD_CX - 55, hand_y)
			v.scale = Vector2(0.3, 0.3)
			hand_layer.add_child(v)
			hand_views[pi][int(c["uid"])] = v
			var tw := v.create_tween()
			tw.tween_property(v, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_layout_hand(pi)
	_refresh_buttons()


func _on_destroy_style(uid: int, style: String) -> void:
	# (1.49.76) o motor avisa ANTES do field_changed: guarda o estilo para a
	# view correspondente receber a morte especial.
	_death_style[int(uid)] = String(style)


func _finish_desonra(uid: int) -> void:
	# (1.49.80) roda a morte especial do SEM HONRA depois que a animação
	# gatilho (combate/bola de fogo) terminou.
	if not _pending_desonra.has(uid):
		return
	_pending_desonra.erase(uid)
	var style: String = String(_death_style.get(uid, "semhonra"))
	_death_style.erase(uid)
	var v: ChampionView = champ_views.get(uid)
	if v == null or not is_instance_valid(v):
		# segurança: sem view, reorganiza o campo na hora
		_layout_field(0)
		_layout_field(1)
		return
	champ_views.erase(uid)
	var pi: int = v.owner_pi
	var fx: Node = _custom_death(v, style)
	_last_destroy_ms = Time.get_ticks_msec()
	_refresh_counts()
	# (1.49.91) REGRA 1: os aliados só se REORGANIZAM 0,5 s APÓS o FIM da
	# animação de morte do SEM HONRA (o VFX emite 'finished' aos 2 s).
	if fx != null and is_instance_valid(fx) and fx.has_signal("finished"):
		fx.finished.connect(_reorg_after_desonra.bind(pi))
	else:
		_reorg_after_desonra(pi)


func _reorg_after_desonra(pi: int) -> void:
	# (1.49.91) meio segundo depois do fim do VFX do SEM HONRA: reorganiza.
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		_layout_field(pi)


func _has_pending_desonra(pi: int) -> bool:
	# (1.49.91) há um campeão deste jogador aguardando a morte do SEM HONRA?
	for uid in _pending_desonra.keys():
		var v: ChampionView = champ_views.get(uid)
		if v != null and is_instance_valid(v) and v.owner_pi == pi:
			return true
	return false


func _custom_death(v: Control, style: String) -> Node:
	# (1.49.76) a CARTA EXPLODE e o VFX especial (2 s) substitui a saída padrão
	var center: Vector2 = v.global_position + v.size / 2.0
	var flash_col := Color(0.9, 0.5, 1.0) if style == "semhonra" else Color(1.0, 0.9, 0.5)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := v.create_tween()
	tw.tween_property(v, "modulate", flash_col, 0.1)
	tw.set_parallel(true)
	tw.tween_property(v, "scale", Vector2(1.15, 1.15), 0.22)
	tw.tween_property(v, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(v.queue_free)
	if style == "semhonra":
		var fx = load("res://scripts/vfx_desonra.gd").new()
		fx_layer.add_child(fx)
		fx.setup(center)
		return fx
	else:
		var fx2 = load("res://scripts/vfx_recompensa.gd").new()
		fx_layer.add_child(fx2)
		fx2.setup(center)
		return fx2


func _animate_view_exit(v: Control) -> void:
	_kill_flight(v)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := v.create_tween()
	tw.set_parallel(true)
	tw.tween_property(v, "scale", Vector2(0.3, 0.3), 0.18)
	tw.tween_property(v, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(v.queue_free)


func _layout_hand(pi: int) -> void:
	var hand: Array = state.players[pi]["hand"]
	var n: int = hand.size()
	if n == 0:
		return
	var hoff: Vector2 = ed.position_of("hand_p") if pi == 0 else ed.position_of("hand_ai")
	if pi == 0:
		var hs: float = ed.scale_of("hand_p")
		var cw := CardView.CARD_W
		var ch := CardView.CARD_H
		# (1.49.86) mão mais junta, centrada na TELA e longe dos hubs dos heróis
		var spacing: float = minf(cw * hs - 10.0, (615.0 - cw) / float(maxi(1, n - 1))) if n > 1 else 0.0
		var total: float = (n - 1) * spacing + cw * hs
		var x0: float = W / 2.0 - total / 2.0 + hoff.x
		for i in n:
			var v: CardView = hand_views[pi].get(int(hand[i]["uid"]))
			if v == null or v.dragging:
				continue
			var mid: float = (n - 1) / 2.0
			var off: float = float(i) - mid
			var rot: float = off * 1.6
			var dy: float = off * off * 1.8
			var cx: float = x0 + i * spacing + cw * hs / 2.0
			var cy: float = hand_y + hoff.y + dy
			v.scale = Vector2(hs, hs)
			v.set_slot_target(Vector2(cx - cw / 2.0, cy + (ch * hs - ch) / 2.0), rot)
			if v.has_meta("snap"):
				v.snap_to_slot()
				v.remove_meta("snap")
	else:
		var hs2: float = ed.scale_of("hand_ai")
		var cw2 := CardView.CARD_W
		var ch2 := CardView.CARD_H
		var spacing2: float = minf(cw2 * hs2 - 8.0, (930.0 - cw2) / float(maxi(1, n - 1))) if n > 1 else 0.0
		var total2: float = (n - 1) * spacing2 + cw2 * hs2
		var x1: float = FIELD_CX - total2 / 2.0 + hoff.x
		for i in n:
			var v2: CardView = hand_views[pi].get(int(hand[i]["uid"]))
			if v2 == null:
				continue
			var mid2: float = (n - 1) / 2.0
			var off2: float = float(i) - mid2
			var cx2: float = x1 + i * spacing2 + cw2 * hs2 / 2.0
			var cy2: float = ai_hand_y + hoff.y - off2 * off2 * 1.8
			v2.scale = Vector2(hs2, hs2)
			v2.set_slot_target(Vector2(cx2 - cw2 / 2.0, cy2 + (ch2 * hs2 - ch2) / 2.0), 180.0 - off2 * 1.6)
			if v2.has_meta("snap"):
				v2.snap_to_slot()
				v2.remove_meta("snap")


func _on_champion_summoned(pi: int, card: Dictionary) -> void:
	var uid := int(card["uid"])
	var v: ChampionView
	if champ_views.has(uid):
		v = champ_views[uid]
		v.setup(card, pi)  # reusa (trocas/charme): recria visual com novas cores
	else:
		v = ChampionView.new()
		v.setup(card, pi)
		v.champ_clicked.connect(_on_champ_clicked)
		v.champ_drag_started.connect(_on_champ_drag_started)
		v.champ_drag_ended.connect(_on_champ_drag_ended)
		champ_layer.add_child(v)
		champ_views[uid] = v
	# vai DIRETO ao slot onde vai ficar (sem passar por cima de outras cartas)
	var cidx := state.idx_of_uid(pi, int(card["uid"]))
	var cnt: int = state.players[pi]["field"].size()
	v.position = _slot_for(pi, maxi(0, cidx), maxi(1, cnt))
	v.visible = false
	_refresh_counts()
	if pi == 1:
		_ai_summon_flight(v, card, v.position)
	else:
		_reveal_summon(v, pi)


func _reveal_summon(v: ChampionView, pi: int) -> void:
	if not is_instance_valid(v) or v.dying:
		return
	_reveal_impact(v, pi)


func _reveal_impact(v: ChampionView, pi: int) -> void:
	if not is_instance_valid(v) or v.dying:
		return
	if v._slot_tw != null and v._slot_tw.is_valid():
		v._slot_tw.kill()
	v.landing = true
	v.visible = true
	# (1.49.64) A carta CHEGA CAINDO: queda vertical curta e acelerada até o
	# slot e pouso SOMENTE com o IMPACTO PESADO — SEM deslizamento no campo.
	# (1.49.63) A carta NÃO encolhe nem cresce ao chegar.
	v.play_summon_pop()
	var slot_pos := v.position
	v.position = slot_pos - Vector2(0, DROP_H)
	var fall := v.create_tween()
	fall.tween_property(v, "position", slot_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_callback(_land_summon.bind(v, false, pi))


func _land_summon(v: ChampionView, cold: bool, pi: int) -> void:
	# Fim da queda: IMPACTO PESADO (como uma carta muito pesada caindo no
	# chão, referência Hearthstone) — poeira, onda de choque, clarão e baque.
	if not is_instance_valid(v) or v.dying:
		return
	var center := v.position + v.size / 2.0
	Sfx.play("summon_land", center.x, 0.7 if cold else 1.0)
	if cold:
		_fx_flash(Color(0.6, 0.85, 1.0, 0.10), 0.3)
		_fx_ring(center, Color(0.4, 0.85, 1.0, 0.9), 24, 120, 0.5)
		_fx_dust(center, 6)
		_fx_sparks(center, Color(0.5, 0.9, 1.0), 8)
	else:
		_fx_impact_summon(center)
	# (1.49.89) FÚRIA / GRITO DE GUERRA / TALENTO GRITO: raio(s) 1s após o pouso.
	var oe: String = String(v.card.get("on_enter", ""))
	var te: String = String(v.card.get("talent_effect", ""))
	if oe == "furia":
		_furia_sequence(int(v.card["uid"]))
	elif oe == "gritoDeGuerra":
		_grito_sequence(pi, int(v.card["uid"]))
	elif te == "gritoDeGuerraTalento":
		_grito_sequence(pi, -1)
	elif oe == "defensor":
		# (1.49.93) animação defensiva épica 0,5 s após o pouso.
		_defensor_sequence(int(v.card["uid"]))
	elif oe == "guardiao":
		# (1.49.93) pilares de luz um a um nos aliados, 0,5 s após o pouso.
		_guardiao_sequence(pi, int(v.card["uid"]))
	elif oe == "pesadelo":
		# (1.49.93) enxurrada de fantasmas 0,5 s após o pouso.
		_pesadelo_sequence(pi, int(v.card["uid"]))
	elif oe == "desacelerar":
		# (1.49.94) relógio mágico no campo adversário 0,5 s após o pouso.
		_desacelerar_sequence(pi, int(v.card["uid"]))
	elif te == "desacelerarTalento":
		# (1.49.94) Talento DESACELERAR: mesmo relógio mágico.
		_desacelerar_sequence(pi, -1)
	elif oe == "invokeDragon" or te == "invocarDragaoTalento":
		# (1.49.93) o ovo do dragão aparece 0,5 s após o pouso e choca.
		_ovo_sequence(pi)
	# (1.49.65) SEM quiche sobe-desce no pouso: a carta chega caindo pesada e
	# pousa firme; o peso é transmitido pelo impacto (poeira/onda/clarão).
	v.modulate = Color(1.5, 1.8, 2.1) if cold else Color(2.1, 1.85, 1.25)
	var gtw := v.create_tween()
	gtw.tween_property(v, "modulate", Color.WHITE, 0.35)
	# (1.49.82) reaplica escurecimento de CANSADO/status após o glow do pouso
	gtw.chain().tween_callback(func() -> void:
		if is_instance_valid(v):
			v.refresh())
	# o reajuste da linha só começa DEPOIS do baque assentar (~0,3 s)
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self) and is_instance_valid(v) and not v.dying:
		v.landing = false
		_layout_field(pi)


func _ai_summon_flight(v: ChampionView, card: Dictionary, slot: Vector2) -> void:
	# A IA também "voa" a carta (verso) da mão dela direto ao slot final (~1,05 s,
	# mesmo ritmo ágil da invocação do jogador — versão 1.49.60).
	var temp := CardView.new()
	temp.setup(card, false)  # ao sair da mão da IA, já mostra a FRENTE
	temp.position = Vector2(FIELD_CX - CardView.CARD_W / 2.0, ai_hand_y)
	temp.z_index = 200
	temp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_layer.add_child(temp)
	var to := slot + Vector2((CHAMP_W - CardView.CARD_W) / 2.0, (CHAMP_H - CardView.CARD_H) / 2.0)
	await _fly_card(temp, to - Vector2(0, DROP_H), 1.05, 40.0)
	temp.queue_free()
	if not is_instance_valid(v) or v.dying or not champ_views.values().has(v):
		return
	_reveal_summon(v, 1)


func _row_top(pi: int) -> float:
	return (AI_ROW_CY if pi == 1 else PL_ROW_CY) - CHAMP_H / 2.0


func _on_field_changed(pi: int) -> void:
	var field: Array = state.players[pi]["field"]
	var alive := {}
	for c in field:
		alive[int(c["uid"])] = true
	for uid in champ_views.keys():
		var v: ChampionView = champ_views[uid]
		if v.owner_pi == pi and not alive.has(int(uid)) and not v.dying and not _pending_desonra.has(int(uid)):
			champ_views.erase(uid)
			_animate_view_exit(v)
	for c in field:
		if not champ_views.has(int(c["uid"])):
			_on_champion_summoned(pi, c)
	if Time.get_ticks_msec() - _last_destroy_ms < 150:
		# (1.49.91) SEM HONRA: a reorganização dos aliados NÃO acontece aqui —
		# ela roda 0,5 s APÓS o fim da morte especial (_reorg_after_desonra).
		if _has_pending_desonra(pi):
			return
		# aguarda 1 s após a destruição antes de reajustar a linha
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(self):
			return
	_layout_field(pi)


func _layout_field(pi: int) -> void:
	# Linha única sempre centralizada + REGRA DE ESPAÇO (nunca excede a metade).
	# Campeões + Talentos em exibição temporária compartilham a linha.
	var field: Array = state.players[pi]["field"]
	var extras: Array = field_extras[pi]
	var order: Array = []
	for i in field.size():
		order.append(champ_views.get(int(field[i]["uid"])))
	for ex in extras:
		var ins: int = clampi(int(ex["slot"]), 0, order.size())
		order.insert(ins, ex["view"])
	var n: int = order.size()
	if n == 0:
		return
	var gap := 10.0
	var avail_w: float = FIELD_W - 24.0
	var avail_h: float = (BANNER_Y - FIELD_Y) - 18.0
	var base_total: float = n * CHAMP_W + (n - 1) * gap
	var s: float = minf(1.0, minf(avail_w / base_total, avail_h / CHAMP_H))
	var eff_w: float = CHAMP_W * s
	var gap_e: float = gap * s
	var total: float = n * eff_w + (n - 1) * gap_e
	var x0: float = FIELD_CX - total / 2.0
	var cy: float = AI_ROW_CY if pi == 1 else PL_ROW_CY
	var off := _field_offset()
	for i in n:
		var v: ChampionView = order[i]
		if v == null or not is_instance_valid(v) or v.dying or v.dragging:
			continue
		v.layout_scale = s
		var cx: float = x0 + i * (eff_w + gap_e) + eff_w / 2.0
		v.set_slot_target(Vector2(cx - CHAMP_W / 2.0, cy - CHAMP_H / 2.0) + off)


func _on_talent_played(pi: int, card: Dictionary) -> void:
	# Talento/Reação: fica no campo de quem usou por 2 s e então some
	# (só um Talento por vez por jogador — regra no motor).
	var uid := int(card["uid"])
	var v := ChampionView.new()
	v.setup(card, pi)
	v.champ_clicked.connect(_on_champ_clicked)
	champ_layer.add_child(v)
	extra_views[uid] = v
	var slot: int = 0
	if pi == 0 and _pending_talent_slot >= 0:
		slot = _pending_talent_slot
		_pending_talent_slot = -1
	else:
		slot = state.players[pi]["field"].size()
	field_extras[pi].append({"view": v, "slot": slot})
	var n: int = state.players[pi]["field"].size() + field_extras[pi].size()
	v.position = _slot_for(pi, clampi(slot, 0, n - 1), n)
	v.visible = false
	_layout_field(pi)
	if pi == 1:
		var temp := CardView.new()
		temp.setup(card, false)  # mostra a FRENTE durante o voo
		temp.position = Vector2(FIELD_CX - CardView.CARD_W / 2.0, ai_hand_y)
		temp.z_index = 120
		temp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand_layer.add_child(temp)
		var to := v.position + Vector2((CHAMP_W - CardView.CARD_W) / 2.0, (CHAMP_H - CardView.CARD_H) / 2.0)
		await _fly_card(temp, to - Vector2(0, DROP_H), 0.9, 40.0)
		temp.queue_free()
		_reveal_extra(v, pi)
	else:
		_reveal_extra(v, pi)
	await get_tree().create_timer(2.0).timeout
	# enquanto esta carta estiver sendo a ORIGEM de uma mira (Bola de Fogo),
	# ela permanece no campo ate o jogador escolher o alvo
	while is_instance_valid(v) and state.targeting_active_for(uid):
		await get_tree().create_timer(0.25).timeout
	# (1.49.79) o Talento só some MEIO SEGUNDO depois que a animação dele
	# termina (Fortalecer/Bola de Fogo/etc.) — e nunca antes de 2 s em campo
	var anim_end: float = float(_talent_anim_until.get(uid, 0))
	while anim_end > 0.0 and Time.get_ticks_msec() < anim_end + 500.0:
		await get_tree().create_timer(0.1).timeout
	# tempo da Bola de Fogo sair da carta antes de ela sumir
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(v):
		for ex in field_extras[pi]:
			if ex["view"] == v:
				field_extras[pi].erase(ex)
				break
		extra_views.erase(uid)
		state.talent_released(pi)
		var tw := v.create_tween()
		tw.tween_property(v, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(v.queue_free)
		_layout_field(pi)


func _reveal_extra(v: ChampionView, pi: int) -> void:
	if not is_instance_valid(v) or v.dying:
		return
	if v._slot_tw != null and v._slot_tw.is_valid():
		v._slot_tw.kill()
	v.landing = true
	v.visible = true
	# (1.49.64) mesma queda pesada dos Campeões, em tom frio (Talento/Reação)
	v.play_summon_pop()
	var slot_pos := v.position
	v.position = slot_pos - Vector2(0, DROP_H)
	var fall := v.create_tween()
	fall.tween_property(v, "position", slot_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_callback(_land_summon.bind(v, true, pi))


func _pre_shift(pi: int, insert_idx: int) -> void:
	# Aliados abrem espaço de forma sutil DURANTE o voo da carta invocada.
	var field: Array = state.players[pi]["field"]
	var n: int = field.size() + 1
	var gap := 10.0
	var avail_w: float = FIELD_W - 24.0
	var avail_h: float = (BANNER_Y - FIELD_Y) - 18.0
	var base_total: float = n * CHAMP_W + (n - 1) * gap
	var s: float = minf(1.0, minf(avail_w / base_total, avail_h / CHAMP_H))
	var eff_w: float = CHAMP_W * s
	var gap_e: float = gap * s
	var total: float = n * eff_w + (n - 1) * gap_e
	var x0: float = FIELD_CX - total / 2.0
	var cy: float = AI_ROW_CY if pi == 1 else PL_ROW_CY
	var off := _field_offset()
	for i in field.size():
		var slot_idx: int = i + (1 if i >= insert_idx else 0)
		var v: ChampionView = champ_views.get(int(field[i]["uid"]))
		if v == null or v.dragging:
			continue
		v.layout_scale = s
		var cx: float = x0 + slot_idx * (eff_w + gap_e) + eff_w / 2.0
		v.set_slot_target(Vector2(cx - CHAMP_W / 2.0, cy - CHAMP_H / 2.0) + off)


func _on_champion_destroyed(pi: int, card: Dictionary, reason: String, gave_vp: bool) -> void:
	Sfx.play("destroy", 640.0, 0.9)
	var uid := int(card["uid"])
	if String(_death_style.get(uid, "")) == "semhonra" and champ_views.has(uid):
		# (1.49.80) SEM HONRA: NADA de explodir no meio da animação alheia.
		# Em COMBATE: o campeão volta ao seu lugar no campo e a morte especial
		# roda 0,5 s depois (gancho no fim de _do_combat). Fora de combate
		# (ex.: Bola de Fogo): espera a animação gatilho terminar (+1,0 s).
		_pending_desonra[uid] = true
		if reason != "combate":
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				if is_instance_valid(self):
					_finish_desonra(uid))
		_last_destroy_ms = Time.get_ticks_msec()
		if gave_vp:
			_spawn_toast("+PV para %s!" % state.players[1 - pi]["name"])
		_refresh_counts()
		return
	if champ_views.has(uid):
		var v: ChampionView = champ_views[uid]
		champ_views.erase(uid)
		if _death_style.has(uid):
			# (1.49.76) RECOMPENSA DUPLA: a animação de destruição padrão é
			# SUBSTITUÍDA pela especial de 2 s.
			var style: String = _death_style[uid]
			_death_style.erase(uid)
			_custom_death(v, style)
			_last_destroy_ms = Time.get_ticks_msec()
			if gave_vp:
				_spawn_toast("+PV para %s!" % state.players[1 - pi]["name"])
			_refresh_counts()
			return
		# FX de destruição estilo Hearthstone: estilhaços + fumaça + anel
		var center := v.global_position + v.size / 2.0
		_fx_shards(center, Color(0.85, 0.32, 0.26))
		_fx_shards(center, Color(0.25, 0.2, 0.3))
		_fx_smoke(center)
		_fx_ring(center, Color(1, 0.35, 0.25, 0.9), 26, 130, 0.5)
		_fx_sparks(center, Color(1, 0.5, 0.3), 7)
		v.play_death()
	_last_destroy_ms = Time.get_ticks_msec()
	if gave_vp:
		_spawn_toast("+PV para %s!" % state.players[1 - pi]["name"])
	_refresh_counts()


func _on_champion_morphed(pi: int, card: Dictionary) -> void:
	var v: ChampionView = champ_views.get(int(card["uid"]))
	if v != null:
		v.setup(card, pi)


func _on_attack_done(_att_p: int, _att_card: Dictionary, _def_p: int, _def_card: Dictionary, _result: String) -> void:
	Sfx.play("attack", 640.0, 0.9)
	pass  # log já emitido pelo estado


func _on_vp_changed(pi: int) -> void:
	vp_labels[pi].text = "PV %d/%d" % [state.players[pi]["vp"], state.win_points]


func _on_actions_changed(pi: int) -> void:
	# (1.49.65) caixa ÚNICA de AÇÕES para os dois jogadores: mede as ações
	# restantes do jogador ATIVO (principal ou IA). No início de cada vez o
	# motor reseta para 3 e emite este sinal, então a caixa volta a 3 sozinha.
	var cur: int = state.current
	var a: int = state.players[cur]["actions"]
	actions_label.text = "AÇÕES: %d" % a
	for i in 3:
		var psb: StyleBoxFlat = pips[i].get_theme_stylebox("panel")
		psb.bg_color = Color(0.95, 0.8, 0.35) if i < a else Color(0.2, 0.19, 0.26)
	_refresh_buttons()


func _on_turn_started(pi: int) -> void:
	Sfx.play("turn", 640.0, 0.45)
	_cancel_drags()
	# (1.49.93) PESADELO sobre o herói: o efeito (e os fantasmas sobre a
	# moldura) some quando TERMINA o turno do jogador afetado.
	if _pesadelo_hero_pi >= 0:
		if pi == _pesadelo_hero_pi:
			_pesadelo_turn_seen = true
		elif _pesadelo_turn_seen:
			_clear_pesadelo_hero()
	if state.winner == -1:
		input_locked = (pi == 1)
	if pi == 0:
		banner_label.text = "SUA VEZ"
		banner_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	else:
		banner_label.text = "VEZ DO ADVERSÁRIO"
		banner_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
	turn_timer = 70.0
	_update_timer_ui()
	# (1.49.73) Muralha (wall_buff) liga/desliga na virada de turno:
	# refresca os campeões para a parede mágica aparecer/sumir na hora.
	for v in champ_views.values():
		if is_instance_valid(v):
			v.refresh()
	var tw := banner.create_tween()
	banner.scale = Vector2(1.18, 1.18)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_buttons()
	_refresh_counts()
	if state.winner != -1:
		return
	if pi == 1 and not ai_running:
		_run_ai_turn()


func _update_timer_ui() -> void:
	if timer_label == null:
		return
	var t := int(ceil(turn_timer))
	timer_label.text = str(t)
	timer_label.add_theme_color_override("font_color", Color(1, 0.45, 0.4) if t <= 10 else Color(1, 0.95, 0.8))
	if clock_hand != null:
		clock_hand.rotation_degrees = (1.0 - turn_timer / 70.0) * 360.0


func _on_medal_input(ev: InputEvent, pi: int) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		if ed != null and ed.active:
			return
		_close_zoom()
		_open_history(pi)


func _open_history(pi: int) -> void:
	_close_history()
	history_overlay = Control.new()
	history_overlay.position = Vector2.ZERO
	history_overlay.size = Vector2(1280, 720)
	history_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	history_overlay.z_index = 1000
	add_child(history_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_history())
	history_overlay.add_child(dim)
	var panel := _panel_local(Vector2(380, 56), Vector2(520, 608), Color(0.09, 0.07, 0.14, 0.98), Color(0.85, 0.68, 0.3), 2, 14)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	history_overlay.add_child(panel)
	var hero: Dictionary = state.players[pi]["hero"]
	# destaque do herói: imagem (medalhão), nome e habilidade
	var medal := Panel.new()
	var msb := StyleBoxFlat.new()
	msb.bg_color = (hero_meds[pi]["medal"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color
	msb.set_corner_radius_all(16)
	msb.border_color = Color(0.95, 0.8, 0.4)
	msb.set_border_width_all(3)
	medal.add_theme_stylebox_override("panel", msb)
	medal.position = Vector2(24, 22)
	medal.size = Vector2(96, 96)
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(medal)
	var ini := Label.new()
	ini.text = hero_meds[pi]["initials"].text
	ini.add_theme_font_size_override("font_size", 34)
	ini.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.position = Vector2.ZERO
	ini.size = Vector2(96, 96)
	ini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.add_child(ini)
	var nm := Label.new()
	nm.text = String(hero.get("name", "")) + ("  (IA)" if pi == 1 else "  (Você)")
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", Color(1, 0.96, 0.85))
	nm.position = Vector2(140, 30)
	nm.size = Vector2(356, 28)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(nm)
	var un := Label.new()
	un.text = "Habilidade: " + String(hero.get("ult", ""))
	un.add_theme_font_size_override("font_size", 13)
	un.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	un.position = Vector2(140, 62)
	un.size = Vector2(356, 20)
	un.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(un)
	var ud := Label.new()
	ud.text = String(hero.get("ult_desc", ""))
	ud.add_theme_font_size_override("font_size", 11)
	ud.add_theme_color_override("font_color", Color(0.88, 0.86, 0.94))
	ud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ud.clip_text = true
	ud.position = Vector2(24, 128)
	ud.size = Vector2(472, 62)
	ud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ud)
	var sep := ColorRect.new()
	sep.color = Color(0.85, 0.68, 0.3, 0.6)
	sep.position = Vector2(24, 198)
	sep.size = Vector2(472, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)
	var ht := Label.new()
	ht.text = "HISTÓRICO DE CARTAS (da última usada para a primeira)"
	ht.add_theme_font_size_override("font_size", 11)
	ht.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	ht.position = Vector2(24, 206)
	ht.size = Vector2(400, 16)
	ht.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ht)
	var xb := Button.new()
	xb.text = "X"
	xb.position = Vector2(478, 8)
	xb.size = Vector2(32, 32)
	xb.pressed.connect(_close_history)
	panel.add_child(xb)
	# lista rolável: miniatura da carta + quem usou
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 228)
	scroll.size = Vector2(472, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	var hist: Array = state.play_history.duplicate()
	hist.reverse()
	if hist.is_empty():
		var empty := Label.new()
		empty.text = "Nenhuma carta usada ainda."
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.8, 0.78, 0.88))
		vbox.add_child(empty)
	for entry in hist:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		vbox.add_child(hb)
		var mini := CardView.new()
		mini.setup(entry["card"], false, 0.52)
		mini.hover_enabled = false
		mini.drag_enabled = false
		mini.mouse_filter = Control.MOUSE_FILTER_STOP
		var hist_card: Dictionary = entry["card"]
		mini.clicked.connect(func(_c: CardView) -> void: _open_zoom(hist_card))
		hb.add_child(mini)
		var who: Label = Label.new()
		var wpi: int = int(entry["pi"])
		who.text = (Profile.player_name() if wpi == 0 else String(state.players[1]["hero"].get("name", "IA"))) + " usou esta carta"
		who.add_theme_font_size_override("font_size", 12)
		who.add_theme_color_override("font_color", Color(1, 0.88, 0.5) if wpi == 0 else Color(1, 0.55, 0.5))
		who.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		who.custom_minimum_size = Vector2(150, 0)
		who.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(who)


func _close_history() -> void:
	if history_overlay != null and is_instance_valid(history_overlay):
		history_overlay.queue_free()
	history_overlay = null


func _on_ult_pressed() -> void:
	Sfx.play("ultimate", 640.0, 0.9)
	if input_locked or state.current != 0 or state.winner != -1:
		return
	state.use_ultimate(0)


func _on_ultimate_used(_pi: int) -> void:
	_refresh_buttons()


func _on_sync_views() -> void:
	for uid in champ_views.keys():
		champ_views[uid].refresh()
	_refresh_buttons()
	_refresh_counts()


func _on_game_over(winner_pi: int) -> void:
	input_locked = true
	_refresh_buttons()
	if winner_pi == 0:
		gameover_title.text = "VITÓRIA!"
		gameover_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	else:
		gameover_title.text = "DERROTA"
		gameover_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	var rew := Profile.add_match_rewards(winner_pi == 0)
	var margin: int = absi(int(state.players[0]["vp"]) - int(state.players[1]["vp"]))
	var cards0 := []
	for e in state.play_history:
		if int(e["pi"]) == 0:
			cards0.append(String(e["card"]["name"]))
	Profile.record_match(winner_pi == 0, margin, state.players[0]["stats"], cards0, String(state.players[0]["hero"].get("id", "")))
	gameover_sub.text = "%s %d x %d %s   |   +%d XP, +%d moeda(s)" % [state.players[0]["name"], state.players[0]["vp"], state.players[1]["vp"], state.players[1]["name"], rew["xp"], rew["coins"]]
	await get_tree().create_timer(0.9).timeout
	gameover_overlay.visible = true


# ----------------------------------------------------------------------------
# Interação do jogador
# ----------------------------------------------------------------------------

func _refresh_buttons() -> void:
	if state == null:
		return
	var my_turn: bool = state.current == 0 and state.winner == -1 and not input_locked and state.targeting.is_empty()
	var chk := state.can_manual_draw(0)
	btn_draw.disabled = not my_turn or not chk["ok"]
	btn_pass.disabled = not my_turn
	if btn_ult != null:
		var uchk := state.can_use_ultimate(0)
		btn_ult.disabled = not my_turn or not uchk["ok"]
		var hero: Dictionary = state.players[0]["hero"]
		btn_ult.text = "ULTIMATE (%d)\n%s" % [state.players[0]["ult_remaining"], String(hero.get("ult", ""))]
		btn_ult.tooltip_text = "" 


func _on_draw_pressed() -> void:
	if input_locked or state.current != 0 or state.winner != -1:
		return
	state.manual_draw(0)


func _on_pass_pressed() -> void:
	if input_locked or state.current != 0 or state.winner != -1:
		return
	_cancel_drags()
	state.end_turn()


func _cancel_drags() -> void:
	if drag_view != null and is_instance_valid(drag_view):
		drag_view.abort_drag()
	drag_view = null
	if drag_champ != null and is_instance_valid(drag_champ):
		drag_champ.abort_drag()
	drag_champ = null
	drop_glow.visible = false
	_close_zoom()


func _on_options_pressed() -> void:
	options_overlay.visible = true


func _on_card_drag_started(view: CardView) -> void:
	if view.in_flight or input_locked or state.current != 0 or state.winner != -1 or drag_champ != null or zoom_overlay != null or not state.targeting.is_empty():
		view.abort_drag()
		if state.current != 0 and state.winner == -1 and zoom_overlay == null:
			_spawn_toast("Aguarde: vez do adversário.")
		return
	drag_view = view
	var idx := _hand_idx_of(0, int(view.card["uid"]))
	var chk := state.can_play(0, idx)
	drop_glow.visible = true
	var sb: StyleBoxFlat = drop_glow.get_theme_stylebox("panel")
	if chk["ok"]:
		sb.bg_color = Color(0.3, 0.9, 0.4, 0.12)
		sb.border_color = Color(0.4, 1.0, 0.5, 0.8)
	else:
		sb.bg_color = Color(0.9, 0.3, 0.3, 0.10)
		sb.border_color = Color(1.0, 0.4, 0.4, 0.7)


func _on_card_drag_ended(view: CardView) -> void:
	drop_glow.visible = false
	if drag_view != view:
		view.end_drag_return()
		return
	drag_view = null
	var mouse := get_global_mouse_position()
	if _drop_rect().has_point(mouse):
		var idx := _hand_idx_of(0, int(view.card["uid"]))
		if idx >= 0:
			var chk := state.can_play(0, idx)
			if not chk["ok"]:
				_spawn_toast(chk["reason"])
				view.end_drag_return()
				return
			# Voo estilo Hearthstone: a carta voa da mão até o centro do campo
			var is_champ: bool = view.card["category"] == "champion"
			var uid := int(view.card["uid"])
			hand_views[0].erase(uid)  # assume o controle: reconcile não a remove
			view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			view.dragging = false
			var center := Vector2(FIELD_CX, PL_ROW_CY)
			if is_champ:
				# posição de soltura define ONDE invoca: à esquerda/direita/entre
				var insert_idx := 0
				for c in state.players[0]["field"]:
					var cv: ChampionView = champ_views.get(int(c["uid"]))
					var cx: float = (cv.global_position.x + CHAMP_W / 2.0) if cv != null else FIELD_CX
					if cx < mouse.x:
						insert_idx += 1
				var n_after: int = state.players[0]["field"].size() + 1
				var slot := _slot_for(0, insert_idx, n_after)
				view.z_index = 200  # sempre POR CIMA das cartas da mão
				_pre_shift(0, insert_idx)
				var to := slot + Vector2((CHAMP_W - view.size.x) / 2.0, (CHAMP_H - view.size.y) / 2.0)
				await _fly_card(view, to - Vector2(0, DROP_H), 1.05, -50.0)
				view.queue_free()
				state.play_card(0, idx, insert_idx)
			else:
				var t_ins := 0
				for c in state.players[0]["field"]:
					var cv0: ChampionView = champ_views.get(int(c["uid"]))
					var cx0: float = (cv0.global_position.x + CHAMP_W / 2.0) if cv0 != null else FIELD_CX
					if cx0 < mouse.x:
						t_ins += 1
				_pending_talent_slot = t_ins
				var t_slot_idx: int = t_ins
				var t_n: int = state.players[0]["field"].size() + 1
				var t_slot := _slot_for(0, t_slot_idx, t_n)
				_pre_shift(0, t_ins)
				var t_to := t_slot + Vector2((CHAMP_W - view.size.x) / 2.0, (CHAMP_H - view.size.y) / 2.0)
				view.z_index = 200
				await _fly_card(view, t_to - Vector2(0, DROP_H), 0.9, -40.0)
				view.queue_free()
				state.play_card(0, idx)
			return
	view.end_drag_return()


func _hand_idx_of(pi: int, uid: int) -> int:
	return state.idx_of_uid(pi, uid, "hand")


func _process(_delta: float) -> void:
	if (ed != null and ed.active) or (state != null and state.winner != -1):
		pass
	elif state != null and state.started_ok():
		turn_timer -= _delta
		if turn_timer <= 0.0:
			turn_timer = 70.0
			_push_msg("Tempo esgotado! A vez passou automaticamente.")
			state.end_turn()
		_update_timer_ui()
	if drag_view != null and is_instance_valid(drag_view):
		drag_view.global_position = get_global_mouse_position() - drag_view._drag_offset
	if drag_champ != null and is_instance_valid(drag_champ):
		drag_champ.global_position = get_global_mouse_position() - drag_champ._drag_offset
		var t: ChampionView = _enemy_under(drag_champ)
		if t != _hover_target:
			if _hover_target != null and is_instance_valid(_hover_target):
				_hover_target.set_target_glow(false)
			_hover_target = t
			if t != null:
				t.set_target_glow(true)


# ----------------------------------------------------------------------------
# Ampliar carta (clique)
# ----------------------------------------------------------------------------

func _on_card_clicked(view: CardView) -> void:
	if drag_view != null or drag_champ != null:
		return
	_open_zoom(view.card)


func _open_zoom(card: Dictionary) -> void:
	_close_zoom()  # o histórico permanece aberto abaixo do zoom
	zoom_overlay = Control.new()
	zoom_overlay.position = Vector2.ZERO
	zoom_overlay.size = Vector2(1280, 720)
	zoom_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	zoom_overlay.z_index = 1000  # nada fica sobre a carta ampliada
	add_child(zoom_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_zoom())
	zoom_overlay.add_child(dim)
	# carta construída em tamanho real (fontes nítidas, sem raster borado)
	var v := CardView.new()
	v.setup(card, false, 3.2)
	v.hover_enabled = false
	v.drag_enabled = false
	v.mouse_filter = Control.MOUSE_FILTER_STOP
	v.clicked.connect(func(_x: CardView) -> void: _close_zoom())
	zoom_overlay.add_child(v)
	v.scale = Vector2(0.55, 0.55)
	v.modulate = Color(1, 1, 1, 0)
	v.position = Vector2(W / 2.0 - v.size.x / 2.0, H / 2.0 - v.size.y / 2.0)
	var tw := v.create_tween()
	tw.set_parallel(true)
	tw.tween_property(v, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "modulate", Color.WHITE, 0.12)
	# (1.49.78) STATUS NO ZOOM: TODOS os status ativos do campeão aparecem
	# acumulados (um não anula o outro), numa coluna de ícones + descrições
	# no padrão do antigo ícone de Proteção.
	var status_list: Array = []
	if String(card.get("category", "")) == "champion":
		if int(card.get("shield_turns", 0)) != 0:
			status_list.append(["res://assets/ICO_PROTECAO.svg", "PROTEÇÃO", "(não pode ser atacado)"])
		if bool(card.get("corrupted", false)) or (not bool(card.get("silenced", false)) and (String(card.get("on_destroy", "")) == "noHonor" or String(card.get("ability_name", "")) == "Sem Honra")):
			status_list.append(["res://assets/ICO_CAVEIRA.svg", "SEM HONRA", "(quem o destruir não ganha PV)"])
		if int(card.get("barrier_turns", 0)) != 0:
			status_list.append(["res://assets/ICO_BARREIRA.svg", "BARREIRA", "(bloqueia a redução de Poder)"])
		if int(card.get("wall_buff", 0)) != 0:
			status_list.append(["res://assets/ICO_MURALHA.svg", "MURALHA", "(+1 Poder fora do seu turno)"])
		if int(card.get("frozen_turns", 0)) > 0:
			status_list.append(["res://assets/VFX_FLOCO.png", "CONGELADO", "(%d rodada(s) restante(s))" % int(card.get("frozen_turns", 0))])
		if int(card.get("poison_turns", 0)) > 0:
			status_list.append(["res://assets/ICO_VENENO.svg", "ENVENENADO", "(será destruído em %d rodada(s))" % int(card.get("poison_turns", 0))])
		if int(card.get("burn_turns", 0)) > 0:
			status_list.append(["res://assets/ICO_CHAMAS.svg", "CHAMAS", ""])
		if int(card.get("fury_stacks", 0)) > 0:
			status_list.append(["res://assets/ICO_FURIA.svg", "FÚRIA", "(+%d de Poder por %d rodada(s))" % [int(card.get("fury_stacks", 0)), int(card.get("fury_turns", 0))]])
		if bool(card.get("prision", false)):
			status_list.append(["res://assets/ICO_PRESO.svg", "PRESO", ""])
		if bool(card.get("silenced", false)):
			status_list.append(["res://assets/ICO_SILENCIADO.svg", "SILENCIADO", ""])
		if int(card.get("charm_turns", 0)) > 0:
			status_list.append(["res://assets/ICO_ENFEITICADO.svg", "ENFEITIÇADO", ""])
		if bool(card.get("tapped", false)):
			status_list.append(["res://assets/ICO_CANSADO.svg", "CANSADO", "(já agiu neste turno — dormindo)"])
	var n_st := status_list.size()
	# (1.49.82) layout em LINHAS: ícone à esquerda e o texto SEMPRE à direita
	# do ícone — nada se sobrepõe, nada toca a carta ampliada.
	var card_right := W / 2.0 + v.size.x / 2.0
	var col_x := card_right + 24
	var row_h := 96.0
	var y0 := H / 2.0 - (n_st * row_h) / 2.0
	for i in n_st:
		var e: Array = status_list[i]
		var ico := TextureRect.new()
		ico.name = "status_icon_%d" % i
		ico.texture = load(String(e[0]))
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.size = Vector2(68, 68)
		ico.position = Vector2(col_x, y0 + i * row_h)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zoom_overlay.add_child(ico)
		var lbs := Label.new()
		lbs.name = "status_caption_%d" % i
		lbs.text = String(e[1]) + ("\n" + String(e[2]) if String(e[2]) != "" else "")
		lbs.add_theme_font_size_override("font_size", 15)
		lbs.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
		lbs.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbs.position = Vector2(col_x + 78, y0 + i * row_h + 4)
		lbs.size = Vector2(250, 72)
		lbs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zoom_overlay.add_child(lbs)


func _close_zoom() -> void:
	if zoom_overlay != null and is_instance_valid(zoom_overlay):
		zoom_overlay.queue_free()
	zoom_overlay = null


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		if ev.keycode == KEY_F9:
			_demo_fireball()  # teste de VFX de bola de fogo
			get_viewport().set_input_as_handled()
		elif ev.keycode == KEY_ESCAPE:
			if zoom_overlay != null and is_instance_valid(zoom_overlay):
				_close_zoom()
				get_viewport().set_input_as_handled()
			elif history_overlay != null and is_instance_valid(history_overlay):
				_close_history()
				get_viewport().set_input_as_handled()


func _on_fx_fire(from_pi: int, from_uid: int, target_uid: int) -> void:
	Sfx.play("fireball_launch", 640.0, 0.9)
	var dst_v: ChampionView = champ_views.get(target_uid)
	if dst_v == null or not is_instance_valid(dst_v):
		# sem view do alvo: aplica o dano imediatamente (sem animação)
		if state != null:
			state.resolve_bola(target_uid)
		return
	var dst: Vector2 = dst_v.global_position + dst_v.size / 2.0
	var src: Vector2
	if from_uid >= 0 and champ_views.has(from_uid):
		# saiu do Campeão que tem a habilidade Bola de Fogo
		var sv: ChampionView = champ_views[from_uid]
		src = sv.global_position + sv.size / 2.0
	elif from_uid >= 0 and extra_views.has(from_uid):
		# saiu da carta de Talento/Reação que foi jogada no campo
		var ev: ChampionView = extra_views[from_uid]
		if is_instance_valid(ev):
			src = ev.global_position + ev.size / 2.0
		else:
			src = Vector2(FIELD_CX, PL_ROW_CY if from_pi == 0 else AI_ROW_CY)
	else:
		# reserva (nunca fora da tela): centro da linha de quem lançou
		src = Vector2(FIELD_CX, PL_ROW_CY if from_pi == 0 else AI_ROW_CY)
	var fbx := _spawn_fireball(src, dst, target_uid)
	# (1.49.79) fim da animação do Talento de origem (regra de permanência)
	fbx.exploded.connect(func(_at2: Vector2) -> void:
		_talent_anim_until[from_uid] = Time.get_ticks_msec())


func _on_fx_congelar(_pi: int, _src: int, target_uid: int) -> void:
	Sfx.play("congelar", 640.0, 0.9)
	# (1.49.87) burst de congelamento sobre o alvo escolhido
	var v: ChampionView = champ_views.get(target_uid)
	var at: Vector2 = (v.global_position + v.size / 2.0) if (v != null and is_instance_valid(v)) else Vector2(FIELD_CX, AI_ROW_CY)
	var fx = load("res://scripts/vfx_congelar.gd").new()
	fx_layer.add_child(fx)
	fx.setup(at)


func _furia_sequence(uid: int) -> void:
	# (1.49.89/91) 1s após invocar: RAIO VERMELHO (1,5s) cai sobre o campeão;
	# 0,5s depois do impacto ele recebe o status FÚRIA — em campo, SOMENTE o
	# ícone de Fúria no canto superior direito (sem aura persistente).
	await get_tree().create_timer(1.0).timeout
	if state == null or not is_inside_tree():
		return
	var v: ChampionView = champ_views.get(uid)
	if v == null or not is_instance_valid(v) or v.dying:
		return
	Sfx.play("raio", 640.0, 0.85)
	var raio := RaioFX.new()
	fx_layer.add_child(raio)
	raio.setup(v.global_position + v.size / 2.0, 1.5)
	await raio.finished
	await get_tree().create_timer(0.5).timeout
	if state != null and is_inside_tree():
		state.resolve_furia(uid)


func _grito_sequence(pi: int, self_uid: int) -> void:
	# (1.49.89) GRITO DE GUERRA: 1s após invocar, raios de 1,0s caem UM A UM em
	# cada aliado (menos no próprio invocador); 0,5s após cada raio o aliado
	# recebe FÚRIA.
	await get_tree().create_timer(1.0).timeout
	if state == null or not is_inside_tree():
		return
	var uids: Array = []
	for c in state.players[pi]["field"]:
		if int(c["uid"]) != self_uid:
			uids.append(int(c["uid"]))
	for uid in uids:
		var v: ChampionView = champ_views.get(uid)
		if v == null or not is_instance_valid(v) or v.dying:
			continue
		Sfx.play("raio", 640.0, 0.85)
		var raio := RaioFX.new()
		fx_layer.add_child(raio)
		raio.setup(v.global_position + v.size / 2.0, 1.0)
		await raio.finished
		await get_tree().create_timer(0.5).timeout
		if state == null or not is_inside_tree():
			return
		state.resolve_furia(uid)


func _defensor_sequence(uid: int) -> void:
	Sfx.play("defensor", 640.0, 0.9)
	# (1.49.93) DEFENSOR: 0,5 s após o pouso, a animação defensiva épica (1,5 s)
	# cobre o Campeão; o ícone de PROTEÇÃO aparece 0,5 s após o INÍCIO dela.
	await get_tree().create_timer(0.5).timeout
	if state == null or not is_inside_tree():
		return
	var v: ChampionView = champ_views.get(uid)
	var at: Vector2 = Vector2(FIELD_CX, PL_ROW_CY)
	if v != null and is_instance_valid(v) and not v.dying:
		at = v.global_position + v.size / 2.0
	else:
		if state != null:
			state.resolve_defensor(uid)
		return
	var fx = load("res://scripts/vfx_defensor.gd").new()
	fx_layer.add_child(fx)
	fx.setup(at)
	await get_tree().create_timer(0.5).timeout
	if state != null and is_inside_tree():
		state.resolve_defensor(uid)


func _guardiao_sequence(pi: int, self_uid: int) -> void:
	Sfx.play("guardiao", 640.0, 0.9)
	# (1.49.93) GUARDIÃO: 0,5 s após o pouso, um PILAR DE LUZ DO CÉU (1,0 s) cai
	# sobre cada campeão aliado, UM POR UM; 0,5 s após o pilar de cada um, o
	# ícone de PROTEÇÃO aparece sobre aquele aliado.
	await get_tree().create_timer(0.5).timeout
	if state == null or not is_inside_tree():
		return
	var uids: Array = []
	for c in state.players[pi]["field"]:
		if int(c["uid"]) != self_uid:
			uids.append(int(c["uid"]))
	for uid in uids:
		var v: ChampionView = champ_views.get(uid)
		if v == null or not is_instance_valid(v) or v.dying:
			if state != null:
				state.resolve_guardiao(uid)
			continue
		var fx = load("res://scripts/vfx_guardiao.gd").new()
		fx_layer.add_child(fx)
		fx.setup(v.global_position + v.size / 2.0)
		await fx.finished
		await get_tree().create_timer(0.5).timeout
		if state == null or not is_inside_tree():
			return
		state.resolve_guardiao(uid)


func _ovo_sequence(pi: int) -> void:
	Sfx.play("ovo_crackle", 640.0, 0.9)
	# (1.49.93) INVOCAR DRAGÃO: 0,5 s após o pouso, o OVO aparece no slot onde o
	# Filhote vai ficar, treme, racha e CHOCA com luz (1,5 s); no burst de luz o
	# FILHOTE DE DRAGÃO é invocado e cai no campo sobre o brilho que esmaece.
	await get_tree().create_timer(0.5).timeout
	if state == null or not is_inside_tree():
		return
	var n: int = state.players[pi]["field"].size()
	# (1.49.98) o slot do Filhote fica LIVRE já no início do ovo: quem está na
	# linha desliza para os n primeiros slots de uma linha de n+1 (posições
	# idênticas às do layout final), então o ovo NUNCA aparece sobre uma carta.
	for i in range(state.players[pi]["field"].size()):
		var uidc := int(state.players[pi]["field"][i]["uid"])
		var vc: ChampionView = champ_views.get(uidc)
		if vc != null and is_instance_valid(vc) and not vc.dying:
			var tw := vc.create_tween()
			tw.tween_property(vc, "position", _slot_for(pi, i, n + 1), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var slot: Vector2 = _slot_for(pi, n, n + 1)
	var center := slot + Vector2(CHAMP_W / 2.0, CHAMP_H / 2.0) + _field_offset()
	var fx = load("res://scripts/vfx_ovo.gd").new()
	fx_layer.add_child(fx)
	fx.setup(center)
	fx.burst.connect(func() -> void:
		Sfx.play("ovo_hatch", center.x, 1.0)
		if state != null and is_inside_tree():
			state.resolve_invoke_dragon())
	# segurança: se o burst não disparar por qualquer motivo, invoca no fim
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		if state != null and is_inside_tree():
			state.resolve_invoke_dragon())
	await fx.finished


func _pesadelo_sequence(pi: int, uid: int) -> void:
	# (1.49.93) PESADELO: 0,5 s após o pouso, o campeão lança MUITOS FANTASMAS e
	# fumaça negra em cone sobre o campo adversário (2,0 s); no fim, o jogador
	# afetado fica sem o próximo saque livre e ganha os fantasmas sobre o herói.
	# (1.49.94) anti-duplicata: NUNCA dois cones por invocação; e quando a IA
	# usa, NADA de animação no topo/esquerda (campo ou caster da IA): o pesadelo
	# desce do centro da tela direto sobre o campo do jogador afetado.
	if _pesadelo_running.has(uid):
		return
	_pesadelo_running[uid] = true
	Sfx.play("pesadelo", 640.0, 0.85)
	await get_tree().create_timer(0.5).timeout
	if state == null or not is_inside_tree():
		_pesadelo_running.erase(uid)
		return
	var foe: int = 1 - pi
	var dst := Vector2(FIELD_CX, AI_ROW_CY if foe == 1 else PL_ROW_CY)
	var src: Vector2
	if pi == 1:
		src = Vector2(FIELD_CX, (AI_ROW_CY + PL_ROW_CY) / 2.0)
	else:
		src = Vector2(FIELD_CX, PL_ROW_CY)
		var v: ChampionView = champ_views.get(uid)
		if v != null and is_instance_valid(v) and not v.dying:
			src = v.global_position + v.size / 2.0
	var fx = load("res://scripts/vfx_pesadelo.gd").new()
	fx_layer.add_child(fx)
	fx.setup(src, dst)
	await fx.finished
	_pesadelo_running.erase(uid)
	if state == null or not is_inside_tree():
		return
	state.resolve_pesadelo()
	_show_pesadelo_hero(foe)


func _desacelerar_sequence(pi: int, _uid: int) -> void:
	Sfx.play("desacelerar", 640.0, 0.9)
	# (1.49.94) DESACELERAR (Campeão e Talento): 0,5 s após a carta entrar em
	# campo, um RELÓGIO MÁGICO de fantasia (bronze, runas, ponteiros voltando
	# para trás) aparece sobre o campo adversário por 2,0 s. O efeito de jogo
	# (1 ação a menos) já é aplicado pelo GameState; aqui é só a animação.
	await get_tree().create_timer(0.5).timeout
	if state == null or not is_inside_tree():
		return
	var foe: int = 1 - pi
	var dst := Vector2(FIELD_CX, AI_ROW_CY if foe == 1 else PL_ROW_CY)
	var fx = load("res://scripts/vfx_desacelerar.gd").new()
	fx_layer.add_child(fx)
	fx.setup(dst)
	await fx.finished


func _show_pesadelo_hero(pi: int) -> void:
	# (1.49.93) fantasmas + fumaça negra em loop ACIMA da moldura do herói
	# afetado (simboliza o saque livre bloqueado); some no fim do turno dele.
	_clear_pesadelo_hero()
	var med: Control = hero_meds[pi]["medal"]
	var fx = load("res://scripts/pesadelo_hero_fx.gd").new()
	fx_layer.add_child(fx)
	fx.setup(med.global_position + Vector2(32.0, -6.0))
	_pesadelo_hero_node = fx
	_pesadelo_hero_pi = pi
	_pesadelo_turn_seen = false


func _clear_pesadelo_hero() -> void:
	if _pesadelo_hero_node != null and is_instance_valid(_pesadelo_hero_node):
		_pesadelo_hero_node.queue_free()
	_pesadelo_hero_node = null
	_pesadelo_hero_pi = -1
	_pesadelo_turn_seen = false


func _on_fx_mordida(pi: int, src_uid: int, target_uid: int) -> void:
	# (1.49.96) MORDIDA VENENOSA: 0,5 s APÓS a seleção do alvo, a animação do
	# vídeo do dono (mandíbula venenosa, 120 px < carta) aparece SOBRE o
	# campeão alvo; ao terminar, aplica o status ENVENENADO (2 rodadas).
	await get_tree().create_timer(0.5).timeout
	if state == null or not is_inside_tree():
		return
	var v: ChampionView = champ_views.get(target_uid)
	if v == null or not is_instance_valid(v) or v.dying:
		state.resolve_mordida(target_uid)
		return
	var fx = load("res://scripts/vfx_mordida.gd").new()
	fx_layer.add_child(fx)
	fx.setup(v.global_position + v.size / 2.0)
	Sfx.play("mordida_launch", v.global_position.x, 0.9)
	fx.finished.connect(func() -> void:
		if state != null and is_inside_tree():
			state.resolve_mordida(target_uid))


func _on_fx_baforada(from_pi: int, from_uid: int, target_uid: int) -> void:
	Sfx.play("baforada", 640.0, 0.9)
	# (1.49.92) BAFORADA VENENOSA: o sopro do Dragão VERDE sai da carta Talento
	# jogada e voa até o Campeão escolhido; NO IMPACTO ele recebe ENVENENADO
	# (ícone no canto superior direito — sem animação persistente).
	var v: ChampionView = champ_views.get(target_uid)
	if v == null or not is_instance_valid(v):
		if state != null:
			state.resolve_baforada(target_uid)
		return
	var dst: Vector2 = v.global_position + v.size / 2.0
	var src: Vector2
	if from_uid >= 0 and extra_views.has(from_uid):
		var ev: ChampionView = extra_views[from_uid]
		if is_instance_valid(ev):
			src = ev.global_position + ev.size / 2.0
		else:
			src = Vector2(FIELD_CX, PL_ROW_CY if from_pi == 0 else AI_ROW_CY)
	else:
		src = Vector2(FIELD_CX, PL_ROW_CY if from_pi == 0 else AI_ROW_CY)
	var fx = load("res://scripts/vfx_baforada.gd").new()
	fx_layer.add_child(fx)
	fx.setup(src, dst)
	fx.finished.connect(func() -> void:
		_talent_anim_until[from_uid] = Time.get_ticks_msec()
		if state != null and is_inside_tree():
			state.resolve_baforada(target_uid))


func _on_fx_forja(pi: int, _uid: int) -> void:
	Sfx.play("forja", 640.0, 0.9)
	# (1.49.86) FORJA = SAQUE LIVRE: 0,5 s após invocar, o jogador ganha uma
	# carta com a MESMA animação de compra (sem gastar ação).
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if state != null and is_inside_tree():
			state.resolve_forja(pi))


func _on_fx_roubo(pi: int, foe: int, uid: int) -> void:
	Sfx.play("roubo", 640.0, 0.8)
	# (1.49.77) segurança idempotente: se o voo não resolver, o roubo efetiva
	get_tree().create_timer(3.2).timeout.connect(func() -> void:
		if state != null and is_inside_tree():
			state.resolve_roubo(pi, uid))
	# (1.49.77) 0,5 s depois: a carta ROUBADA sai da mão do alvo (verso) e voa
	# 1,5 s até a mão de quem usou ROUBAR — só então o roubo efetiva.
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self) or state == null:
		return
	var card: Dictionary = {}
	for c in state.players[foe]["hand"]:
		if int(c["uid"]) == uid:
			card = c
	if card.is_empty():
		state.resolve_roubo(pi, uid)
		return
	var hv: CardView = hand_views[foe].get(int(uid))
	var from: Vector2 = hv.global_position if (hv != null and is_instance_valid(hv)) else Vector2(FIELD_CX, ai_hand_y if foe == 1 else hand_y)
	if hv != null and is_instance_valid(hv):
		hand_views[foe].erase(int(uid))
		hv.queue_free()
	var fly := CardView.new()
	fly.setup(card, true)   # verso da carta
	fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fly.z_index = 200
	fly.position = from
	hand_layer.add_child(fly)
	var to := Vector2(FIELD_CX - 55, hand_y if pi == 0 else ai_hand_y)
	await _fly_card(fly, to, 1.5, 50.0)
	if is_instance_valid(fly):
		fly.queue_free()
	if state != null:
		state.resolve_roubo(pi, uid)


func _on_fx_fortalecer(_pi: int, src: int, target_uid: int) -> void:
	Sfx.play("fortalecer", 640.0, 0.9)
	# (1.49.70) VFX de Fortalecer: 2 s de aura verde ascendente; o +1 de Poder
	# só é aplicado NO FIM da animação (resolve_fortalecer).
	var v: ChampionView = champ_views.get(target_uid)
	var at: Vector2 = (v.position + v.size / 2.0) if v != null and is_instance_valid(v) else Vector2(FIELD_CX, PL_ROW_CY)
	var fx := _spawn_fortalecer(at, target_uid)
	# (1.49.79) marca o fim da animação do Talento de origem (se for Talento)
	fx.finished.connect(func() -> void:
		_talent_anim_until[src] = Time.get_ticks_msec())


func _spawn_fortalecer(at: Vector2, target_uid: int = -1) -> FortalecerFX:
	# (1.49.73) base no chão (under_layer, abaixo das cartas) + luzes por cima
	var fx = load("res://scripts/vfx_fortalecer.gd").new()
	add_child(fx)
	fx.setup(at, under_layer, fx_layer)
	if target_uid >= 0:
		fx.finished.connect(func() -> void:
			if state != null:
				state.resolve_fortalecer(target_uid))
		# segurança: se o sinal não disparar, resolve após 3,5 s
		get_tree().create_timer(3.5).timeout.connect(func() -> void:
			if state != null and is_inside_tree():
				state.resolve_fortalecer(target_uid))
	return fx


func _spawn_fireball(src: Vector2, dst: Vector2, target_uid: int = -1) -> FireballFX:
	var fx := FireballFX.new()
	fx_layer.add_child(fx)
	fx.setup(src, dst, 1.5, 140.0)   # voo de 1,5 s (mínimo do jogo)
	# (1.49.63) SEM tremor de tela na explosão. O dano/destruição do alvo só
	# é aplicado NO IMPACTO (resolve_bola), nunca antes ou durante o voo.
	if target_uid >= 0:
		fx.exploded.connect(func(_at: Vector2) -> void:
			if state != null:
				state.resolve_bola(target_uid))
		# segurança: se a explosão não disparar por qualquer motivo,
		# resolve o dano pendente após 4 s
		get_tree().create_timer(4.0).timeout.connect(func() -> void:
			if state != null and is_inside_tree():
				state.resolve_bola(target_uid))
	return fx


func _demo_fireball() -> void:
	# F9: a Bola de Fogo sai DA CARTA (campeão ou mão), nunca de fora da tela
	var src: Vector2 = Vector2.ZERO
	var f0: Array = state.players[0]["field"]
	if not f0.is_empty() and champ_views.has(int(f0[0]["uid"])):
		var sv: ChampionView = champ_views[int(f0[0]["uid"])]
		src = sv.global_position + sv.size / 2.0
	elif not hand_views[0].is_empty():
		var hv: CardView = hand_views[0].values()[0]
		src = hv.global_position + hv.size / 2.0
	else:
		src = (hero_meds[0]["medal"] as Control).global_position + Vector2(32, 32)
	var dst := Vector2(FIELD_CX, AI_ROW_CY)
	var foes: Array = state.players[1]["field"]
	if not foes.is_empty():
		var fv: ChampionView = champ_views.get(int(foes[0]["uid"]))
		if fv != null:
			dst = fv.global_position + fv.size / 2.0
	_spawn_fireball(src, dst)


# ----------------------------------------------------------------------------
# MIRA (escolha de alvo da BOLA DE FOGO): alvos ficam AVERMELHADOS com leve zoom
# ----------------------------------------------------------------------------

func _on_targeting_started(pi: int, effect: String, _src: int, candidates: Array) -> void:
	# (1.49.70) FORTALECER destaca os ALIADOS em verde; BOLA DE FOGO mantém os
	# inimigos avermelhados.
	var ally: bool = effect == "fortalecer" or effect == "fortalecerTalento" or effect == "corromper" or effect == "corromperTalento"
	var frost: bool = effect == "rajadaCongelante" or effect == "zeroAbsoluto"
	var ven: bool = effect == "mordidaVenenosa" or effect == "baforadaVenenosa"
	for uid in candidates:
		var v: ChampionView = champ_views.get(int(uid))
		if v != null and is_instance_valid(v):
			if frost:
				v.set_frost_pulse(true)
			elif ven:
				v.set_poison_pulse(true)
			elif ally:
				v.set_ally_pulse(true)
			else:
				v.set_target_pulse(true)
	_refresh_buttons()
	if pi == 1:
		_ai_target_think()


func _ai_target_think() -> void:
	# a IA "pensa" por 1,6 s com os alvos destacados e então escolhe
	await get_tree().create_timer(1.6).timeout
	if state == null or not is_instance_valid(self):
		return
	if not state.targeting.is_empty() and int(state.targeting["pi"]) == 1:
		var uid := state.auto_pick_uid()
		if uid >= 0:
			state.confirm_targeting(uid)


func _on_targeting_ended(_pi: int) -> void:
	for v in champ_views.values():
		if is_instance_valid(v):
			v.set_target_pulse(false)
			v.set_ally_pulse(false)
			v.set_frost_pulse(false)
			v.set_poison_pulse(false)
	_refresh_buttons()


# ----------------------------------------------------------------------------
# Ataque por ARRASTO do campeão (combate com choque e impacto)
# ----------------------------------------------------------------------------

func _on_champ_clicked(view: ChampionView) -> void:
	if drag_view != null or drag_champ != null:
		return
	# mira ativa: tocar num Campeão DESTACADO confirma o alvo (inimigo
	# vermelho na Bola de Fogo, aliado verde no Fortalecer — 1.49.70)
	if state != null and not state.targeting.is_empty() and int(state.targeting["pi"]) == 0:
		if (state.targeting["candidates"] as Array).has(int(view.card["uid"])):
			state.confirm_targeting(int(view.card["uid"]))
			return
	_open_zoom(view.card)


func _on_champ_drag_started(view: ChampionView) -> void:
	if input_locked or state.current != 0 or state.winner != -1 or drag_view != null or drag_champ != null or zoom_overlay != null or not state.targeting.is_empty():
		view.abort_drag()
		return
	if view.owner_pi != 0:
		view.abort_drag()
		_spawn_toast("Arraste um campeão SEU para atacar.")
		return
	var c: Dictionary = view.card
	if c.get("tapped", false):
		view.abort_drag()
		_spawn_toast("%s já atacou neste turno." % c["name"])
		return
	if int(c.get("frozen_turns", 0)) > 0:
		view.abort_drag()
		_spawn_toast("%s está congelado." % c["name"])
		return
	if int(c.get("charm_turns", 0)) > 0:
		view.abort_drag()
		_spawn_toast("%s está enfeitiçado e não ataca." % c["name"])
		return
	drag_champ = view


func _on_champ_drag_ended(view: ChampionView) -> void:
	if _hover_target != null and is_instance_valid(_hover_target):
		_hover_target.set_target_glow(false)
	_hover_target = null
	if drag_champ != view:
		view.set_slot_target(view._slot_pos)
		return
	drag_champ = null
	var mouse := get_global_mouse_position()
	var drect := view.get_global_rect()
	var target: ChampionView = null
	for uid in champ_views.keys():
		var v: ChampionView = champ_views[uid]
		# basta soltar PARCIALMENTE em cima do campeão inimigo
		if v.owner_pi == 1 and not v.dying and v.get_global_rect().intersects(drect):
			target = v
			break
	if target == null:
		view.set_slot_target(view._slot_pos)
		return
	var ai_idx := state.idx_of_uid(0, int(view.card["uid"]))
	var di := state.idx_of_uid(1, int(target.card["uid"]))
	if ai_idx < 0 or di < 0:
		view.set_slot_target(view._slot_pos)
		return
	var chk := state.can_attack(0, ai_idx, di)
	if not chk["ok"]:
		_spawn_toast(chk["reason"])
		view.set_slot_target(view._slot_pos)
		return
	# a carta arrastada VOLTA ao seu lugar e DEPOIS o combate começa
	var rt := view.create_tween()
	rt.tween_property(view, "position", view._slot_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.parallel().tween_property(view, "rotation_degrees", 0.0, 0.2)
	await rt.finished
	_do_combat(0, ai_idx, di)


func _enemy_under(v: Control) -> ChampionView:
	var dr := v.get_global_rect()
	for uid in champ_views.keys():
		var cv: ChampionView = champ_views[uid]
		if cv.owner_pi == 1 and not cv.dying and cv.get_global_rect().intersects(dr):
			return cv
	return null


func _do_combat(att_p: int, ai_idx: int, di: int) -> void:
	## Combate estilo Hearthstone (~1,5s): os dois campeões SOBEM em arco
	## um de encontro ao outro, colidem no ponto médio com impacto (anel,
	## faíscas, clarão e tremor), o destruído explode e os sobreviventes
	## retornam em arco aos seus lugares.
	var def_p := 1 - att_p
	var a_uid := int(state.players[att_p]["field"][ai_idx]["uid"])
	var d_uid := int(state.players[def_p]["field"][di]["uid"])
	var av: ChampionView = champ_views.get(a_uid)
	var dv: ChampionView = champ_views.get(d_uid)
	input_locked = true
	_refresh_buttons()
	if av == null or dv == null:
		state.attack(att_p, ai_idx, di)
		if state.winner == -1:
			input_locked = (state.current == 1)
		_refresh_buttons()
		return
	av.z_index = 60  # combatentes sempre ACIMA das demais cartas do campo
	dv.z_index = 60
	var a_from := av.position
	var d_from := dv.position
	var a_c: Vector2 = av.global_position + av.size / 2.0
	var d_c: Vector2 = dv.global_position + dv.size / 2.0
	var mid: Vector2 = (a_c + d_c) / 2.0
	var dirv: Vector2 = (d_c - a_c).normalized()
	# param "borda com borda" no ponto médio: NENHUMA carta fica sobre a outra
	var a_tgt: Vector2 = (mid - dirv * (CHAMP_W * av.layout_scale * 0.51)) - av.size / 2.0
	var d_tgt: Vector2 = (mid + dirv * (CHAMP_W * dv.layout_scale * 0.51)) - dv.size / 2.0
	# investida em arco (0,6s) com leve "salto do chão"; total 1,5s
	var ta := _tween_arc(av, a_tgt, 0.6, 34.0)
	ta.parallel().tween_property(av, "scale", Vector2(av.layout_scale * 1.14, av.layout_scale * 1.14), 0.3)
	var td := _tween_arc(dv, d_tgt, 0.6, 18.0)
	td.parallel().tween_property(dv, "scale", Vector2(dv.layout_scale * 1.1, dv.layout_scale * 1.1), 0.3)
	await ta.finished
	_fx_impact(mid)
	await get_tree().create_timer(0.15).timeout
	state.attack(att_p, ai_idx, di)
	await get_tree().create_timer(0.15).timeout
	# sobreviventes voltam em arco (0,5s); destruídos já explodiram
	var tb: Tween = null
	if is_instance_valid(av) and not av.dying:
		av.z_index = 0
		tb = _tween_arc(av, av._slot_pos, 0.6, 22.0)
		tb.parallel().tween_property(av, "scale", Vector2(av.layout_scale, av.layout_scale), 0.6)
	if is_instance_valid(dv) and not dv.dying:
		dv.z_index = 0
		var td2 := _tween_arc(dv, dv._slot_pos, 0.6, 14.0)
		td2.parallel().tween_property(dv, "scale", Vector2(dv.layout_scale, dv.layout_scale), 0.6)
	if tb != null:
		await tb.finished
	else:
		await get_tree().create_timer(0.6).timeout
	# (1.49.80) SEM HONRA em combate: o campeão voltou ao campo primeiro; a
	# morte especial começa 0,5 s depois do fim da animação de combate.
	for u in [a_uid, d_uid]:
		if _pending_desonra.has(u):
			get_tree().create_timer(0.5).timeout.connect(func() -> void:
				if is_instance_valid(self):
					_finish_desonra(u))
	if state.winner == -1:
		input_locked = (state.current == 1)
	_refresh_buttons()


# ----------------------------------------------------------------------------
# Voo de cartas (invocação) e movimento em arco
# ----------------------------------------------------------------------------

func _kill_flight(view: Control) -> void:
	if view == null or not is_instance_valid(view):
		return
	if view.has_meta("ftw"):
		var tw = view.get_meta("ftw")
		if tw != null and (tw as Tween).is_valid():
			(tw as Tween).kill()
		view.remove_meta("ftw")
	if view is CardView:
		(view as CardView).in_flight = false


func _fly_card(view: Control, to_pos: Vector2, dur: float, arc_h: float) -> void:
	## Voo EXTREMAMENTE fluido: bezier quadrático com easing seno e leve
	## inclinação. (1.49.65) SEM rastro de partículas acompanhando a carta.
	var p0 := view.position
	var p2 := to_pos
	var p1 := (p0 + p2) / 2.0 + Vector2(0, -arc_h)
	var tw := create_tween()
	view.set_meta("ftw", tw)
	tw.tween_method(_fly_set.bind(view, p0, p1, p2), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if is_instance_valid(view) and view.has_meta("ftw"):
		view.remove_meta("ftw")
	if is_instance_valid(view):
		view.position = p2
		view.rotation_degrees = (view as CardView)._base_rotation if view is CardView else 0.0


func _fly_set(t: float, view: Control, p0: Vector2, p1: Vector2, p2: Vector2) -> void:
	if not is_instance_valid(view):
		return
	var u := 1.0 - t
	var br: float = (view as CardView)._base_rotation if view is CardView else 0.0
	view.position = u * u * p0 + 2.0 * u * t * p1 + t * t * p2
	view.rotation_degrees = br + sin(t * PI) * 5.0
	# (1.49.63) SEM pulso de tamanho no voo: a carta mantém o tamanho do
	# início ao fim (nada de diminuir/crescer durante a invocação).
	view.scale = Vector2.ONE


func _tween_arc(view: Control, to: Vector2, dur: float, arc_h: float) -> Tween:
	var from := view.position
	var cb := func(t: float) -> void:
		if is_instance_valid(view):
			view.position = from.lerp(to, t) + Vector2(0, -sin(t * PI) * arc_h)
	var tw := view.create_tween()
	tw.tween_method(cb, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw


func _fx_impact_summon(at: Vector2) -> void:
	# (1.49.63) IMPACTO PESADO da invocação: como se a carta fosse muito,
	# muito pesada e tivesse caído no chão (referência Hearthstone) —
	# clarão, onda de choque dupla, nuvem de poeira e faíscas.
	# SEM tremor de tela e SEM alterar o tamanho da carta.
	_fx_flash(Color(1, 0.9, 0.6, 0.14), 0.3)
	_fx_ring(at, Color(0.92, 0.82, 0.66, 0.95), 26, 150, 0.5)   # onda de poeira
	_fx_ring(at, Color(1, 1, 1, 0.75), 12, 76, 0.45)             # onda de choque
	_fx_dust(at, 12)
	_fx_sparks(at, Color(1, 0.8, 0.35), 9)


func _fx_dust(at: Vector2, n: int) -> void:
	# nuvem de poeira levantada pelo impacto pesado: fragmentos marrons/
	# acinzentados voando para fora e desvanecendo (partículas de chão).
	if fx_layer == null:
		return
	for i in n:
		var s := ColorRect.new()
		s.color = Color(0.74, 0.66, 0.56, randf_range(0.55, 0.85))
		s.size = Vector2(randf_range(5, 9), randf_range(4, 7))
		s.position = at + Vector2(randf_range(-16, 16), randf_range(-8, 12))
		s.pivot_offset = s.size / 2.0
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(s)
		var ang := randf() * TAU
		var dist := randf_range(28, 64)
		var life := randf_range(0.42, 0.62)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", s.position + Vector2(cos(ang), sin(ang) * 0.6) * dist, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "size", s.size * 1.9, life)
		tw.tween_property(s, "modulate:a", 0.0, life)
		tw.chain().tween_callback(s.queue_free)


# ----------------------------------------------------------------------------
# Efeitos visuais (FX)
# ----------------------------------------------------------------------------

func _fx_ring(at: Vector2, col: Color, start_sz: float, end_sz: float, dur: float) -> void:
	if fx_layer == null:
		return
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(64)
	p.add_theme_stylebox_override("panel", sb)
	p.size = Vector2(start_sz, start_sz)
	p.position = at - p.size / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(p)
	var tw := p.create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "size", Vector2(end_sz, end_sz), dur)
	tw.tween_property(p, "position", at - Vector2(end_sz, end_sz) / 2.0, dur)
	tw.tween_property(p, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(p.queue_free)


func _fx_sparks(at: Vector2, col: Color, n: int) -> void:
	if fx_layer == null:
		return
	for i in n:
		var s := ColorRect.new()
		s.color = col
		s.size = Vector2(5, 5)
		s.position = at
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(s)
		var ang := randf() * TAU
		var dist := randf_range(28, 64)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", at + Vector2(cos(ang), sin(ang)) * dist, randf_range(1.2, 1.5))
		tw.tween_property(s, "modulate:a", 0.0, 1.5)
		tw.chain().tween_callback(s.queue_free)


func _fx_smoke(at: Vector2) -> void:
	if fx_layer == null:
		return
	for i in 3:
		var p := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.35, 0.3, 0.4, 0.5)
		sb.set_corner_radius_all(24)
		p.add_theme_stylebox_override("panel", sb)
		p.size = Vector2(26, 26)
		p.position = at + Vector2(randf_range(-14, 14), randf_range(-10, 10))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(p)
		var from := p.position
		var tw := p.create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "size", Vector2(64, 64), 0.55)
		tw.tween_property(p, "position", from - Vector2(19, 26), 0.55)
		tw.tween_property(p, "modulate:a", 0.0, 0.55)
		tw.chain().tween_callback(p.queue_free)


func _fx_shards(at: Vector2, col: Color) -> void:
	if fx_layer == null:
		return
	for i in 8:
		var s := ColorRect.new()
		s.color = col
		s.size = Vector2(randf_range(8, 14), randf_range(10, 18))
		s.position = at
		s.pivot_offset = s.size / 2.0
		s.rotation = randf() * TAU
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_layer.add_child(s)
		var ang := TAU * float(i) / 8.0 + randf_range(-0.3, 0.3)
		var dist := randf_range(40, 85)
		var tw := s.create_tween()
		tw.set_parallel(true)
		tw.tween_property(s, "position", at + Vector2(cos(ang), sin(ang)) * dist, randf_range(1.2, 1.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "rotation", s.rotation + randf_range(-3.0, 3.0), 1.5)
		tw.tween_property(s, "modulate:a", 0.0, 1.5)
		tw.chain().tween_callback(s.queue_free)


func _fx_flash(col: Color, dur: float) -> void:
	if fx_layer == null:
		return
	var r := ColorRect.new()
	r.color = col
	r.position = Vector2.ZERO
	r.size = Vector2(1280, 720)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, dur)
	tw.tween_callback(r.queue_free)


func _fx_clarao_local(at: Vector2, radius: float, col: Color, dur: float) -> void:
	# (1.49.64) Clarão SOMENTE no ponto de impacto (gradiente radial que
	# esmaece) — substitui o flash de tela cheia: a tela não pisca mais.
	if fx_layer == null:
		return
	var grad := Gradient.new()
	grad.colors = PackedColorArray([col, Color(col.r, col.g, col.b, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var tr := TextureRect.new()
	tr.texture = tex
	tr.size = Vector2(radius * 2.0, radius * 2.0)
	tr.position = at - tr.size / 2.0
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(tr)
	var tw := tr.create_tween()
	tw.tween_property(tr, "modulate:a", 0.0, dur)
	tw.tween_callback(tr.queue_free)


func _fx_impact(at: Vector2) -> void:
	# impacto do choque no combate: rápido (ritmo 1.49.60).
	# (1.49.63) SEM tremor de tela — a tela não treme em nenhum momento.
	# (1.49.64) clarão LOCAL no ponto do choque — a TELA NÃO PISCA mais.
	_fx_clarao_local(at, 110.0, Color(1, 0.9, 0.6, 0.5), 0.3)
	_fx_ring(at, Color(1, 0.85, 0.4, 0.9), 20, 110, 0.5)
	_fx_ring(at, Color(1, 1, 1, 0.8), 10, 70, 0.5)
	_fx_sparks(at, Color(1, 0.8, 0.35), 10)


# ----------------------------------------------------------------------------
# Turno da IA
# ----------------------------------------------------------------------------

func _run_ai_turn() -> void:
	ai_running = true
	input_locked = true
	_refresh_buttons()
	await get_tree().create_timer(ai_step_delay).timeout
	var fails := 0
	while state.winner == -1 and state.current == 1:
		var act: Dictionary = AIBrain.next_action(state)
		var ok := false
		match String(act["type"]):
			"summon", "talent":
				ok = state.play_card(1, int(act["hand_idx"]))
			"attack":
				await _do_combat(1, int(act["att_idx"]), int(act["def_idx"]))
				ok = true
			"draw":
				ok = state.manual_draw(1)
			"ultimate":
				ok = state.use_ultimate(1)
			"end_turn":
				break
		if ok:
			fails = 0
			match String(act["type"]):
				"summon", "talent":
					await get_tree().create_timer(2.0).timeout  # animação de invocação
				"ultimate":
					await get_tree().create_timer(0.4).timeout
		else:
			fails += 1
			if fails >= 2:
				break
		await get_tree().create_timer(ai_step_delay).timeout
	if state.winner == -1 and state.current == 1:
		state.end_turn()
	ai_running = false
	if state.winner == -1:
		input_locked = false
	_refresh_buttons()


# ----------------------------------------------------------------------------
# Slots / offsets (editor de layout)
# ----------------------------------------------------------------------------

func _field_offset() -> Vector2:
	return grp_field.position if grp_field != null else Vector2.ZERO


func _slot_for(pi: int, idx: int, n: int) -> Vector2:
	## Posição do slot idx de uma linha com n campeões (regra de espaço + centro).
	var gap := 10.0
	var avail_w: float = FIELD_W - 24.0
	var avail_h: float = (BANNER_Y - FIELD_Y) - 18.0
	var base_total: float = n * CHAMP_W + (n - 1) * gap
	var sc: float = minf(1.0, minf(avail_w / base_total, avail_h / CHAMP_H))
	var eff_w: float = CHAMP_W * sc
	var gap_e: float = gap * sc
	var total: float = n * eff_w + (n - 1) * gap_e
	var x0: float = FIELD_CX - total / 2.0
	var cx: float = x0 + idx * (eff_w + gap_e) + eff_w / 2.0
	var cy: float = AI_ROW_CY if pi == 1 else PL_ROW_CY
	return Vector2(cx - CHAMP_W / 2.0, cy - CHAMP_H / 2.0) + _field_offset()


func _drop_rect() -> Rect2:
	return Rect2(DROP_RECT.position + _field_offset(), DROP_RECT.size)


func _reparent(n: Control, new_parent: Control) -> void:
	var pp: Vector2 = n.position
	remove_child(n)
	new_parent.add_child(n)
	n.position = pp


# ----------------------------------------------------------------------------
# EDITOR DE LAYOUT — arraste os grupos destacados e salve
# ----------------------------------------------------------------------------

func _on_editor_changed(id: String) -> void:
	match id:
		"field":
			_layout_field(0)
			_layout_field(1)
		"hand_p":
			_layout_hand(0)
		"hand_ai":
			_layout_hand(1)


func _on_editor_toggled(a: bool) -> void:
	if a:
		input_locked = true
	else:
		if state != null and state.winner == -1:
			input_locked = (state.current == 1)
	_refresh_buttons()
