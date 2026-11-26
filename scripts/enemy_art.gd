class_name EnemyArt
extends RefCounted

# Sprites for the stage-signature enemies (GameEnemy.THEMED) and their special shots, in each
# stage's palette. Called from PixelArt._build_all. Sprites are drawn without an outline;
# _finish() adds a 1-px dark outline so they read against the busy stage backgrounds.
# All enemies face left, toward the player.

const OUTLINE: Color = Color("#0a0c16")

# Every key built here. The smoke test checks they all exist, because PixelArt.tex() quietly
# falls back to another sprite on a typo.
const KEYS: Array[String] = [
	"en_asteroid_0", "en_asteroid_1", "en_rock_chunk", "en_mine_layer", "en_space_mine_0", "en_space_mine_1",
	"en_turret", "en_turret_barrel", "en_sec_drone_0", "en_sec_drone_1",
	"en_blimp", "en_jet",
	"en_spore_pod_0", "en_spore_pod_1", "en_spore_pod_2", "en_beetle_0", "en_beetle_1",
	"en_ice_crystal_0", "en_ice_crystal_1", "en_snow_drone",
	"en_lava_blob_0", "en_lava_blob_1", "en_golem_0", "en_golem_1", "en_golem_shield_0", "en_golem_shield_1",
	"en_jelly_0", "en_jelly_1", "en_eel_head", "en_eel_body", "en_eel_tail", "en_angler_0", "en_angler_1",
	"en_virus_0", "en_virus_1", "en_glitch_0", "en_glitch_1", "en_firewall",
	"bullet_enemy_bomb", "bullet_enemy_spore", "bullet_enemy_shard", "bullet_frost_0", "bullet_frost_1",
]


static func build_all(cache: Dictionary) -> void:
	_build_orbit(cache)
	_build_starcruiser(cache)
	_build_cloud_base(cache)
	_build_xeno_forest(cache)
	_build_cryo(cache)
	_build_magma(cache)
	_build_abyss(cache)
	_build_cyber(cache)
	_build_shots(cache)


# --- 1 OUTER ORBIT: grey-brown ore rocks, steel-blue minelayer -------------------------------

static func _build_orbit(cache: Dictionary) -> void:
	var rock: Dictionary = {
		"H": Color("#d2c4ae"), "L": Color("#a39280"), "M": Color("#7a6855"), "D": Color("#54453a"),
		"K": Color("#382c24"), "c": Color("#241b15"), "C": Color("#6ee6ff"), "W": Color("#ffffff"),
	}
	cache["en_asteroid_0"] = _finish(_rows(PackedStringArray([
		".....LLLLL.....",
		"...LLHHHLLMM...",
		"..LHHHLLLMMMD..",
		".LHHLLMDDMMMMD.",
		".LHLLMDKKDMMMD.",
		"LHLLMMDKcDMMMMD",
		"LLLMMMMDDMMDDMD",
		"LLMMDDMMMMDKKDD",
		"LMMDKKDMMMMDcDD",
		"LMMDKcDMMCMMDDD",
		".MMMDDMMMWCMDD.",
		".MMMMMMMMMMDDD.",
		"..DMMMDDMMMDD..",
		"...DDMMMMDDD...",
		".....DDDDD.....",
	]), rock))
	cache["en_asteroid_1"] = _finish(_rows(PackedStringArray([
		"...............",
		"....LLLL.......",
		"..LLHHHLLL.....",
		".LHHHLLLMMMM...",
		".LHLLMMMMDDMMD.",
		"LHLMMDDMMDKDMD.",
		"LLMMDKKDMMDDMMD",
		"LLMMDKcDMMMMMMD",
		"LMMMMDDMMMCDMMD",
		"LMMMMMMMMDKKDMD",
		".MMDDMMMMDKcDDD",
		".MDKKDMMMMDDMD.",
		"..DKcDMMMMMDDD.",
		"...DDMMMDDDDD..",
		"....DDDDD......",
	]), rock))
	cache["en_rock_chunk"] = _finish(_rows(PackedStringArray([
		"..LLLM...",
		".LHHLMMD.",
		"LHLLMMMD.",
		"LLMMDDMMD",
		"LMMDKcDMD",
		"LMMMDDMMD",
		".MMMMMMD.",
		"..DMMMDD.",
		"...DDDD..",
	]), rock))

	var steel: Dictionary = {
		"W": Color("#ffffff"), "L": Color("#dce8ff"), "S": Color("#8ca6d8"), "D": Color("#3b5284"),
		"N": Color("#1d294a"), "C": Color("#28e8ff"), "R": Color("#f03c4e"), "Y": Color("#ffe854"),
		"O": Color("#ff9624"), "k": Color("#2c3240"), "K": Color("#596378"),
	}
	cache["en_mine_layer"] = _finish(_rows(PackedStringArray([
		".........DDDDDDDDD......",
		".......DDSSSSSSSSSDD....",
		".....DDSSLLLLLLLLSSSD...",
		"...DDSSLLCCCLLLLLLSSDKO.",
		".DDSSLLLCWWCLLLLLLLSDKYO",
		"DSSLLLLLLCCLLLLLLLLSDKYW",
		".DDSSSSSSSSSSSSSSSSSDKYO",
		"...DDNNNNNNNNNNNNNNDDKO.",
		"....DNYYkkYYkkYYkkYND...",
		"....DNkkYYkkYYkkYYkND...",
		".....DNNNNNNNNNNNNND....",
		"......DD.RRR..RRR.DD....",
		".........R.R..R.R.......",
	]), steel))

	var mine_rows: PackedStringArray = PackedStringArray([
		".....k.....",
		"..k..K..k..",
		"...kKSKk...",
		"..kKSSSKk..",
		".kKSDrDSKk.",
		"kKKSrRrSKKk",
		".kKSDrDSKk.",
		"..kKSSSKk..",
		"...kKSKk...",
		"..k..K..k..",
		".....k.....",
	])
	var mine_pal: Dictionary = {
		"k": Color("#2c3240"), "K": Color("#596378"), "S": Color("#8ca6d8"), "D": Color("#3b5284"),
		"r": Color("#941c2f"), "R": Color("#f03c4e"), "W": Color("#ffffff"), "Y": Color("#ffe854"),
	}
	cache["en_space_mine_0"] = _finish(_rows(mine_rows, mine_pal))
	cache["en_space_mine_1"] = _finish(_rows(PackedStringArray([
		".....R.....",
		"..R..K..R..",
		"...kKSKk...",
		"..kKSYSKk..",
		".kKSYRYSKk.",
		"RKKYRWRYKKR",
		".kKSYRYSKk.",
		"..kKSYSKk..",
		"...kKSKk...",
		"..R..K..R..",
		".....R.....",
	]), mine_pal))


