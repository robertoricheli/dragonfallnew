class_name DeckStore
## Persistência dos 5 baralhos do jogador (até 20 cartas cada).

const PATH := "user://decks.cfg"


static func load_decks() -> Array:
	var decks := []
	for i in 5:
		decks.append({"name": "Baralho %d" % (i + 1), "cards": []})
	if not FileAccess.file_exists(PATH):
		return decks
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return decks
	for i in 5:
		var sec := "deck%d" % i
		if cf.has_section(sec):
			decks[i]["name"] = String(cf.get_value(sec, "name", decks[i]["name"]))
			decks[i]["cards"] = Array(cf.get_value(sec, "cards", []))
	return decks


static func save_decks(decks: Array) -> void:
	var cf := ConfigFile.new()
	for i in 5:
		var sec := "deck%d" % i
		cf.set_value(sec, "name", decks[i]["name"])
		cf.set_value(sec, "cards", decks[i]["cards"])
	cf.save(PATH)
