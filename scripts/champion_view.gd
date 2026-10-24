class_name ChampionView
extends Control
## Campeão no campo: mesma textura bakeada da carta (cópia exata), com
## PODER ATUAL e STATUS ao vivo por cima (valores dinâmicos da partida).

signal champ_clicked(view)
signal champ_drag_started(view)
signal champ_drag_ended(view)

const CHAMP_W := 100.0
const CHAMP_H := 140.0   # proporção 5:7

var card: Dictionary = {}
var owner_pi: int = 0
## (1.49.73) Muralha mágica (habilidade constante MURALHA / wall_buff).
const WALL_TEX := preload("res://assets/VFX_MURO_PEDRA.png")
var _wall: TextureRect
var _wall_on := false
var _wall_pulse: Tween
var _wall_pulse2: Tween
## (1.49.91/92) STATUS EM CAMPO = ÍCONES PEQUENOS no CANTO SUPERIOR DIREITO da
## carta (PROTEÇÃO, SEM HONRA, ENVENENADO, FÚRIA e CONGELADO), empilhados de
## CIMA para BAIXO na ORDEM DE AQUISIÇÃO (o 1º status adquirido fica no topo).
## As animações persistentes antigas (redoma, caveira, bolhas, aura e cristal
## de gelo) saíram do jogo; os detalhes de cada status continuam no zoom da
## carta (§6 do manual).
const STATUS_ICON_SZ := 18.0
const STATUS_ICON_BG := 24.0
const STATUS_ICON_STEP := 26.0
const STATUS_ICON_TEX := {
	"prot": preload("res://assets/ICO_PROTECAO.svg"),
	"semhonra": preload("res://assets/ICO_CAVEIRA.svg"),
	"veneno": preload("res://assets/ICO_VENENO.svg"),
	"furia": preload("res://assets/ICO_FURIA.svg"),
	"cong": preload("res://assets/ICO_CONGELADO.svg"),
}
var _status_icons: Dictionary = {}     # chave -> {"ico": TextureRect, "bg": TextureRect}
var _status_order: Array[String] = []  # ordem de aquisição (índice 0 = topo)
static var _icon_bg_tex: ImageTexture
## (1.49.77) BARREIRA: painel de energia semitransparente (topo da carta para
## o jogador principal; base, apontando p/ o campo do jogador, para a IA).
const BAR_TEX := preload("res://assets/VFX_BARREIRA_MAGICA.png")
var _barrier: TextureRect
var _barrier_on := false
var _barrier_pulse: Tween
## (1.49.82) status CANSADO (tapped): zzz saindo da carta.
var _sleep_on := false
var dying := false
var dragging := false
## (1.49.64) TRUE durante a janela de pouso (queda + baque): nessa janela a
## carta NAO recebe tween de posicao externo — o reajuste da linha espera o
## baque assentar (regra do manual) e nenhum deslizamento cancela o impacto.
var landing := false
var _pressed := false
var _press_global := Vector2.ZERO
var _drag_offset := Vector2.ZERO
var layout_scale := 1.0
var _slot_pos := Vector2.ZERO
var _slot_tw: Tween
var _zoom_tw: Tween
var _baked_power := -1

var _hl: Panel
var _face: TextureRect
var _status_label: Label
var _baker_conn := false
var _frozen_rect: ColorRect
var _target_rect: ColorRect


func _init() -> void:
	custom_minimum_size = Vector2(CHAMP_W, CHAMP_H)
	size = Vector2(CHAMP_W, CHAMP_H)
	pivot_offset = size / 2.0
	# (1.49.83) SEM clip: muros/zzz/status precisam sair dos limites da carta
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(card_data: Dictionary, pidx: int) -> void:
	card = card_data
	owner_pi = pidx
	_build()
	refresh()
	tooltip_text = ""  # sem caixa de texto ao passar o mouse