# --- 2 STARCRUISER: gunmetal, hazard orange, cyan sensors ------------------------------------

static func _build_starcruiser(cache: Dictionary) -> void:
	var gun: Dictionary = {
		"K": Color("#687894"), "k": Color("#323c4f"), "S": Color("#9aaac4"), "L": Color("#c8d4e8"),
		"O": Color("#ff9624"), "o": Color("#8c4408"), "C": Color("#28e8ff"), "N": Color("#1c2230"),
		"W": Color("#ffffff"), "Y": Color("#ffe854"),
	}
	cache["en_turret"] = _finish(_rows(PackedStringArray([
		".....kkkkkk.....",
		"....kKSLLSKk....",
		"...kKSLCCLSKk...",
		"...kKSSCCSSKk...",
		"..kkkKKKKKKkkk..",
		".kOOooOOooOOook.",
		"kOOooOOooOOooOOk",
		"kKKKKKKKKKKKKKKk",
		"kNNNNNNNNNNNNNNk",
	]), gun))
	cache["en_turret_barrel"] = _finish(_rows(PackedStringArray([
		"kkkkkkkkk.",
		"KSSSSSSSLW",
		"KKKKKKKKSC",
		"kkkkkkkkk.",
	]), gun))

	var drone_rows: PackedStringArray = PackedStringArray([
		".......kk......",
		"........k......",
		".....kkKKkk....",
		"...kKKSSSSKKk..",
		"..kKSSLLLLSSKk.",
		".kKSLkkkkLLSKkO",
		"kKSLkcEEkkLSKOY",
		"kKSLkEWEEkLSKOY",
		"kKSLkcEEkkLSKOY",
		".kKSLkkkkLLSKkO",
		"..kKSSLLLLSSKk.",
		"...kKKSSSSKKk..",
		".....kkKKkk....",
	])
	var eye_calm: Dictionary = gun.duplicate()
	eye_calm["E"] = Color("#28e8ff")
	eye_calm["c"] = Color("#0b5a73")
	var eye_alert: Dictionary = gun.duplicate()
	eye_alert["E"] = Color("#ff3848")
	eye_alert["c"] = Color("#7a1020")
	cache["en_sec_drone_0"] = _finish(_rows(drone_rows, eye_calm))
	cache["en_sec_drone_1"] = _finish(_rows(drone_rows, eye_alert))


# --- 3 CLOUD BASE: ivory hulls, cobalt stripes, gold trim ------------------------------------

