class_name GuardiaoFX
extends Node2D
## (1.49.93) HABILIDADE GUARDIÃO — PILAR DE LUZ DO CÉU (1,0 s) sobre um campeão
## aliado, estilo Hearthstone: o feixe sagrado desce do alto, firma-se dourado
## e quente com poeira de luz subindo por dentro, anel de energia no chão e
## lavagem de brilho sobre a carta; então recolhe para o céu.
## A Proteção do aliado é aplicada 0,5 s APÓS o fim deste pilar
## (state.resolve_guardiao, orquestrado pela Tela de Combate).
## Uso: add_child(fx); fx.setup(pos_global_centro_carta)

signal finished

const DUR := 1.0
const BEAM_H := 470.0
const TOP_Y := -450.0

var _t := 0.0
var _done := false
var _started := false
var _firm_played := false

var _beam: Sprite2D
var _glow: Sprite2D
var _ground: Sprite2D
var _ring: Sprite2D
var _flash: Sprite2D
var _dust: CPUParticles2D

static var _beam_tex: ImageTexture


static func _make_beam() -> ImageTexture:
	## Pilar sagrado: queda gaussiana lateral + estrias verticais de luz.
	if _beam_tex != null:
		return _beam_tex
	var W := 110
	var H := 470
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in range(H):
		for x in range(W):
			var u: float = float(x) / float(W - 1)
			var v: float = float(y) / float(H - 1)
			var side: float = exp(-pow((u - 0.5) / 0.20, 2.0))
			var core: float = exp(-pow((u - 0.5) / 0.075, 2.0))
			var stri: float = 0.72 + 0.28 * sin(u * 46.0 + v * 6.0)
			var vert: float = smoothstep(0.0, 0.10, v) * (0.82 + 0.18 * smoothstep(0.55, 1.0, v))
			var a: float = clampf(side * 0.55 + core * 0.65, 0.0, 1.0) * stri * vert
			if a <= 0.01:
				continue
			var col := Color(1.0, 0.88, 0.52, 1.0).lerp(Color(1.0, 1.0, 0.92, 1.0), core)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * 0.9))
	_beam_tex = ImageTexture.create_from_image(img)
	return _beam_tex


func setup(at: Vector2) -> void:
	position = at
	z_index = 87
	_started = true
	# ---- pilar de luz (topo fixo no céu, cresce para baixo)
	_beam = Sprite2D.new()
	_beam.texture = _make_beam()
	_beam.material = Vfx.add_mat()
	_beam.modulate = Color(1, 1, 1, 0)
	_beam.scale = Vector2(1.0, 0.02)
	_beam.position = Vector2(0, TOP_Y + BEAM_H * 0.01)
	add_child(_beam)
	# ---- lavagem de brilho sobre a carta
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("gua_glow", 200, Color(1.0, 0.90, 0.55, 0.75), 0.08)
	_glow.material = Vfx.add_mat()
	_glow.modulate = Color(1, 1, 1, 0)
	_glow.scale = Vector2(0.9, 1.15)
	add_child(_glow)
	# ---- poça/anel de energia no chão
	_ground = Sprite2D.new()
	_ground.texture = Vfx.radial("gua_ground", 150, Color(1.0, 0.85, 0.42, 0.8), 0.12)
	_ground.material = Vfx.add_mat()
	_ground.scale = Vector2(1.15, 0.36)
	_ground.position = Vector2(0, 62)
	_ground.modulate = Color(1, 1, 1, 0)
	add_child(_ground)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("gua_ring", 140, Color(1.0, 0.90, 0.55, 0.9), 0.07)
	_ring.material = Vfx.add_mat()
	_ring.scale = Vector2(1.0, 0.32)
	_ring.position = Vector2(0, 62)
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("gua_flash", 220, Color(1.0, 0.95, 0.70, 0.9), 0.15)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	# ---- poeira de luz subindo POR DENTRO do pilar
	_dust = CPUParticles2D.new()
	_dust.material = Vfx.add_mat()
	_dust.texture = Vfx.radial("gua_dust", 12, Color(1.0, 0.92, 0.60, 0.95), 0.45)
	_dust.emitting = false
	_dust.amount = 30
	_dust.lifetime = 0.55
	_dust.direction = Vector2(0, -1)
	_dust.spread = 10.0
	_dust.initial_velocity_min = 90.0
	_dust.initial_velocity_max = 170.0
	_dust.gravity = Vector2(0, -30)
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.2
	var cg := Gradient.new()
	cg.offsets = [0.0, 0.3, 1.0]
	cg.colors = [Color(1, 0.97, 0.8, 0.0), Color(1, 0.92, 0.6, 0.95), Color(1, 0.8, 0.35, 0.0)]
	_dust.color_ramp = cg
	add_child(_dust)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	# ---------------- pilar desce do céu (0,06 .. 0,30)
	var gk: float = clampf((t - 0.06) / 0.24, 0.0, 1.0)
	var gk_e: float = gk * gk * (3.0 - 2.0 * gk)
	var fade: float = clampf(1.0 - (t - 0.78) / 0.22, 0.0, 1.0) if t > 0.78 else 1.0
	var flick: float = 0.86 + 0.14 * sin(t * 31.0) * sin(t * 17.0 + 1.7)
	if gk > 0.0:
		var s: float = maxf(0.02, gk_e)
		_beam.scale = Vector2(1.0 + 0.05 * sin(t * 23.0), s)
		_beam.position = Vector2(0, TOP_Y + BEAM_H * s * 0.5)
		_beam.modulate = Color(1, 1, 1, clampf(gk * 3.0, 0.0, 1.0) * flick * fade)
	# ---------------- chão + lavagem (0,26 ..)
	if t > 0.26:
		var ck: float = clampf((t - 0.26) / 0.16, 0.0, 1.0)
		_ground.modulate = Color(1, 1, 1, ck * (0.7 + 0.12 * sin(t * 12.0)) * fade)
		_glow.modulate = Color(1, 1, 1, ck * (0.55 + 0.12 * sin(t * 15.0 + 0.6)) * fade)
		var rk: float = clampf((t - 0.26) / 0.5, 0.0, 1.0)
		_ring.modulate = Color(1, 1, 1, (1.0 - rk) * 0.8 * fade)
		_ring.scale = Vector2(1.0, 0.32) * (0.35 + rk * 1.5)
		if not _dust.emitting:
			_dust.emitting = true
	# clarão curto quando o pilar firma (0,30)
	if t > 0.30:
		if not _firm_played:
			_firm_played = true
			Sfx.play("guardiao", position.x, 0.8)
		var fk2: float = clampf(1.0 - (t - 0.30) / 0.22, 0.0, 1.0)
		_flash.modulate = Color(1, 1, 1, fk2 * fk2 * 0.8)
		_flash.scale = Vector2.ONE * (0.55 + (1.0 - fk2) * 0.7)
	if t >= DUR and not _done:
		_done = true
		finished.emit()
		queue_free()
