class_name OvoFX
extends Node2D
## (1.49.97) HABILIDADE/CARTA TALENTO INVOCAR DRAGÃO — animação vinda do
## VÍDEO do dono ("OVO DE DRAGÃO", 67 frames recortados do fundo PRETO com
## keying profissional por conectividade: NADA do fundo preto aparece;
## pretos internos da arte preservados; bordas semi-transparentes com
## unblend; vinheta suave dissolve as lascas laterais): o ovo aparece
## SOMENTE no SLOT do Filhote (<= 112 px de largura, <= 140 px de altura):
## NUNCA encosta no campeão que usou a habilidade nem em outro cartão.
## Um glow aditivo pulsante atrás do núcleo preenche o miolo de luz como se
## a luz viesse de dentro; polimento local contido (sombra, anel rúnico,
## clarão de slot, lascas e faíscas). IMMEDIATAMENTE após o fim do vídeo o
## Filhote surge (burst em 1.97 s -> resolve_invoke_dragon; finished 2.0 s).
## Uso: add_child(fx); fx.setup(centro_do_slot)

signal burst
signal finished

const DUR := 2.0
const BURST_AT := 1.97
const N_FRAMES := 67
const MAX_W := 112.0         # px: NUNCA encosta no campeão ao lado (slot 100 + folga)
const MAX_H := 140.0         # px em campo (< 140 da carta)

var _t := 0.0
var _done := false
var _bursted := false
var _started := false
var _frame := -1
var _scale := 1.0

var _seq: Sprite2D
var _core: Sprite2D          # glow atrás do núcleo (luz "de dentro")
var _bloom: Sprite2D         # bloom aditivo suave na frente
var _shadow: Sprite2D
var _rune: Sprite2D
var _flash: Sprite2D
var _ring: Sprite2D
var _shards: Array = []
var _sparkles: CPUParticles2D
var _frames: Array = []


func _init() -> void:
	for i in N_FRAMES:
		_frames.append(load("res://assets/FILHOTE_DE_DRAGAO_F%02d.png" % (i + 1)))


func setup(at: Vector2) -> void:
	position = at
	z_index = 86
	_started = true
	var tex: Texture2D = _frames[0]
	_scale = minf(MAX_W / float(tex.get_width()), MAX_H / float(tex.get_height()))
	# ---- sombra contida no slot
	_shadow = Sprite2D.new()
	_shadow.texture = Vfx.radial("ovo3_shadow", 90, Color(0.0, 0.0, 0.0, 0.5), 0.1)
	_shadow.scale = Vector2(1.0, 0.3)
	_shadow.position = Vector2(0, 60)
	_shadow.modulate = Color(1, 1, 1, 0)
	add_child(_shadow)
	# ---- anel rúnico do slot
	_rune = Sprite2D.new()
	_rune.texture = Vfx.ring("ovo3_rune", 105, Color(0.35, 0.95, 0.75, 0.8), 0.05)
	_rune.material = Vfx.add_mat()
	_rune.scale = Vector2(1.0, 0.34)
	_rune.position = Vector2(0, 60)
	_rune.modulate = Color(1, 1, 1, 0)
	add_child(_rune)
	# ---- glow do núcleo ATRÁS do frame: a luz "vaza" de dentro do ovo
	_core = Sprite2D.new()
	_core.texture = Vfx.radial("ovo3_core", 110, Color(1.0, 0.85, 0.45, 0.95), 0.18)
	_core.material = Vfx.add_mat()
	_core.modulate = Color(1, 1, 1, 0)
	_core.position = Vector2(0, -6)
	add_child(_core)
	# ---- o vídeo em frames
	_seq = Sprite2D.new()
	_seq.texture = _frames[0]
	_seq.centered = true
	_seq.scale = Vector2(_scale, _scale)
	_seq.modulate = Color(1, 1, 1, 0)
	add_child(_seq)
	# ---- bloom suave na frente
	_bloom = Sprite2D.new()
	_bloom.texture = Vfx.radial("ovo3_bloom", 90, Color(1.0, 0.90, 0.55, 0.5), 0.3)
	_bloom.material = Vfx.add_mat()
	_bloom.modulate = Color(1, 1, 1, 0)
	_bloom.position = Vector2(0, -6)
	add_child(_bloom)
	# ---- clarão contido no slot (choco)
	_flash = Sprite2D.new()
	_flash.texture = Vfx.radial("ovo3_flash", 150, Color(1.0, 0.92, 0.60, 0.85), 0.22)
	_flash.material = Vfx.add_mat()
	_flash.modulate = Color(1, 1, 1, 0)
	add_child(_flash)
	_ring = Sprite2D.new()
	_ring.texture = Vfx.ring("ovo3_ring", 115, Color(1.0, 0.88, 0.50, 0.85), 0.06)
	_ring.material = Vfx.add_mat()
	_ring.modulate = Color(1, 1, 1, 0)
	add_child(_ring)
	for i in 6:
		var sh := Sprite2D.new()
		sh.texture = Vfx.spark(16, Color(0.95, 0.75, 0.40))
		sh.material = Vfx.add_mat()
		sh.modulate = Color(1, 1, 1, 0)
		add_child(sh)
		_shards.append({
			"n": sh,
			"dir": Vector2(randf_range(-1, 1), randf_range(-1.0, -0.1)).normalized(),
			"sp": randf_range(55.0, 100.0),
			"sc": randf_range(0.7, 1.3),
		})
	_sparkles = CPUParticles2D.new()
	_sparkles.texture = Vfx.spark(18, Color(1.0, 0.88, 0.50))
	_sparkles.material = Vfx.add_mat()
	_sparkles.emitting = false
	_sparkles.amount = 26
	_sparkles.lifetime = 0.5
	_sparkles.explosiveness = 0.9
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 180.0
	_sparkles.initial_velocity_min = 40.0
	_sparkles.initial_velocity_max = 110.0
	_sparkles.gravity = Vector2(0, 180)
	_sparkles.scale_amount_min = 0.5
	_sparkles.scale_amount_max = 1.1
	add_child(_sparkles)