static func _build_cloud_base(cache: Dictionary) -> void:
	var aero: Dictionary = {
		"W": Color("#ffffff"), "L": Color("#e8f0ff"), "S": Color("#b4c6e6"), "D": Color("#6a84b8"),
		"N": Color("#34507e"), "B": Color("#2f78e0"), "b": Color("#1b3f84"), "Y": Color("#ffd94a"),
		"y": Color("#b88a1c"), "R": Color("#ff4c4c"), "O": Color("#ff9624"), "C": Color("#7ce8ff"),
	}
	# Blimp: shaded envelope with a cobalt-and-gold band, tail fins and a bomb-bay gondola.
	var blimp: Image = _blank(44, 19)
	var envelope: Array[Color] = [Color("#6a84b8"), Color("#b4c6e6"), Color("#e8f0ff"), Color("#ffffff")]
	_ball(blimp, 20.5, 7.5, 20.5, 7.5, envelope)
	for x: int in range(2, 40):
		for y: int in range(0, 16):
			if blimp.get_pixel(x, y).a > 0.0 and (y == 6 or y == 8):
				blimp.set_pixel(x, y, aero["B"] if x % 6 != 0 else aero["b"])
			elif blimp.get_pixel(x, y).a > 0.0 and y == 7:
				blimp.set_pixel(x, y, aero["Y"])
	# Panel seams.
	for sx: int in [10, 18, 26, 33]:
		for y: int in range(1, 15):
			if blimp.get_pixel(sx, y).a > 0.0 and y != 6 and y != 7 and y != 8:
				blimp.set_pixel(sx, y, aero["S"] if y < 7 else aero["D"])
	# Tail fins (top and bottom) and a rear propeller hub.
	for i: int in range(5):
		_rect(blimp, 36 + i, 0 + i / 2, 1, 4 - i / 2, aero["B"])
		_rect(blimp, 36 + i, 12, 1, 3 - i / 3, aero["B"])
	_rect(blimp, 41, 5, 2, 5, aero["N"])
	_put(blimp, 43, 6, aero["S"])
	_put(blimp, 43, 8, aero["S"])
	# Gondola with windows and the bomb bay.
	_rect(blimp, 13, 14, 14, 3, aero["N"])
	_rect(blimp, 14, 14, 12, 2, aero["S"])
	for wx: int in [15, 18, 21, 24]:
		_put(blimp, wx, 14, aero["C"])
	_rect(blimp, 18, 17, 5, 1, aero["b"])
	_put(blimp, 20, 17, aero["R"])
	_rect(blimp, 19, 18, 3, 1, aero["N"])
	# Nose cap and running lights.
	_rect(blimp, 0, 6, 2, 3, aero["Y"])
	_put(blimp, 3, 4, aero["R"])
	cache["en_blimp"] = _finish(blimp)

	cache["en_jet"] = _finish(_rows(PackedStringArray([
		"...............NN....",
		"..............NBBN...",
		".....NNCCN....NBBN...",
		"..NNSLCCWCLLLLLLBBN..",
		"NNSLLLLLLLLLLLLLLLSOY",
		".NSSSSSSSSSSSSSSSSNOY",
		"...NNDDDBBBBBDDDNN...",
		"........NBBBBBN......",
		".........NNNNN.......",
	]), aero))


# --- 4 XENO FOREST: emerald chitin, bioluminescent lime, magenta venom -----------------------

static func _build_xeno_forest(cache: Dictionary) -> void:
	var bulb: Array[Color] = [Color("#16692b"), Color("#2ec95a"), Color("#5eff6e"), Color("#c8ffd0")]
	var stalk: Color = Color("#1f5c2e")
	var leaf: Color = Color("#2a8a3e")
	var spot: Color = Color("#ff54b8")
	# 0: closed pod on its stalk.
	var pod0: Image = _blank(16, 20)
	_pod_stalk(pod0, stalk, leaf)
	_ball(pod0, 8.0, 7.0, 6.0, 6.5, bulb)
	for sp: Vector2i in [Vector2i(6, 5), Vector2i(10, 7), Vector2i(7, 9), Vector2i(9, 3)]:
		_put(pod0, sp.x, sp.y, spot)
	_put(pod0, 8, 0, Color("#ffe854"))
	cache["en_spore_pod_0"] = _finish(pod0)
	# 1: swollen and glowing, about to burst.
	var pod1: Image = _blank(16, 20)
	_pod_stalk(pod1, stalk, leaf)
	_ball(pod1, 8.0, 7.0, 7.5, 7.5, [Color("#2ec95a"), Color("#8cff7a"), Color("#e8ff9c"), Color("#ffffff")])
	for sp: Vector2i in [Vector2i(5, 5), Vector2i(10, 6), Vector2i(7, 10), Vector2i(9, 2), Vector2i(4, 8), Vector2i(12, 9)]:
		_rect(pod1, sp.x, sp.y, 2, 2, Color("#ff54b8"))
		_put(pod1, sp.x, sp.y, Color("#ffd0ec"))
	cache["en_spore_pod_1"] = _finish(pod1)
	# 2: spent husk, regrowing.
	var pod2: Image = _blank(16, 20)
	_pod_stalk(pod2, stalk, leaf)
	_ball(pod2, 8.0, 11.0, 5.0, 3.5, [Color("#123d1f"), Color("#1e5a2c"), Color("#2e7a3c"), Color("#4a9a52")])
	_put(pod2, 6, 9, Color("#5a2a48"))
	_put(pod2, 10, 10, Color("#5a2a48"))
	cache["en_spore_pod_2"] = _finish(pod2)

	var chitin: Dictionary = {
		"H": Color("#d8ffd8"), "G": Color("#5eff6e"), "E": Color("#2ec95a"), "g": Color("#16692b"),
		"e": Color("#0e4a22"), "M": Color("#ff54b8"), "Y": Color("#ffe854"), "k": Color("#123d1f"),
	}
	var beetle_top: PackedStringArray = PackedStringArray([
		"YY..................",
		".GG.................",
		".gGE.....ggggggg....",
		"..gEE..ggEGGHHGEgg..",
		"...gEE.gEGGHHGGEEEg.",
		"...gEEggEEGGGGEEEEeg",
		".ggEEEggEEEEEEEEEEeg",
		"gEMEEEEggEEEEEEEEEeg",
		"gEEEEEEegEEEEEEEEeeg",
		".geeeeeegeeeeeeeeeg.",
		"..gggggggggggggggg..",
	])
	var legs_a: PackedStringArray = PackedStringArray([
		"...ee...ee....ee....",
		"..e....e.....e......",
	])
	var legs_b: PackedStringArray = PackedStringArray([
		"....ee...ee....ee...",
		".....e....e.....e...",
	])
	var b0: PackedStringArray = beetle_top.duplicate()
	b0.append_array(legs_a)
	var b1: PackedStringArray = beetle_top.duplicate()
	b1.append_array(legs_b)
	cache["en_beetle_0"] = _finish(_rows(b0, chitin))
	cache["en_beetle_1"] = _finish(_rows(b1, chitin))


