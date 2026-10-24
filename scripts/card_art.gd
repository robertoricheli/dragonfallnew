class_name CardArt
## Texturas das cartas: verso oficial e molduras finais das frentes
## (MOLDURA PRINCIPAL CAMPEÃO / TALENTO / REAÇÃO), em altíssima qualidade.

static var _verso: Texture2D = null
static var _fr_champ: Texture2D = null
static var _fr_tal: Texture2D = null
static var _fr_rea: Texture2D = null


static func verso() -> Texture2D:
	if _verso == null and ResourceLoader.exists("res://assets/VERSO_DAS_CARTAS.png"):
		_verso = load("res://assets/VERSO_DAS_CARTAS.png")
	return _verso


static func frame(category: String, subcategory: String = "") -> Texture2D:
	if category == "champion":
		if _fr_champ == null and ResourceLoader.exists("res://assets/MOLDURA_CAMPEAO_FINAL.png"):
			_fr_champ = load("res://assets/MOLDURA_CAMPEAO_FINAL.png")
		return _fr_champ
	if subcategory == "reaction":
		if _fr_rea == null and ResourceLoader.exists("res://assets/MOLDURA_REACAO_FINAL.png"):
			_fr_rea = load("res://assets/MOLDURA_REACAO_FINAL.png")
		return _fr_rea
	if _fr_tal == null and ResourceLoader.exists("res://assets/MOLDURA_TALENTO_FINAL.png"):
		_fr_tal = load("res://assets/MOLDURA_TALENTO_FINAL.png")
	return _fr_tal


## Retângulos normalizados (fração da carta) das zonas da moldura.
const Z_GEM := Rect2(0.05, 0.045, 0.17, 0.10)        # esfera do poder/custo
const Z_NAME := Rect2(0.232, 0.054, 0.697, 0.072)    # barra do nome
const Z_ART := Rect2(0.088, 0.161, 0.822, 0.576)     # janela de arte (futura)
const Z_ABIL := Rect2(0.128, 0.720, 0.743, 0.054)    # barra da habilidade (campeão)
const Z_DESC_CH := Rect2(0.081, 0.777, 0.838, 0.170) # descrição (campeão)
const Z_DESC_T := Rect2(0.081, 0.760, 0.838, 0.190)  # descrição (talento/reação)
const Z_TAB := Rect2(0.30, 0.958, 0.40, 0.038)       # selo inferior do tipo
const Z_STATUS := Rect2(0.09, 0.695, 0.82, 0.032)    # linha de status (campo)


static func heavy_font() -> Font:
	if not ResourceLoader.exists("res://assets/font/Heavy.ttf"):
		return null
	return load("res://assets/font/Heavy.ttf")


static func fit_fs(text: String, rect: Rect2, base: int, max_lines: int = 2, charw_f: float = 0.78) -> int:
	## Maior tamanho de fonte (<= base) que faz o texto CABER inteiro na rect.
	var fs := int(base)
	while fs > 4:
		var charw: float = fs * charw_f
		var lines: int = ceili(float(text.length()) * charw / maxf(1.0, rect.size.x * 0.94))
		if lines <= max_lines and lines * fs * 1.45 <= rect.size.y * 0.96:
			return fs
		fs -= 1
	return 3


static func inset(r: Rect2, fx: float, fy: float) -> Rect2:
	return Rect2(r.position.x + r.size.x * fx, r.position.y + r.size.y * fy, r.size.x * (1.0 - 2.0 * fx), r.size.y * (1.0 - 2.0 * fy))


static var _fred: Font = null
static var _fred_cache := {}


static func fredoka(weight: float = 500.0) -> Font:
	## Fredoka (variável) com peso OpenType "wght".
	if _fred == null:
		if not ResourceLoader.exists("res://assets/font/Fredoka.ttf"):
			return null
		_fred = load("res://assets/font/Fredoka.ttf")
	if weight <= 505:
		return _fred
	var key := int(weight)
	if not _fred_cache.has(key):
		var fv := FontVariation.new()
		fv.base_font = _fred
		fv.variation_opentype = {"wght": weight}
		_fred_cache[key] = fv
	return _fred_cache[key]