func _process(delta: float) -> void:
	if not _started:
		return
	_t += delta
	var t := _t
	var k: float = clampf(t / DUR, 0.0, 1.0)
	# ---- frames do vídeo em cadência uniforme (54 frames / 2,0 s = 27 fps)
	var idx := mini(N_FRAMES - 1, int(k * N_FRAMES))
	if idx != _frame:
		_frame = idx
		_seq.texture = _frames[idx]
	# ---- entrada suave + respiração
	var mk: float = clampf(t / 0.25, 0.0, 1.0)
	_seq.modulate = Color(1, 1, 1, Ease.out_cubic(mk))
	var sc: float = _scale * lerpf(0.8, 1.0, Ease.out_cubic(mk)) * (1.0 + 0.012 * sin(t * 9.0))
	_seq.scale = Vector2(sc, sc)
	_seq.position = Vector2(0, sin(t * 3.0) * 1.5)
	# ---- glow do núcleo cresce com a rachadura (frames 18..54)
	var ck: float = clampf((t - 0.6) / 1.2, 0.0, 1.0)
	_core.modulate = Color(1, 1, 1, ck * (0.55 + 0.25 * sin(t * 14.0)))
	_core.scale = Vector2.ONE * (0.5 + ck * 0.7)
	_bloom.modulate = Color(1, 1, 1, ck * 0.35)
	_bloom.scale = Vector2.ONE * (0.6 + ck * 0.5)
	# ---- chão local
	_shadow.modulate = Color(1, 1, 1, mk * 0.75)
	_rune.modulate = Color(1, 1, 1, (sin(mk * PI) * 0.7 if t < 0.7 else 0.25 + 0.3 * ck * absf(sin(t * 12.0))))
	_rune.rotation += delta * 0.9
	# ---- choco contido no fim do vídeo
	if t >= BURST_AT - 0.25:
		var hk: float = clampf((t - (BURST_AT - 0.25)) / 0.2, 0.0, 1.0)
		var hf: float = clampf(1.0 - (t - BURST_AT) / 0.2, 0.0, 1.0) if t > BURST_AT else 1.0
		_flash.modulate = Color(1, 1, 1, hk * hf * 0.8)
		_flash.scale = Vector2.ONE * (0.5 + hk * 0.6)
		_ring.modulate = Color(1, 1, 1, hk * hf * 0.75)
		_ring.scale = Vector2(0.35 + hk * 0.75, 0.14 + hk * 0.3)
		if not _sparkles.emitting:
			_sparkles.emitting = true
			_sparkles.restart()
		for sh in _shards:
			var n: Sprite2D = sh["n"]
			var st: float = t - (BURST_AT - 0.25)
			var life := 0.4
			if st > life:
				n.modulate = Color(1, 1, 1, 0)
				continue
			n.position = Vector2(0, -6) + sh["dir"] * sh["sp"] * st + Vector2(0, 120.0 * st * st)
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
