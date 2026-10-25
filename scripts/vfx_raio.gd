class_name RaioFX
extends Node2D
## (1.49.89) RAIO VERMELHO caindo do céu sobre um campeão (FÚRIA / GRITO DE
## GUERRA). Inspirado em arte de referência (raio rubro serrilhado com estrela
## de impacto), mas 100% procedural: serrilha gerada por caminhada aleatória,
## núcleo branco-quente, corpo rubro e halo profundo; no impacto: estrela de
## pontas, lascas, anel de choque, clarão e brasa no chão.
## Uso: add_child(raio); raio.setup(pos_global_alvo, duracao)

signal finished

var _dur: float = 1.5
var _t: float = 0.0
var _started := false
var _bolt: Sprite2D
var _star: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _scorch: Sprite2D
var _shards: Array = []
var _embers: Array = []
var _charge: Sprite2D
var _seed: int = 0
var _impact_at := 0.30
var _hit_played := false
var _done := false

const BOLT_W := 110
const BOLT_H := 340

static var _bolt_texs: Dictionary = {}
static var _star_tex: ImageTexture
static var _shard_tex: ImageTexture


static func _bolt_tex(seed_i: int) -> ImageTexture:
	if _bolt_texs.has(seed_i):
		return _bolt_texs[seed_i]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var img := Image.create(BOLT_W, BOLT_H, false, Image.FORMAT_RGBA8)
	# caminhada aleatória: eixo principal de cima p/ baixo
	var pts: Array = []
	var n := 11
	var x := float(BOLT_W) * 0.5
	for i in range(n):
		var yy: float = float(i) * float(BOLT_H) / float(n - 1)
		if i > 0 and i < n - 1:
			x = clampf(x + rng.randf_range(-16.0, 16.0), 18.0, float(BOLT_W) - 18.0)
		pts.append(Vector2(x, yy))
	# ramos curtos saindo do tronco
	var branches: Array = []
	for bi in [3, 6]:
		var base: Vector2 = pts[bi]
		var dir := Vector2(1.0 if rng.randf() < 0.5 else -1.0, 0.55).normalized()
		var bp: Array = [base]
		var cur := base
		for k in 3:
			cur = cur + dir * 16.0 + Vector2(rng.randf_range(-5, 5), rng.randf_range(-4, 6))
			bp.append(cur)
		branches.append(bp)
	var segs: Array = []
	for i in range(pts.size() - 1):
		segs.append([pts[i], pts[i + 1]])
	for b in branches:
		for i in range(b.size() - 1):
			segs.append([b[i], b[i + 1]])
	for y in range(BOLT_H):
		for xx in range(BOLT_W):
			var p := Vector2(float(xx) + 0.5, float(y) + 0.5)
			var d := 999.0
			for sg in segs:
				d = minf(d, _seg_dist(p, sg[0], sg[1]))
			var core := smoothstep(2.6, 0.4, d)
			var mid := smoothstep(7.0, 2.6, d)
			var glow := smoothstep(20.0, 7.0, d)
			var r: float = clampf(core * 1.0 + mid * 1.0 + glow * 0.85, 0.0, 1.0)
			var g: float = clampf(core * 0.95 + mid * 0.22 + glow * 0.05, 0.0, 1.0)
			var b2: float = clampf(core * 0.85 + mid * 0.10 + glow * 0.06, 0.0, 1.0)
			var a: float = clampf(core + mid * 0.95 + glow * 0.55, 0.0, 1.0)
			if a <= 0.004:
				continue
			img.set_pixel(xx, y, Color(r, g, b2, a))
	var tex := ImageTexture.create_from_image(img)
	_bolt_texs[seed_i] = tex
	return tex


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var L := ab.length_squared()
	var t: float = 0.0 if L < 0.0001 else clampf((p - a).dot(ab) / L, 0.0, 1.0)
	return (p - (a + ab * t)).length()