func _build() -> void:
	for c in get_children():
		c.queue_free()
	# (1.49.91) ícones de status são filhos dinâmicos: reset na reconstrução
	_status_icons.clear()
	_status_order.clear()
	var w: float = CHAMP_W
	var h: float = CHAMP_H
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.position = Vector2.ZERO
	_face.size = Vector2(w, h)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_apply_face()
	_hl = Panel.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0, 0, 0, 0)
	# (1.49.64) SEM linha de borda permanente no campeao (a borda so aparece
	# em destaques temporarios: alvo do arrasto, mira e escudo).
	hsb.set_border_width_all(0)
	hsb.set_corner_radius_all(8)
	_hl.add_theme_stylebox_override("panel", hsb)
	_hl.position = Vector2.ZERO
	_hl.size = Vector2(w, h)
	_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hl)
	_target_rect = ColorRect.new()
	_target_rect.color = Color(1.0, 0.14, 0.1, 0.3)
	_target_rect.position = Vector2.ZERO
	_target_rect.size = Vector2(w, h)
	_target_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_rect.visible = false
	add_child(_target_rect)
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 5)
	if CardArt.baloo(700) != null:
		_status_label.add_theme_font_override("font", CardArt.baloo(700))
	_status_label.add_theme_color_override("font_color", Color(0.62, 0.42, 0.02))
	_status_label.clip_text = true
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sz: Rect2 = CardArt.Z_STATUS
	_status_label.position = Vector2(sz.position.x * w, sz.position.y * h)
	_status_label.size = Vector2(sz.size.x * w, sz.size.y * h)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_label)
	_frozen_rect = ColorRect.new()
	_frozen_rect.color = Color(0.45, 0.75, 1.0, 0.22)
	_frozen_rect.position = Vector2.ZERO
	_frozen_rect.size = Vector2(w, h)
	_frozen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frozen_rect.visible = false
	add_child(_frozen_rect)
	# (1.49.73) MURALHA: muro mágico horizontal na PARTE DE CIMA da carta
	# (dentro dela, nunca encosta no campo adversário), vista de cima.
	_wall = TextureRect.new()
	_wall.texture = WALL_TEX
	_wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wall.stretch_mode = TextureRect.STRETCH_SCALE
	# (1.49.81) MURALHA = MURO DE PEDRA detalhado (estilo Hearthstone):
	# grosso, na borda da carta — TOPO para o jogador principal, BASE
	# (invertido, apontando p/ o campo do jogador) para a IA.
	var ww: float = w + 12
	var wh: float = 44.0
	_wall.size = Vector2(ww, wh)
	if owner_pi == 0:
		_wall.position = Vector2(-6.0, -34.0)
		_wall.flip_v = false
	else:
		_wall.position = Vector2(-6.0, h - 10.0)
		_wall.flip_v = true
	_wall.pivot_offset = Vector2(ww / 2.0, wh)
	_wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wall.visible = false
	add_child(_wall)
	# (1.49.77) painel da BARREIRA: semitransparente, curvado, bem visível
	_barrier = TextureRect.new()
	_barrier.texture = BAR_TEX
	_barrier.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_barrier.stretch_mode = TextureRect.STRETCH_SCALE
	_barrier.size = Vector2(w + 8, 52)
	if owner_pi == 0:
		_barrier.position = Vector2(-4, -14)
	else:
		# IA: na parte de BAIXO da carta, apontada p/ o campo do jogador
		_barrier.flip_v = true
		_barrier.position = Vector2(-4, h - 38)
	_barrier.pivot_offset = _barrier.size / 2.0
	# (1.49.79) blend NORMAL (folha semitransparente como na referência):
	# muito mais visível sobre a carta do que blend aditivo
	_barrier.modulate = Color(1, 1, 1, 0)
	_barrier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barrier.visible = false
	add_child(_barrier)


func _apply_face() -> void:
	var pw: int = int(card.get("current_power", 0))
	var t: ImageTexture = Baker.request(card, pw)
	if t != null:
		_face.texture = t
	elif _face.texture == null:
		var fr: Texture2D = CardArt.frame("champion")
		if fr != null:
			_face.texture = fr
	if not _baker_conn:
		_baker_conn = true
		Baker.baked.connect(_on_baked)


func _on_baked(k: String) -> void:
	if k == Baker.key_of(card, int(card.get("current_power", 0))):
		var t: ImageTexture = Baker.cached(card, int(card.get("current_power", 0)))
		if t != null:
			_face.texture = t


func _exit_tree() -> void:
	if _baker_conn:
		Baker.baked.disconnect(_on_baked)
		_baker_conn = false


func refresh() -> void:
	if card.is_empty() or _face == null:
		return
	var pw: int = int(card.get("current_power", 0))
	if pw != _baked_power:
		_baked_power = pw
		_apply_face()
	var chips: Array[String] = []
	# (1.49.66) Sem textos amarelos "PROTEGIDO"/"VULNERAVEL" na carta: a
	# Proteção é comunicada pela redoma + ícone no zoom (regra do dono).
	if int(card.get("barrier_turns", 0)) != 0:
		chips.append("BARREIRA")
	if int(card.get("poison_turns", 0)) > 0:
		chips.append("ENVENENADO(%d)" % int(card["poison_turns"]))
	if int(card.get("burn_turns", 0)) > 0:
		chips.append("CHAMAS(%d)" % int(card["burn_turns"]))
	if int(card.get("fury_stacks", 0)) > 0:
		chips.append("FURIA+%d" % int(card["fury_stacks"]))
	if card.get("prision", false):
		chips.append("PRESO")
	if card.get("silenced", false):
		chips.append("SILENCIADO")
	if int(card.get("charm_turns", 0)) > 0:
		chips.append("ENFEITICADO")
	var stx: String = " ".join(chips)
	_status_label.text = stx.substr(0, 34) + ("…" if stx.length() > 34 else "")
	_frozen_rect.visible = int(card.get("frozen_turns", 0)) > 0
	_update_status_vfx()
	if _hl != null:
		var bsb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
		# (1.49.67) Proteção NÃO desenha mais borda/linha amarela na carta: o
		# status é comunicado só pela barreira circular + ícone no zoom.
		if bsb.shadow_size == 0:
			bsb.set_border_width_all(0)
	# (1.49.92) CONGELADO NÃO tem mais cristal de gelo sobre a carta: resta a
	# tinta azulada (abaixo) + o ícone no canto superior direito (§4.14/4.15).
	var frozen: bool = int(card.get("frozen_turns", 0)) > 0
	if card.get("tapped", false) and not dying:
		modulate = Color(0.5, 0.6, 0.75) if frozen else Color(0.62, 0.62, 0.7)
		_sleep_start()
	elif frozen:
		modulate = Color(0.72, 0.86, 1.05)
	elif modulate == Color(0.62, 0.62, 0.7) or modulate == Color(0.72, 0.72, 0.78) or modulate == Color(0.5, 0.6, 0.75) or modulate == Color(0.72, 0.86, 1.05):
		modulate = Color.WHITE
		_sleep_stop()
	# (1.49.91) status em campo = SOMENTE ícones no canto superior direito,
	# empilhados na ordem de aquisição (regras 2–6 da 1.49.91).
	_refresh_status_icons()
	# (1.49.77) BARREIRA: painel de energia enquanto barrier_turns != 0
	var bar_on: bool = int(card.get("barrier_turns", 0)) != 0
	if bar_on and not _barrier_on:
		_barrier_on = true
		_barrier_show()
	elif not bar_on and _barrier_on:
		_barrier_on = false
		_barrier_hide()
	# (1.49.73/81) MURALHA: muro de pedra sobe do chão enquanto wall_buff > 0
	var wall_on: bool = int(card.get("wall_buff", 0)) > 0
	if wall_on and not _wall_on:
		_wall_on = true
		_wall_show()
	elif not wall_on and _wall_on:
		_wall_on = false
		_wall_hide()


func _barrier_show() -> void:
	if _barrier == null or not is_instance_valid(_barrier) or _barrier.visible:
		return
	_barrier.visible = true
	_barrier.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_barrier, "modulate:a", 1.0, 0.3)
	if _barrier_pulse != null and _barrier_pulse.is_valid():
		_barrier_pulse.kill()
	_barrier_pulse = create_tween()
	_barrier_pulse.set_loops()
	_barrier_pulse.tween_property(_barrier, "modulate:a", 0.8, 0.7).set_trans(Tween.TRANS_SINE)
	_barrier_pulse.tween_property(_barrier, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _barrier_hide() -> void:
	if _barrier_pulse != null and _barrier_pulse.is_valid():
		_barrier_pulse.kill()
		_barrier_pulse = null
	if _barrier == null or not is_instance_valid(_barrier) or not _barrier.visible:
		return
	var tw := create_tween()
	tw.tween_property(_barrier, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_barrier):
			_barrier.visible = false
			_barrier.modulate = Color(1, 1, 1, 0)
	)


func _sleep_start() -> void:
	# (1.49.82) campeões CANSADOS dormem: "z z z" saindo de cima da carta
	if _sleep_on or dying:
		return
	_sleep_on = true
	_sleep_loop()


