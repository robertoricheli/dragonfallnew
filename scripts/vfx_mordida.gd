class_name MordidaFX
extends Node2D
## (1.49.94) MORDIDA VENENOSA REFEITA (regra do dono): NADA de cobra/serpente.
## Uma MANDÍBULA ESPECTRAL DE PRESAS VENENOSAS (arte pintada semi-3D estilo
## Hearthstone, assets/MORDIDA_F1..F4.png, fundo preto + blend aditivo) se
## ABRE acima do alvo com vapor tóxico e gotas de veneno, PAUSA um instante e
## FECHA COM UM BOTE SECO (F1->F2->F3 em 0,12 s com punch de escala): clarão,
## anel de choque, marcas de presa, respingo de veneno e lascas tóxicas.
## Depois a mandíbula TREME cravada enquanto o veneno escorre (poça + gotas +
## névoa) e por fim DISSOLVE em névoa tóxica (F4). DUR 1.6 (contrato antigo).
## Uso: add_child(fx); fx.setup(pos_global_alvo)

signal finished

const DUR := 1.6
const APPEAR_END := 0.30   # mandíbula aberta plenamente visível
const SNAP1_AT := 0.30     # F2 (semi-fechada)
const SNAP2_AT := 0.40     # F3 (cravada) + IMPACTO
const GNASH_END := 1.10    # fim do tremor cravado
const DISSOLVE_AT := 1.10  # F4 dissolve

var _t := 0.0
var _done := false
var _started := false
var _impacted := false

var _jaw: Sprite2D
var _glow: Sprite2D
var _ground: Sprite2D
var _pool: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _mist: CPUParticles2D
var _drips: CPUParticles2D
var _splash: Array = []
var _marks: Array = []
var _streaks: Array = []

const TEX_F1 := preload("res://assets/MORDIDA_F1.png")
const TEX_F2 := preload("res://assets/MORDIDA_F2.png")
const TEX_F3 := preload("res://assets/MORDIDA_F3.png")
const TEX_F4 := preload("res://assets/MORDIDA_F4.png")