static var _baloo: Font = null
static var _baloo_cache := {}


static func baloo(weight: float = 600.0) -> Font:
	## Baloo 2 (variável 400-800) com peso OpenType — a fonte oficial das cartas.
	if _baloo == null:
		if not ResourceLoader.exists("res://assets/font/Baloo2.ttf"):
			return null
		_baloo = load("res://assets/font/Baloo2.ttf")
	if weight <= 450:
		return _baloo
	var key := int(weight)
	if not _baloo_cache.has(key):
		var fv := FontVariation.new()
		fv.base_font = _baloo
		fv.variation_opentype = {"wght": weight}
		_baloo_cache[key] = fv
	return _baloo_cache[key]


static func text_fits(font: Font, text: String, fs: int, box: Rect2, max_lines: int, wrapped: bool) -> bool:
	## Medição ANALÍTICA (sem depender de layout/frames): nunca falha por race.
	if font == null or fs <= 0:
		return false
	if not wrapped:
		var wtxt: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
		var lh: float = font.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).y
		return wtxt <= box.size.x + 1.0 and lh <= box.size.y + 1.0
	var lh2: float = font.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).y
	var space_w: float = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
	var lines := 1
	var cur := 0.0
	for word in text.split(" "):
		var ww: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
		if cur > 0.0 and cur + space_w + ww > box.size.x:
			lines += 1
			cur = ww
		else:
			cur += (space_w if cur > 0.0 else 0.0) + ww
	return lines <= max_lines and lines * lh2 <= box.size.y + 1.0


static func wrap_text(font: Font, text: String, fs: int, width: float) -> Array:
	## Quebra de linha própria (idêntica à métrica usada no ajuste).
	var lines := []
	var sw: float = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
	var cur := ""
	var curw := 0.0
	for word in text.split(" "):
		var ww: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
		if curw > 0.0 and curw + sw + ww > width:
			lines.append(cur)
			cur = word
			curw = ww
		else:
			cur = (cur + " " + word) if curw > 0.0 else word
			curw += (sw if curw > 0.0 else 0.0) + ww
	if cur != "":
		lines.append(cur)
	return lines


# ---------------------------------------------------------------------------
# Tipografia DETERMINÍSTICA centralizada: calculada 1x por carta no tamanho
# base e escalada proporcionalmente => miniatura == carta == zoom (cópia exata).
# ---------------------------------------------------------------------------

static var _layout_cache := {}
static var version := 0  # bump => rebake de todas as cartas
static var type_offsets := {}   # {cat: {elem: Vector2}}   (layout por TIPO)
static var type_scales := {}    # {cat: {elem: Vector2}}   (tamanho H/V por TIPO)
static var text_overrides := {} # {nome_carta: {"name":..,"desc":..}} (por CARTA)
static var _cfg_loaded := false
const CARD_CFG := "user://card_layout.cfg"


static func _t(cat: String, elem: String, r: Rect2) -> Rect2:
	var off: Vector2 = type_offsets.get(cat, {}).get(elem, Vector2.ZERO)
	var sc: Vector2 = type_scales.get(cat, {}).get(elem, Vector2.ONE)
	return Rect2(r.position + off, Vector2(r.size.x * sc.x, r.size.y * sc.y))


static func ensure_loaded() -> void:
	if _cfg_loaded:
		return
	_cfg_loaded = true
	if not FileAccess.file_exists(CARD_CFG):
		return
	var cf := ConfigFile.new()
	if cf.load(CARD_CFG) != OK:
		return
	for cat in ["champion", "talent", "reaction"]:
		for elem in ["gem", "name", "abil", "desc", "tab"]:
			if cf.has_section_key(cat, elem + "_off"):
				if not type_offsets.has(cat):
					type_offsets[cat] = {}
				type_offsets[cat][elem] = cf.get_value(cat, elem + "_off")
			if cf.has_section_key(cat, elem + "_scl"):
				if not type_scales.has(cat):
					type_scales[cat] = {}
				type_scales[cat][elem] = cf.get_value(cat, elem + "_scl")
	if cf.has_section("texts"):
		for key in cf.get_section_keys("texts"):
			text_overrides[key] = cf.get_value("texts", key)