func _sleep_loop() -> void:
	while _sleep_on and is_instance_valid(self) and not dying:
		var z := Label.new()
		z.text = "z"
		if CardArt.baloo(700) != null:
			z.add_theme_font_override("font", CardArt.baloo(700))
		# (1.49.84) zzz MAIS GROSSOS e saindo da JANELA DE ARTE (área vazia)
		z.add_theme_font_size_override("font_size", int(randf_range(18.0, 30.0)))
		z.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0, 0.95))
		z.add_theme_color_override("font_outline_color", Color(0.1, 0.16, 0.4, 0.95))
		z.add_theme_constant_override("outline_size", 5)
		z.mouse_filter = Control.MOUSE_FILTER_IGNORE
		z.position = Vector2(randf_range(CHAMP_W / 2.0 - 16.0, CHAMP_W / 2.0 + 16.0), CardArt.Z_ART.position.y * CHAMP_H + 14.0)
		z.scale = Vector2(0.6, 0.6)
		add_child(z)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(z, "position", z.position + Vector2(randf_range(10.0, 26.0), -randf_range(34.0, 54.0)), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(z, "scale", Vector2(1.1, 1.1), 1.5)
		tw.tween_property(z, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(z.queue_free)
		await get_tree().create_timer(randf_range(0.55, 0.85)).timeout


func _sleep_stop() -> void:
	_sleep_on = false


func set_frost_pulse(on: bool) -> void:
	## (1.49.87) destaque de MIRA de CONGELAR: azulado, leve zoom, sem piscar
	if _hl == null or dying:
		return
	var bsb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
	if on:
		bsb.set_border_width_all(2)
		bsb.border_color = Color(0.35, 0.78, 1.0)
		bsb.shadow_size = 0
		if _target_rect != null:
			_target_rect.color = Color(0.3, 0.7, 1.0, 0.28)
			_target_rect.visible = true
		if _zoom_tw == null or not _zoom_tw.is_valid():
			_zoom_tw = create_tween()
			_zoom_tw.set_loops()
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale * 1.06, layout_scale * 1.06), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _zoom_tw != null and _zoom_tw.is_valid():
			_zoom_tw.kill()
		_zoom_tw = null
		if _target_rect != null:
			_target_rect.visible = false
			_target_rect.color = Color(1.0, 0.14, 0.1, 0.3)
		bsb.shadow_size = 0
		refresh()
		if not dying:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.15)


