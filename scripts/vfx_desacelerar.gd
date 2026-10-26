class_name DesacelerarFX
extends Node2D
## (1.49.97) DESACELERAR (Campeão e Talento) — animação vinda do VÍDEO do dono
## ("DESACELERAR", 60 frames recortados do fundo PRETO com keying profissional
## por conectividade: NADA do fundo preto aparece): o RELÓIO ARCANO de bronze
## com engrenagens e vórtice aparece SOBRE O CAMPO ADVERSÁRIO por 2,6 s
## (vídeo integral em cadência suave), um pouco maior que uma carta (170 px
## vs 140 px), contido na linha adversária; polimento local (anel rúnico
## girando no chão, clarões de tick contidos e areia de tempo).
## Contrato: finished em 2,6 s. Uso: add_child(fx); fx.setup(centro_linha_adv)

signal finished

const DUR := 5.0
const N_FRAMES := 75
const HEIGHT := 170.0        # px em campo (> 140 da carta, contido na linha)

var _t := 0.0
var _done := false
var _started := false
var _frame := -1
var _scale := 1.0
var _snd_played := false

var _seq: Sprite2D
var _rune: Sprite2D
var _tick: Sprite2D
var _sand: CPUParticles2D

var _frames: Array = []


func _init() -> void:
	for i in N_FRAMES:
		_frames.append(load("res://assets/DESAC2_F%02d.png" % (i + 1)))


func setup(at: Vector2) -> void:
	position = at
	z_index = 88
	_started = true
	var tex: Texture2D = _frames[0]
	_scale = HEIGHT / float(tex.get_height())
	# ---- anel rúnico local no chão da linha adversária
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("desac3_rune", 130, Color(0.90, 0.70, 0.30, 0.8), 0.05)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.0, 0.32)
	_rune.position = Vector2(0, 78)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	# ---- o vídeo em frames
	_seq = Sprite2D.new()
	_seq.texture = _frames[0]
	_seq.centered = true
	_seq.scale = Vector2(_scale, _scale)
	_seq.modulate = Color(1, 1, 1, 0)
	add_child(_seq)
	# ---- clarão de tick contido
	_tick = Sprite2D.new()
	_tick.texture = Vfx.radial("desac3_tick", 90, Color(1.0, 0.85, 0.45, 0.7), 0.25)
	_tick.material = Vfx.add_mat()
	_tick.modulate = Color(1, 1, 1, 0)
	add_child(_tick)
	# ---- areia de tempo subindo do relógio
	_sand = CPUParticles2D.new()
	_sand.texture = Vfx.spark(14, Color(1.0, 0.85, 0.50))
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


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var k: float = clampf(t / DUR, 0.0, 1.0)
	# (1.50.6) o SOM DO VÍDEO é o som padrão da animação, desde o 1º frame
	if not _snd_played:
		_snd_played = true
		Sfx.play("desacelerar", position.x, 1.0)
	var idx := mini(N_FRAMES - 1, int(k * N_FRAMES))
	if idx != _frame:
		var old := _frame
		_frame = idx
		_seq.texture = _frames[idx]
		# clarão de tick a cada troca na fase central (ponteiros voltando)
		if old >= 0 and idx >= 10 and idx <= 68 and idx % 4 == 0:
			_tick.modulate = Color(1, 1, 1, 0.35)
	# flutuação suave + entrada/saída
	var mk: float = clampf(t / 0.3, 0.0, 1.0)
	var outk: float = clampf((t - (DUR - 0.2)) / 0.2, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, Ease.out_cubic(mk) * (1.0 - 0.0 * outk))
	_seq.position = Vector2(sin(t * 1.8) * 3.0, sin(t * 2.6) * 4.0 - 6.0)
	_seq.rotation = 0.04 * sin(t * 2.2)
	var sc: float = _scale * lerpf(0.82, 1.0, Ease.out_cubic(mk))
	_seq.scale = Vector2(sc, sc)
	# anel rúnico local
	_rune.modulate = Color(1, 1, 1, (sin(mk * PI) * 0.7 if t < 0.9 else 0.30 + 0.15 * sin(t * 5.0)))
	_rune.rotation -= delta * 0.7
	# clarão de tick decai
	if _tick.modulate.a > 0.0:
		_tick.modulate = Color(1, 1, 1, maxf(0.0, _tick.modulate.a - delta * 2.2))
	# areia de tempo na fase central
	if t >= 0.4 and t < DUR - 0.5:
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
