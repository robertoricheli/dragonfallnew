class_name DefensorFX
extends Node2D
## (1.49.93) HABILIDADE DEFENSOR — animação defensiva épica (1,5 s) sobre o
## Campeão recém-invocado, estilo Hearthstone: runas douradas girando no chão,
## faíscas convergindo, DOMO de energia dourada varrendo de baixo para cima com
## clarão e brasão de luz, feixes verticais e poeira dourada subindo.
## A Proteção (ícone no canto) é aplicada pela Tela de Combate 0,5 s após o
## INÍCIO desta animação (state.resolve_defensor).
## Uso: add_child(fx); fx.setup(pos_global_centro_carta)

signal finished

const DUR := 1.5

var _t := 0.0
var _done := false
var _started := false

var _rune: Sprite2D
var _rune2: Sprite2D
var _dome: Sprite2D
var _rim: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _emblem: Sprite2D
var _dust: CPUParticles2D
var _converge: Array = []
var _streaks: Array = []


static func _beam_tex() -> ImageTexture:
	## Feixe vertical dourado (bordas suaves) p/ listras de luz do domo.
	var key := "def_streak"
	if Vfx._cache.has(key):
		return Vfx._cache[key]
	var W := 16
	var H := 120
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in range(H):
		for x in range(W):
			var u: float = float(x) / float(W - 1)
			var v: float = float(y) / float(H - 1)
			var side: float = pow(clampf(1.0 - absf(u - 0.5) * 2.0, 0.0, 1.0), 1.8)
			var tip: float = smoothstep(0.0, 0.25, v) * smoothstep(1.0, 0.7, v)
			var a: float = side * tip * 0.85
			if a <= 0.01:
				continue
			img.set_pixel(x, y, Color(1.0, 0.85, 0.42, a))
	var tex := ImageTexture.create_from_image(img)
	Vfx._cache[key] = tex
	return tex


