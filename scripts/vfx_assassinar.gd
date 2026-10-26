class_name AssassinarFX
extends Node2D
## (1.50.6) HABILIDADE ASSASSINAR — animação vinda dos VÍDEOS do dono,
## recortados do fundo branco com keying profissional, tocando SOBRE o
## campeão afetado (contida: ~1,15x a carta) e com o SOM DO PRÓPRIO VÍDEO:
##   style "vega" = ASSASSINAR 1 (a ADAGA corta o campeão, 3,69 s)
##   style "mira" = ASSASSINAR 2 (a MIRA mira e atira no campeão, 2,40 s)
## 0,5 s após a escolha (orquestrado pela Tela de Combate). Ao terminar, a
## Tela aplica a destruição PADRÃO da carta. A carta NÃO muda de tamanho.
## Contrato: finished no fim do vídeo. Uso: fx.setup(view, style)

signal finished

const DUR_VEGA := 3.69
const DUR_MIRA := 2.40
const N_VEGA := 110
const N_MIRA := 72

var _t := 0.0
var _done := false
var _started := false
var _frame := -1
var _dur := 3.69
var _nframes := 110
var _scale := 1.0

var _view: ChampionView
var _pos := Vector2.ZERO
var _size := Vector2(100, 140)
var _seq: Sprite2D

var _frames: Array = []


func setup(v: ChampionView, style: String) -> void:
	_view = v
	position = Vector2.ZERO
	z_index = 95
	_started = true
	_size = v.size * v.scale
	_pos = v.get_global_rect().get_center()
	if style == "mira":
		_dur = DUR_MIRA
		_nframes = N_MIRA
		for i in _nframes:
			_frames.append(load("res://assets/ASS2_F%02d.png" % (i + 1)))
		# mira: altura ~1,1x a carta
		_scale = (140.0 * 1.1) / float(_frames[0].get_height())
		Sfx.play("assassinar_mira", _pos.x, 1.0)   # som do vídeo
	else:
		_dur = DUR_VEGA
		_nframes = N_VEGA
		for i in _nframes:
			_frames.append(load("res://assets/ASS1_F%02d.png" % (i + 1)))
		# adaga: largura ~1,7x a carta (o corte varre na horizontal)
		_scale = (100.0 * 1.7) / float(_frames[0].get_width())
		Sfx.play("assassinar_vega", _pos.x, 1.0)   # som do vídeo
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