func _wall_show() -> void:
	# (1.49.81) o muro de pedra SOBE DO CHÃO com poeira na base
	if _wall == null or not is_instance_valid(_wall) or _wall.visible:
		return
	_wall.visible = true
	_wall.modulate = Color.WHITE
	_wall.scale = Vector2(1.0, 0.08)
	var tw := create_tween()
	tw.tween_property(_wall, "scale", Vector2(1.0, 1.06), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_wall, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
	# poeira subindo nas laterais da base
	for i in 6:
		var d := Sprite2D.new()
		d.texture = Vfx.radial("wall_dust", 32, Color(0.72, 0.66, 0.55, 0.55), 0.0)
		d.material = Vfx.add_mat()
		d.scale = Vector2(0.5, 0.5)
		d.position = Vector2(randf_range(-50.0, 50.0), _wall.position.y + _wall.size.y - 4.0)
		add_child(d)
		var td := create_tween()
		td.set_parallel(true)
		td.tween_property(d, "position:y", d.position.y - randf_range(10.0, 22.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		td.tween_property(d, "modulate:a", 0.0, 0.6)
		td.tween_property(d, "scale", Vector2(1.0, 1.0), 0.6)
		td.chain().tween_callback(d.queue_free)


func _wall_hide() -> void:
	# (1.49.81) o muro SE DESTRÓI: estilhaços de pedra + poeira + afundamento
	if _wall_pulse != null and _wall_pulse.is_valid():
		_wall_pulse.kill()
		_wall_pulse = null
	if _wall_pulse2 != null and _wall_pulse2.is_valid():
		_wall_pulse2.kill()
		_wall_pulse2 = null
	if _wall == null or not is_instance_valid(_wall) or not _wall.visible:
		return
	var base_y: float = _wall.position.y + (_wall.size.y if owner_pi == 0 else 0.0)
	for i in 9:
		var sh := Sprite2D.new()
		sh.texture = Vfx.radial("wall_rock", 20, Color(0.55, 0.5, 0.44, 0.95), 0.25)
		sh.scale = Vector2(randf_range(0.35, 0.8), randf_range(0.35, 0.8))
		sh.rotation = randf_range(0, TAU)
		sh.position = Vector2(randf_range(-50.0, 50.0), base_y + randf_range(-6.0, 6.0))
		add_child(sh)
		var ts := create_tween()
		ts.set_parallel(true)
		ts.tween_property(sh, "position", sh.position + Vector2(randf_range(-40.0, 40.0), randf_range(18.0, 46.0)), randf_range(0.35, 0.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ts.tween_property(sh, "rotation", sh.rotation + randf_range(-3.0, 3.0), 0.5)
		ts.tween_property(sh, "modulate:a", 0.0, randf_range(0.45, 0.7))
		ts.chain().tween_callback(sh.queue_free)
	for i in 5:
		var d := Sprite2D.new()
		d.texture = Vfx.radial("wall_dust", 32, Color(0.72, 0.66, 0.55, 0.5), 0.0)
		d.material = Vfx.add_mat()
		d.scale = Vector2(0.6, 0.6)
		d.position = Vector2(randf_range(-45.0, 45.0), base_y)
		add_child(d)
		var td := create_tween()
		td.set_parallel(true)
		td.tween_property(d, "position:y", d.position.y - randf_range(12.0, 26.0), 0.55)
		td.tween_property(d, "modulate:a", 0.0, 0.7)
		td.chain().tween_callback(d.queue_free)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_wall, "scale", Vector2(1.0, 0.06), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_wall, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(_wall):
			_wall.visible = false
			_wall.modulate = Color.WHITE
			_wall.scale = Vector2.ONE
	)


func set_slot_target(pos: Vector2) -> void:
	_slot_pos = pos
	if dying:
		return
	if landing:
		return
	if _slot_tw != null and _slot_tw.is_valid():
		_slot_tw.kill()
	_slot_tw = create_tween()
	_slot_tw.set_parallel(true)
	# deslize sutil e ágil (~0,45 s) — ritmo da versão 1.49.60
	_slot_tw.tween_property(self, "position", pos, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _zoom_tw == null or not _zoom_tw.is_valid():
		_slot_tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func snap_to_slot() -> void:
	position = _slot_pos


func set_target_glow(on: bool) -> void:
	if _hl == null or dying:
		return
	var bsb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
	if on:
		bsb.set_border_width_all(2)
		bsb.border_color = Color(1.0, 0.25, 0.2)
		bsb.shadow_color = Color(1.0, 0.2, 0.15, 0.65)
		bsb.shadow_size = 14
	else:
		bsb.shadow_size = 0
		refresh()


func set_ally_pulse(on: bool) -> void:
	## (1.49.70) Destaque de MIRA ALIADA (ex.: FORTALECER): a carta fica com
	## cor VERDE constante e um LEVE efeito de zoom in/out — sem piscar.
	if _hl == null or dying:
		return
	var bsb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
	if on:
		bsb.set_border_width_all(2)
		bsb.border_color = Color(0.25, 1.0, 0.45)
		bsb.shadow_size = 0
		_hl.modulate = Color(1, 1, 1, 1)
		if _target_rect != null:
			_target_rect.color = Color(0.2, 1.0, 0.35, 0.28)
			_target_rect.visible = true
		if _zoom_tw == null or not _zoom_tw.is_valid():
			_zoom_tw = create_tween()
			_zoom_tw.set_loops()
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale * 1.06, layout_scale * 1.06), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _zoom_tw != null and _zoom_tw.is_valid():
			_zoom_tw.kill()
		_zoom_tw = null
		if _target_rect != null:
			_target_rect.visible = false
			_target_rect.color = Color(1.0, 0.14, 0.1, 0.3)
		bsb.shadow_size = 0
		refresh()
		if not dying:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.15)


func set_target_pulse(on: bool) -> void:
	## Destaque de MIRA (ex.: BOLA DE FOGO): a carta fica com cor AVERMELHADA
	## constante e um LEVE efeito de zoom in/out — sem piscar e sem brilho.
	if _hl == null or dying:
		return
	var bsb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
	if on:
		bsb.set_border_width_all(2)
		bsb.border_color = Color(1.0, 0.2, 0.15)
		bsb.shadow_size = 0
		_hl.modulate = Color(1, 1, 1, 1)
		if _target_rect != null:
			_target_rect.visible = true
		if _zoom_tw == null or not _zoom_tw.is_valid():
			_zoom_tw = create_tween()
			_zoom_tw.set_loops()
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale * 1.06, layout_scale * 1.06), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _zoom_tw != null and _zoom_tw.is_valid():
			_zoom_tw.kill()
		_zoom_tw = null
		if _target_rect != null:
			_target_rect.visible = false
		bsb.shadow_size = 0
		refresh()
		if not dying:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.15)


func play_summon_pop() -> void:
	# (1.49.63) SEM encolher/crescer na chegada: a carta já aparece no
	# tamanho final. O "peso" da aterrissagem vem do baque + poeira
	# (ver _land_summon/_fx_impact_summon na Tela de Combate).
	scale = Vector2(layout_scale, layout_scale)


func play_death() -> void:
	dying = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sleep_stop()
	hide_status_icons()
	if _wall != null and is_instance_valid(_wall):
		_wall.visible = false
	if _barrier != null and is_instance_valid(_barrier):
		_barrier.visible = false
	if _zoom_tw != null and _zoom_tw.is_valid():
		_zoom_tw.kill()
	if _slot_tw != null and _slot_tw.is_valid():
		_slot_tw.kill()
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.7, 0.55, 0.4), 0.15)
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.15)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(self, "scale", Vector2(0.05, 0.05), 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tw2.tween_property(self, "modulate", Color(0.6, 0.15, 0.1, 0.0), 0.5).set_ease(Tween.EASE_IN)
	tw2.chain().tween_callback(queue_free)


func abort_drag() -> void:
	dragging = false
	_pressed = false
	scale = Vector2(layout_scale, layout_scale)
	rotation_degrees = 0.0
	z_index = 0
	position = _slot_pos


func _gui_input(event: InputEvent) -> void:
	if dying:
		return
	if event is InputEventMouseMotion:
		if _pressed and not dragging and (get_global_mouse_position() - _press_global).length() > 8.0:
			dragging = true
			_drag_offset = _press_global - global_position
			rotation_degrees = 4.0
			z_index = 100
			champ_drag_started.emit(self)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_press_global = get_global_mouse_position()
		else:
			var was := dragging
			_pressed = false
			if was:
				dragging = false
				rotation_degrees = 0.0
				z_index = 0
				champ_drag_ended.emit(self)
			else:
				champ_clicked.emit(self)


func set_poison_pulse(on: bool) -> void:
	## (1.49.89) Destaque de MIRA da MORDIDA VENENOSA: inimigos ficam VERDEADOS
	## (verde-veneno) com leve zoom — sem piscar.
	if _hl == null or dying:
		return
	var bsb: StyleBoxFlat = _hl.get_theme_stylebox("panel")
	if on:
		bsb.set_border_width_all(2)
		bsb.border_color = Color(0.50, 0.98, 0.28)
		bsb.shadow_size = 0
		_hl.modulate = Color(1, 1, 1, 1)
		if _target_rect != null:
			_target_rect.color = Color(0.42, 0.95, 0.25, 0.30)
			_target_rect.visible = true
		if _zoom_tw == null or not _zoom_tw.is_valid():
			_zoom_tw = create_tween()
			_zoom_tw.set_loops()
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale * 1.06, layout_scale * 1.06), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_zoom_tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		if _zoom_tw != null and _zoom_tw.is_valid():
			_zoom_tw.kill()
		_zoom_tw = null
		if _target_rect != null:
			_target_rect.visible = false
			_target_rect.color = Color(1.0, 0.14, 0.1, 0.3)
		bsb.shadow_size = 0
		refresh()
		if not dying:
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector2(layout_scale, layout_scale), 0.15)


func _update_status_vfx() -> void:
	## (1.49.91) ENVENENADO mantém a carta ESVERDEADA; as animações persistentes
	## de veneno (símbolo + bolhas) e de FÚRIA (aura + olhos) saíram do jogo —
	## em campo resta SOMENTE o ícone no canto superior direito.
	var poisoned: bool = int(card.get("poison_turns", 0)) > 0 and not dying
	modulate = Color(0.84, 1.06, 0.86, 1.0) if poisoned else Color(1, 1, 1, 1)


# ----------------------------------------------------------------------------
# (1.49.91) ÍCONES DE STATUS NO CANTO SUPERIOR DIREITO (regras 2–6)
# ----------------------------------------------------------------------------

func _has_sem_honra() -> bool:
	if card.get("corrupted", false):
		return true
	if card.get("silenced", false):
		return false
	return String(card.get("on_destroy", "")) == "noHonor" or String(card.get("ability_name", "")) == "Sem Honra"


func _active_statuses() -> Array[String]:
	## Status que exibem ícone em campo, na ordem fixa de verificação; a ORDEM
	## DE EXIBIÇÃO (pilha) é a de aquisição, mantida em _status_order.
	var keys: Array[String] = []
	if int(card.get("shield_turns", 0)) != 0:
		keys.append("prot")
	if _has_sem_honra():
		keys.append("semhonra")
	if int(card.get("poison_turns", 0)) > 0:
		keys.append("veneno")
	if int(card.get("fury_turns", 0)) > 0 and int(card.get("fury_stacks", 0)) > 0:
		keys.append("furia")
	if int(card.get("frozen_turns", 0)) > 0:
		keys.append("cong")   # (1.49.92) CONGELADO = só ícone no canto
	return keys


