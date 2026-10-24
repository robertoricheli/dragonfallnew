class_name FxCardShard
extends Node2D
## (1.49.64) PEDAÇO da carta campeão destruída: um polígono irregular que
## carrega a própria arte bakeada da carta (via UV), como um caco de vidro/
## pedra. Voa para fora com gravidade, gira no ar e desvanece perto do fim
## (estilhaçamento estilo Hearthstone).

var pts := PackedVector2Array()    # polígono local, centrado no centróide
var uvs := PackedVector2Array()    # UVs em pixels da textura
var tex: Texture2D = null
var vel := Vector2.ZERO
var spin := 0.0
var gravity := 720.0
var life := 0.0
var fade_at := 0.38
var gone_at := 0.95
var _edge := PackedVector2Array()


func setup(p_pts: PackedVector2Array, p_uvs: PackedVector2Array, p_tex: Texture2D, p_vel: Vector2, p_spin: float) -> void:
	pts = p_pts
	uvs = p_uvs
	tex = p_tex
	vel = p_vel
	spin = p_spin
	_edge = PackedVector2Array(pts)
	_edge.append(pts[0])


func _process(d: float) -> void:
	life += d
	vel.y += gravity * d
	vel *= 1.0 - 0.55 * d          # arrasto do ar
	position += vel * d
	rotation += spin * d
	if life > fade_at:
		modulate.a = clampf(1.0 - (life - fade_at) / (gone_at - fade_at), 0.0, 1.0)
	if life >= gone_at:
		queue_free()


func _draw() -> void:
	if pts.size() < 3:
		return
	var cols := PackedColorArray()
	for i in pts.size():
		cols.append(Color(1, 1, 1, 1))
	if tex != null:
		draw_polygon(pts, cols, uvs, tex)
	else:
		draw_polygon(pts, cols)
	# borda escura = o "corte" do estilhaço
	draw_polyline(_edge, Color(0.04, 0.03, 0.05, 0.85), 1.3)