static func _pod_stalk(img: Image, stalk: Color, leaf: Color) -> void:
	_rect(img, 7, 12, 2, 8, stalk)
	_rect(img, 3, 17, 4, 2, leaf)
	_rect(img, 9, 16, 4, 2, leaf)
	_put(img, 2, 16, leaf)
	_put(img, 13, 15, leaf)


# --- 5 CRYO GLACIER: translucent cyan crystal, sapphire, snow white --------------------------

static func _build_cryo(cache: Dictionary) -> void:
	var ice: Dictionary = {
		"W": Color("#ffffff"), "C": Color("#c8f8ff"), "B": Color("#7ce8ff"), "b": Color("#2890dc"),
		"N": Color("#1e4f8c"), "D": Color("#0e2a52"),
	}
	var crystal: PackedStringArray = PackedStringArray([
		"......W......",
		".....WCb.....",
		".....WCb.....",
		"....WCCBb....",
		".W..WCCBb..W.",
		"WCb.WCCBb.WCb",
		"WCBbWCCBbWCBb",
		"WCBbWCCBbWCBb",
		"WCBbWCCBbWCBb",
		"WCBbWCCBbWCBb",
		".CBbWCCBbWBb.",
		".CBbWCCBbCBb.",
		"..BbWCCBbBb..",
		"..NbbCCBbbN..",
		"...NbbBBbN...",
		"....NbbbN....",
		".....NNN.....",
	])
	cache["en_ice_crystal_0"] = _finish(_rows(crystal, ice))
	var cracked: PackedStringArray = crystal.duplicate()
	for p: Vector3i in [Vector3i(6, 4, 0), Vector3i(5, 5, 0), Vector3i(6, 6, 0), Vector3i(7, 7, 0), Vector3i(6, 8, 0),
			Vector3i(5, 9, 0), Vector3i(6, 10, 0), Vector3i(7, 11, 0), Vector3i(2, 7, 0), Vector3i(1, 8, 0),
			Vector3i(10, 8, 0), Vector3i(11, 9, 0), Vector3i(4, 7, 1), Vector3i(8, 9, 1)]:
		cracked[p.y] = cracked[p.y].substr(0, p.x) + ("W" if p.z == 1 else "D") + cracked[p.y].substr(p.x + 1)
	cache["en_ice_crystal_1"] = _finish(_rows(cracked, ice))

	var snow: Dictionary = {
		"W": Color("#ffffff"), "L": Color("#e8f8ff"), "S": Color("#a8d8f0"), "B": Color("#4aa8e0"),
		"D": Color("#2a5a90"), "N": Color("#18345c"), "C": Color("#88eeff"), "k": Color("#1a2a40"),
	}
	# Twin-rotor snow drone: visor up front, frost vent at the back.
	cache["en_snow_drone"] = _finish(_rows(PackedStringArray([
		"..kSSSSSk.kSSSSSk..",
		"......k.....k......",
		"......kNNNNNk......",
		"....NNSLLLLLSNN....",
		"...NSLLWWWLLLLSN...",
		"..NSLWWLLLLLLLLSN..",
		".NCCCCLLLLLLLLLSSNB",
		"NCWWCCLLLLLLLLSSDBC",
		"NCCCCCLLLLLLLSSSDBC",
		".NSSSSSSSSSSSSSSDN.",
		"..NDDDDDDDDDDDDDN..",
		"....NN.......NN....",
	]), snow))


# --- 6 MAGMA CORE: obsidian, molten orange, white-hot yellow ---------------------------------

