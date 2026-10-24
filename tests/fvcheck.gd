extends SceneTree
func _init() -> void:
	var fv := FontVariation.new()
	var names: Array = []
	for p in fv.get_property_list():
		names.append(String(p["name"]))
	print("FV_PROPS=", names)
	quit(0)
