class_name OvoFX
extends Node2D
## (1.49.94) HABILIDADE INVOCAR DRAGÃO — o OVO DO DRAGÃO refeito com arte
## PINTADA semi-3D estilo Hearthstone (assets/OVO_DRAGAO_F1..F5.png, fundo
## preto + blend aditivo): 5 estados de arte (inteiro -> fissuras finas ->
## fissuras fundas com feixes -> casca explodindo -> casca aberta) ligados a
## UMA coreografia rica: materialização com espiral de faíscas e anel rúnico
## no chão, tremor CRESCENTE com squash&stretch e poeira, clarões de fissura,
## lascas orbitando, e no CHOCA: explosão de luz, anel de choque, lascas
## voando com rotação, PILAR DE ENERGIA subindo e chuva de faíscas — só então
## o FILHOTE é invocado (sinal `burst` -> resolve_invoke_dragon).
## Mesmos timings/contrato da 1.49.93: DUR 1.5, burst ~1.32, finished 1.5.
## Uso: add_child(fx); fx.setup(pos_global_slot)

signal burst
signal finished

const DUR := 1.5
const MAT_END := 0.35      # fim da materialização
const CRACK1_AT := 0.55    # troca p/ fissuras finas (F2)
const CRACK2_AT := 0.80    # troca p/ fissuras fundas (F3)
const HATCH_AT := 1.08     # casca explode (F4)
const BURST_AT := 1.32     # explosão de luz -> invoca o Filhote
const OPEN_AT := 1.40      # casca aberta (F5)

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
var _runering: Sprite2D
var _crackflash: Sprite2D
var _rays: Sprite2D
var _swirl: Array = []
var _shards: Array = []
var _dust: CPUParticles2D
var _sparkles: CPUParticles2D