static func _build_magma(cache: Dictionary) -> void:
	var lava: Array[Color] = [Color("#9c2410"), Color("#ff5818"), Color("#ffa030"), Color("#ffe854")]
	var crust: Color = Color("#4a1408")
	# 0: rising (drip trailing below), 1: falling (drip trailing above).
	for f: int in range(2):
		var img: Image = _blank(12, 15)
		var cy: float = 6.5 if f == 0 else 8.5
		_ball(img, 6.0, cy, 5.5, 5.5, lava)
		var drip_y: int = 12 if f == 0 else 2
		_rect(img, 5, drip_y, 2, 2, lava[1])
		_put(img, 5, drip_y + (2 if f == 0 else -1), lava[0])
		for sp: Vector2i in [Vector2i(3, int(cy) + 2), Vector2i(8, int(cy) - 1), Vector2i(7, int(cy) + 3)]:
			_put(img, sp.x, sp.y, crust)
		_put(img, 4, int(cy) - 2, Color.WHITE)
		cache["en_lava_blob_%d" % f] = _finish(img)

	# Rock golem: basalt body with glowing lava seams; the core in its chest is dim while the
	# shield is up (0) and white-hot when it opens (1).
	var rock: Array[Color] = [Color("#2e1c1a"), Color("#553a32"), Color("#82604e"), Color("#b08a70")]
	var crack: Color = Color("#ff7a24")
	for f: int in range(2):
		var g: Image = _blank(30, 32)
		_ball(g, 17.0, 17.5, 11.5, 13.5, rock)               # torso
		_ball(g, 10.0, 7.0, 6.5, 5.0, rock)                  # head
		_ball(g, 6.0, 12.5, 4.5, 4.5, rock)                  # upper fist (holds the shield)
		_ball(g, 6.0, 24.0, 4.5, 4.5, rock)                  # lower fist
		_ball(g, 24.0, 29.0, 4.5, 2.5, rock)                 # foot
		_ball(g, 25.0, 9.0, 4.0, 3.5, rock)                  # shoulder boulder
		for seg: Array in [[Vector2(16, 6), Vector2(20, 13)], [Vector2(20, 13), Vector2(25, 15)],
				[Vector2(19, 21), Vector2(25, 27)], [Vector2(13, 24), Vector2(18, 28)], [Vector2(23, 7), Vector2(26, 11)],
				[Vector2(8, 11), Vector2(5, 14)], [Vector2(7, 23), Vector2(5, 26)]]:
			_line(g, Vector2(seg[0]), Vector2(seg[1]), crack)
		var eye: Color = Color("#ffe854") if f == 1 else Color("#ff8a24")
		_rect(g, 6, 6, 3, 2, eye)
		_rect(g, 11, 6, 3, 2, eye)
		_put(g, 7, 6, Color.WHITE)
		_put(g, 12, 6, Color.WHITE)
		if f == 0:
			_disc(g, 14.0, 17.5, 3.5, Color("#5a1408"))
			_disc(g, 14.0, 17.5, 2.0, Color("#b83410"))
		else:
			_disc(g, 14.0, 17.5, 4.2, Color("#ff7a24"))
			_disc(g, 14.0, 17.5, 2.8, Color("#ffe854"))
			_disc(g, 14.0, 17.5, 1.4, Color.WHITE)
		cache["en_golem_%d" % f] = _finish(g)

	# Obsidian shield slab: glassy violet-black with highlight streaks; its cracks glow just
	# before the golem opens up (1).
	var glass: Array[Color] = [Color("#16121e"), Color("#2e2640"), Color("#4c4064"), Color("#9c8cc0")]
	var jag: Array[int] = [1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1]
	for f: int in range(2):
		var sl: Image = _blank(9, 30)
		for y: int in range(30):
			var x0: int = jag[y]
			var x1: int = 8 - jag[(y + 7) % 30]
			for x: int in range(x0, x1 + 1):
				var col: Color = glass[1]
				if x == x0:
					col = glass[3]
				elif x == x0 + 1:
					col = glass[2]
				elif x == x1:
					col = glass[0]
				sl.set_pixel(x, y, col)
			if y > 0 and y < 29 and (y + 3) % 9 == 0:
				_put(sl, x0 + 2, y, glass[3])
				_put(sl, x0 + 3, y + 1, glass[2])
		var glow: Color = Color("#ffe854") if f == 1 else Color("#3a1a20")
		for seg: Array in [[Vector2(4, 2), Vector2(2, 8)], [Vector2(6, 10), Vector2(3, 17)], [Vector2(5, 19), Vector2(3, 27)]]:
			_line(sl, Vector2(seg[0]), Vector2(seg[1]), glow)
		cache["en_golem_shield_%d" % f] = _finish(sl)


# --- 7 ABYSSAL TRENCH: deep teal, bioluminescent pink and aqua -------------------------------

