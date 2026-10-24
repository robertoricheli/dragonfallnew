extends Node
## Verifica o destaque de MIRA (1.49.62): cor avermelhada constante +
## leve zoom in/out — SEM piscar (modulate/borda estáveis).
## Rodar:  godot --headless --path . res://tests/pulse.tscn

func _ready() -> void:
	var card: Dictionary = {
		"id": "lilith", "name": "LILITH", "category": "champion",
		"ability_type": "instant", "ability_name": "Bola de Fogo",
		"power": 3, "current_power": 3, "uid": 9100, "owner": 1,
		"on_enter": "", "silenced": false, "tapped": false,
		"frozen_turns": 0, "fury_stacks": 0, "fury_turns": 0,
		"desafiante_buff": 0, "inspirar_buff": 0, "wall_buff": 0, "charm_turns": 0,
		"barrier_turns": 0, "vulnerable": false,
	}
	var v := ChampionView.new()
	v.setup(card, 1)
	v.layout_scale = 1.0
	add_child(v)
	await get_tree().process_frame
	v.set_target_pulse(true)
	var min_s := 99.0
	var max_s := 0.0
	var min_hl_a := 99.0
	for i in 150:
		await get_tree().process_frame
		min_s = minf(min_s, v.scale.x)
		max_s = maxf(max_s, v.scale.x)
		min_hl_a = minf(min_hl_a, v._hl.modulate.a)
	var bsb: StyleBoxFlat = v._hl.get_theme_stylebox("panel")
	var tint_ok: bool = v._target_rect.visible and v._target_rect.color.r > 0.8 and v._target_rect.color.g < 0.4
	var zoom_ok: bool = max_s > 1.04 and min_s < 1.02
	var no_blink: bool = min_hl_a > 0.99 and bsb.shadow_size == 0
	print("MIRA: zoom min=%.3f max=%.3f | tint=%s | sem-piscar=%s" % [min_s, max_s, tint_ok, no_blink])
	v.set_target_pulse(false)
	for i in 40:
		await get_tree().process_frame
	var off_ok: bool = (not v._target_rect.visible) and absf(v.scale.x - 1.0) < 0.01
	print("MIRA off: escala=%.3f tint_vis=%s ok=%s" % [v.scale.x, v._target_rect.visible, off_ok])
	v.queue_free()
	get_tree().quit(0 if (tint_ok and zoom_ok and no_blink and off_ok) else 1)