const TEX_F1 := preload("res://assets/OVO_DRAGAO_F1.png")
const TEX_F2 := preload("res://assets/OVO_DRAGAO_F2.png")
const TEX_F3 := preload("res://assets/OVO_DRAGAO_F3.png")
const TEX_F4 := preload("res://assets/OVO_DRAGAO_F4.png")
const TEX_F5 := preload("res://assets/OVO_DRAGAO_F5.png")


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
	# ---- anel rúnico no chão (invocação)
	_runering = Sprite2D.new()
	_runering.texture = Vfx.ring("ovo_rune", 150, Color(0.35, 0.95, 0.75, 0.85), 0.05)
	_runering.material = Vfx.add_mat()
	_runering.scale = Vector2(1.0, 0.32)
	_runering.position = Vector2(0, 58)
	_runering.modulate = Color(1, 1, 1, 0)
	add_child(_runering)
	# ---- brilho mágico sob o ovo
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("ovo_glow", 200, Color(1.0, 0.80, 0.35, 0.7), 0.1)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	add_child(_glow)
	# ---- o ovo (5 estados de arte pintada)
	_egg = Sprite2D.new()
	_egg.texture = TEX_F1
	_egg.material = Vfx.add_mat()
	_egg.modulate = Color(1, 1, 1, 0)
	_egg.scale = Vector2(0.32, 0.32)
	_egg.position = Vector2(0, -6)
	add_child(_egg)
	# ---- feixes de luz das fissuras (atrás do ovo)
	_rays = Sprite2D.new()
	_rays.texture = Vfx.ring("ovo_rays", 240, Color(1.0, 0.85, 0.45, 0.8), 0.03)
	_rays.material = Vfx.add_mat()
	_rays.modulate = Color(1, 1, 1, 0)
	_rays.position = Vector2(0, -6)
	add_child(_rays)
	# ---- clarão de fissura / explosão
	_crackflash = Sprite2D.new()
	_crackflash.texture = Vfx.radial("ovo_cflash", 150, Color(1.0, 0.92, 0.65, 0.9), 0.3)
	_crackflash.material = Vfx.add_mat()
	_crackflash.modulate = Color(1, 1, 1, 0)
	_crackflash.position = Vector2(0, -6)
	add_child(_crackflash)
	# ---- pilar de energia do choco
	_beam = Sprite2D.new()
	_beam.texture = Vfx.radial("ovo_beam", 120, Color(1.0, 0.88, 0.50, 0.85), 0.12)
	_beam.material = Vfx.add_mat()
	_beam.scale = Vector2(0.7, 0.1)
	_beam.position = Vector2(0, -40)
	_beam.modulate = Color(1, 1, 1, 0)
	add_child(_beam)
	# ---- anel de choque do choco
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ovo_ring", 160, Color(1.0, 0.90, 0.55, 0.9), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	# ---- clarão global do choco
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("ovo_flash", 320, Color(1.0, 0.95, 0.75, 0.9), 0.2)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	# ---- espiral de faíscas da materialização
	for i in 6:
		var s := Sprite2D.new()
		s.texture = Vfx.spark(26, Color(1.0, 0.85, 0.45))
		s.material = Vfx.add_mat()
		s.modulate = Color(1, 1, 1, 0)
		add_child(s)
		_swirl.append({"n": s, "a": TAU * float(i) / 6.0})
	# ---- lascas de casca (voam no choco)
	for i in 8:
		var sh := Sprite2D.new()
		sh.texture = Vfx.spark(18, Color(0.55, 0.95, 0.80))
		sh.material = Vfx.add_mat()
		sh.modulate = Color(1, 1, 1, 0)
		add_child(sh)
		_shards.append({
			"n": sh,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, -0.2)).normalized(),
			"sp": randf_range(140.0, 260.0),
			"rot": randf_range(-9.0, 9.0),
			"sc": randf_range(0.8, 1.6),
		})
	# ---- poeira do tremor na base
	_dust = CPUParticles2D.new()
	_dust.texture = Vfx.radial("ovo_dust", 40, Color(0.55, 0.45, 0.35, 0.5), 0.05)
	_dust.emitting = false
	_dust.amount = 26
	_dust.lifetime = 0.6
	_dust.direction = Vector2(0, -1)
	_dust.spread = 55.0
	_dust.initial_velocity_min = 22.0
	_dust.initial_velocity_max = 60.0
	_dust.gravity = Vector2(0, 60)
	_dust.scale_amount_min = 0.8
	_dust.scale_amount_max = 1.8
	_dust.position = Vector2(0, 56)
	add_child(_dust)
	# ---- chuva de faíscas douradas do choco
	_sparkles = CPUParticles2D.new()
	_sparkles.texture = Vfx.spark(22, Color(1.0, 0.90, 0.55))
	_sparkles.material = Vfx.add_mat()
	_sparkles.emitting = false
	_sparkles.amount = 60
	_sparkles.lifetime = 0.7
	_sparkles.explosiveness = 0.9
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 90.0
	_sparkles.initial_velocity_max = 260.0
	_sparkles.gravity = Vector2(0, 240)
	_sparkles.scale_amount_min = 0.6
	_sparkles.scale_amount_max = 1.4
	add_child(_sparkles)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ================= materialização (0 .. MAT_END)
	var mk: float = clampf(t / MAT_END, 0.0, 1.0)
	var mf: float = clampf(1.0 - (t - 0.9) / 0.3, 0.0, 1.0) if t > 0.9 else 1.0
	for s in _swirl:
		var n: Sprite2D = s["n"]
		var a: float = float(s["a"]) + t * 7.0
		var r: float = lerpf(90.0, 26.0, mk)
		n.position = Vector2(cos(a) * r, -6.0 + sin(a) * r * 0.45)
		n.modulate = Color(1, 1, 1, sin(mk * PI) * 0.9 * mf)
		n.scale = Vector2.ONE * (0.6 + 0.5 * sin(mk * PI))
	# ================= ovo: frame + tremor + squash
	var tremor: float = 0.0
	if t >= MAT_END and t < HATCH_AT:
		tremor = clampf((t - MAT_END) / (HATCH_AT - MAT_END), 0.0, 1.0)
	var jx: float = randf_range(-1, 1) * 3.4 * tremor * tremor
	var jy: float = randf_range(-1, 1) * 2.2 * tremor * tremor
	var rot: float = randf_range(-1, 1) * 0.045 * tremor * tremor
	var squash: float = 1.0 + 0.06 * tremor * sin(t * 34.0)
	var egg_sc: float
	if t < MAT_END:
		egg_sc = lerpf(0.32, 1.0, Ease.out_cubic(mk))
	elif t < HATCH_AT:
		egg_sc = 1.0 + 0.03 * sin(t * 9.0)
	elif t < OPEN_AT:
		egg_sc = 1.12
	else:
		egg_sc = 1.0
	var egg_a: float = mk if t < HATCH_AT else clampf(1.0 - (t - OPEN_AT) / 0.10, 0.0, 1.0)
	_egg.modulate = Color(1, 1, 1, egg_a)
	_egg.scale = Vector2(egg_sc * (2.0 - squash), egg_sc * squash)
	_egg.rotation = rot
	_egg.position = Vector2(jx, -6.0 + jy)
	# troca de frames de arte (5 estados)
	var want: Texture2D = TEX_F1
	if t >= OPEN_AT:
		want = TEX_F5
	elif t >= HATCH_AT:
		want = TEX_F4
	elif t >= CRACK2_AT:
		want = TEX_F3
	elif t >= CRACK1_AT:
		want = TEX_F2
	if _egg.texture != want:
		_egg.texture = want
		# clarão de transição de fissura
		_crackflash.modulate = Color(1, 1, 1, 0.75)
	# ================= chão / brilho / anel rúnico
	_shadow.modulate = Color(1, 1, 1, mk * 0.8)
	_runering.modulate = Color(1, 1, 1, sin(mk * PI) * 0.8 if t < 0.9 else clampf(0.8 - (t - 0.9) * 0.6, 0.0, 0.8) + 0.25 * tremor * absf(sin(t * 12.0)))
	_runering.scale = Vector2(0.5 + mk * 0.7, 0.16 + mk * 0.22)
	_glow.modulate = Color(1, 1, 1, (0.25 + 0.55 * mk) * (0.75 + 0.25 * sin(t * 14.0)) + 0.5 * tremor)
	_glow.scale = Vector2.ONE * (0.7 + 0.35 * mk + 0.1 * tremor * sin(t * 21.0))
	# ================= feixes das fissuras (F3+)
	if t >= CRACK2_AT and t < HATCH_AT + 0.2:
		var rk: float = clampf((t - CRACK2_AT) / 0.2, 0.0, 1.0)
		_rays.modulate = Color(1, 1, 1, rk * (0.5 + 0.4 * absf(sin(t * 18.0))))
		_rays.rotation += delta * 1.6
		_rays.scale = Vector2.ONE * (0.6 + rk * 0.5)
	else:
		_rays.modulate = Color(1, 1, 1, 0)
	# ================= poeira do tremor
	if tremor > 0.25 and t < HATCH_AT:
		_dust.emitting = true
	else:
		_dust.emitting = false
	# ================= clarão de fissura decai
	if _crackflash.modulate.a > 0.0:
		_crackflash.modulate = Color(1, 1, 1, maxf(0.0, _crackflash.modulate.a - delta * 3.2))
		_crackflash.scale = Vector2.ONE * (0.7 + (0.75 - minf(0.75, _crackflash.modulate.a)))
	# ================= CHOCA (HATCH_AT ..): explosão + pilar + lascas
	if t >= HATCH_AT:
		var hk: float = clampf((t - HATCH_AT) / 0.24, 0.0, 1.0)
		var hf: float = clampf(1.0 - (t - HATCH_AT - 0.24) / 0.26, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, hk * hf)
		_flash.scale = Vector2.ONE * (0.5 + hk * 1.3)
		_ring.modulate = Color(1, 1, 1, hk * hf * 0.9)
		_ring.scale = Vector2.ONE * (0.3 + hk * 1.9)
		_beam.modulate = Color(1, 1, 1, hk * clampf(1.0 - (t - BURST_AT) / 0.18, 0.0, 1.0) * 0.9)
		_beam.scale = Vector2(0.7 + 0.25 * sin(t * 30.0), lerpf(0.1, 4.2, Ease.out_cubic(hk)))
		_beam.position = Vector2(0, lerpf(20.0, -150.0, Ease.out_cubic(hk)))
		if not _sparkles.emitting:
			_sparkles.emitting = true
			_sparkles.restart()
		for sh in _shards:
			var n: Sprite2D = sh["n"]
			var st: float = t - HATCH_AT
			var life := 0.55
			if st > life:
				n.modulate = Color(1, 1, 1, 0)
				continue
			n.position = Vector2(0, -6) + sh["dir"] * sh["sp"] * st + Vector2(0, 200.0 * st * st)
			n.rotation = sh["rot"] * st
			n.scale = Vector2.ONE * sh["sc"]
			n.modulate = Color(1, 1, 1, clampf(1.0 - st / life, 0.0, 1.0))
	if t >= BURST_AT and not _bursted:
		_bursted = true
		burst.emit()
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()


class Ease:
	static func out_cubic(x: float) -> float:
		var inv := 1.0 - x
		return 1.0 - inv * inv * inv