static func _build_abyss(cache: Dictionary) -> void:
	# Jellyfish: 0 relaxed, 1 contracted (taller bell, flared tentacles, brighter).
	for f: int in range(2):
		var j: Image = _blank(18, 22)
		var rx: float = 8.0 if f == 0 else 6.5
		var ry: float = 7.0 if f == 0 else 8.0
		var cy: float = 8.0
		var bell: Array[Color] = [Color("#a8307c"), Color("#ff6eb4"), Color("#ffb0d8"), Color("#ffe8f4")]
		if f == 1:
			bell = [Color("#c8449c"), Color("#ff8cc8"), Color("#ffd0ea"), Color("#ffffff")]
		for y: int in range(0, int(cy) + 2):
			for x: int in range(18):
				var nx: float = (float(x) + 0.5 - 9.0) / rx
				var ny: float = (float(y) + 0.5 - cy) / ry
				var d: float = nx * nx + ny * ny
				if d > 1.0 and y <= int(cy):
					continue
				if y > int(cy) and absf(nx) > 1.0:
					continue
				var v: float = (1.0 - d) * 0.55 + (-nx * 0.45 - ny * 0.65) * 0.55
				var idx: int = 0
				if v > 0.62:
					idx = 3
				elif v > 0.3:
					idx = 2
				elif v > 0.0:
					idx = 1
				j.set_pixel(x, y, bell[idx])
		# Frilly rim.
		var rim_y: int = int(cy) + 2
		for x: int in range(int(9.0 - rx) + 1, int(9.0 + rx)):
			if x % 2 == 0:
				_put(j, x, rim_y, bell[1])
		# Glowing core.
		_disc(j, 9.0, cy - 1.0, 2.0 if f == 0 else 2.5, Color("#38f0d8"))
		_put(j, 9, int(cy) - 2, Color.WHITE)
		# Tentacles.
		var tcol: Color = Color("#ff9ccc")
		for t: int in range(4):
			var base_x: float = 9.0 + (float(t) - 1.5) * (3.0 if f == 0 else 2.2)
			for y: int in range(rim_y + 1, 22):
				var k: float = float(y - rim_y)
				var flare: float = (float(t) - 1.5) * k * (0.08 if f == 0 else 0.32)
				var x: int = int(round(base_x + flare + sin(k * 0.9 + float(t)) * 0.8))
				_put(j, x, y, tcol if y < 19 else Color("#38f0d8"))
		cache["en_jelly_%d" % f] = _finish(j)

	var eel: Dictionary = {
		"D": Color("#0a2a3c"), "M": Color("#1a5a78"), "L": Color("#2e86a8"), "H": Color("#8ce8f0"),
		"C": Color("#28f0d4"), "Y": Color("#ffe854"), "R": Color("#ff6496"), "W": Color("#ffffff"),
		"B": Color("#c8f0e8"),
	}
	cache["en_eel_head"] = _finish(_rows(PackedStringArray([
		".....DDDDDDD..",
		"...DDMMLLLLMD.",
		"..DMLLHLLLLMMD",
		".DMLWYLLLLLMMD",
		"DMLLDYLLLCLLMD",
		"RRRRMLLLLLLLMD",
		"DBBBBBMLLCLMMD",
		".DDBBBBBBBBMD.",
		"...DDDDBBBDD..",
		".......DDD....",
	]), eel))
	var seg: Image = _blank(9, 9)
	var seg_cols: Array[Color] = [Color("#0a2a3c"), Color("#1a5a78"), Color("#2e86a8"), Color("#8ce8f0")]
	_ball(seg, 4.5, 4.5, 4.5, 4.5, seg_cols)
	_put(seg, 4, 2, eel["C"])
	_put(seg, 4, 6, eel["B"])
	_put(seg, 5, 6, eel["B"])
	cache["en_eel_body"] = _finish(seg)
	cache["en_eel_tail"] = _finish(_rows(PackedStringArray([
		"......CC.",
		"..DD.CMMC",
		".DMLDMM..",
		"DMLLMM...",
		".DMLDMM..",
		"..DD.CMMC",
		"......CC.",
	]), eel))

	# Anglerfish: dark lurker with a lit lure on a stalk (the lure glow is drawn by GameEnemy).
	for f: int in range(2):
		var a: Image = _blank(36, 30)
		var body: Array[Color] = [Color("#06141e"), Color("#0e2c3e"), Color("#18485e"), Color("#2c6c84")]
		_ball(a, 21.0, 16.0, 13.0, 10.0, body)
		# Tail fin.
		for i: int in range(6):
			_rect(a, 31 + i / 2, 10 + i, 2, 12 - i * 2, body[1])
		_rect(a, 33, 9, 3, 2, body[2])
		_rect(a, 33, 21, 3, 2, body[2])
		# Dorsal spines.
		for sx: int in [16, 20, 24]:
			_line(a, Vector2(sx, 7), Vector2(sx + 2, 3), body[2])
		# Jaw and teeth.
		var jaw_drop: int = 0 if f == 0 else 4
		if f == 1:
			_rect(a, 4, 17, 13, 4, Color("#7a1030"))
			_rect(a, 5, 18, 11, 2, Color("#c82850"))
		_ball(a, 11.0, 20.0 + float(jaw_drop), 9.0, 4.0, body)
		for tx: int in range(4, 17, 2):
			_put(a, tx, 16, Color("#e8f4f0"))
			_put(a, tx + 1, 19 + jaw_drop, Color("#e8f4f0"))
		_rect(a, 3, 15, 4, 2, body[2])
		# Eye.
		_disc(a, 13.0, 11.0, 2.5, Color("#ffe854"))
		_disc(a, 12.5, 11.0, 1.2, Color("#06141e"))
		_put(a, 13, 10, Color.WHITE)
		# Pectoral fin and glowing side spots.
		_line(a, Vector2(20, 19), Vector2(25, 23), body[3])
		for sp: Vector2i in [Vector2i(22, 13), Vector2i(26, 15), Vector2i(24, 18), Vector2i(28, 12)]:
			_put(a, sp.x, sp.y, Color("#28f0d4"))
		# Lure stalk curving forward from the forehead.
		var stalk: Color = Color("#2c6c84")
		_line(a, Vector2(15, 7), Vector2(13, 2), stalk)
		_line(a, Vector2(13, 2), Vector2(7, 1), stalk)
		_line(a, Vector2(7, 1), Vector2(4, 3), stalk)
		_put(a, 3, 4, Color("#8cfff0"))
		cache["en_angler_%d" % f] = _finish(a)


