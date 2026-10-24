extends SceneTree
func _init() -> void:
	var holder := Control.new()
	holder.size = Vector2(1280, 720)
	get_root().add_child(holder)
	for nm in ["SIR DUNKAN", "FERAGROSS", "SCARLET", "ZERO ABSOLUTO"]:
		var def: Dictionary = {}
		for c in CardDB.playable_defs():
			if c["name"] == nm:
				def = c
				break
		for zf in [1.0, 3.2]:
			var v := CardView.new()
			v.setup(def, false, zf)
			holder.add_child(v)
			var d: Label = v._desc_label
			print(nm, " zf=", zf, " desc_fs=", d.get_theme_font_size("font_size"), " linhas=", d.text.split("\n").size(), " box_h=", d.size.y, " txt=", d.text.replace("\n", " | "))
			v.queue_free()
	quit(0)