static func save_card_layout() -> void:
	var cf := ConfigFile.new()
	for cat in type_offsets:
		for elem in type_offsets[cat]:
			cf.set_value(cat, elem + "_off", type_offsets[cat][elem])
	for cat in type_scales:
		for elem in type_scales[cat]:
			cf.set_value(cat, elem + "_scl", type_scales[cat][elem])
	for key in text_overrides:
		cf.set_value("texts", key, text_overrides[key])
	cf.save(CARD_CFG)


static func bump_offset(cat: String, elem: String, d: Vector2) -> void:
	if not type_offsets.has(cat):
		type_offsets[cat] = {}
	type_offsets[cat][elem] = type_offsets[cat].get(elem, Vector2.ZERO) + d
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func bump_scale(cat: String, elem: String, fx: float, fy: float) -> void:
	if not type_scales.has(cat):
		type_scales[cat] = {}
	var cur: Vector2 = type_scales[cat].get(elem, Vector2.ONE)
	type_scales[cat][elem] = Vector2(clampf(cur.x * fx, 0.5, 2.0), clampf(cur.y * fy, 0.5, 2.0))
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func zones_for(cat: String, sub: String, w0: float, h0: float) -> Dictionary:
	var gem := _t(cat, "gem", Rect2(Z_GEM.position.x * w0 - 0.004 * w0, (Z_GEM.position.y - 0.010) * h0, Z_GEM.size.x * w0, Z_GEM.size.y * h0))
	var nrect := _t(cat, "name", inset(Rect2(Z_NAME.position.x * w0, (Z_NAME.position.y - 0.006) * h0, Z_NAME.size.x * w0, Z_NAME.size.y * h0), 0.005, 0.02))
	var arect := Rect2()
	var atitle := Rect2()
	var drect := Rect2()
	if cat == "champion":
		arect = _t(cat, "abil", inset(Rect2(Z_ABIL.position.x * w0, (Z_ABIL.position.y - 0.006) * h0, Z_ABIL.size.x * w0, Z_ABIL.size.y * h0), 0.02, 0.08))
		drect = _t(cat, "desc", inset(Rect2(Z_DESC_CH.position.x * w0, Z_DESC_CH.position.y * h0, Z_DESC_CH.size.x * w0, Z_DESC_CH.size.y * h0), 0.03, 0.03))
	else:
		# TALENTO/REAÇÃO: descrição ocupa a caixa inteira (sem título redundante)
		drect = _t(cat, "desc", inset(Rect2(Z_DESC_T.position.x * w0, Z_DESC_T.position.y * h0, Z_DESC_T.size.x * w0, Z_DESC_T.size.y * h0), 0.03, 0.06))
		atitle = Rect2(0, 0, 0, 0)
	var ty: float = (Z_TAB.position.y - 0.008) * h0 if cat == "champion" else (Z_TAB.position.y - 0.014) * h0
	var trect := _t(cat, "tab", inset(Rect2(Z_TAB.position.x * w0, ty, Z_TAB.size.x * w0, Z_TAB.size.y * h0), 0.05, 0.10))
	return {"gem": gem, "name": nrect, "abil": arect, "atitle": atitle, "desc": drect, "tab": trect}


static func _fit_single(font: Font, text: String, rect: Rect2, base: int) -> int:
	var fs := base
	while fs > 2:
		var wtxt: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
		var lh: float = font.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).y
		if wtxt <= rect.size.x * 0.98 and lh <= rect.size.y * 0.98:
			return fs
		fs -= 1
	return 2


static func _fit_name(font: Font, text: String, rect: Rect2, base: int) -> Array:
	## Nome da carta: usa a MAIOR fonte que cabe na ALTURA da barra; se o nome
	## for comprido demais para a LARGURA, a fonte é CONDENSADA horizontalmente
	## (variation_transform) — o nome fica grande, completo e nunca extrapola.
	var fs := base
	if font == null:
		return [fs, 1.0]
	# altura VISIVEL dos glifos (ascent + meia descent), nao a linha inteira:
	# assim o nome usa toda a altura da barra sem extrapolar
	var lh: float = font.get_ascent(fs) + font.get_descent(fs) * 0.5
	while fs > 2 and lh > rect.size.y * 0.98:
		fs -= 1
		lh = font.get_ascent(fs) + font.get_descent(fs) * 0.5
	var avail: float = rect.size.x * 0.98
	var kx := 1.0
	while fs > 2:
		var wtxt: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
		kx = (avail / wtxt) if wtxt > 0.0 else 1.0
		if kx >= 0.62:
			break
		fs -= 1
	var w2: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x
	kx = clampf((avail / w2) if w2 > 0.0 else 1.0, 0.55, 1.0)
	return [fs, kx]


