class_name Vfx
extends RefCounted
## Texturas procedurais de partículas (alta qualidade, aditivas) para VFX.

static var _cache := {}


static func radial(key: String, size: int, col: Color, hardness: float = 0.25) -> ImageTexture:
	var k := "%s%d" % [key, size]
	if _cache.has(k):
		return _cache[k]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: float = size / 2.0
	for y in size:
		for x in size:
			var d: float = Vector2(x - c, y - c).length() / c
			var a: float = clampf(1.0 - smoothstep(hardness, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * col.a))
	var tex := ImageTexture.create_from_image(img)
	_cache[k] = tex
	return tex


static func ring(key: String, size: int, col: Color, thick: float = 0.16) -> ImageTexture:
	var k := "%s%d" % [key, size]
	if _cache.has(k):
		return _cache[k]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: float = size / 2.0
	for y in size:
		for x in size:
			var d: float = Vector2(x - c, y - c).length() / c
			var a: float = clampf(1.0 - absf(d - 0.8) / thick, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * col.a))
	var tex := ImageTexture.create_from_image(img)
	_cache[k] = tex
	return tex


static func spark(size: int, col: Color) -> ImageTexture:
	var key := "spark%d" % size
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c: float = size / 2.0
	for y in size:
		for x in size:
			var p := Vector2(x - c, y - c) / c
			var d: float = p.length()
			var star: float = maxf(absf(p.x), absf(p.y)) * 0.6 + d * 0.4
			var a: float = clampf(1.0 - smoothstep(0.15, 1.0, star), 0.0, 1.0)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * col.a))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static var _add_mat: CanvasItemMaterial = null


static func add_mat() -> CanvasItemMaterial:
	## Material aditivo compartilhado (brilho/fogo): o jeito correto no Godot 4.
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat
