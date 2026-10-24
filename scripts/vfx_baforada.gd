class_name BaforadaFX
extends Node2D
## (1.49.93) BAFORADA VENENOSA — o SOPRO DO DRAGÃO VERDE de verdade: após a
## carga na origem, um CONE SUSTENTADO de fogo verde (línguas de chama
## turbulentas, núcleo incandescente, fumaça escura e brasas) jorra da origem
## e ENGOLFA o Campeão alvo com chamas lambendo a carta; quando o sopro cessa,
## restam clarão, anel de choque, respingos de veneno e névoa tóxica.
## ~1,7 s; emite `finished` (a batalha aplica ENVENENADO via resolve_baforada).
## Uso: add_child(fx); fx.setup(origem, alvo)

signal finished

const CHARGE := 0.22
const BREATH_END := 1.2
const DUR := 1.7

var _t := 0.0
var _done := false
var _impacted := false
var _started := false
var _from := Vector2.ZERO
var _at := Vector2.ZERO
var _dist := 100.0
var _ang := 0.0

var _pivot: Node2D
var _cone: Sprite2D
var _core: Sprite2D
var _charge_glow: Sprite2D
var _charge_flare: Sprite2D
var _flames: CPUParticles2D
var _smoke: CPUParticles2D
var _embers: CPUParticles2D
var _lick: CPUParticles2D
var _wash: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _drops: Array = []
var _puffs: Array = []

static var _cone_tex: ImageTexture
static var _core_tex: ImageTexture


static func _make_cone() -> ImageTexture:
	## Cone de sopro: largura cresce da boca p/ o alvo, bordas turbulentas
	## (senos sobrepostos), núcleo quente e ventre verde-vivo.
	if _cone_tex != null:
		return _cone_tex
	var W := 320
	var H := 190
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cy := H / 2.0
	for y in range(H):
		for x in range(W):
			var u := float(x) / float(W - 1)             # 0 = boca, 1 = alvo
			var sy := float(y) + 0.5 - cy
			var turb := 1.0 + 0.13 * sin(u * 26.0) + 0.08 * sin(u * 57.0 + 1.3) + 0.05 * sin(u * 91.0 + 2.2)
			var half: float = (H * 0.5) * pow(0.10 + 0.90 * u, 0.85) * turb
			half *= smoothstep(0.0, 0.05, u)              # boca fechada
			half *= smoothstep(1.0, 0.93, u)              # ponta dissolvendo
			if half <= 0.5:
				continue
			var d := absf(sy) / half
			if d >= 1.0:
				continue
			var body := pow(clampf(1.0 - d, 0.0, 1.0), 1.35)
			var corek := pow(clampf(1.0 - d, 0.0, 1.0), 3.2) * smoothstep(0.0, 0.18, u)
			var outer := Color(0.02, 0.30, 0.05, 1.0)
			var mid := Color(0.30, 0.92, 0.16, 1.0)
			var hot := Color(0.98, 1.0, 0.80, 1.0)
			var col := outer.lerp(mid, pow(clampf(1.0 - d, 0.0, 1.0), 0.8))
			col = col.lerp(hot, clampf(corek * 1.15, 0.0, 1.0))
			var a := body * (0.55 + 0.45 * smoothstep(0.0, 0.12, u)) * smoothstep(1.0, 0.9, u)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * 0.92))
	_cone_tex = ImageTexture.create_from_image(img)
	return _cone_tex


static func _make_core() -> ImageTexture:
	## Núcleo incandescente fino ao longo do sopro.
	if _core_tex != null:
		return _core_tex
	var W := 320
	var H := 26
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var cy := H / 2.0
	for y in range(H):
		for x in range(W):
			var u := float(x) / float(W - 1)
			var dy := absf(float(y) + 0.5 - cy) / cy
			var prof := pow(clampf(1.0 - dy, 0.0, 1.0), 2.2)
			var wob := 0.75 + 0.25 * sin(u * 40.0)
			var a := prof * wob * smoothstep(0.0, 0.06, u) * smoothstep(1.0, 0.82, u) * 0.95
			if a <= 0.01:
				continue
			var col := Color(0.72, 1.0, 0.42, 1.0).lerp(Color(1.0, 1.0, 0.88, 1.0), pow(clampf(1.0 - dy, 0.0, 1.0), 2.0))
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	_core_tex = ImageTexture.create_from_image(img)
	return _core_tex


func setup(from: Vector2, at: Vector2) -> void:
	_from = from
	_at = at
	_dist = maxf(60.0, from.distance_to(at))
	_ang = (at - from).angle()
	z_index = 88
	_started = true
	# ---- carga na origem
	_charge_glow = Sprite2D.new()
	_charge_glow.texture = Vfx.radial("baf2_charge", 160, Color(0.55, 1.0, 0.30, 0.9), 0.18)
	_charge_glow.material = Vfx.add_mat()
	_charge_glow.modulate = Color(1, 1, 1, 0)
	_charge_glow.position = from
	add_child(_charge_glow)
	_charge_flare = Sprite2D.new()
	_charge_flare.texture = Vfx.spark(120, Color(0.8, 1.0, 0.5, 0.9))
	_charge_flare.material = Vfx.add_mat()
	_charge_flare.modulate = Color(1, 1, 1, 0)
	_charge_flare.position = from
	_charge_flare.rotation = _ang
	add_child(_charge_flare)
	# ---- pivot do cone (boca do dragão)
	_pivot = Node2D.new()
	_pivot.position = from
	_pivot.rotation = _ang
	add_child(_pivot)
	_cone = Sprite2D.new()
	_cone.texture = _make_cone()
	_cone.material = Vfx.add_mat()
	_cone.modulate = Color(1, 1, 1, 0)
	_cone.position = Vector2(_dist * 0.5, 0)
	_cone.scale = Vector2(_dist / 320.0, 1.0)
	_pivot.add_child(_cone)
	_core = Sprite2D.new()
	_core.texture = _make_core()
	_core.material = Vfx.add_mat()
	_core.modulate = Color(1, 1, 1, 0)
	_core.position = Vector2(_dist * 0.5, 0)
	_core.scale = Vector2(_dist / 320.0, 1.0)
	_pivot.add_child(_core)
	# ---- partículas do sopro (chamas, fumaça, brasas)
	_flames = _mk_parts(0)
	_flames.material = Vfx.add_mat()
	_flames.texture = Vfx.radial("baf2_flame", 42, Color(1, 1, 1, 1), 0.12)
	_flames.amount = 110
	_flames.lifetime = 0.45
	_flames.direction = Vector2(cos(_ang), sin(_ang))
	_flames.spread = 11.0
	_flames.initial_velocity_min = _dist * 1.5
	_flames.initial_velocity_max = _dist * 2.3
	_flames.gravity = Vector2(0, -30)
	_flames.scale_amount_min = 1.8
	_flames.scale_amount_max = 3.6
	var cgrow := Curve.new()
	cgrow.add_point(Vector2(0.0, 0.45))
	cgrow.add_point(Vector2(0.5, 1.0))
	cgrow.add_point(Vector2(1.0, 1.45))
	_flames.scale_amount_curve = cgrow
	var cr := Gradient.new()
	cr.offsets = [0.0, 0.25, 0.65, 1.0]
	cr.colors = [
		Color(1.0, 1.0, 0.78, 0.95),
		Color(0.55, 1.0, 0.25, 0.85),
		Color(0.10, 0.62, 0.12, 0.45),
		Color(0.0, 0.28, 0.05, 0.0),
	]
	_flames.color_ramp = cr
	_flames.position = from
	add_child(_flames)
	_smoke = _mk_parts(-2)
	_smoke.texture = Vfx.radial("baf2_smoke", 64, Color(0.05, 0.12, 0.05, 0.4), 0.05)
	_smoke.amount = 70
	_smoke.lifetime = 0.8
	_smoke.direction = Vector2(cos(_ang), sin(_ang))
	_smoke.spread = 24.0
	_smoke.initial_velocity_min = _dist * 0.9
	_smoke.initial_velocity_max = _dist * 1.4
	_smoke.gravity = Vector2(0, -52)
	_smoke.scale_amount_min = 3.0
	_smoke.scale_amount_max = 6.0
	var csm := Curve.new()
	csm.add_point(Vector2(0.0, 0.4))
	csm.add_point(Vector2(0.5, 1.0))
	csm.add_point(Vector2(1.0, 1.6))
	_smoke.scale_amount_curve = csm
	_smoke.position = from
	add_child(_smoke)
	_embers = _mk_parts(1)
	_embers.material = Vfx.add_mat()
	_embers.texture = Vfx.radial("baf2_ember", 10, Color(1.0, 0.96, 0.45, 1.0), 0.55)
	_embers.amount = 26
	_embers.lifetime = 0.6
	_embers.direction = Vector2(cos(_ang), sin(_ang))
	_embers.spread = 16.0
	_embers.initial_velocity_min = _dist * 1.2
	_embers.initial_velocity_max = _dist * 2.0
	_embers.gravity = Vector2(0, 60)
	_embers.scale_amount_min = 0.5
	_embers.scale_amount_max = 1.1
	_embers.color = Color(1.0, 0.95, 0.42, 0.95)
	_embers.position = from
	add_child(_embers)
	# ---- chamas lambendo o alvo (engolfar)
	_lick = _mk_parts(2)
	_lick.material = Vfx.add_mat()
	_lick.texture = Vfx.radial("baf2_lick", 36, Color(1, 1, 1, 1), 0.14)
	_lick.amount = 60
	_lick.lifetime = 0.4
	_lick.direction = Vector2(0, -1)
	_lick.spread = 34.0
	_lick.initial_velocity_min = 50.0
	_lick.initial_velocity_max = 120.0
	_lick.gravity = Vector2(0, -60)
	_lick.scale_amount_min = 1.4
	_lick.scale_amount_max = 2.8
	_lick.color_ramp = cr
	_lick.position = at
	add_child(_lick)
	_wash = Sprite2D.new()
	_wash.texture = Vfx.radial("baf2_wash", 190, Color(0.45, 1.0, 0.22, 0.6), 0.08)
	_wash.material = Vfx.add_mat()
	_wash.modulate = Color(1, 1, 1, 0)
	_wash.position = at
	add_child(_wash)
	# ---- kit do fim (clarão, anel, respingos, névoa)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("baf2_flash", 200, Color(0.62, 1.0, 0.35, 0.9), 0.2)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	_flash.position = at
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("baf2_ring", 130, Color(0.55, 1.0, 0.30, 0.9), 0.07)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.position = at
	add_child(_ring)
	for i in 12:
		var dr := Sprite2D.new()
		dr.texture = Vfx.radial("baf2_drop", 14, Color(0.60, 1.0, 0.32, 0.95), 0.45)
		dr.material = Vfx.add_mat()
		dr.modulate = Color(1, 1, 1, 0)
		add_child(dr)
		var a2 := randf() * TAU
		_drops.append({"n": dr, "v": Vector2(cos(a2), sin(a2)) * randf_range(70.0, 190.0), "dl": randf_range(0.0, 0.12)})
	for i in 4:
		var pf := Sprite2D.new()
		pf.texture = Vfx.radial("baf2_puff", 70, Color(0.30, 0.75, 0.18, 0.40), 0.05)
		pf.material = Vfx.add_mat()
		pf.modulate = Color(1, 1, 1, 0)
		add_child(pf)
		_puffs.append({"n": pf, "dx": randf_range(-26.0, 26.0), "dy": randf_range(-46.0, -26.0), "dl": randf_range(0.05, 0.3)})


func _mk_parts(z: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.z_index = z
	p.emitting = false
	p.one_shot = false
	p.explosiveness = 0.0
	p.local_coords = false
	return p


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---------------- carga (0 .. CHARGE)
	if t < CHARGE:
		var k := t / CHARGE
		_charge_glow.modulate = Color(1, 1, 1, sin(k * PI * 0.5) * 0.9)
		_charge_glow.scale = Vector2.ONE * (0.3 + k * 0.85)
		_charge_flare.modulate = Color(1, 1, 1, k * k * 0.8)
		_charge_flare.scale = Vector2.ONE * (0.4 + k * 0.5)
		return
	var bt: float = t - CHARGE
	# ---------------- sopro sustentado (CHARGE .. BREATH_END)
	if t < BREATH_END:
		var snap: float = clampf(bt / 0.10, 0.0, 1.0)
		var snap_e: float = 1.0 - pow(1.0 - snap, 3.0)
		var flick: float = 0.86 + 0.10 * sin(t * 37.0) + 0.06 * sin(t * 61.0 + 1.1)
		var wdt: float = 0.92 + 0.10 * sin(t * 23.0 + 0.4)
		_cone.modulate = Color(1, 1, 1, snap_e * flick)
		_cone.scale = Vector2(_dist / 320.0, wdt)
		_cone.position = Vector2(_dist * 0.5, 0)
		_core.modulate = Color(1, 1, 1, snap_e * (0.75 + 0.25 * sin(t * 47.0)))
		_core.scale = Vector2(_dist / 320.0, 0.9 + 0.2 * sin(t * 33.0))
		_core.position = Vector2(_dist * 0.5, 0)
		_charge_glow.modulate = Color(1, 1, 1, (0.75 + 0.2 * sin(t * 30.0)) * clampf(1.0 - bt / 0.25, 0.35, 1.0))
		_charge_flare.modulate = Color(1, 1, 1, clampf(1.0 - bt / 0.18, 0.0, 1.0) * 0.85)
		if not _flames.emitting:
			_flames.emitting = true
			_smoke.emitting = true
			_embers.emitting = true
		# engolfa o alvo a partir de meio sopro
		var ek: float = clampf((bt - 0.18) / 0.2, 0.0, 1.0)
		_lick.emitting = ek > 0.0
		_wash.modulate = Color(1, 1, 1, ek * (0.5 + 0.18 * sin(t * 26.0)))
		_wash.scale = Vector2.ONE * (0.85 + 0.12 * sin(t * 19.0))
	else:
		# ---------------- sopro cessa: recolhe e apaga
		var ck: float = clampf((t - BREATH_END) / 0.25, 0.0, 1.0)
		_cone.modulate = Color(1, 1, 1, (1.0 - ck) * 0.86)
		_cone.scale = Vector2(_dist / 320.0 * (1.0 - 0.45 * ck), 0.92 * (1.0 - 0.5 * ck))
		_cone.position = Vector2(_dist * 0.5 * (1.0 + 0.45 * ck), 0)
		_core.modulate = Color(1, 1, 1, (1.0 - ck) * 0.75)
		_charge_glow.modulate = Color(1, 1, 1, (1.0 - ck) * 0.5)
		if not _impacted:
			_flames.emitting = false
			_smoke.emitting = false
			_embers.emitting = false
			_lick.emitting = false
			_wash.modulate = Color(1, 1, 1, 0)
	# ---------------- fim: clarão, anel, respingos, névoa no alvo
	if t >= BREATH_END:
		_impacted = true
		var it: float = t - BREATH_END
		var fk: float = clampf(1.0 - it / 0.3, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, fk * fk * 0.9)
		_flash.scale = Vector2.ONE * (0.55 + (1.0 - fk) * 0.9)
		var rk: float = clampf(it / 0.42, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.85)
		_ring.scale = Vector2.ONE * (0.25 + rk * 1.8)
		for d in _drops:
			var n: Sprite2D = d["n"]
			var dt: float = maxf(0.0, it - float(d["dl"]))
			var vv: Vector2 = d["v"]
			n.position = _at + vv * dt + Vector2(0, 160.0) * dt * dt
			n.modulate = Color(1, 1, 1, clampf(1.0 - dt / 0.5, 0.0, 1.0) * 0.9)
		for p in _puffs:
			var n2: Sprite2D = p["n"]
			var dt2: float = maxf(0.0, it - float(p["dl"]))
			n2.position = _at + Vector2(float(p["dx"]), 0) * dt2 * 1.4 + Vector2(0, float(p["dy"])) * dt2
			n2.scale = Vector2.ONE * (0.6 + dt2 * 1.5)
			n2.modulate = Color(1, 1, 1, clampf(dt2 / 0.1, 0.0, 1.0) * clampf(1.0 - dt2 / 0.7, 0.0, 1.0) * 0.75)
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