func setup(at: Vector2) -> void:
	position = at
	z_index = 88
	_started = true
	# ---- runas no chão (duas rodas douradas girando em sentidos opostos)
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("def_rune", 150, Color(1.0, 0.80, 0.30, 0.95), 0.10)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.25, 0.42)
	_rune.position = Vector2(0, 52)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	_rune2 = Sprite2D.new()
	_rune2.texture = Vfx.ring("def_rune2", 108, Color(1.0, 0.90, 0.55, 0.9), 0.16)
	_rune2.material = Vfx.add_mat()
	_rune2.scale = Vector2(0.95, 0.32)
	_rune2.position = Vector2(0, 52)
	_rune2.modulate = Color(1, 1, 1, 0)
	add_child(_rune2)
	# ---- domo de energia (brilho esférico) + aro vivo
	_dome = Sprite2D.new()
	_dome.texture = Vfx.radial("def_dome", 220, Color(1.0, 0.82, 0.35, 0.55), 0.05)
	_dome.material = Vfx.add_mat()
	_dome.modulate = Color(1, 1, 1, 0)
	_dome.scale = Vector2(0.2, 0.2)
	add_child(_dome)
	_rim = Sprite2D.new()
	_rim.texture = Vfx.ring("def_rim", 210, Color(1.0, 0.88, 0.45, 0.95), 0.05)
	_rim.material = Vfx.add_mat()
	_rim.modulate = Color(1, 1, 1, 0)
	_rim.scale = Vector2(0.2, 0.2)
	add_child(_rim)
	# ---- clarão + anel de choque do selamento
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("def_flash", 260, Color(1.0, 0.92, 0.60, 0.9), 0.15)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("def_ring", 150, Color(1.0, 0.85, 0.40, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	# ---- brasão de luz (estrela dourada) no peito da carta
	_emblem = Sprite2D.new()
	_emblem.texture = Vfx.spark(120, Color(1.0, 0.90, 0.50, 0.95))
	_emblem.material = Vfx.add_mat()
	_emblem.modulate = Color(1, 1, 1, 0)
	_emblem.scale = Vector2(0.6, 0.6)
	add_child(_emblem)
	# ---- faíscas convergindo (0 .. 0,3 s)
	for i in 10:
		var sp := Sprite2D.new()
		sp.texture = Vfx.spark(int(randf_range(10, 18)), Color(1.0, 0.88, 0.45, 0.95))
		sp.material = Vfx.add_mat()
		sp.modulate = Color(1, 1, 1, 0)
		add_child(sp)
		var ang := TAU * float(i) / 10.0 + randf_range(-0.25, 0.25)
		_converge.append({"n": sp, "a": ang, "r0": randf_range(95.0, 130.0), "d": randf_range(0.0, 0.12)})
	# ---- feixes verticais de luz ao redor da carta
	for i in 6:
		var st := Sprite2D.new()
		st.texture = _beam_tex()
		st.material = Vfx.add_mat()
		st.modulate = Color(1, 1, 1, 0)
		st.position = Vector2(-42.0 + 17.0 * float(i) + randf_range(-3, 3), randf_range(-16, 8))
		st.scale = Vector2(1.0, randf_range(0.7, 1.15))
		add_child(st)
		_streaks.append({"n": st, "d": randf_range(0.0, 0.35)})
	# ---- poeira dourada subindo
	_dust = CPUParticles2D.new()
	_dust.material = Vfx.add_mat()
	_dust.texture = Vfx.radial("def_dust", 14, Color(1.0, 0.86, 0.45, 0.95), 0.4)
	_dust.emitting = false
	_dust.amount = 42
	_dust.lifetime = 0.8
	_dust.direction = Vector2(0, -1)
	_dust.spread = 24.0
	_dust.initial_velocity_min = 40.0
	_dust.initial_velocity_max = 95.0
	_dust.gravity = Vector2(0, -18)
	_dust.scale_amount_min = 0.6
	_dust.scale_amount_max = 1.5
	var cg := Gradient.new()
	cg.offsets = [0.0, 0.35, 1.0]
	cg.colors = [Color(1, 0.95, 0.7, 0.0), Color(1, 0.88, 0.45, 0.9), Color(1, 0.7, 0.25, 0.0)]
	_dust.color_ramp = cg
	add_child(_dust)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---------------- runas girando no chão (0 .. fim)
	var ra: float = clampf(t / 0.22, 0.0, 1.0)
	var rf: float = clampf(1.0 - (t - 1.15) / 0.35, 0.0, 1.0) if t > 1.15 else 1.0
	_rune.modulate = Color(1, 1, 1, ra * rf * (0.75 + 0.15 * sin(t * 9.0)))
	_rune.rotation += delta * 1.4
	_rune2.modulate = Color(1, 1, 1, ra * rf * 0.7)
	_rune2.rotation -= delta * 2.2
	# ---------------- faíscas convergindo (0 .. 0,35)
	for c in _converge:
		var n: Sprite2D = c["n"]
		var ct: float = clampf((t - float(c["d"])) / 0.3, 0.0, 1.0)
		if ct <= 0.0 or ct >= 1.0:
			n.modulate = Color(1, 1, 1, 0) if ct >= 1.0 else n.modulate
			continue
		var r: float = lerpf(float(c["r0"]), 12.0, ct * ct)
		n.position = Vector2.from_angle(float(c["a"]) + ct * 1.2) * Vector2(r, r * 0.75)
		n.modulate = Color(1, 1, 1, sin(ct * PI) * 0.95)
	# ---------------- domo varrendo (0,25 .. 1,5)
	if t > 0.25:
		var dk: float = clampf((t - 0.25) / 0.3, 0.0, 1.0)
		var dk_e: float = dk * dk * (3.0 - 2.0 * dk)
		var dfade: float = clampf(1.0 - (t - 1.1) / 0.4, 0.0, 1.0) if t > 1.1 else 1.0
		var pulse: float = 0.5 + 0.14 * sin(t * 14.0)
		_dome.modulate = Color(1, 1, 1, dk_e * pulse * dfade)
		_dome.scale = Vector2.ONE * lerpf(0.25, 1.0, dk_e) * Vector2(1.0, 1.12)
		_rim.modulate = Color(1, 1, 1, dk_e * (0.85 + 0.15 * sin(t * 18.0 + 1.0)) * dfade)
		_rim.scale = Vector2.ONE * lerpf(0.25, 0.98, dk_e) * Vector2(1.0, 1.12)
	# ---------------- clarão + anel + brasão no selamento (0,5)
	if t > 0.5:
		var it: float = t - 0.5
		var fk: float = clampf(1.0 - it / 0.3, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, fk * fk * 0.95)
		_flash.scale = Vector2.ONE * (0.6 + (1.0 - fk) * 0.9)
		var rk: float = clampf(it / 0.5, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.9)
		_ring.scale = Vector2(1.0, 0.8) * (0.3 + rk * 1.9)
		var ek: float = clampf(it / 0.12, 0.0, 1.0)
		var ef: float = clampf(1.0 - (it - 0.35) / 0.45, 0.0, 1.0) if it > 0.35 else 1.0
		_emblem.modulate = Color(1, 1, 1, ek * ef * 0.95)
		_emblem.scale = Vector2.ONE * (0.45 + ek * 0.55) * (1.0 + 0.06 * sin(t * 22.0))
		_emblem.rotation += delta * 0.8
	# ---------------- feixes verticais (0,35 .. 1,15)
	for s in _streaks:
		var n2: Sprite2D = s["n"]
		var st0: float = 0.35 + float(s["d"])
		var st: float = t - st0
		if st <= 0.0:
			continue
		var lf: float = clampf(st / 0.12, 0.0, 1.0) * clampf(1.0 - (st - 0.45) / 0.3, 0.0, 1.0)
		n2.modulate = Color(1, 1, 1, lf * 0.75)
		n2.position.y -= delta * 46.0
	# ---------------- poeira dourada
	if t > 0.3 and t < 1.25 and not _dust.emitting:
		_dust.emitting = true
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