# --- 8 CYBER NEXUS: neon magenta, electric cyan, dark violet ---------------------------------

static func _build_cyber(cache: Dictionary) -> void:
	for f: int in range(2):
		var v: Image = _blank(15, 15)
		var core: Array[Color] = [Color("#7a149c"), Color("#c828c8"), Color("#ff38d4"), Color("#ffc8f4")]
		var knob: Color = Color("#28f8ff")
		if f == 1:
			core = [Color("#c828c8"), Color("#ff6ee0"), Color("#ffc8f4"), Color("#ffffff")]
			knob = Color.WHITE
		for i: int in range(8):
			var dir: Vector2 = Vector2.from_angle(TAU * float(i) / 8.0)
			for r: int in range(4, 7):
				_put(v, int(round(7.0 + dir.x * float(r))), int(round(7.0 + dir.y * float(r))), core[0])
			_put(v, int(round(7.0 + dir.x * 7.0)), int(round(7.0 + dir.y * 7.0)), knob)
		_ball(v, 7.5, 7.5, 4.6, 4.6, core)
		_put(v, 6, 8, Color("#28f8ff"))
		_put(v, 9, 6, Color("#28f8ff"))
		cache["en_virus_%d" % f] = _finish(v)

	var neon: Dictionary = {
		"M": Color("#ff38d4"), "m": Color("#7a149c"), "C": Color("#28f8ff"), "c": Color("#14528c"),
		"K": Color("#48206e"), "k": Color("#200b38"), "W": Color("#ffffff"), "P": Color("#c070ff"),
	}
	var glitch: PackedStringArray = PackedStringArray([
		"......kkkkkk......",
		"....kkKKPPKKkk....",
		"..CkKKPPWWPPKKkM..",
		".CkKPPMMMMMMPPKkM.",
		"CkKPMMkkkkkkMMPKkM",
		"CkPMMkCCWWCCkMMPkM",
		"ckPMMkCWWWWCkMMPkm",
		"CkPMMkCCWWCCkMMPkM",
		"CkKPMMkkkkkkMMPKkM",
		".CkKPPMMMMMMPPKkM.",
		"..CkKKPPWWPPKKkM..",
		"....kkKKPPKKkk....",
		"......kkkkkk......",
	])
	cache["en_glitch_0"] = _finish(_rows(glitch, neon))
	var torn: PackedStringArray = glitch.duplicate()
	for sh: Vector2i in [Vector2i(2, 2), Vector2i(5, -2), Vector2i(6, 3), Vector2i(10, -1)]:
		var row: String = torn[sh.x]
		if sh.y > 0:
			torn[sh.x] = ".".repeat(sh.y) + row.substr(0, row.length() - sh.y)
		else:
			torn[sh.x] = row.substr(-sh.y) + ".".repeat(-sh.y)
	cache["en_glitch_1"] = _finish(_rows(torn, neon))

	cache["en_firewall"] = _finish(_rows(PackedStringArray([
		"..MMMMMMMMMM..",
		".MmmmmmmmmmmM.",
		"MmkkkkkkkkkkmM",
		"MmkkkkMMkkkkmM",
		"MmkkkMWWMkkkmM",
		"MmkkkMWMMkkkmM",
		"MmkkMWMMMMkkmM",
		"MmkMMWMCMMMkmM",
		"MmkMWMCCMMMkmM",
		"MmkMMMCCCMMkmM",
		"MmkkMMMMMMkkmM",
		"MmkkkkkkkkkkmM",
		"MmCkCkCkCkCkmM",
		"MmkCkCkCkCkkmM",
		"MmkkkkkkkkkkmM",
		".MmmmmmmmmmmM.",
		"..MMMMMMMMMM..",
	]), neon))


# --- Special enemy shots ---------------------------------------------------------------------

