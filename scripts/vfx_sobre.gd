class_name SobreFX
extends Node2D
## (1.50.4) SOBREPUJAR — destruição ESPECIAL contida no próprio slot (regra
## do dono: mesmo padrão das destruições, sem mudar tamanho, sem sair do
## lugar): style = "socos" (POPPY: rajada de SOCOS com estrelas de impacto,
## sacudidas e poeira por 1,5 s) ou "rapier" (A DUELISTA: 5 CORTES finos de
## espada rapieira em ângulos diferentes com faíscas por 1,5 s). No fim, a
## Tela de Combate aplica a destruição padrão (estilhaços+fumaça+anel).
## Contrato: finished em 1,5 s. Uso: add_child(fx); fx.setup(view, style)

signal finished

const DUR := 1.5

var _t := 0.0
var _done := false
var _started := false
var _style := "socos"
var _next_hit := 0.12
var _hit_i := 0

var _view: ChampionView
var _pos := Vector2.ZERO
var _size := Vector2(100, 140)
var _base_pos := Vector2.ZERO
var _fx_nodes: Array = []


func setup(v: ChampionView, style: String) -> void:
	_view = v
	_style = style
	position = Vector2.ZERO
	z_index = 93
	_started = true
	_size = v.size * v.scale
	_pos = v.global_position + _size / 2.0
	_base_pos = v.position


func _punch() -> void:
	# estrela de impacto + sacudida + poeira (tudo no slot)
	var star := Sprite2D.new()
	star.texture = Vfx.spark(46, Color(1.0, 0.85, 0.35))
	star.material = Vfx.add_mat()
	star.modulate = Color(1, 1, 1, 0.95)
	star.position = _pos + Vector2(randf_range(-26, 26), randf_range(-44, 44))
	star.scale = Vector2.ONE * randf_range(0.8, 1.3)
	add_child(star)
	var tw := star.create_tween()
	tw.tween_property(star, "modulate:a", 0.0, 0.18)
	tw.tween_callback(star.queue_free)
	if is_instance_valid(_view):
		var jx := randf_range(-3.5, 3.5)
		var jy := randf_range(-2.5, 2.5)
		var tw2 := _view.create_tween()
		tw2.tween_property(_view, "position", _base_pos + Vector2(jx, jy), 0.04)
		tw2.tween_property(_view, "position", _base_pos, 0.09).set_trans(Tween.TRANS_ELASTIC)
		_view.modulate = Color(1.35, 1.25, 1.15, 1.0)
		var tw3 := _view.create_tween()
		tw3.tween_property(_view, "modulate", Color(1, 1, 1, 1), 0.12)
	Sfx.play("punch", _pos.x, 0.9)


func _slash(i: int) -> void:
	# corte FINO de rapieira em ângulo variado, contido na carta
	var sl := Sprite2D.new()
	sl.texture = Vfx.ring("sob_slash", 150, Color(0.95, 0.97, 1.0, 0.9), 0.035)
	sl.material = Vfx.add_mat()
	sl.modulate = Color(1, 1, 1, 0.9)
	sl.rotation = deg_to_rad(-35.0 + 18.0 * float(i) + randf_range(-6, 6))
	sl.scale = Vector2(0.42, 0.05)
	sl.position = _pos + Vector2(randf_range(-8, 8), randf_range(-30, 30))
	add_child(sl)
	var tw := sl.create_tween()
	tw.tween_property(sl, "modulate:a", 0.0, 0.16)
	tw.tween_callback(sl.queue_free)
	for k in 3:
		var sp := Sprite2D.new()
		sp.texture = Vfx.spark(12, Color(1.0, 1.0, 0.9))
		sp.material = Vfx.add_mat()
		sp.modulate = Color(1, 1, 1, 0.9)
		sp.position = sl.position + Vector2(randf_range(-20, 20), randf_range(-30, 30))
		add_child(sp)
		var tw2 := sp.create_tween()
		tw2.tween_property(sp, "position", sp.position + Vector2(randf_range(-18, 18), randf_range(6, 22)), 0.22)
		tw2.parallel().tween_property(sp, "modulate:a", 0.0, 0.22)
		tw2.tween_callback(sp.queue_free)
	if is_instance_valid(_view):
		_view.modulate = Color(1.25, 1.28, 1.35, 1.0)
		var tw3 := _view.create_tween()
		tw3.tween_property(_view, "modulate", Color(1, 1, 1, 1), 0.1)
	Sfx.play("rapier", _pos.x, 0.8)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var total := 6 if _style == "socos" else 5
	if t >= _next_hit and _hit_i < total:
		if _style == "socos":
			_punch()
		else:
			_slash(_hit_i)
		_hit_i += 1
		_next_hit = t + (0.22 if _style == "socos" else 0.26)
	if t >= DUR and not _done:
		_done = true
		if is_instance_valid(_view):
			_view.position = _base_pos
			_view.modulate = Color(1, 1, 1, 1)
		finished.emit()
		queue_free()
