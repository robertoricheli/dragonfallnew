class_name FireballFX
extends Node2D
## VFX BOLA DE FOGO (estilo Hearthstone, vista 100% de cima):
## núcleo flamejante sai da carta, voa em arco deixando rastro de brasas/fumaça,
## e EXPLODE no alvo com clarão, anel de choque, faíscas, fogo e fumaça.

signal exploded(at: Vector2)

var from := Vector2.ZERO
var to := Vector2.ZERO
var dur := 1.5      # voo de no MÍNIMO 1,5 s (regra do jogador)
var arc := 140.0
var _t := -1.0   # <0 = aguardando início
var _done := false
var _core: Sprite2D
var _glow: Sprite2D
var _trail: CPUParticles2D
var _smoke_trail: CPUParticles2D


func setup(p_from: Vector2, p_to: Vector2, p_dur: float = 1.5, p_arc: float = 140.0) -> void:
	from = p_from
	to = p_to
	dur = p_dur
	arc = p_arc
	position = from
	# núcleo de fogo (aditivo, pulsa)
	_core = Sprite2D.new()
	_core.texture = Vfx.radial("fire", 96, Color(1.0, 0.75, 0.25, 1.0), 0.1)
	_core.material = Vfx.add_mat()
	_core.scale = Vector2(0.55, 0.55)
	add_child(_core)
	_glow = Sprite2D.new()
	_glow.texture = Vfx.radial("glow", 160, Color(1.0, 0.45, 0.12, 0.75), 0.0)
	_glow.material = Vfx.add_mat()
	_glow.scale = Vector2(0.9, 0.9)
	add_child(_glow)
	# rastro de brasas
	_trail = _particles(60, 0.38, Vfx.spark(24, Color(1.0, 0.7, 0.2, 0.9)), 26.0, 0.0, 1)
	add_child(_trail)
	# fumaça do rastro
	_smoke_trail = _particles(26, 0.7, Vfx.radial("smoke", 64, Color(0.25, 0.2, 0.2, 0.5), 0.0), 12.0, -14.0, 0)
	add_child(_smoke_trail)


func _particles(amount: int, life: float, tex: Texture2D, speed: float, grav: float, blend: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.texture = tex
	p.emitting = true
	p.one_shot = false
	p.explosiveness = 0.0
	p.speed_scale = 1.0
	p.direction = Vector2(0, 0)
	p.spread = 180.0
	p.gravity = Vector2(0, grav)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.damping_min = 20.0
	p.damping_max = 40.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	if blend == 1:
		p.material = Vfx.add_mat()
	var ramp := Gradient.new()
	ramp.colors = [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
	p.color_ramp = ramp
	return p


func _process(d: float) -> void:
	if _t < 0.0:
		_t = 0.0
		return
	if not _done:
		_t += d
		var t: float = clampf(_t / dur, 0.0, 1.0)
		var u := 1.0 - t
		var mid := (from + to) / 2.0 + Vector2(0, -arc)
		position = u * u * from + 2.0 * u * t * mid + t * t * to
		var pulse := 1.0 + 0.12 * sin(_t * 40.0)
		_core.scale = Vector2(0.55 * pulse * (0.8 + 0.4 * t), 0.55 * pulse * (0.8 + 0.4 * t))
		_core.rotation += d * 6.0
		_glow.scale = Vector2(0.9 + 0.15 * sin(_t * 30.0), 0.9 + 0.15 * sin(_t * 30.0))
		if t >= 1.0:
			_done = true
			_explode()
	elif _t > dur + 2.4:
		queue_free()


func _explode() -> void:
	Sfx.play("fireball_hit", global_position.x, 1.0)
	_trail.emitting = false
	_smoke_trail.emitting = false
	_core.visible = false
	_glow.visible = false
	var at := Vector2.ZERO  # local
	# clarão aditivo grande
	var flash := Sprite2D.new()
	flash.texture = Vfx.radial("flash", 220, Color(1.0, 0.85, 0.45, 0.95), 0.0)
	flash.material = Vfx.add_mat()
	flash.position = at
	flash.scale = Vector2(0.4, 0.4)
	add_child(flash)
	var tw := flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector2(1.5, 1.5), 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(flash, "modulate:a", 0.0, 1.5)
	tw.chain().tween_callback(flash.queue_free)
	# anel de choque de fogo
	var ring := Sprite2D.new()
	ring.texture = Vfx.ring("shock", 190, Color(1.0, 0.6, 0.2, 0.95), 0.14)
	ring.material = Vfx.add_mat()
	ring.position = at
	ring.scale = Vector2(0.15, 0.15)
	add_child(ring)
	var tw2 := ring.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(ring, "scale", Vector2(1.35, 1.35), 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.tween_property(ring, "modulate:a", 0.0, 1.5)
	tw2.chain().tween_callback(ring.queue_free)
	# faíscas rápidas
	var sparks := _burst(48, 1.5, Vfx.spark(28, Color(1.0, 0.85, 0.3, 1.0)), 170.0, 1)
	add_child(sparks)
	# bolas de fogo espalhadas
	var fire := _burst(22, 1.6, Vfx.radial("firepuff", 72, Color(1.0, 0.5, 0.12, 0.95), 0.05), 90.0, 1)
	add_child(fire)
	# fumaça escura subindo (vista de cima: expande e some)
	var smoke := _burst(16, 1.9, Vfx.radial("smokebig", 96, Color(0.22, 0.18, 0.18, 0.55), 0.0), 34.0, 0)
	add_child(smoke)
	exploded.emit(global_position)


func _burst(amount: int, life: float, tex: Texture2D, speed: float, blend: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.texture = tex
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 0)
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.3
	if blend == 1:
		p.material = Vfx.add_mat()
	var ramp := Gradient.new()
	ramp.offsets = [0.0, 0.25, 1.0]
	ramp.colors = [Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
	p.color_ramp = ramp
	return p
