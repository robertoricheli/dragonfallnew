class_name MordidaFX
extends Node2D
## (1.49.93) MORDIDA VENENOSA AAA — a cabeça da SERPENTE VENENOSA (arte pintada
## estilo Hearthstone, assets/MANDIBULA_VENENO.png) surge do alto com a boca
## escancarada, faz o BOTE sobre o Campeão alvo e CRAVA AS PRESAS: clarão
## verde, anel de choque, respingos de veneno, marcas de presa na carta, baba
## escorrendo e névoa tóxica; então recua para o céu. ~1,6 s; emite `finished`
## (a batalha aplica ENVENENADO via state.resolve_mordida).
## Uso: add_child(fx); fx.setup(pos_global_centro, [view_alvo])

signal finished

const DUR := 1.6
const LUNGE_AT := 0.22
const CHOMP_AT := 0.42

var _t := 0.0
var _done := false
var _started := false

var _jaw: Sprite2D
var _glow: Sprite2D
var _ground: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _pool: Sprite2D
var _streaks: Array = []
var _marks: Array = []
var _drops: Array = []
var _drips: Array = []
var _puffs: Array = []

const JAW_TEX := preload("res://assets/MANDIBULA_VENENO.png")

static var _mark_tex: ImageTexture


static func _make_mark() -> ImageTexture:
	## Marca de presa: ponto de veneno com halo.
	if _mark_tex != null:
		return _mark_tex
	var S := 22
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S * 0.5, S * 0.5)
	for y in range(S):
		for x in range(S):
			var d := (Vector2(float(x), float(y)) - c).length()
			var core := smoothstep(4.5, 1.2, d)
			var halo := smoothstep(10.0, 4.5, d) * 0.5
			var m := clampf(core + halo, 0.0, 1.0)
			if m <= 0.01:
				continue
			img.set_pixel(x, y, Color(0.55 + 0.4 * core, 1.0, 0.28, m * 0.92))
	_mark_tex = ImageTexture.create_from_image(img)
	return _mark_tex


func setup(at: Vector2, _target: Node = null) -> void:
	position = at
	z_index = 89
	_started = true
	# ----.presença: poça de veneno no chão + brilho sinistro sobre a carta
	_ground = Sprite2D.new()
	_ground.texture = Vfx.ring("mord_ground", 140, Color(0.45, 1.0, 0.25, 0.8), 0.09)
	_ground.material = Vfx.add_mat()
	_ground.scale = Vector2(1.0, 0.32)
	_ground.position = Vector2(0, 60)
	_ground.modulate = Color(1, 1, 1, 0)
	add_child(_ground)
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("mord_glow", 190, Color(0.35, 0.95, 0.18, 0.5), 0.08)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	add_child(_glow)
	_pool = Sprite2D.new()
	_pool.texture = Vfx.radial("mord_pool", 130, Color(0.30, 0.80, 0.12, 0.55), 0.1)
	_pool.material = Vfx.add_mat()
	_pool.scale = Vector2(1.0, 0.3)
	_pool.position = Vector2(0, 62)
	_pool.modulate = Color(1, 1, 1, 0)
	add_child(_pool)
	# ---- a cabeça da serpente
	_jaw = Sprite2D.new()
	_jaw.texture = JAW_TEX
	_jaw.modulate = Color(1, 1, 1, 0)
	_jaw.scale = Vector2(0.46, 0.46)
	_jaw.position = Vector2(0, -250)
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
	_flash.texture = Vfx.radial("mord_flash", 230, Color(0.70, 1.0, 0.40, 0.9), 0.18)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("mord_ring", 130, Color(0.55, 1.0, 0.30, 0.9), 0.06)
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
	for i in 8:
		var dr := Sprite2D.new()
		dr.texture = Vfx.radial("mord_drop", 14, Color(0.60, 1.0, 0.32, 0.95), 0.45)
		dr.material = Vfx.add_mat()
		dr.modulate = Color(1, 1, 1, 0)
		add_child(dr)
		var ang := randf() * TAU
		_drops.append({"n": dr, "v": Vector2(cos(ang), sin(ang)) * randf_range(90.0, 220.0), "dl": randf_range(0.0, 0.1)})
	# ---- baba escorrendo das presas após a mordida
	for i in 3:
		var dp := Sprite2D.new()
		dp.texture = Vfx.radial("mord_drip", 12, Color(0.62, 1.0, 0.34, 0.95), 0.4)
		dp.material = Vfx.add_mat()
		dp.modulate = Color(1, 1, 1, 0)
		add_child(dp)
		_drips.append({"n": dp, "x": -22.0 + 22.0 * float(i), "dl": 0.52 + 0.13 * float(i)})
	# ---- névoa tóxica subindo
	for i in 4:
		var pf := Sprite2D.new()
		pf.texture = Vfx.radial("mord_puff", 80, Color(0.30, 0.75, 0.15, 0.42), 0.05)
		pf.material = Vfx.add_mat()
		pf.modulate = Color(1, 1, 1, 0)
		add_child(pf)
		_puffs.append({"n": pf, "dx": randf_range(-30.0, 30.0), "dy": randf_range(-52.0, -30.0), "dl": randf_range(0.45, 0.85)})


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---------------- presença sinistra (0 .. LUNGE)
	var pa: float = clampf(t / 0.16, 0.0, 1.0)
	var pf: float = clampf(1.0 - (t - CHOMP_AT) / 0.5, 0.0, 1.0) if t > CHOMP_AT else 1.0
	_glow.modulate = Color(1, 1, 1, pa * pf * (0.45 + 0.25 * sin(t * 18.0)))
	_ground.modulate = Color(1, 1, 1, pa * pf * 0.7)
	_ground.scale = Vector2(1.0, 0.32) * (0.6 + 0.4 * pa + 0.05 * sin(t * 10.0))
	# ---------------- surgimento + BOTE (LUNGE .. CHOMP)
	if t < LUNGE_AT:
		var sk: float = clampf(t / LUNGE_AT, 0.0, 1.0)
		_jaw.modulate = Color(1, 1, 1, sk * 0.95)
		_jaw.position = Vector2(0, lerpf(-250.0, -190.0, sk))
		_jaw.scale = Vector2.ONE * lerpf(0.34, 0.42, sk)
	else:
		var lk: float = clampf((t - LUNGE_AT) / (CHOMP_AT - LUNGE_AT), 0.0, 1.0)
		var lk_e: float = lk * lk   # acelera no bote
		for s in _streaks:
			var sn: Sprite2D = s
			sn.modulate = Color(1, 1, 1, sin(lk * PI) * 0.7)
			sn.position.y = lerpf(-220.0, -40.0, lk_e)
		if t < CHOMP_AT:
			_jaw.position = Vector2(sin(lk * 9.0) * 2.0, lerpf(-190.0, -4.0, lk_e))
			_jaw.scale = Vector2.ONE * lerpf(0.42, 0.50, lk_e)
			_jaw.modulate = Color(1, 1, 1, 0.95)
			_jaw.rotation = sin(lk * 6.0) * 0.03
	# ---------------- CRAVADA DAS PRESAS (CHOMP ..)
	if t >= CHOMP_AT:
		var it: float = t - CHOMP_AT
		# squash da mordida + tremor segurando a presa
		var sq: float = 1.0 - 0.20 * clampf(1.0 - it / 0.12, 0.0, 1.0)
		var jit: float = clampf(1.0 - it / 0.35, 0.0, 1.0)
		var recuo: float = 0.0
		if t > 0.95:
			var rt: float = clampf((t - 0.95) / 0.4, 0.0, 1.0)
			recuo = -266.0 * (rt * rt)
		_jaw.position = Vector2(randf_range(-1.6, 1.6) * jit, -4.0 + recuo + randf_range(-1.2, 1.2) * jit)
		_jaw.scale = Vector2(0.50 * (2.0 - sq), 0.50 * sq)
		var jaw_f: float = clampf(1.0 - (t - 1.05) / 0.3, 0.0, 1.0) if t > 1.05 else 1.0
		_jaw.modulate = Color(1, 1, 1, jaw_f * 0.95)
		# clarão + anel
		var fk: float = clampf(1.0 - it / 0.26, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, fk * fk * 0.95)
		_flash.scale = Vector2.ONE * (0.55 + (1.0 - fk) * 0.95)
		var rk: float = clampf(it / 0.45, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.9)
		_ring.scale = Vector2(1.0, 0.75) * (0.3 + rk * 1.8)
		# marcas de presa cravadas
		for m in _marks:
			var mn: Sprite2D = m
			var mf: float = clampf(1.0 - (it - 0.55) / 0.5, 0.0, 1.0) if it > 0.55 else 1.0
			mn.modulate = Color(1, 1, 1, clampf(it / 0.05, 0.0, 1.0) * mf * 0.95)
		# respingos
		for d in _drops:
			var n: Sprite2D = d["n"]
			var dt: float = maxf(0.0, it - float(d["dl"]))
			var vv: Vector2 = d["v"]
			n.position = vv * dt + Vector2(0, 190.0) * dt * dt
			n.modulate = Color(1, 1, 1, clampf(1.0 - dt / 0.5, 0.0, 1.0) * 0.9)
		# baba caindo das presas
		for dr in _drips:
			var dn: Sprite2D = dr["n"]
			var dtt: float = maxf(0.0, t - float(dr["dl"]))
			dn.position = Vector2(float(dr["x"]) + sin(dtt * 8.0) * 1.5, 26.0 + 150.0 * dtt * dtt)
			dn.scale = Vector2(0.8, 0.8 + dtt * 1.6)
			dn.modulate = Color(1, 1, 1, clampf(dtt / 0.05, 0.0, 1.0) * clampf(1.0 - dtt / 0.6, 0.0, 1.0) * 0.85)
		# poça + névoa tóxica
		var pk: float = clampf(it / 0.3, 0.0, 1.0)
		var pf2: float = clampf(1.0 - (it - 0.75) / 0.45, 0.0, 1.0) if it > 0.75 else 1.0
		_pool.modulate = Color(1, 1, 1, pk * pf2 * 0.7)
		_pool.scale = Vector2(1.0, 0.3) * (0.5 + pk * 0.6)
		for p in _puffs:
			var pn: Sprite2D = p["n"]
			var pt: float = maxf(0.0, it - float(p["dl"]))
			pn.position = Vector2(float(p["dx"]) * pt * 1.3, float(p["dy"]) * pt)
			pn.scale = Vector2.ONE * (0.6 + pt * 1.6)
			pn.modulate = Color(1, 1, 1, clampf(pt / 0.1, 0.0, 1.0) * clampf(1.0 - pt / 0.7, 0.0, 1.0) * 0.7)
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
