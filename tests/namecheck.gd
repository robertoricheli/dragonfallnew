extends SceneTree
func _init() -> void:
	var names := ["GUERREIRO CÚBICO CORROMPIDO", "CAVALEIRO JURAMENTADO", "LILITH", "PRISÃO PRISMÁTICA", "OLAF, O DESTROÇADOR DE MUNDOS"]
	for n in names:
		var card := {"name": n, "category": "champion", "subcategory": ""}
		var L: Dictionary = CardArt.layout_for(card, 110.0, 154.0)
		var f: Font = CardArt.baloo(800)
		var r: Rect2 = (L["zones"] as Dictionary)["name"]
		var fs: int = int(L["name_fs"])
		var kx: float = float(L["name_kx"])
		var w: float = f.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x * kx
		print("NAME %s | fs=%d kx=%.2f larg=%.1f disp=%.1f cabe=%s" % [n, fs, kx, w, r.size.x * 0.98, w <= r.size.x * 0.98 + 0.5])
	quit(0)
