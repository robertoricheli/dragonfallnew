class_name MordidaFX
extends Node2D
## (1.49.95) MORDIDA VENENOSA — refeita com a SERPENTE MÁGICA VERDE pintada
## (asset SERPENTE_VENENO.png, arte fornecida pelo dono, estilo Hearthstone):
## a serpente NASCE da carta Campeão em campo (fade + scale-in com névoa
## tóxica), DESLIZA pelo campo em curva bezier com ondulação lateral e rastro
## de vapores (nunca maior que uma carta em campo: máx. ~132 px), faz uma
## pausa curta mirando e então dá o BOTE (ease-in rápido com punch de escala)
## cravando a mordida no campeão alvo: clarão local, anel, marcas de presa,
## respingos e poça de veneno; depois dissolve em névoa tóxica.
## DURAÇÃO 2,0 s (regra do dono). Contrato: finished -> resolve_mordida.
## Uso: add_child(fx); fx.setup(centro_da_carta_origem, centro_do_alvo)

signal finished

const DUR := 2.0
const EMERGE_END := 0.35     # nasce da carta de origem
const GLIDE_END := 1.30      # desliza pelo campo até perto do alvo
const STRIKE_AT := 1.50      # bote + impacto
const TEX_SZ := 1254.0
const SCALE_BASE := 0.095    # 1254 * 0.095 = ~119 px (< carta 140 px)
const SCALE_STRIKE := 0.105  # punch do bote: ~132 px (ainda < carta)

var _t := 0.0
var _done := false
var _started := false
var _impacted := false

var _from := Vector2.ZERO
var _dst := Vector2.ZERO
var _mid := Vector2.ZERO

var _serp: Sprite2D
var _glow: Sprite2D
var _trail: CPUParticles2D
var _mist: CPUParticles2D
var _flash: Sprite2D
var _ring: Sprite2D
var _pool: Sprite2D
var _marks: Array = []
var _splash: Array = []

const SERP_TEX := preload("res://assets/SERPENTE_VENENO.png")


func setup(src: Vector2, dst: Vector2) -> void:
	_from = src
	_dst = dst
	position = Vector2.ZERO
	z_index = 89
	_started = true
	# curva do deslizamento: arco perpendicular entre origem e alvo
	var dir := (dst - src)
	var perp := dir.orthogonal().normalized()
	_mid = (src + dst) / 2.0 + perp * clampf(dir.length() * 0.22, 26.0, 70.0)
	# ---- brilho tóxico na origem
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("mord2_glow", 130, Color(0.35, 0.95, 0.18, 0.55), 0.09)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	_glow.position = src
	add_child(_glow)
	# ---- a serpente mágica
	_serp = Sprite2D.new()
	_serp.texture = SERP_TEX
	_serp.centered = true
	_serp.scale = Vector2(0.03, 0.03)
	_serp.modulate = Color(1, 1, 1, 0)
	_serp.position = src
	add_child(_serp)
	# ---- rastro de vapores (filho da serpente: segue junto)
	_trail = CPUParticles2D.new()
	_trail.texture = Vfx.radial("mord2_trail", 40, Color(0.30, 0.80, 0.15, 0.4), 0.05)
	_trail.emitting = false
	_trail.amount = 22
	_trail.lifetime = 0.55
	_trail.direction = Vector2(0, 1)
	_trail.spread = 30.0
	_trail.initial_velocity_min = 8.0
	_trail.initial_velocity_max = 26.0
	_trail.gravity = Vector2(0, -14)
	_trail.scale_amount_min = 0.8
	_trail.scale_amount_max = 1.8
	_serp.add_child(_trail)
	_trail.position = Vector2(0, 30)
	# ---- névoa da dissolução final
	_mist = CPUParticles2D.new()
	_mist.texture = Vfx.radial("mord2_mist", 50, Color(0.30, 0.75, 0.15, 0.45), 0.05)
	_mist.emitting = false
	_mist.amount = 26
	_mist.lifetime = 0.6
	_mist.direction = Vector2(0, -1)
	_mist.spread = 60.0
	_mist.initial_velocity_min = 16.0
	_mist.initial_velocity_max = 44.0
	_mist.gravity = Vector2(0, -12)
	_mist.scale_amount_min = 1.0
	_mist.scale_amount_max = 2.2
	add_child(_mist)
	# ---- kit de impacto (local, no alvo)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("mord2_flash", 160, Color(0.70, 1.0, 0.40, 0.9), 0.2)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	_flash.position = dst
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("mord2_ring", 110, Color(0.55, 1.0, 0.30, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.position = dst
	add_child(_ring)
	_pool = Sprite2D.new()
	_pool.texture = Vfx.radial("mord2_pool", 110, Color(0.30, 0.80, 0.12, 0.5), 0.1)
	_pool.material = Vfx.add_mat()
	_pool.scale = Vector2(1.0, 0.3)
	_pool.modulate = Color(1, 1, 1, 0)
	_pool.position = dst + Vector2(0, 56)
	add_child(_pool)
	var mtex: ImageTexture = _make_mark()
	for i in 4:
		var mk := Sprite2D.new()
		mk.texture = mtex
		mk.material = Vfx.add_mat()
		mk.modulate = Color(1, 1, 1, 0)
		mk.position = dst + Vector2(-20.0 + 14.0 * float(i % 2) + randf_range(-3, 3), -26.0 + 52.0 * float(i / 2) + randf_range(-3, 3))
		mk.scale = Vector2.ONE * randf_range(0.6, 0.9)
		add_child(mk)
		_marks.append(mk)
	for i in 8:
		var sp := Sprite2D.new()
		sp.texture = Vfx.spark(18, Color(0.55, 1.0, 0.30))
		sp.material = Vfx.add_mat()
		sp.modulate = Color(1, 1, 1, 0)
		add_child(sp)
		_splash.append({
			"n": sp,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, 0.3)).normalized(),
			"sp": randf_range(90.0, 200.0),
			"sc": randf_range(0.5, 1.2),
		})


func _make_mark() -> ImageTexture:
	var img := Image.create(24, 40, false, Image.FORMAT_RGBA8)
	for y in 40:
		for x in 24:
			var dx := absf(float(x) - 12.0) / 12.0
			var dy := absf(float(y) - 20.0) / 20.0
			var a := pow(clampf(1.0 - (dx + dy), 0.0, 1.0), 1.6)
			img.set_pixel(x, y, Color(0.62, 1.0, 0.35, a))
	return ImageTexture.create_from_image(img)


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, k: float) -> Vector2:
	var a := p0.lerp(p1, k)
	var b := p1.lerp(p2, k)
	return a.lerp(b, k)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ================= 0 .. EMERGE_END: nasce da carta de origem
	var ek: float = clampf(t / EMERGE_END, 0.0, 1.0)
	var serp_a := 1.0
	var serp_sc := SCALE_BASE
	var pos := _from
	var rot := 0.0
	if t < EMERGE_END:
		serp_a = Ease.out_cubic(ek)
		serp_sc = lerpf(0.03, SCALE_BASE, Ease.out_cubic(ek))
		pos = _from + Vector2(0, lerpf(18.0, -6.0, ek))
		_glow.modulate = Color(1, 1, 1, sin(ek * PI) * 0.8)
	elif t < GLIDE_END:
		# ============ desliza pelo campo em curva com ondulação
		var gk: float = (t - EMERGE_END) / (GLIDE_END - EMERGE_END)
		pos = _bezier(_from + Vector2(0, -6), _mid, _dst + Vector2(0, -34), gk)
		var ahead := _bezier(_from + Vector2(0, -6), _mid, _dst + Vector2(0, -34), minf(1.0, gk + 0.06))
		var vel := ahead - pos
		if vel.length() > 0.01:
			rot = clampf(vel.angle() * 0.18, -0.35, 0.35) + sin(t * 9.0) * 0.10
		serp_sc = SCALE_BASE * (1.0 + 0.04 * sin(t * 11.0))
		if not _trail.emitting:
			_trail.emitting = true
		_glow.modulate = Color(1, 1, 1, clampf(1.0 - gk * 1.6, 0.0, 1.0) * 0.6)
	elif t < STRIKE_AT:
		# ============ mira curta pairando sobre o alvo
		var mk2: float = (t - GLIDE_END) / (STRIKE_AT - GLIDE_END)
		pos = (_dst + Vector2(0, -34)).lerp(_dst + Vector2(0, -46), Ease.out_cubic(mk2))
		rot = sin(t * 14.0) * 0.06
		serp_sc = SCALE_BASE * lerpf(1.0, 0.92, mk2)   # arma o bote
		_glow.modulate = Color(1, 1, 1, 0)
	else:
		# ============ BOTE + mordida + dissolução
		var sk: float = clampf((t - STRIKE_AT) / 0.14, 0.0, 1.0)
		var dk: float = clampf((t - STRIKE_AT - 0.14) / 0.36, 0.0, 1.0)
		pos = (_dst + Vector2(0, -46)).lerp(_dst + Vector2(0, -6), Ease.in_cubic(sk))
		serp_sc = lerpf(SCALE_BASE * 0.92, SCALE_STRIKE, Ease.in_cubic(sk)) * lerpf(1.0, 0.85, dk)
		serp_a = 1.0 - dk
		rot = 0.0
		if dk > 0.0 and not _mist.emitting:
			_mist.emitting = true
			_mist.position = _dst
			_trail.emitting = false
	# aplica serpente
	_serp.modulate = Color(0.96, 1.05, 0.94, serp_a)
	_serp.scale = Vector2(serp_sc, serp_sc)
	_serp.position = pos
	_serp.rotation = rot
	_serp.flip_h = (_dst.x - _from.x) < 0.0
	# ================= impacto em STRIKE_AT
	if t >= STRIKE_AT and not _impacted:
		_impacted = true
	for i in _splash.size():
		var sp: Dictionary = _splash[i]
		var n: Sprite2D = sp["n"]
		var st: float = t - STRIKE_AT
		var life := 0.45
		if st < 0.0 or st > life:
			n.modulate = Color(1, 1, 1, 0)
			continue
		n.position = _dst + sp["dir"] * sp["sp"] * st + Vector2(0, 220.0 * st * st)
		n.scale = Vector2.ONE * sp["sc"]
		n.modulate = Color(1, 1, 1, clampf(1.0 - st / life, 0.0, 1.0))
	if t >= STRIKE_AT:
		var ik: float = clampf((t - STRIKE_AT) / 0.14, 0.0, 1.0)
		var iff: float = clampf(1.0 - (t - STRIKE_AT - 0.14) / 0.2, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, ik * iff * 0.85)
		_flash.scale = Vector2.ONE * (0.5 + ik * 0.8)
		_ring.modulate = Color(1, 1, 1, ik * iff * 0.9)
		_ring.scale = Vector2(1.0, 0.5) * (0.3 + ik * 1.1)
		var pool_a: float = clampf((t - STRIKE_AT) / 0.25, 0.0, 1.0) * clampf(1.0 - (t - STRIKE_AT - 0.25) / 0.25, 0.0, 1.0)
		_pool.modulate = Color(1, 1, 1, pool_a * 0.65)
		for i in _marks.size():
			var mk3: Sprite2D = _marks[i]
			var ma: float = clampf((t - STRIKE_AT - 0.04) / 0.1, 0.0, 1.0) * clampf(1.0 - (t - STRIKE_AT - 0.3) / 0.2, 0.0, 1.0)
			mk3.modulate = Color(1, 1, 1, ma * 0.8)
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv

	static func in_cubic(x: float) -> float:
		return x * x * x
