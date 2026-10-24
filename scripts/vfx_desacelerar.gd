class_name DesacelerarFX
extends Node2D
## (1.49.95) DESACELERAR (Campeão e Talento) — refeita com o RELÓGIO MÁGICO
## de 20 FRAMES pintados (assets/RELOGIO_SEQ_F01..F20.png, sprite sheet do
## dono: relógio arcano dourado com ampulhetas e vórtice azul de tempo, que
## materializa, gira os ponteiros para trás e dissolve): aparece SOBRE O
## CAMPO ADVERSÁRIO por 2,0 s, UM POUCO MAIOR que uma carta (170 px de
## altura vs. 140 px da carta), contido na linha adversária (nada de ondas
## na tela inteira): cadência variável (materializa lento -> ticks aceleram
## -> dissolve), bob e balanço suaves, anel rúnico local girando no chão,
## clarões de tick contidos e areia de tempo subindo do próprio relógio.
## Contrato: finished em 2,0 s. Uso: add_child(fx); fx.setup(centro_linha_adv)

signal finished

const DUR := 2.0
const SCALE := 0.664          # 256 px * 0.664 = 170 px (> carta 140 px)

## cadência: instante em que cada frame (0..19) entra
const FRAME_AT := [
	0.00, 0.10, 0.20, 0.30, 0.40,          # 1-5  materializa
	0.52, 0.64, 0.76, 0.88, 1.00,          # 6-10 ponteiros voltando (ticks)
	1.10, 1.20, 1.30, 1.40, 1.50,          # 11-15 ticks + vórtice
	1.60, 1.70, 1.80, 1.90, 2.00,          # 16-20 dissolve em magia
]

var _t := 0.0
var _done := false
var _started := false
var _frame := -1

var _seq: Sprite2D
var _rune: Sprite2D
var _tick: Sprite2D
var _sand: CPUParticles2D

const FRAMES := [
	preload("res://assets/RELOGIO_SEQ_F01.png"), preload("res://assets/RELOGIO_SEQ_F02.png"),
	preload("res://assets/RELOGIO_SEQ_F03.png"), preload("res://assets/RELOGIO_SEQ_F04.png"),
	preload("res://assets/RELOGIO_SEQ_F05.png"), preload("res://assets/RELOGIO_SEQ_F06.png"),
	preload("res://assets/RELOGIO_SEQ_F07.png"), preload("res://assets/RELOGIO_SEQ_F08.png"),
	preload("res://assets/RELOGIO_SEQ_F09.png"), preload("res://assets/RELOGIO_SEQ_F10.png"),
	preload("res://assets/RELOGIO_SEQ_F11.png"), preload("res://assets/RELOGIO_SEQ_F12.png"),
	preload("res://assets/RELOGIO_SEQ_F13.png"), preload("res://assets/RELOGIO_SEQ_F14.png"),
	preload("res://assets/RELOGIO_SEQ_F15.png"), preload("res://assets/RELOGIO_SEQ_F16.png"),
	preload("res://assets/RELOGIO_SEQ_F17.png"), preload("res://assets/RELOGIO_SEQ_F18.png"),
	preload("res://assets/RELOGIO_SEQ_F19.png"), preload("res://assets/RELOGIO_SEQ_F20.png"),
]


func setup(at: Vector2) -> void:
	position = at
	z_index = 88
	_started = true
	# ---- anel rúnico local no chão da linha adversária
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("desac2_rune", 130, Color(0.35, 0.90, 1.0, 0.8), 0.05)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.0, 0.32)
	_rune.position = Vector2(0, 74)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	# ---- a sequencia de 20 frames do relógio
	_seq = Sprite2D.new()
	_seq.texture = FRAMES[0]
	_seq.centered = true
	_seq.scale = Vector2(SCALE, SCALE)
	_seq.modulate = Color(1, 1, 1, 0)
	add_child(_seq)
	# ---- clarão de tick CONTIDO
	_tick = Sprite2D.new()
	_tick.texture = Vfx.radial("desac2_tick", 90, Color(0.55, 0.95, 1.0, 0.75), 0.25)
	_tick.material = Vfx.add_mat()
	_tick.modulate = Color(1, 1, 1, 0)
	add_child(_tick)
	# ---- areia de tempo subindo do próprio relógio
	_sand = CPUParticles2D.new()
	_sand.texture = Vfx.spark(14, Color(0.55, 0.95, 1.0))
	_sand.material = Vfx.add_mat()
	_sand.emitting = false
	_sand.amount = 22
	_sand.lifetime = 0.7
	_sand.direction = Vector2(0, -1)
	_sand.spread = 45.0
	_sand.initial_velocity_min = 16.0
	_sand.initial_velocity_max = 40.0
	_sand.gravity = Vector2(0, -8)
	_sand.scale_amount_min = 0.4
	_sand.scale_amount_max = 0.9
	add_child(_sand)


func _frame_index(t: float) -> int:
	var idx := 0
	for i in FRAME_AT.size():
		if t >= FRAME_AT[i]:
			idx = i
	return idx


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var idx := _frame_index(t)
	if idx != _frame:
		var old := _frame
		_frame = idx
		_seq.texture = FRAMES[idx]
		# clarão de tick a cada troca de frame na fase de ponteiros (6..15)
		if old >= 0 and idx >= 5 and idx <= 15:
			_tick.modulate = Color(1, 1, 1, 0.4)
	# flutuação suave + balanço de pêndulo contido
	var mk: float = clampf(t / 0.35, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, Ease.out_cubic(mk))
	_seq.position = Vector2(sin(t * 1.8) * 3.0, sin(t * 2.6) * 4.0 - 6.0)
	_seq.rotation = 0.045 * sin(t * 2.2)
	var sc: float = SCALE * lerpf(0.8, 1.0, Ease.out_cubic(mk))
	_seq.scale = Vector2(sc, sc)
	# anel rúnico local
	_rune.modulate = Color(1, 1, 1, sin(mk * PI) * 0.7 if t < 0.8 else 0.30 + 0.15 * sin(t * 5.0))
	_rune.rotation -= delta * 0.7
	# clarão de tick decai
	if _tick.modulate.a > 0.0:
		_tick.modulate = Color(1, 1, 1, maxf(0.0, _tick.modulate.a - delta * 2.2))
	# areia de tempo na fase central
	if t >= 0.45 and t < 1.65:
		_sand.emitting = true
	else:
		_sand.emitting = false
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv
