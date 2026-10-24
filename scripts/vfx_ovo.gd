class_name OvoFX
extends Node2D
## (1.49.93) HABILIDADE INVOCAR DRAGÃO — o OVO DO DRAGÃO (1,5 s): o ovo é
## materializado no slot com espiral de faíscas, treme cada vez mais forte,
## racha com luz vazando pelas fissuras e então CHOCA: a casca superior voa,
## uma explosão de luz dourada e um pilar de energia inundam o campo e só
## então o FILHOTE DE DRAGÃO é invocado (sinal `burst` -> resolve_invoke_dragon).
## Arte pintada estilo Hearthstone (assets/OVO_DRAGAO*.png).
## Uso: add_child(fx); fx.setup(pos_global_slot)

signal burst
signal finished

const DUR := 1.5
const MAT_END := 0.35      # fim da materialização
const CRACK_AT := 0.55     # troca p/ ovo rachado
const HATCH_AT := 0.78     # casca abre
const BURST_AT := 0.88     # explosão de luz -> invoca o Filhote

var _t := 0.0
var _done := false
var _bursted := false
var _started := false

var _egg: Sprite2D
var _shadow: Sprite2D
var _glow: Sprite2D
var _flash: Sprite2D
var _beam: Sprite2D
var _ring: Sprite2D
var _crackflash: Sprite2D
var _rays: Sprite2D
var _swirl: Array = []
var _shards: Array = []
var _sparkles: CPUParticles2D

const TEX_INT := preload("res://assets/OVO_DRAGAO.png")
const TEX_RACH := preload("res://assets/OVO_DRAGAO_RACHADO.png")
const TEX_ABERT := preload("res://assets/OVO_DRAGAO_ABERTO.png")


func setup(at: Vector2) -> void:
	position = at
	z_index = 86
	_started = true
	# ---- sombra no chão
	_shadow = Sprite2D.new()
	_shadow.texture = Vfx.radial("ovo_shadow", 120, Color(0.0, 0.0, 0.0, 0.55), 0.1)
	_shadow.scale = Vector2(1.0, 0.30)
	_shadow.position = Vector2(0, 58)
	_shadow.modulate = Color(1, 1, 1, 0)
	add_child(_shadow)
	# ---- brilho mágico sob o ovo
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("ovo_glow", 190, Color(1.0, 0.80, 0.35, 0.7), 0.1)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	add_child(_glow)
	# ---- o ovo (3 estados de arte)
	_egg = Sprite2D.new()
	_egg.texture = TEX_INT
	_egg.modulate = Color(1, 1, 1, 0)
	_egg.scale = Vector2(0.34, 0.34)
	_egg.offset = Vector2(0, 6)   # base do ovo apoiada no chão do slot
	add_child(_egg)
	# ---- espiral de faíscas convergindo (materialização)
	for i in 9:
		var sp := Sprite2D.new()
		sp.texture = Vfx.spark(int(randf_range(10, 16)), Color(1.0, 0.85, 0.40, 0.95))
		sp.material = Vfx.add_mat()
		sp.modulate = Color(1, 1, 1, 0)
		add_child(sp)
		_swirl.append({"n": sp, "a": TAU * float(i) / 9.0, "r0": randf_range(80.0, 115.0), "d": randf_range(0.0, 0.1)})
	# ---- kit da chocada
	_crackflash = Sprite2D.new()
	_crackflash.texture = Vfx.radial("ovo_cflash", 150, Color(1.0, 0.95, 0.7, 0.9), 0.2)
	_crackflash.material = Vfx.add_mat()
	_crackflash.modulate = Color(1, 1, 1, 0)
	add_child(_crackflash)
	_rays = Sprite2D.new()
	_rays.texture = Vfx.spark(170, Color(1.0, 0.92, 0.6, 0.95))
	_rays.material = Vfx.add_mat()
	_rays.modulate = Color(1, 1, 1, 0)
	add_child(_rays)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("ovo_flash", 300, Color(1.0, 0.96, 0.75, 0.95), 0.12)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_beam = Sprite2D.new()
	_beam.texture = Vfx.radial("ovo_beam", 120, Color(1.0, 0.93, 0.62, 0.85), 0.06)
	_beam.material = Vfx.add_mat()
	_beam.modulate = Color(1, 1, 1, 0)
	_beam.scale = Vector2(0.8, 3.4)
	_beam.position = Vector2(0, -110)
	add_child(_beam)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ovo_ring", 150, Color(1.0, 0.88, 0.5, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	_ring.scale = Vector2(1.0, 0.34)
	_ring.position = Vector2(0, 58)
	add_child(_ring)
	for i in 8:
		var sh := Sprite2D.new()
		sh.texture = Vfx.spark(int(randf_range(8, 14)), Color(0.20, 0.62, 0.52, 0.95))
		sh.modulate = Color(1, 1, 1, 0)
		add_child(sh)
		var ang := -PI * 0.5 + randf_range(-1.1, 1.1)
		_shards.append({"n": sh, "v": Vector2(cos(ang), sin(ang)) * randf_range(120.0, 230.0), "rot": randf_range(-9.0, 9.0), "d": randf_range(0.0, 0.1)})
	# ---- fagulhas douradas subindo após a chocada
	_sparkles = CPUParticles2D.new()
	_sparkles.material = Vfx.add_mat()
	_sparkles.texture = Vfx.radial("ovo_spark", 12, Color(1.0, 0.90, 0.5, 0.95), 0.45)
	_sparkles.emitting = false
	_sparkles.amount = 34
	_sparkles.lifetime = 0.7
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 34.0
	_sparkles.initial_velocity_min = 60.0
	_sparkles.initial_velocity_max = 150.0
	_sparkles.gravity = Vector2(0, 40)
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.3
	var cg := Gradient.new()
	cg.offsets = [0.0, 0.3, 1.0]
	cg.colors = [Color(1, 0.97, 0.8, 0.0), Color(1, 0.9, 0.55, 0.95), Color(1, 0.7, 0.3, 0.0)]
	_sparkles.color_ramp = cg
	add_child(_sparkles)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---------------- materialização (0 .. MAT_END)
	var mk: float = clampf(t / MAT_END, 0.0, 1.0)
	var mk_e: float = 1.0 - pow(1.0 - mk, 3.0)     # ease-out cúbico
	var egg_a: float = clampf(t / 0.22, 0.0, 1.0)
	# tremor cresce entre MAT_END e HATCH_AT
	var shake: float = clampf((t - MAT_END) / (HATCH_AT - MAT_END), 0.0, 1.0) if t > MAT_END else 0.0
	if t >= HATCH_AT:
		shake = 0.0
	var jx: float = sin(t * 47.0) * 3.2 * shake
	var jr: float = sin(t * 41.0 + 0.7) * 0.055 * shake
	var sc: float = lerpf(0.18, 1.0, mk_e) * (1.0 + 0.03 * sin(t * 30.0) * shake)
	_egg.modulate = Color(1, 1, 1, egg_a)
	_egg.scale = Vector2(sc, sc)
	_egg.rotation = jr
	_egg.position = Vector2(jx, 0)
	_shadow.modulate = Color(1, 1, 1, egg_a * 0.85)
	_shadow.scale = Vector2(0.5 + 0.5 * mk_e, 0.30)
	_glow.modulate = Color(1, 1, 1, egg_a * (0.35 + 0.5 * shake + 0.1 * sin(t * 12.0)))
	# espiral de faíscas convergindo
	for s in _swirl:
		var n: Sprite2D = s["n"]
		var ct: float = clampf((t - float(s["d"])) / 0.34, 0.0, 1.0)
		if ct >= 1.0:
			n.modulate = Color(1, 1, 1, 0)
			continue
		var r: float = lerpf(float(s["r0"]), 10.0, ct)
		var a: float = float(s["a"]) + ct * 3.4
		n.position = Vector2(cos(a) * r, sin(a) * r * 0.8)
		n.modulate = Color(1, 1, 1, sin(ct * PI) * 0.9)
	# ---------------- rachadura (CRACK_AT): luz vaza pelas fissuras
	if t >= CRACK_AT and _egg.texture == TEX_INT:
		_egg.texture = TEX_RACH
	if t >= CRACK_AT and t < HATCH_AT:
		var ck: float = clampf((t - CRACK_AT) / 0.12, 0.0, 1.0)
		_crackflash.modulate = Color(1, 1, 1, ck * (0.5 + 0.3 * sin(t * 36.0)))
		_crackflash.scale = Vector2.ONE * (0.5 + ck * 0.4)
		_rays.modulate = Color(1, 1, 1, ck * (0.35 + 0.25 * sin(t * 27.0 + 1.0)))
		_rays.scale = Vector2.ONE * (0.5 + ck * 0.35)
		_rays.rotation += delta * 0.9
	# ---------------- chocada (HATCH_AT): casca abre + explosão de luz
	if t >= HATCH_AT:
		if _egg.texture != TEX_ABERT:
			_egg.texture = TEX_ABERT
			_crackflash.modulate = Color(1, 1, 1, 0)
			_rays.modulate = Color(1, 1, 1, 0)
		var ht: float = t - HATCH_AT
		# a arte aberta já traz a casca voando + o jato de luz pintado
		var ef: float = clampf(1.0 - (ht - 0.30) / 0.35, 0.0, 1.0) if ht > 0.30 else 1.0
		_egg.modulate = Color(1, 1, 1, ef)
		_egg.scale = Vector2.ONE * (1.0 + 0.06 * clampf(ht / 0.1, 0.0, 1.0))
		var fk: float = clampf(ht / 0.08, 0.0, 1.0)
		var ff: float = clampf(1.0 - (ht - 0.10) / 0.45, 0.0, 1.0) if ht > 0.10 else 1.0
		_flash.modulate = Color(1, 1, 1, fk * ff * 0.95)
		_flash.scale = Vector2.ONE * (0.35 + clampf(ht / 0.35, 0.0, 1.0) * 1.6)
		var bk: float = clampf(ht / 0.14, 0.0, 1.0)
		var bf: float = clampf(1.0 - (ht - 0.25) / 0.4, 0.0, 1.0) if ht > 0.25 else 1.0
		_beam.modulate = Color(1, 1, 1, bk * bf * 0.8)
		_beam.scale = Vector2(0.8 + 0.2 * sin(t * 19.0), 3.4)
		var rk: float = clampf(ht / 0.5, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.9)
		_ring.scale = Vector2(1.0, 0.34) * (0.3 + rk * 2.0)
		_glow.modulate = Color(1, 1, 1, 0.9 * bf + 0.2)
		_shadow.modulate = Color(1, 1, 1, 0.85 * ef)
		# lascas de casca voando
		for s in _shards:
			var n2: Sprite2D = s["n"]
			var st: float = maxf(0.0, ht - float(s["d"]))
			n2.position = Vector2(float(s["v"].x) * st, float(s["v"].y) * st + 330.0 * st * st)
			n2.rotation = float(s["rot"]) * st
			n2.modulate = Color(1, 1, 1, clampf(st / 0.03, 0.0, 1.0) * clampf(1.0 - st / 0.55, 0.0, 1.0) * 0.9)
		if not _sparkles.emitting and ht < 0.5:
			_sparkles.emitting = true
	if not _bursted and t >= BURST_AT:
		_bursted = true
		burst.emit()
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