static func _fit_wrap(font: Font, text: String, rect: Rect2, base: int, max_lines: int) -> Array:
	var fs := base
	while fs > 2:
		var ls: Array = wrap_text(font, text, fs, rect.size.x * 0.98)
		var lh: float = font.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).y
		if ls.size() <= max_lines and ls.size() * lh <= rect.size.y * 0.98:
			return [fs, ls]
		fs -= 1
	var ls2: Array = wrap_text(font, text, 2, rect.size.x * 0.98)
	return [2, ls2]


static func layout_for(card: Dictionary, w0: float, h0: float) -> Dictionary:
	var key: String = String(card.get("name", "")) + "|" + str(int(w0))
	if _layout_cache.has(key):
		return _layout_cache[key]
	var cat: String = String(card.get("category", ""))
	var sub: String = String(card.get("subcategory", ""))
	var z: Dictionary = zones_for(cat, sub, w0, h0)
	var f800 := baloo(800)
	var f600 := baloo(600)
	ensure_loaded()
	var ov: Dictionary = text_overrides.get(String(card.get("name", "")), {})
	# (1.49.86) fonte escolhida por carta vale para TODOS os textos
	var fid: int = int(ov.get("font", 0))
	f800 = font_for(fid, 800)
	f600 = font_for(fid, 600)
	var name_txt: String = String(ov.get("name", String(card.get("name", ""))))
	var out := {"zones": z, "name_text": name_txt}
	out["pow_fs"] = int(int(h0 * 0.085) * zone_textscale(String(card.get("name", "")), "gem"))
	var nf: Array = _fit_name(f800, name_txt, z["name"], int(int(h0 * 0.056) * float(ov.get("tscale", 1.0)) * zone_textscale(String(card.get("name", "")), "name")))
	out["name_fs"] = nf[0]
	out["name_kx"] = nf[1]
	if cat == "champion":
		var at: String = String(card.get("ability_type", ""))
		var tipo: String = "Constante" if at == "constant" else ("Instantânea" if at == "instant" else "")
		var atxt: String = String(ov.get("abil_txt", ("%s (%s)" % [card.get("ability_name", ""), tipo]) if tipo != "" else String(card.get("ability_name", ""))))
		out["abil_text"] = atxt
		out["abil_fs"] = _fit_single(f800, atxt, z["abil"], int(int(h0 * 0.050) * float(ov.get("tscale", 1.0)) * zone_textscale(String(card.get("name", "")), "abil")))
		out["title_fs"] = 0
	else:
		out["abil_text"] = ""
		out["title_fs"] = 0
	# (1.49.83) descrições com QUEBRAS EXPLICITAS (Enter persiste), marcadores
	# **negrito** e opções de centralização/fonte por carta.
	var ts: float = float(ov.get("tscale", 1.0))
	var lhmul: float = float(ov.get("lh", 0.88))  # (1.49.89) entrelinha padrão 0.88
	var zw: float = zone_textwidth(String(card.get("name", "")), "desc")
	var dtxt: String = String(ov.get("desc", String(card.get("ability_desc", ""))))
	var raw_lines := dtxt.split("\n")
	var fs := int(int(int(h0 * 0.050) * ts) * zone_textscale(String(card.get("name", "")), "desc"))
	var all: Array = []
	var maxl := maxi(3, raw_lines.size())
	while fs > 2:
		all = []
		for ln in raw_lines:
			for wr in wrap_text(f600, String(ln), fs, z["desc"].size.x * 0.98 * zw):
				all.append(wr)
		var lh: float = f600.get_string_size("Ag", HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).y * lhmul
		if all.size() <= maxl and all.size() * lh <= z["desc"].size.y * 0.98:
			break
		fs -= 1
	var cname2: String = String(card.get("name", ""))
	if zone_textscale(cname2, "desc") != 1.0:
		# (1.49.85) alça de texto: tamanho manda, pode vazar da caixa
		fs = int(int(h0 * 0.050) * ts * zone_textscale(cname2, "desc"))
		all = []
		for ln in raw_lines:
			for wr in wrap_text(f600, String(ln), fs, z["desc"].size.x * 0.98 * zw):
				all.append(wr)
	out["desc_fs"] = fs
	out["desc_lines"] = all
	out["desc_lh"] = lhmul
	out["zw_name"] = zone_textwidth(cname2, "name")
	out["zw_abil"] = zone_textwidth(cname2, "abil")
	out["zw_tab"] = zone_textwidth(cname2, "tab")
	if zone_textscale(cname2, "name") != 1.0:
		out["name_fs"] = int(int(h0 * 0.056) * zone_textscale(cname2, "name"))
	if zone_textscale(cname2, "abil") != 1.0:
		out["abil_fs"] = int(int(h0 * 0.050) * zone_textscale(cname2, "abil"))
	if zone_textscale(cname2, "gem") != 1.0:
		out["pow_fs"] = int(int(h0 * 0.085) * zone_textscale(cname2, "gem"))
	out["desc_center"] = bool(ov.get("center", true))  # (1.49.89) centralizado por padrão
	out["desc_font"] = int(ov.get("font", 0))
	var ttxt2: String = String(ov.get("tab_txt", "Campeão" if cat == "champion" else ("Reação" if sub == "reaction" else "Talento")))
	# (1.49.86/88) selo: fit SOMENTE por largura numa janela 6x (equivalente a
	# 600 px) — o tamanho da ABA PODE SER REDIMENSIONADO livremente pelas alças
	var tab_base: int = maxi(2, int(int(h0 * 0.036) * zone_textscale(String(card.get("name", "")), "tab")))
	var tfs := tab_base
	while tfs > 2 and f600.get_string_size(ttxt2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tfs).x > z["tab"].size.x * 0.98 * 6.0:
		tfs -= 1
	out["tab_fs"] = tfs
	# (1.49.86) retângulos REAIS dos textos (o box do editor acompanha o texto)
	var cname3: String = String(card.get("name", ""))
	var tr := {}
	tr["gem"] = z["gem"]
	var nw: float = f800.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, out["name_fs"]).x * float(nf[1])
	var nh: float = float(out["name_fs"]) * 1.25
	nw *= zone_textwidth(cname3, "name")
	tr["name"] = Rect2(z["name"].position.x + (z["name"].size.x - nw) / 2.0, z["name"].position.y + (z["name"].size.y - nh) / 2.0, nw, nh)
	if cat == "champion":
		var aw: float = f800.get_string_size(String(out["abil_text"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, out["abil_fs"]).x
		var ah: float = float(out["abil_fs"]) * 1.25
		aw *= zone_textwidth(cname3, "abil")
		tr["abil"] = Rect2(z["abil"].position.x + (z["abil"].size.x - aw) / 2.0, z["abil"].position.y + (z["abil"].size.y - ah) / 2.0, aw, ah)
	else:
		tr["abil"] = z["abil"]
	var dw := 0.0
	for ln3 in all:
		dw = maxf(dw, f600.get_string_size(String(ln3).replace("**", ""), HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs).x)
	dw = minf(dw, z["desc"].size.x * zw)
	var dh: float = fs * lhmul * float(all.size())
	var dx0: float = z["desc"].position.x + (z["desc"].size.x - dw) / 2.0 if bool(ov.get("center", true)) else z["desc"].position.x + 2.0
	tr["desc"] = Rect2(dx0, z["desc"].position.y + (z["desc"].size.y - dh) / 2.0, dw, dh)
	var tw3: float = f800.get_string_size(ttxt2, HORIZONTAL_ALIGNMENT_LEFT, -1.0, out["tab_fs"]).x
	var th3: float = float(out["tab_fs"]) * 1.25
	tw3 *= zone_textwidth(cname3, "tab")
	tr["tab"] = Rect2(z["tab"].position.x + (z["tab"].size.x - tw3) / 2.0, z["tab"].position.y + (z["tab"].size.y - th3) / 2.0, tw3, th3)
	out["text_rects"] = tr
	_layout_cache[key] = out
	return out


static func set_text_override(card_name: String, nn: String, dd: String, center: bool = true, font: int = 0, lh: float = -1.0) -> void:
	var old: Dictionary = text_overrides.get(card_name, {})
	var ts: float = float(old.get("tscale", 1.0))
	var lhv: float = float(old.get("lh", 0.88)) if lh < 0 else lh
	text_overrides[card_name] = {"name": nn, "desc": dd, "center": center, "font": font, "tscale": ts, "lh": lhv}
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func set_zone_text(card_name: String, zone: String, txt: String) -> void:
	# (1.49.87) override de texto POR ZONA (nome/desc/abil/tab)
	var ov: Dictionary = text_overrides.get(card_name, {}).duplicate()
	match zone:
		"name": ov["name"] = txt
		"desc": ov["desc"] = txt
		"abil": ov["abil_txt"] = txt
		"tab": ov["tab_txt"] = txt
	text_overrides[card_name] = ov
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func set_text_style(card_name: String, font: int, center: bool, lh: float) -> void:
	var ov: Dictionary = text_overrides.get(card_name, {}).duplicate()
	ov["font"] = font
	ov["center"] = center
	ov["lh"] = lh
	text_overrides[card_name] = ov
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func bump_text_scale(card_name: String, f: float) -> void:
	var ov: Dictionary = text_overrides.get(card_name, {}).duplicate()
	ov["tscale"] = clampf(float(ov.get("tscale", 1.0)) * f, 0.6, 1.9)
	text_overrides[card_name] = ov
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func set_zone_textscale(card_name: String, zone: String, v: float) -> void:
	# (1.49.85) tamanho do texto DESTA zona DESTA carta (alças do editor):
	# não espelha em outros textos nem em outras cartas.
	var ov: Dictionary = text_overrides.get(card_name, {}).duplicate()
	var zs: Dictionary = ov.get("zscale", {}).duplicate()
	zs[zone] = clampf(v, 0.5, 2.2)
	ov["zscale"] = zs
	text_overrides[card_name] = ov
	_layout_cache.clear()
	version += 1


static func zone_textscale(card_name: String, zone: String) -> float:
	var ov: Dictionary = text_overrides.get(card_name, {})
	var zs: Dictionary = ov.get("zscale", {})
	return float(zs.get(zone, 1.0))


static func set_zone_textwidth(card_name: String, zone: String, v: float) -> void:
	# (1.49.86) largura da caixa de texto (re-quebra ao arrastar na horizontal)
	var ov: Dictionary = text_overrides.get(card_name, {}).duplicate()
	var zw: Dictionary = ov.get("zwidth", {}).duplicate()
	zw[zone] = clampf(v, 0.5, 1.6)
	ov["zwidth"] = zw
	text_overrides[card_name] = ov
	_layout_cache.clear()
	version += 1


static func zone_textwidth(card_name: String, zone: String) -> float:
	var ov: Dictionary = text_overrides.get(card_name, {})
	var zw: Dictionary = ov.get("zwidth", {})
	return float(zw.get(zone, 1.0))


static func font_for(fid: int, weight: int) -> Font:
	# (1.49.86) fonte de TODOS os textos da carta (não só da descrição)
	match fid:
		1: return fredoka(float(weight))
		2: return heavy_font()
		_: return baloo(float(weight))
	_layout_cache.clear()
	version += 1
	save_card_layout()


static func snapshot() -> Dictionary:
	return {
		"offsets": type_offsets.duplicate(true),
		"scales": type_scales.duplicate(true),
		"texts": text_overrides.duplicate(true),
	}


static func restore(snap: Dictionary) -> void:
	type_offsets = snap["offsets"].duplicate(true)
	type_scales = snap["scales"].duplicate(true)
	text_overrides = snap["texts"].duplicate(true)
	_layout_cache.clear()
	version += 1
	save_card_layout()