func _refresh_status_icons() -> void:
	var act := _active_statuses()
	# os que EXPIRARAM saem da pilha (e os de baixo sobem)
	for k in _status_order.duplicate():
		if not act.has(k):
			_status_order.erase(k)
			_free_icon(k)
	# os NOVOS entram no FIM da pilha (adquiridos por último => abaixo)
	for k in act:
		if not _status_icons.has(k):
			_mk_icon(k)
			_status_order.append(k)
	_layout_status_icons()


func _mk_icon(k: String) -> void:
	var bg := TextureRect.new()
	bg.texture = _icon_bg_circle()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(STATUS_ICON_BG, STATUS_ICON_BG)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var ico := TextureRect.new()
	ico.texture = STATUS_ICON_TEX[k]
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.size = Vector2(STATUS_ICON_SZ, STATUS_ICON_SZ)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ico)
	_status_icons[k] = {"bg": bg, "ico": ico}


func _free_icon(k: String) -> void:
	var ent: Dictionary = _status_icons.get(k, {})
	_status_icons.erase(k)
	for key in ["bg", "ico"]:
		var n = ent.get(key)
		if n != null and is_instance_valid(n):
			n.queue_free()


func _layout_status_icons() -> void:
	# canto superior direito: 1º adquirido no TOPO, demais ABAIXO dele
	var pad: float = (STATUS_ICON_BG - STATUS_ICON_SZ) / 2.0
	for i in _status_order.size():
		var ent: Dictionary = _status_icons.get(_status_order[i], {})
		var bg = ent.get("bg")
		var ico = ent.get("ico")
		var y: float = 3.0 + float(i) * STATUS_ICON_STEP
		if bg != null and is_instance_valid(bg):
			bg.position = Vector2(CHAMP_W - STATUS_ICON_BG - 3.0, y)
		if ico != null and is_instance_valid(ico):
			ico.position = Vector2(CHAMP_W - STATUS_ICON_BG - 3.0 + pad, y + pad)


func hide_status_icons() -> void:
	for ent in _status_icons.values():
		for key in ["bg", "ico"]:
			var n = ent.get(key)
			if n != null and is_instance_valid(n):
				n.visible = false


static func _icon_bg_circle() -> ImageTexture:
	## Selo escuro arredondado atrás de cada ícone (legível sobre a moldura).
	if _icon_bg_tex != null:
		return _icon_bg_tex
	var S := 48
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S / 2.0, S / 2.0)
	var r := S / 2.0 - 1.0
	for y in S:
		for x in S:
			var d: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			if d > r:
				continue
			var edge: float = clampf(r - d, 0.0, 1.0)
			var ring: float = 1.0 - smoothstep(r - 4.0, r - 2.0, d)
			var col := Color(0.07, 0.07, 0.12, 0.82)
			if ring > 0.01:
				col = col.lerp(Color(0.93, 0.80, 0.42, 0.95), ring * 0.85)
			col.a *= edge
			img.set_pixel(x, y, col)
	_icon_bg_tex = ImageTexture.create_from_image(img)
	return _icon_bg_tex