static func _build_shots(cache: Dictionary) -> void:
	var p: Dictionary = {
		"k": Color("#2c3240"), "K": Color("#596378"), "S": Color("#8ca6d8"), "R": Color("#ff4c4c"),
		"Y": Color("#ffe854"), "W": Color("#ffffff"), "G": Color("#5eff6e"), "g": Color("#16692b"),
		"M": Color("#ff54b8"), "C": Color("#c8f8ff"), "B": Color("#7ce8ff"), "b": Color("#2890dc"),
	}
	# Bomb points right; the bullet rotates it along its fall.
	cache["bullet_enemy_bomb"] = _finish(_rows(PackedStringArray([
		"KK.......",
		"kKkSSSR..",
		".kKSSSSRY",
		"kKkSSSR..",
		"KK.......",
	]), p))
	cache["bullet_enemy_spore"] = _finish(_rows(PackedStringArray([
		"..GGG..",
		".GgMgG.",
		"GgMWMgG",
		"GMWWWMG",
		"GgMWMgG",
		".GgMgG.",
		"..GGG..",
	]), p))
	cache["bullet_enemy_shard"] = _finish(_rows(PackedStringArray([
		"...W...",
		"..WCb..",
		".WCCBb.",
		"WCCWBBb",
		".bCBBb.",
		"..bBb..",
		"...b...",
	]), p))
	for f: int in range(2):
		var fr: Image = _blank(10, 10)
		var soft: Color = Color(0.74, 0.95, 1.0, 0.72)
		_disc(fr, 5.0, 5.0, 4.6 if f == 0 else 4.2, soft)
		_disc(fr, 5.0, 5.0, 2.8, Color(0.94, 1.0, 1.0, 0.9))
		var arm: Color = Color(1.0, 1.0, 1.0, 0.95)
		if f == 0:
			_line(fr, Vector2(5, 1), Vector2(5, 8), arm)
			_line(fr, Vector2(1, 5), Vector2(8, 5), arm)
		else:
			_line(fr, Vector2(2, 2), Vector2(7, 7), arm)
			_line(fr, Vector2(7, 2), Vector2(2, 7), arm)
		cache["bullet_frost_%d" % f] = ImageTexture.create_from_image(fr)


# --- Drawing helpers -------------------------------------------------------------------------

static func _rows(rows: PackedStringArray, pal: Dictionary) -> Image:
	var w: int = 0
	for r: String in rows:
		w = maxi(w, r.length())
	var img: Image = Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			var ch: String = row.substr(x, 1)
			if ch == ".":
				continue
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
			else:
				push_error("EnemyArt: no colour for '%s'" % ch)
	return img


# Adds a 1-px dark outline around the sprite (the image grows by 2 px each way).
static func _finish(img: Image) -> ImageTexture:
	var sw: int = img.get_width()
	var sh: int = img.get_height()
	var out: Image = Image.create(sw + 2, sh + 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(0, 0, sw, sh), Vector2i(1, 1))
	for y: int in range(sh + 2):
		for x: int in range(sw + 2):
			if _solid(img, x - 1, y - 1):
				continue
			if _solid(img, x - 2, y - 1) or _solid(img, x, y - 1) or _solid(img, x - 1, y - 2) or _solid(img, x - 1, y):
				out.set_pixel(x, y, OUTLINE)
	return ImageTexture.create_from_image(out)


static func _solid(img: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	return img.get_pixel(x, y).a > 0.3


static func _blank(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


static func _put(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)


static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy: int in range(y, y + h):
		for xx: int in range(x, x + w):
			_put(img, xx, yy, col)


static func _disc(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	for y: int in range(int(floorf(cy - r)), int(ceilf(cy + r)) + 1):
		for x: int in range(int(floorf(cx - r)), int(ceilf(cx + r)) + 1):
			if Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - cy).length() <= r:
				_put(img, x, y, col)


static func _line(img: Image, a: Vector2, b: Vector2, col: Color) -> void:
	var steps: int = int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i: int in range(steps + 1):
		var t: float = 0.0 if steps == 0 else float(i) / float(steps)
		var p: Vector2 = a.lerp(b, t)
		_put(img, int(round(p.x)), int(round(p.y)), col)


# Filled ellipse shaded like a ball lit from the upper left. cols = [dark, mid, light, highlight].
static func _ball(img: Image, cx: float, cy: float, rx: float, ry: float, cols: Array[Color]) -> void:
	for y: int in range(int(floorf(cy - ry)), int(ceilf(cy + ry)) + 1):
		for x: int in range(int(floorf(cx - rx)), int(ceilf(cx + rx)) + 1):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			var d: float = nx * nx + ny * ny
			if d > 1.0:
				continue
			var v: float = (1.0 - d) * 0.55 + (-nx * 0.45 - ny * 0.65) * 0.55
			var idx: int = 0
			if v > 0.62:
				idx = 3
			elif v > 0.3:
				idx = 2
			elif v > 0.0:
				idx = 1
			_put(img, x, y, cols[idx])
