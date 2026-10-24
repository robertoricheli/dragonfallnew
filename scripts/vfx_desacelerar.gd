class_name DesacelerarFX
extends Node2D
## (1.49.94) HABILIDADE/CARTA TALENTO DESACELERAR — 0,5 s após a carta entrar
## em campo, um RELÓGIO MÁGICO DE FANTASIA (bronze arcano, runas, cristal ciano
## — NADA moderno/realista; arte pintada semi-3D estilo Hearthstone em
## assets/RELOGIO_*.png, fundo preto + blend aditivo) aparece SOBRE O CAMPO
## ADVERSÁRIO por 2,0 s: materializa-se com anel de runas, os PONTEIROS
## (5 frames pintados: 0°/30°/60°/90°/120°) GIRAM PARA TRÁS com "ticks"
## mecânico-mágicos (troca de frame + repique de rotação + clarão de tick),
## anéis de ONDA TEMPORAL se expandem em câmera lenta, areia rúnica sobe e o
## relógio flutua balançando; no fim, DISSOLVE em areia de tempo (RELOGIO_F4).
## Uso: add_child(fx); fx.setup(pos_global_centro_campo_adversario)

signal finished

const DUR := 2.0
const MAT_END := 0.35        # fim da materialização
const DISSOLVE_AT := 1.65    # início da dissolução
const TICK_EVERY := 0.22     # cadência dos ticks dos ponteiros

var _t := 0.0
var _done := false
var _started := false
var _next_tick := MAT_END
var _tick_i := 0
var _next_ripple := 0.45

var _face: Sprite2D
var _hands: Sprite2D
var _ghost_face: Sprite2D    # materialização (F1) e dissolução (F4)
var _runering: Sprite2D
var _tickflash: Sprite2D
var _ripple_a: Sprite2D
var _ripple_b: Sprite2D
var _sand: CPUParticles2D
var _rune_sparks: CPUParticles2D

const TEX_F1 := preload("res://assets/RELOGIO_F1.png")
const TEX_FACE := preload("res://assets/RELOGIO_FACE.png")
const TEX_F4 := preload("res://assets/RELOGIO_F4.png")
const HAND_FRAMES := [
	preload("res://assets/RELOGIO_MAOS.png"),      # 0°
	preload("res://assets/RELOGIO_MAOS_R1.png"),   # 30°
	preload("res://assets/RELOGIO_MAOS_R2.png"),   # 60°
	preload("res://assets/RELOGIO_MAOS_R3.png"),   # 90°
	preload("res://assets/RELOGIO_MAOS_R4.png"),   # 120°
]


func setup(at: Vector2) -> void:
	position = at
	z_index = 88
	_started = true
	# ---- anel de runas de invocação do relógio
	_runering = Sprite2D.new()
	_runering.texture = Vfx.ring("desac_rune", 190, Color(0.35, 0.90, 1.0, 0.85), 0.05)
	_runering.material = Vfx.add_mat()
	_runering.modulate = Color(1, 1, 1, 0)
	add_child(_runering)
	# ---- face fantasma (materialização F1 / dissolução F4)
	_ghost_face = Sprite2D.new()
	_ghost_face.texture = TEX_F1
	_ghost_face.material = Vfx.add_mat()
	_ghost_face.modulate = Color(1, 1, 1, 0)
	_ghost_face.scale = Vector2(0.17, 0.17)
	add_child(_ghost_face)
	# ---- a face do relógio
	_face = Sprite2D.new()
	_face.texture = TEX_FACE
	_face.material = Vfx.add_mat()
	_face.modulate = Color(1, 1, 1, 0)
	_face.scale = Vector2(0.17, 0.17)
	add_child(_face)
	# ---- os ponteiros (frames pintados, girando PARA TRÁS)
	_hands = Sprite2D.new()
	_hands.texture = HAND_FRAMES[4]
	_hands.material = Vfx.add_mat()
	_hands.modulate = Color(1, 1, 1, 0)
	_hands.scale = Vector2(0.15, 0.15)
	add_child(_hands)
	# ---- clarão de tick
	_tickflash = Sprite2D.new()
	_tickflash.texture = Vfx.radial("desac_tick", 120, Color(0.55, 0.95, 1.0, 0.8), 0.25)
	_tickflash.material = Vfx.add_mat()
	_tickflash.modulate = Color(1, 1, 1, 0)
	add_child(_tickflash)
	# ---- ondas temporais (2 anéis alternados)
	_ripple_a = _mk_ripple("desac_rip_a")
	_ripple_b = _mk_ripple("desac_rip_b")
	# ---- areia rúnica que sobe (tempo escapando)
	_sand = CPUParticles2D.new()
	_sand.texture = Vfx.spark(14, Color(0.55, 0.95, 1.0))
	_sand.material = Vfx.add_mat()
	_sand.emitting = false
	_sand.amount = 30
	_sand.lifetime = 0.9
	_sand.direction = Vector2(0, -1)
	_sand.spread = 60.0
	_sand.initial_velocity_min = 18.0
	_sand.initial_velocity_max = 46.0
	_sand.gravity = Vector2(0, -6)
	_sand.scale_amount_min = 0.5
	_sand.scale_amount_max = 1.1
	add_child(_sand)
	_rune_sparks = CPUParticles2D.new()
	_rune_sparks.texture = Vfx.spark(18, Color(1.0, 0.85, 0.45))
	_rune_sparks.material = Vfx.add_mat()
	_rune_sparks.emitting = false
	_rune_sparks.amount = 18
	_rune_sparks.lifetime = 0.7
	_rune_sparks.direction = Vector2(0, -1)
	_rune_sparks.spread = 180.0
	_rune_sparks.initial_velocity_min = 40.0
	_rune_sparks.initial_velocity_max = 90.0
	_rune_sparks.gravity = Vector2(0, 60)
	_rune_sparks.scale_amount_min = 0.4
	_rune_sparks.scale_amount_max = 0.9
	add_child(_rune_sparks)


func _mk_ripple(key: String) -> Sprite2D:
	var r := Sprite2D.new()
	r.texture = Vfx.ring(key, 220, Color(0.45, 0.90, 1.0, 0.7), 0.04)
	r.material = Vfx.add_mat()
	r.modulate = Color(1, 1, 1, 0)
	r.scale = Vector2(1.0, 0.45)
	add_child(r)
	return r


var _ripple_t := {"a": -1.0, "b": -1.0}


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ================= materialização (0 .. MAT_END)
	var mk: float = clampf(t / MAT_END, 0.0, 1.0)
	var alive: float = 1.0 if t < DISSOLVE_AT else clampf(1.0 - (t - DISSOLVE_AT) / 0.35, 0.0, 1.0)
	var bob: float = sin(t * 2.6) * 4.0
	var sway: float = 0.05 * sin(t * 1.9)
	if t < DISSOLVE_AT:
		_ghost_face.modulate = Color(1, 1, 1, sin(mk * PI) * 0.9 if t < MAT_END else 0.0)
		_face.modulate = Color(1, 1, 1, mk * alive * (0.92 + 0.08 * sin(t * 6.0)))
		_hands.modulate = Color(1, 1, 1, clampf((mk - 0.5) * 2.0, 0.0, 1.0) * alive)
	else:
		_ghost_face.texture = TEX_F4
		var dk: float = clampf((t - DISSOLVE_AT) / 0.35, 0.0, 1.0)
		_ghost_face.modulate = Color(1, 1, 1, dk * clampf(1.0 - (t - DISSOLVE_AT - 0.1) / 0.25, 0.0, 1.0))
		_ghost_face.scale = Vector2(0.17, 0.17) * (1.0 + dk * 0.25)
		_face.modulate = Color(1, 1, 1, alive)
		_hands.modulate = Color(1, 1, 1, alive)
	_face.position = Vector2(0, bob)
	_face.rotation = sway
	_ghost_face.position = Vector2(0, bob)
	_hands.position = Vector2(0, bob)
	_hands.rotation = sway
	# anel de runas
	_runering.modulate = Color(1, 1, 1, sin(mk * PI) * 0.85 if t < MAT_END * 2.0 else 0.0)
	_runering.scale = Vector2(0.5 + mk * 0.8, 0.22 + mk * 0.36)
	_runering.rotation -= delta * 0.8
	# ================= TICKS: ponteiros PARA TRÁS (frames em ordem reversa)
	if t >= _next_tick and t < DISSOLVE_AT:
		_tick_i += 1
		_next_tick = t + TICK_EVERY
		# ordem reversa: 4,3,2,1,0,4,3,...  (ponteiros voltando no tempo)
		var idx: int = HAND_FRAMES.size() - 1 - (_tick_i % HAND_FRAMES.size())
		_hands.texture = HAND_FRAMES[idx]
		_tickflash.modulate = Color(1, 1, 1, 0.55)
		# repique mecânico: rotação volta um pouco e assenta
		var tw := _hands.create_tween()
		tw.tween_property(_hands, "rotation", sway - 0.16, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_hands, "rotation", sway, 0.10).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if _tickflash.modulate.a > 0.0:
		_tickflash.modulate = Color(1, 1, 1, maxf(0.0, _tickflash.modulate.a - delta * 2.6))
	_tickflash.position = Vector2(0, bob)
	# ================= ONDAS TEMPORAIS em câmera lenta
	if t >= _next_ripple and t < DISSOLVE_AT:
		var key: String = "a" if fmod(_tick_i, 2) == 0 else "b"
		_ripple_t[key] = t
		_next_ripple = t + 0.55
	for key in _ripple_t:
		var t0: float = _ripple_t[key]
		var r: Sprite2D = _ripple_a if key == "a" else _ripple_b
		if t0 < 0.0:
			continue
		var rt: float = (t - t0) / 1.1   # expansão LENTA (câmera lenta)
		if rt > 1.0:
			r.modulate = Color(1, 1, 1, 0)
			continue
		r.modulate = Color(1, 1, 1, (1.0 - rt) * 0.6)
		r.scale = Vector2(0.35 + rt * 1.5, 0.16 + rt * 0.66)
		r.position = Vector2(0, bob)
	# ================= partículas
	if t >= MAT_END and t < DISSOLVE_AT:
		_sand.emitting = true
		_rune_sparks.emitting = true
	else:
		_sand.emitting = false
		_rune_sparks.emitting = false
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
