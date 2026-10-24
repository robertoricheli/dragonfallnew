extends SceneTree
func _init() -> void:
	for p in ["res://assets/CAPA_DO_JOGO_NOVA.png", "res://assets/bg_menu.jpg", "res://assets/MOLDURA_CAMPEAO_FINAL.png", "res://assets/MOLDURA_TALENTO_FINAL.png", "res://assets/MOLDURA_REACAO_FINAL.png", "res://assets/VERSO_DAS_CARTAS.png"]:
		var t = load(p)
		print(p, " -> ", (t.get_size() if t else "NULL"))
	quit(0)
