extends Node
## (1.49.98) CENTRAL DE SFX DAS ANIMAÇÕES — cada animação do jogo tem um som
## simples e impactante, sintetizado sob medida (coerente com o que a tela
## mostra): projéteis whoosh+boom, mordida snap+squelch, relógio ticks, ovo
## crackle+hatch etc. Pool de players 2D com PAN pela posição X na tela,
## pitch ±4% (evita repetição mecânica) e volume por evento.
## Uso: Sfx.play("fireball_hit", carta.global_position.x)

const KEYS := {
	"summon_land": "res://assets/sfx/summon_land.wav",
	"draw": "res://assets/sfx/draw.wav",
	"attack": "res://assets/sfx/attack.wav",
	"destroy": "res://assets/sfx/destroy.wav",
	"fireball_launch": "res://assets/sfx/fireball_launch.wav",
	"fireball_hit": "res://assets/sfx/fireball_hit.wav",
	"mordida_launch": "res://assets/sfx/mordida_launch.wav",
	"mordida_hit": "res://assets/sfx/mordida_hit.wav",
	"raio": "res://assets/sfx/raio.wav",
	"congelar": "res://assets/sfx/congelar.wav",
	"baforada": "res://assets/sfx/baforada.wav",
	"fortalecer": "res://assets/sfx/fortalecer.wav",
	"defensor": "res://assets/sfx/defensor.wav",
	"guardiao": "res://assets/sfx/guardiao.wav",
	"pesadelo": "res://assets/sfx/pesadelo.wav",
	"desacelerar": "res://assets/sfx/desacelerar.wav",
	"ovo_crackle": "res://assets/sfx/ovo_crackle.wav",
	"ovo_hatch": "res://assets/sfx/ovo_hatch.wav",
	"forja": "res://assets/sfx/forja.wav",
	"roubo": "res://assets/sfx/roubo.wav",
	"ultimate": "res://assets/sfx/ultimate.wav",
	"assassinar_mark": "res://assets/sfx/assassinar_mark.wav",
	"assassinar_slash": "res://assets/sfx/assassinar_slash.wav",
	"assassinar_split": "res://assets/sfx/assassinar_split.wav",
	"assassinar_shatter": "res://assets/sfx/assassinar_shatter.wav",
}

const POOL := 10

var _streams := {}
var _pool: Array = []


func _ready() -> void:
	for k in KEYS:
		_streams[k] = load(KEYS[k])
	for i in POOL:
		var p := AudioStreamPlayer2D.new()
		p.max_distance = 4000.0
		if "attenuation" in p:
			p.set("attenuation", 0.4)
		add_child(p)
		_pool.append(p)


func play(key: String, x: float = 640.0, vol: float = 1.0) -> void:
	var s = _streams.get(key)
	if s == null:
		return
	var p: AudioStreamPlayer2D = _pool[0]
	for q in _pool:
		if not q.playing:
			p = q
			break
	p.stream = s
	p.position = Vector2(x, 360.0)
	p.pitch_scale = randf_range(0.96, 1.04)
	p.volume_db = linear_to_db(clampf(vol, 0.01, 1.0))
	p.play()
