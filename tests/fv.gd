extends SceneTree
func _init() -> void:
	var f: Font = load("res://assets/font/Baloo2.ttf")
	var ms := f.get_method_list().map(func(m): return m["name"])
	print("has get_string_image: ", ms.has("get_string_image"))
	var img: Image = f.get_string_image("Olá", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20)
	print("img: ", img.get_width(), "x", img.get_height(), " mode=", img.get_format())
	quit(0)
