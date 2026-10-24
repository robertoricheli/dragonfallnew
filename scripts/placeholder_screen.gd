class_name PlaceholderScreen
extends ScreenBase
## Tela reservada (EM CONSTRUÇÃO) com editor: RANK, PASSE, HISTÓRIA,
## COMO JOGAR, OPÇÕES do menu.


func setup_screen(title: String, subtitle: String, cfg: String, show_rank := false) -> void:
	_base_setup(title, cfg)
	var l := _lbl(Vector2(340, 260), Vector2(600, 60), 34, Color(0.9, 0.88, 0.95), true)
	l.text = "EM CONSTRUÇÃO"
	reg("big", l, Rect2(340, 260, 600, 60))
	var l2 := _lbl(Vector2(340, 330), Vector2(600, 40), 14, Color(0.7, 0.68, 0.8), true)
	l2.text = subtitle
	reg("sub", l2, Rect2(340, 330, 600, 40))
	if show_rank:
		var rk: Dictionary = Profile.rank_tier()
		var l3 := _lbl(Vector2(340, 390), Vector2(600, 60), 14, Color(1, 0.85, 0.4), true)
		if rk.has("need"):
			l3.text = "Rank local atual: Sem Rank (faltam %d partidas ranqueadas)" % int(rk["need"])
		else:
			l3.text = "Rank local atual: %s (%.0f%% de vitórias)" % [rk.get("name", ""), rk.get("pct", 0.0)]
		reg("rank", l3, Rect2(340, 390, 600, 60))
	_base_finish()
