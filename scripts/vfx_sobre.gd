class_name SobreFX
extends Node2D
## (1.50.6) SOBREPUJAR — final da destruição especial com os VÍDEOS do dono
## (recortados do fundo branco, keying profissional), tocando SOBRE o campeão
## perdedor, contidos (~1,1x a carta, sem mudar tamanho):
##   style "rapier" (A DUELISTA) = SOBREPUJAR 1: a espada corta a carta (2,77 s)
##   style "socos"  (POPPY)      = SOBREPUJAR 2: os socos atingem a carta (2,20 s)
## Sons sintéticos de corte/soco acompanham o início. Ao terminar, a Tela
## aplica a destruição PADRÃO. Contrato: finished no fim do vídeo.
## Uso: fx.setup(view, style)

signal finished

const DUR_RAPIER := 2.77
const DUR_SOCOS := 2.20
const N_RAPIER := 83
const N_SOCOS := 65

var _t := 0.0
var _done := false
var _started := false
var _frame := -1
var _dur := 2.77
var _nframes := 83
var _scale := 1.0
var _snd2 := false

var _view: ChampionView
var _pos := Vector2.ZERO
var _seq: Sprite2D

var _frames: Array = []


func setup(v: ChampionView, style: String) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 93
	_started = true
	_pos = v.get_global_rect().get_center()
	if style == "socos":
		_dur = DUR_SOCOS
		_nframes = N_SOCOS
		for i in _nframes:
			_frames.append(load("res://assets/SOB2_F%02d.png" % (i + 1)))
		_scale = (100.0 * 1.7) / float(_frames[0].get_width())
		Sfx.play("punch", _pos.x, 0.9)
	else:
		_dur = DUR_RAPIER
		_nframes = N_RAPIER
		for i in _nframes:
			_frames.append(load("res://assets/SOB1_F%02d.png" % (i + 1)))
		_scale = (140.0 * 1.1) / float(_frames[0].get_height())
		Sfx.play("rapier", _pos.x, 0.9)
	_seq = Sprite2D.new()
	_seq.texture = _frames[0]
	_seq.centered = true
	_seq.scale = Vector2(_scale, _scale)
	_seq.modulate = Color(1, 1, 1, 0)
	_seq.position = _pos
	add_child(_seq)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var k: float = clampf(t / _dur, 0.0, 1.0)
	var idx := mini(_nframes - 1, int(k * _nframes))
	if idx != _frame:
		_frame = idx
		_seq.texture = _frames[idx]
	var mk: float = clampf(t / 0.12, 0.0, 1.0)
	var outk: float = clampf((t - (_dur - 0.12)) / 0.12, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, mk * (1.0 - outk))
	_seq.position = _pos
	if t >= _dur and not _done:
		_done = true
		finished.emit()
		queue_free()