func setup(at: Vector2, _target: Node = null) -> void:
	position = at
	z_index = 89
	_started = true
	# ---- presença tóxica no chão/alvo
	_ground = Sprite2D.new()
	_ground.texture = Vfx.ring("mord_ground", 150, Color(0.45, 1.0, 0.25, 0.8), 0.09)
	_ground.material = Vfx.add_mat()
	_ground.scale = Vector2(1.0, 0.32)
	_ground.position = Vector2(0, 60)
	_ground.modulate = Color(1, 1, 1, 0)
	add_child(_ground)
	_pool = Sprite2D.new()
	_pool.texture = Vfx.radial("mord_pool", 140, Color(0.30, 0.80, 0.12, 0.55), 0.1)
	_pool.material = Vfx.add_mat()
	_pool.scale = Vector2(1.0, 0.3)
	_pool.position = Vector2(0, 62)
	_pool.modulate = Color(1, 1, 1, 0)
	add_child(_pool)
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("mord_glow", 200, Color(0.35, 0.95, 0.18, 0.5), 0.08)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	add_child(_glow)
	# ---- a MANDÍBULA DE PRESAS (4 frames pintados)
	_jaw = Sprite2D.new()
	_jaw.texture = TEX_F1
	_jaw.material = Vfx.add_mat()
	_jaw.modulate = Color(1, 1, 1, 0)
	_jaw.scale = Vector2(0.62, 0.62)
	_jaw.position = Vector2(0, -46)
	add_child(_jaw)
	# ---- rastros de velocidade do bote
	for i in 3:
		var st := Sprite2D.new()
		st.texture = Vfx.radial("mord_streak", 60, Color(0.55, 1.0, 0.30, 0.5), 0.1)
		st.material = Vfx.add_mat()
		st.scale = Vector2(0.35, 3.2)
		st.modulate = Color(1, 1, 1, 0)
		st.position = Vector2(-34.0 + 34.0 * float(i), -160)
		add_child(st)
		_streaks.append(st)
	# ---- kit do impacto
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("mord_flash", 240, Color(0.70, 1.0, 0.40, 0.9), 0.18)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("mord_ring", 140, Color(0.55, 1.0, 0.30, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	var mtex: ImageTexture = _make_mark()
	for i in 4:
		var mk := Sprite2D.new()
		mk.texture = mtex
		mk.material = Vfx.add_mat()
		mk.modulate = Color(1, 1, 1, 0)
		mk.position = Vector2(-26.0 + 18.0 * float(i % 2) + randf_range(-3, 3), -34.0 + 66.0 * float(i / 2) + randf_range(-3, 3))
		mk.scale = Vector2.ONE * randf_range(0.7, 1.05)
		add_child(mk)
		_marks.append(mk)
	# ---- respingo de veneno no impacto
	for i in 10:
		var sp := Sprite2D.new()
		sp.texture = Vfx.spark(20, Color(0.55, 1.0, 0.30))
		sp.material = Vfx.add_mat()
		sp.modulate = Color(1, 1, 1, 0)
		add_child(sp)
		_splash.append({
			"n": sp,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, 0.4)).normalized(),
			"sp": randf_range(120.0, 300.0),
			"sc": randf_range(0.6, 1.5),
		})
	# ---- névoa tóxica (dissolução) e gotas de veneno
	_mist = CPUParticles2D.new()
	_mist.texture = Vfx.radial("mord_mist", 60, Color(0.30, 0.75, 0.15, 0.45), 0.05)
	_mist.emitting = false
	_mist.amount = 40
	_mist.lifetime = 0.9
	_mist.direction = Vector2(0, -1)
	_mist.spread = 40.0
	_mist.initial_velocity_min = 20.0
	_mist.initial_velocity_max = 55.0
	_mist.gravity = Vector2(0, -10)
	_mist.scale_amount_min = 1.4
	_mist.scale_amount_max = 3.0
	add_child(_mist)
	_drips = CPUParticles2D.new()
	_drips.texture = Vfx.spark(14, Color(0.45, 0.95, 0.25))
	_drips.material = Vfx.add_mat()
	_drips.emitting = false
	_drips.amount = 24
	_drips.lifetime = 0.55
	_drips.direction = Vector2(0, 1)
	_drips.spread = 25.0
	_drips.initial_velocity_min = 40.0
	_drips.initial_velocity_max = 120.0
	_drips.gravity = Vector2(0, 420)
	_drips.scale_amount_min = 0.5
	_drips.scale_amount_max = 1.1
	_drips.position = Vector2(0, -10)
	add_child(_drips)