static func _make_star() -> ImageTexture:
	if _star_tex != null:
		return _star_tex
	var S := 160
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var c := Vector2(S * 0.5, S * 0.5)
	for y in range(S):
		for x in range(S):
			var p := Vector2(float(x) + 0.5, float(y) + 0.5) - c
			var d := p.length()
			var th := atan2(p.y, p.x)
			# estrela de 8 pontas finas + núcleo
			var spike := pow(abs(cos(4.0 * th + 0.35)), 6.0)
			var spike2 := pow(abs(cos(4.0 * th + 0.35 + PI * 0.5)), 6.0) * 0.55
			var rstar: float = 12.0 + 62.0 * maxf(spike, spike2)
			var core := smoothstep(14.0, 2.0, d)
			var body := smoothstep(rstar, rstar * 0.35, d)
			var halo := smoothstep(rstar * 1.25, rstar * 0.5, d) * 0.5
			var m: float = clampf(core + body + halo, 0.0, 1.0)
			if m <= 0.004:
				continue
			var r: float = clampf(0.85 + core * 0.15 + body * 0.15, 0.0, 1.0)
			var g: float = clampf(core * 0.95 + body * 0.28 + halo * 0.06, 0.0, 1.0)
			var b: float = clampf(core * 0.80 + body * 0.12 + halo * 0.06, 0.0, 1.0)
			img.set_pixel(x, y, Color(r, g, b, m))
	_star_tex = ImageTexture.create_from_image(img)
	return _star_tex


static func _make_shard() -> ImageTexture:
	if _shard_tex != null:
		return _shard_tex
	var S := 26
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in range(S):
		for x in range(S):
			# lasca triangular alongada (aponta p/ +x)
			var u: float = float(x) / float(S - 1)
			var v: float = abs(float(y) - float(S) * 0.5) / (float(S) * 0.5)
			var half: float = (1.0 - u) * 0.85
			if v > half:
				continue
			var m: float = (1.0 - v / maxf(half, 0.001)) * 0.6 + 0.4
			m *= smoothstep(1.0, 0.75, u) + 0.25
			var col := Color(1.0, 0.32 + 0.5 * (1.0 - u), 0.14, clampf(m, 0.0, 1.0))
			img.set_pixel(x, y, col)
	_shard_tex = ImageTexture.create_from_image(img)
	return _shard_tex


func setup(at: Vector2, dur: float) -> void:
	position = at
	_dur = maxf(0.8, dur)
	_seed = int(randf() * 99999.0) + 7
	_started = true
	# textures
	var btex: ImageTexture = _bolt_tex(_seed)
	_bolt = Sprite2D.new()
	_bolt.texture = btex
	_bolt.offset = Vector2(0, -float(BOLT_H) * 0.5)
	_bolt.modulate = Color(1, 1, 1, 0)
	_bolt.material = Vfx.add_mat()
	add_child(_bolt)
	_charge = Sprite2D.new()
	_charge.texture = Vfx.radial("raio_charge", 96, Color(1.0, 0.25, 0.12, 0.9), 0.35)
	_charge.modulate = Color(1, 1, 1, 0)
	_charge.material = Vfx.add_mat()
	add_child(_charge)
	_star = Sprite2D.new()
	_star.texture = _make_star()
	_star.modulate = Color(1, 1, 1, 0)
	_star.material = Vfx.add_mat()
	add_child(_star)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("raio_flash", 220, Color(1.0, 0.45, 0.30, 0.85), 0.15)
	_flash.modulate = Color(1, 1, 1, 0)
	_flash.material = Vfx.add_mat()
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.radial("raio_ring", 120, Color(1.0, 0.35, 0.18, 0.9), 0.06)
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.material = Vfx.add_mat()
	add_child(_ring)
	_scorch = Sprite2D.new()
	_scorch.texture = Vfx.radial("raio_scorch", 110, Color(1.0, 0.22, 0.10, 0.75), 0.3)
	_scorch.scale = Vector2(1.5, 0.42)
	_scorch.modulate = Color(1, 1, 1, 0)
	_scorch.material = Vfx.add_mat()
	add_child(_scorch)
	var stex: ImageTexture = _make_shard()
	for i in 9:
		var sh := Sprite2D.new()
		sh.texture = stex
		sh.material = Vfx.add_mat()
		sh.modulate = Color(1, 1, 1, 0)
		sh.rotation = TAU * float(i) / 9.0 + randf_range(-0.2, 0.2)
		sh.scale = Vector2.ONE * randf_range(0.7, 1.25)
		add_child(sh)
		_shards.append({"n": sh, "spd": randf_range(150.0, 260.0), "rot": sh.rotation})
	for i in 7:
		var em := Sprite2D.new()
		em.texture = Vfx.radial("raio_ember", 14, Color(1.0, 0.42, 0.16, 0.95), 0.4)
		em.material = Vfx.add_mat()
		em.modulate = Color(1, 1, 1, 0)
		add_child(em)
		_embers.append({"n": em, "dx": randf_range(-26.0, 26.0), "dy": randf_range(-70.0, -34.0), "dl": randf_range(0.0, 0.25)})


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	if t < _impact_at:
		# carga: brilho crescendo no alvo + raio despencando do céu
		var k: float = clampf(t / _impact_at, 0.0, 1.0)
		_charge.modulate = Color(1, 1, 1, k * 0.55)
		_charge.scale = Vector2.ONE * (0.35 + k * 0.75)
		var fall: float = clampf((t - 0.04) / (_impact_at - 0.04), 0.0, 1.0)
		fall = fall * fall * (3.0 - 2.0 * fall)
		_bolt.position = Vector2(randf_range(-1.2, 1.2), lerpf(-430.0, 0.0, fall))
		_bolt.modulate = Color(1, 1, 1, clampf(fall * 1.6, 0.0, 1.0))
		_bolt.scale = Vector2(1.0, lerpf(1.25, 1.0, fall))
	else:
		if not _hit_played:
			_hit_played = true
			Sfx.play("raio", position.x, 1.0)
		var it: float = t - _impact_at
		_bolt.modulate = Color(1, 1, 1, clampf(1.0 - it / 0.28, 0.0, 1.0) * randf_range(0.7, 1.0))
		_charge.modulate = Color(1, 1, 1, 0)
		# clarão
		var fk: float = clampf(1.0 - it / 0.34, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, fk * fk * 0.9)
		_flash.scale = Vector2.ONE * (0.7 + (1.0 - fk) * 0.9)
		# estrela de impacto
		var sk: float = clampf(it / 0.16, 0.0, 1.0)
		var sf: float = clampf(1.0 - (it - 0.16) / 0.42, 0.0, 1.0) if it > 0.16 else 1.0
		_star.modulate = Color(1, 1, 1, minf(sk * 2.0, 1.0) * sf)
		_star.scale = Vector2.ONE * (0.45 + sk * 0.85)
		_star.rotation += delta * 1.6
		# anel de choque
		var rk: float = clampf(it / 0.5, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.8)
		_ring.scale = Vector2(1.0, 0.42) * (0.3 + rk * 2.1)
		# brasa no chão
		var ck: float = clampf(it / 0.22, 0.0, 1.0)
		var cf: float = clampf(1.0 - (it - 0.22) / maxf(_dur - _impact_at - 0.2, 0.3), 0.0, 1.0) if it > 0.22 else 1.0
		_scorch.modulate = Color(1, 1, 1, ck * cf * 0.75)
		# lascas
		for s in _shards:
			var n: Sprite2D = s["n"]
			var d: float = float(s["spd"]) * it
			n.position = Vector2.from_angle(float(s["rot"])) * d
			n.modulate = Color(1, 1, 1, clampf(1.0 - it / 0.5, 0.0, 1.0))
		# brasas subindo
		for e in _embers:
			var n2: Sprite2D = e["n"]
			var et: float = maxf(0.0, it - float(e["dl"]))
			n2.position = Vector2(float(e["dx"]) * (et * 1.6), float(e["dy"]) * et)
			n2.modulate = Color(1, 1, 1, clampf(1.0 - et / 0.7, 0.0, 1.0) * 0.9)
	if t >= _dur and not _done:
		_done = true
		finished.emit()
		queue_free()
