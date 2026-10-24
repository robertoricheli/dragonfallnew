class_name Profile
## Perfil do jogador: nome, avatar/moldura, fundo, XP, moedas, estatísticas,
## conquistas, jornada e rank local. Persistido em user://profile.cfg.
## Conquistas/jornada/rank portados (imitados) do projeto original do GitHub
## (df-achievements.mjs, df-journey.mjs, df-rank.mjs).

const PATH := "user://profile.cfg"

const AVATAR_COLORS := [
	Color(0.45, 0.25, 0.6), Color(0.15, 0.4, 0.65), Color(0.2, 0.5, 0.3),
	Color(0.6, 0.45, 0.15), Color(0.6, 0.2, 0.25), Color(0.35, 0.35, 0.45),
	Color(0.5, 0.25, 0.45), Color(0.25, 0.5, 0.5),
]
const FRAME_STYLES := [
	{"name": "Ouro", "color": Color(0.95, 0.8, 0.4), "w": 3},
	{"name": "Prata", "color": Color(0.8, 0.82, 0.86), "w": 3},
	{"name": "Bronze", "color": Color(0.75, 0.48, 0.25), "w": 3},
	{"name": "Neon", "color": Color(0.4, 0.95, 1.0), "w": 4},
]
const BACKGROUNDS := [
	{"name": "Pedra Arcana", "path": "res://assets/bg_battle.jpg"},
	{"name": "Dragão Rúnico", "path": "res://assets/bg_menu.jpg"},
	{"name": "Capa Dragonfall", "path": "res://assets/CAPA_DO_JOGO_NOVA.png"},
	{"name": "Sólido Escuro", "path": ""},
]

# --- Jornada (igual ao original): herói por nível; demais níveis = 4 moedas ---
const JOURNEY_MAX_LEVEL := 62
const JOURNEY_COINS := 4
const XP_PER_LEVEL := 10
const HERO_LEVELS := {
	1: "euravia", 5: "ironGuard", 8: "iceWitch", 11: "thor", 14: "vaughan",
	17: "linguarudo", 20: "pirate", 23: "princesaSlime", 26: "quimera",
	29: "diablos", 32: "hercules", 35: "paladino", 38: "tristana",
	41: "tecnomago", 44: "sinistrela", 47: "alquimista", 50: "estrelar",
	53: "gancho", 56: "valmont", 59: "sangueDragao", 62: "jekiro",
}

# --- Rank local (faixas do original, por % de vitórias, mín. 15 partidas) ---
const RANK_MIN_MATCHES := 15
const RANK_TIERS := [
	{"id": "bronze", "name": "Bronze", "min": 25, "coins": 10},
	{"id": "silver", "name": "Prata", "min": 50, "coins": 20},
	{"id": "gold", "name": "Ouro", "min": 60, "coins": 30},
	{"id": "diamond", "name": "Diamante", "min": 65, "coins": 40},
	{"id": "platinum", "name": "Platina", "min": 70, "coins": 50},
	{"id": "challenger", "name": "Desafiante", "min": 80, "coins": 60},
	{"id": "mythic", "name": "Mítico", "min": 90, "coins": 70},
]

# --- Conquistas (famílias do original) ---
const ACH_FAMILIES := [
	{"family": "duelist", "name": "Duelista", "metric": "matches", "goals": [10, 50, 100, 200, 500]},
	{"family": "scourge", "name": "Flagelo da IA", "metric": "aiWins", "goals": [10, 50, 100, 200, 500]},
	{"family": "collector", "name": "Colecionador", "metric": "cards", "goals": [30, 50, 80, 100, 120]},
	{"family": "openhand", "name": "Mão Aberta", "metric": "coinsSpent", "goals": [20, 50, 100, 200, 400]},
	{"family": "victor", "name": "Vitorioso", "metric": "pvpWins", "goals": [10, 20, 50, 70, 100]},
	{"family": "hunter", "name": "Caçador", "metric": "champKills", "goals": [20, 50, 100, 200, 500]},
	{"family": "heroes", "name": "Coleção de Heróis", "metric": "heroes", "goals": [5, 10, 15, 20, 25]},
	{"family": "fury", "name": "Fúria", "metric": "bestStreak", "goals": [2, 4, 6, 8, 10]},
	{"family": "master", "name": "Mestre", "metric": "bigWins", "goals": [10, 20, 30, 40, 50]},
]
const TIER_COINS := [2, 4, 6, 8, 10]

static var data := {
	"name": "Jogador",
	"xp": 0,
	"coins": 3,
	"owned": [],
	"offers": [],
	"avatar_color": 0,
	"avatar_frame": 0,
	"bg": 0,
	"stats": {
		"matches": 0, "aiWins": 0, "pvpWins": 0, "champKills": 0,
		"coinsSpent": 0, "streak": 0, "bestStreak": 0, "bigWins": 0,
		"summons": 0, "attacks": 0, "talents": 0, "ultimates": 0,
	},
	"cards_played": [],   # nomes únicos jogados (collector)
	"heroes_played": [],  # ids únicos (heroes)
	"claimed": [],        # ids de conquistas já recompensadas
	"journey_claimed": 0, # último nível de jornada já recompensado
}
static var loaded := false


static func ensure() -> void:
	if loaded:
		return
	loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in ["name", "xp", "coins", "owned", "offers", "avatar_color", "avatar_frame", "bg", "cards_played", "heroes_played", "claimed", "journey_claimed"]:
		if cf.has_section_key("p", k):
			data[k] = cf.get_value("p", k)
	if cf.has_section("stats"):
		var st: Dictionary = data["stats"]
		for k in st:
			if cf.has_section_key("stats", k):
				st[k] = int(cf.get_value("stats", k))


static func save() -> void:
	var cf := ConfigFile.new()
	for k in ["name", "xp", "coins", "owned", "offers", "avatar_color", "avatar_frame", "bg", "cards_played", "heroes_played", "claimed", "journey_claimed"]:
		cf.set_value("p", k, data[k])
	var st: Dictionary = data["stats"]
	for k in st:
		cf.set_value("stats", k, st[k])
	cf.save(PATH)


static func player_name() -> String:
	ensure()
	return String(data["name"])


static func level() -> int:
	ensure()
	return clampi(1 + int(int(data["xp"]) / XP_PER_LEVEL), 1, JOURNEY_MAX_LEVEL)


static func level_progress() -> float:
	ensure()
	var lv := level()
	if lv >= JOURNEY_MAX_LEVEL:
		return 1.0
	var base := (lv - 1) * XP_PER_LEVEL
	return clampf(float(int(data["xp"]) - base) / float(XP_PER_LEVEL), 0.0, 1.0)


static func rank_tier() -> Dictionary:
	ensure()
	var st: Dictionary = data["stats"]
	var m: int = int(st["matches"])
	if m < RANK_MIN_MATCHES:
		return {"name": "Sem Rank", "need": RANK_MIN_MATCHES - m}
	var pct: float = float(int(st["aiWins"]) + int(st["pvpWins"])) / float(m) * 100.0
	var tier: Dictionary = {"name": "Sem Rank", "pct": pct}
	for t in RANK_TIERS:
		if pct >= float(t["min"]):
			tier = t
			tier["pct"] = pct
	return tier


static func metric_value(metric: String) -> int:
	ensure()
	var st: Dictionary = data["stats"]
	match metric:
		"matches": return int(st["matches"])
		"aiWins": return int(st["aiWins"])
		"pvpWins": return int(st["pvpWins"])
		"champKills": return int(st["champKills"])
		"coinsSpent": return int(st["coinsSpent"])
		"bestStreak": return int(st["bestStreak"])
		"bigWins": return int(st["bigWins"])
		"cards": return (data["cards_played"] as Array).size()
		"heroes": return (data["heroes_played"] as Array).size()
	return 0


static func achievement_state(fam: Dictionary) -> Array:
	## Por nível: {tier, goal, coins, done, claimed, value}
	ensure()
	var out := []
	var val: int = metric_value(String(fam["metric"]))
	var goals: Array = fam["goals"]
	for i in goals.size():
		var aid: String = "%s%d" % [fam["family"], i + 1]
		out.append({
			"tier": i + 1,
			"goal": goals[i],
			"coins": TIER_COINS[i],
			"value": val,
			"done": val >= int(goals[i]),
			"claimed": (data["claimed"] as Array).has(aid),
			"id": aid,
		})
	return out


static func claim_achievements() -> int:
	## Recompensa automática de níveis recém-concluídos. Retorna moedas ganhas.
	ensure()
	var gained := 0
	for fam in ACH_FAMILIES:
		for a in achievement_state(fam):
			if a["done"] and not a["claimed"]:
				(data["claimed"] as Array).append(a["id"])
				data["coins"] = int(data["coins"]) + int(a["coins"])
				gained += int(a["coins"])
	if gained > 0:
		save()
	return gained


static func claim_journey() -> int:
	## Moedas de níveis de jornada alcançados (+JOURNEY_COINS por nível).
	ensure()
	var lv := level()
	var gained := 0
	var jc: int = int(data["journey_claimed"])
	while jc < lv:
		jc += 1
		if not HERO_LEVELS.has(jc):
			data["coins"] = int(data["coins"]) + JOURNEY_COINS
			gained += JOURNEY_COINS
	data["journey_claimed"] = jc
	if gained > 0:
		save()
	return gained


static func journey_reward(lv: int) -> String:
	if HERO_LEVELS.has(lv):
		for h in CardDB.HEROES:
			if h["id"] == HERO_LEVELS[lv]:
				return "Herói: " + String(h["name"])
	return "%d moedas" % JOURNEY_COINS


static func add_match_rewards(win: bool) -> Dictionary:
	ensure()
	var r := {"xp": 2, "coins": 0}
	if win:
		r = {"xp": 4, "coins": 1}
	data["xp"] = int(data["xp"]) + r["xp"]
	data["coins"] = int(data["coins"]) + r["coins"]
	save()
	return r


static func record_match(win: bool, margin: int, match_stats: Dictionary, cards_used: Array, hero_id: String) -> void:
	ensure()
	var st: Dictionary = data["stats"]
	st["matches"] = int(st["matches"]) + 1
	if win:
		st["aiWins"] = int(st["aiWins"]) + 1
		st["streak"] = int(st["streak"]) + 1
		st["bestStreak"] = maxi(int(st["bestStreak"]), int(st["streak"]))
		if margin >= 10:
			st["bigWins"] = int(st["bigWins"]) + 1
	else:
		st["streak"] = 0
	for k in ["champKills", "summons", "attacks", "talents", "ultimates"]:
		if match_stats.has(k):
			st[k] = int(st[k]) + int(match_stats[k])
	var cp: Array = data["cards_played"]
	for cn in cards_used:
		if not cp.has(String(cn)):
			cp.append(String(cn))
	var hp: Array = data["heroes_played"]
	if hero_id != "" and not hp.has(hero_id):
		hp.append(hero_id)
	save()
	claim_achievements()
	claim_journey()


static func spend(n: int) -> bool:
	ensure()
	if int(data["coins"]) >= n:
		data["coins"] = int(data["coins"]) - n
		data["stats"]["coinsSpent"] = int(data["stats"]["coinsSpent"]) + n
		save()
		return true
	return false


static func price_of(card: Dictionary) -> int:
	return 2 + int(card.get("power", 0))


static func ensure_offers() -> void:
	ensure()
	if (data["offers"] as Array).size() < 6:
		var pool: Array = CardDB.playable_defs().duplicate()
		pool.shuffle()
		var names := []
		for c in pool:
			if names.size() >= 6:
				break
			names.append(String(c["name"]))
		data["offers"] = names
		save()


static func reroll() -> bool:
	ensure()
	if spend(1):
		data["offers"] = []
		ensure_offers()
		save()
		return true
	return false


static func avatar_color() -> Color:
	ensure()
	return AVATAR_COLORS[clampi(int(data["avatar_color"]), 0, AVATAR_COLORS.size() - 1)]


static func frame_style() -> Dictionary:
	ensure()
	return FRAME_STYLES[clampi(int(data["avatar_frame"]), 0, FRAME_STYLES.size() - 1)]


static func bg_path() -> String:
	ensure()
	return String(BACKGROUNDS[clampi(int(data["bg"]), 0, BACKGROUNDS.size() - 1)]["path"])


static func initials_of(txt: String) -> String:
	var words := txt.split(" ")
	var ini := String(words[0]).left(1)
	if words.size() > 1:
		ini += String(words[words.size() - 1]).left(1)
	return ini.to_upper()