func _make_mark() -> ImageTexture:
	# marca de presa: losango alongado com brilho verde
	var img := Image.create(24, 40, false, Image.FORMAT_RGBA8)
	for y in 40:
		for x in 24:
			var dx := absf(float(x) - 12.0) / 12.0
			var dy := absf(float(y) - 20.0) / 20.0
			var d := dx + dy
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 1.6)
			img.set_pixel(x, y, Color(0.62, 1.0, 0.35, a))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ============ abertura ameaçadora (0 .. APPEAR_END)
	var ak: float = clampf(t / APPEAR_END, 0.0, 1.0)
	var jaw_a: float
	var jaw_sc: float
	var jaw_y: float
	if t < SNAP1_AT:
		jaw_a = Ease.out_cubic(ak)
		jaw_sc = lerpf(0.62, 1.06, Ease.out_cubic(ak))
		jaw_y = lerpf(-150.0, -46.0, Ease.out_cubic(ak))
	elif t < SNAP2_AT:
		# bote seco: semi-fechada avançando
		jaw_a = 1.0
		jaw_sc = 1.12
		jaw_y = -40.0
	elif t < DISSOLVE_AT:
		# cravada: tremor de rosnado
		jaw_a = 1.0
		jaw_sc = 0.98 + 0.03 * sin(t * 42.0)
		jaw_y = -34.0 + randf_range(-1.5, 1.5)
	else:
		# dissolvendo em névoa
		jaw_a = clampf(1.0 - (t - DISSOLVE_AT) / 0.4, 0.0, 1.0)
		jaw_sc = lerpf(0.98, 1.25, (t - DISSOLVE_AT) / 0.4)
		jaw_y = -34.0
	var want: Texture2D = TEX_F1
	if t >= DISSOLVE_AT:
		want = TEX_F4
	elif t >= SNAP2_AT:
		want = TEX_F3
	elif t >= SNAP1_AT:
		want = TEX_F2
	if _jaw.texture != want:
		_jaw.texture = want
	_jaw.modulate = Color(0.95, 1.05, 0.92, jaw_a)
	_jaw.scale = Vector2(jaw_sc, jaw_sc)
	_jaw.position = Vector2(randf_range(-1, 1) * 1.2 * (1.0 if t >= SNAP2_AT and t < DISSOLVE_AT else 0.0), jaw_y)
	# rastros de velocidade só no bote
	var streak_a: float = 0.0
	if t >= SNAP1_AT - 0.08 and t < SNAP2_AT + 0.10:
		streak_a = 0.8
	for i in _streaks.size():
		var st: Sprite2D = _streaks[i]
		st.modulate = Color(1, 1, 1, streak_a * randf_range(0.5, 1.0))
		st.position.y = lerpf(-160.0, -60.0, clampf((t - SNAP1_AT + 0.08) / 0.2, 0.0, 1.0))
	# ============ presença tóxica
	_ground.modulate = Color(1, 1, 1, ak * 0.7 * (0.7 + 0.3 * sin(t * 8.0)))
	_glow.modulate = Color(1, 1, 1, ak * (0.45 + 0.2 * sin(t * 11.0)) + (0.4 if t >= SNAP2_AT else 0.0))
	var pool_on: float = clampf((t - SNAP2_AT) / 0.3, 0.0, 1.0) * clampf(1.0 - (t - DISSOLVE_AT) / 0.5, 0.0, 1.0)
	_pool.modulate = Color(1, 1, 1, pool_on * 0.7)
	_pool.scale = Vector2(0.7 + pool_on * 0.6, 0.22 + pool_on * 0.16)
	# gotas de veneno enquanto cravada
	if t >= SNAP2_AT and t < DISSOLVE_AT:
		_drips.emitting = true
	else:
		_drips.emitting = false
	# névoa na dissolução
	if t >= DISSOLVE_AT - 0.15:
		_mist.emitting = true
	# ============ IMPACTO (SNAP2_AT)
	if t >= SNAP2_AT and not _impacted:
		_impacted = true
	for i in _splash.size():
		var sp: Dictionary = _splash[i]
		var n: Sprite2D = sp["n"]
		var st: float = t - SNAP2_AT
		var life := 0.5
		if st < 0.0 or st > life:
			n.modulate = Color(1, 1, 1, 0)
			continue
		n.position = Vector2(0, -30) + sp["dir"] * sp["sp"] * st + Vector2(0, 260.0 * st * st)
		n.scale = Vector2.ONE * sp["sc"]
		n.modulate = Color(1, 1, 1, clampf(1.0 - st / life, 0.0, 1.0))
	var ik: float = clampf((t - SNAP2_AT) / 0.18, 0.0, 1.0)
	var iff: float = clampf(1.0 - (t - SNAP2_AT - 0.18) / 0.22, 0.0, 1.0)
	if t >= SNAP2_AT:
		_flash.modulate = Color(1, 1, 1, ik * iff * 0.9)
		_flash.scale = Vector2.ONE * (0.5 + ik * 1.1)
		_ring.modulate = Color(1, 1, 1, ik * iff)
		_ring.scale = Vector2(1.0, 0.55) * (0.3 + ik * 1.7)
		for i in _marks.size():
			var mk: Sprite2D = _marks[i]
			var ma: float = clampf((t - SNAP2_AT - 0.05) / 0.12, 0.0, 1.0) * clampf(1.0 - (t - DISSOLVE_AT) / 0.35, 0.0, 1.0)
			mk.modulate = Color(1, 1, 1, ma * 0.85)
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv
