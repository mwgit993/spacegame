class_name ShipArt
extends RefCounted

# Sprites for the 10 hangar-expansion ships: two hull frames each (only the jet flame moves),
# their shots, GEMINI's orbit pods and the skill-tree / pause badges. Called from
# PixelArt._build_all. Rows are one character per pixel, read through BASE (PixelArt's
# palette) plus each sprite's own colours; 'q' is a sprite's dark outline. Ships face right.

const BASE: Dictionary = {
	"W": Color("#ffffff"),
	"L": Color("#dce8ff"),
	"S": Color("#8ca6d8"),
	"D": Color("#3b5284"),
	"N": Color("#1d294a"),
	"C": Color("#28e8ff"),
	"B": Color("#0088cc"),
	"R": Color("#f03c4e"),
	"r": Color("#941c2f"),
	"O": Color("#ff9624"),
	"Y": Color("#ffe854"),
	"G": Color("#3ce878"),
	"g": Color("#197a44"),
	"P": Color("#d44cff"),
	"p": Color("#681d94"),
	"M": Color("#ff4ca8"),
	"K": Color("#596378"),
	"k": Color("#2c3240"),
}

# Every key built here. The smoke test checks they exist, because PixelArt.tex() quietly
# falls back to another sprite on a typo.
const KEYS: Array[String] = [
	"ship_frog_0", "ship_frog_1", "ship_hog_0", "ship_hog_1", "ship_gemini_0",
	"ship_gemini_1", "ship_hanabi_0", "ship_hanabi_1", "ship_ronin_0", "ship_ronin_1",
	"ship_bloom_0", "ship_bloom_1", "ship_comet_0", "ship_comet_1", "ship_orca_0",
	"ship_orca_1", "ship_lancer_0", "ship_lancer_1", "ship_horizon_0", "ship_horizon_1",
	"bullet_seedpod_0", "bullet_seedpod_1", "bullet_petal", "bullet_sonar", "bullet_slash",
	"bullet_pellet", "bullet_pellet_trio", "bullet_rocket", "bullet_spark", "bullet_orb_0",
	"bullet_orb_1", "bullet_comet", "bullet_twin", "orbit_pod_0", "orbit_pod_1",
	"bullet_tongue", "bullet_spit", "bullet_lance", "badge_frog", "badge_hog",
	"badge_gemini", "badge_hanabi", "badge_ronin", "badge_bloom", "badge_comet",
	"badge_orca", "badge_lancer", "badge_horizon",
]


static func build_all(cache: Dictionary) -> void:
	_build_ships(cache)
	_build_shots(cache)


static func _build_ships(cache: Dictionary) -> void:
	# LEAPFROG: green frog, big eyes on top, wide smile, blush, folded back leg
	var frog_pal: Dictionary = {"q": Color("#0c3a1c"), "y": Color("#d8f890"), "m": Color("#ff9ccc")}
	var frog_0: PackedStringArray = PackedStringArray([
		"..........................",
		"...............qqq..qqq...",
		"..............qGGGqqGGGq..",
		".............qGWWWGGWWWGq.",
		".........qqqqqGWWNGGWWNGq.",
		"......qqqGGGGGGWWNGGWWNGq.",
		".....qGGGGGgGGGGWGGGGWGGq.",
		"....qGGGgGGGGGGGGGGGGGGq..",
		"...qGGGGGGGGGGGmGGGGGGGmq.",
		"..qgGGGGGGgGGGyGqGGGGGGGqq",
		"OOYgGGGGyyyyyyyyyqqqqqqqq.",
		".qgggGGyyyyyyyyyyyyyyyGq..",
		"..qgggGGyyyyyyyyyyyyyGq...",
		"...qqgggqGyyyggyyyyggq....",
		".....qqq.qqqqqqqqqqqq.....",
	])
	_add(cache, "ship_frog_0", frog_pal, frog_0)
	var frog_1: PackedStringArray = frog_0.duplicate()
	frog_1[10] = "OYWgGGGGyyyyyyyyyqqqqqqqq."
	_add(cache, "ship_frog_1", frog_pal, frog_1)

	# WARHOG: armoured pink tank-hog, helmet band with rivets, snout, tusk, curly tail
	var hog_pal: Dictionary = {"q": Color("#4a1426"), "h": Color("#ff9cb4"), "H": Color("#e0607e"), "i": Color("#ffc8d6")}
	var hog_0: PackedStringArray = PackedStringArray([
		".............qq...........",
		"............qhhq..........",
		"...........qqhHhq.........",
		".......qqqqShhHhhqq.......",
		"..q..qqWKKKWKKKWKKKqq.....",
		".qhqqKKKKKKKKKKKKKKhhq....",
		"qhqhhhhhhhhhhhhhhhhNWhqqq.",
		".qhhhhhhhhhhhhhhhhhNhhHiHq",
		"..qhhhhhhhhhhhhhhhhhhHiqqH",
		"OOYhhhhhhhhhhhhhhhhhhHiiii",
		"..qhhhhhhhhhhhhhhhhhhHHiiH",
		"...qhhhHHHHHHHHHHHhhhWHHHq",
		"....qhhHHHHHHHHHHHhhhqWWq.",
		".....qqhhHHHHHHHhhhqq.qq..",
		".......qKKqhhhhKKqq.......",
	])
	_add(cache, "ship_hog_0", hog_pal, hog_0)
	var hog_1: PackedStringArray = hog_0.duplicate()
	hog_1[9] = "OYWhhhhhhhhhhhhhhhhhhHiiii"
	_add(cache, "ship_hog_1", hog_pal, hog_1)

	# GEMINI TWINS: round pod with twin pink / cyan canopies and a star emblem
	var gemini_pal: Dictionary = {"q": Color("#1c1c48"), "m": Color("#ffb0dc"), "c": Color("#9cf4ff")}
	var gemini_0: PackedStringArray = PackedStringArray([
		"..........................",
		"..........................",
		"....q.....qqqqqqqqq.......",
		"...qSqq.qqmmmLLLLccqq.....",
		"....qYSqLmWmmmLLWcccLqq...",
		".....qLLLmmmmmLccccccLLq..",
		"....qLLLLmmNmmLcccNccLLLq.",
		".OOYqLLLLmmmmmSSccccLLYYq.",
		"....qLLSSSSmSSSSSSSSSSYYq.",
		"....qLSSSSSSSSYSSSSSSSSLq.",
		"....qSSSSSSSSYYYSSSSSSSq..",
		"...qSYqqSSSSSYSYSSSSSqq...",
		"....qq..qqqLLLLLLLqqq.....",
		"...........qqqqqqq........",
		"..........................",
	])
	_add(cache, "ship_gemini_0", gemini_pal, gemini_0)
	var gemini_1: PackedStringArray = gemini_0.duplicate()
	gemini_1[7] = ".OYWqLLLLmmmmmSSccccLLYYq."
	_add(cache, "ship_gemini_1", gemini_pal, gemini_1)

	# HANABI FESTIVAL: red festival rocket, gold bands, porthole, blue fins
	var hanabi_pal: Dictionary = {"q": Color("#3a0a10"), "c": Color("#9cf4ff")}
	var hanabi_0: PackedStringArray = PackedStringArray([
		"..........................",
		"...q......................",
		"..qBqq....................",
		"..qBBBqq..................",
		"..qBBBBBqqqqqqqqqqqqq.....",
		"..qBrrrrYrrrrrrrYrrYYqq...",
		"..qBRRRRYRRRYYRRYRRYYYYqq.",
		"OOYqRRYRYRRYccYRYRRWWWWWWq",
		"OOYBRRRRYRRYccYRYRYWWWWqq.",
		"..qBRRRRYRRRYYRRYRRWWqq...",
		"..qBrrrrYrrrrrrrYrrrq.....",
		"..qBBBqqqqqqqqqqqqqq......",
		"..qBqq....................",
		"...q......................",
		"..........................",
	])
	_add(cache, "ship_hanabi_0", hanabi_pal, hanabi_0)
	var hanabi_1: PackedStringArray = hanabi_0.duplicate()
	hanabi_1[7] = "OYWqRRYRYRRYccYRYRRWWWWWWq"
	hanabi_1[8] = "OYWBRRRRYRRYccYRYRYWWWWqq."
	_add(cache, "ship_hanabi_1", hanabi_pal, hanabi_1)

	# RONIN-7: black-and-red samurai jet, gold crescent crest, katana-blade nose
	var ronin_pal: Dictionary = {"q": Color("#16060c"), "k": Color("#3a3448"), "c": Color("#ff6a7a")}
	var ronin_0: PackedStringArray = PackedStringArray([
		"................q.........",
		"............qq.qYq........",
		"..qq.......qYYqYq.........",
		".qrrqqq....qqYYYq.........",
		"..qRRrrqqqqkkkkqqq........",
		"...qrrrrRRRRRRRckkqq......",
		"....qrkkkkkkkcccWckkqqqqqq",
		"..OOYqkkkkkkkcccccYWWWWWWW",
		"..OOYrkkkkkkkkkckkYLLLLLLq",
		"...qrrkkkkkkkkkkkkkkqqqqq.",
		"..qrrrrqRRRRRRRRkkqq......",
		".qrRRqq.qqqkkkkqqq........",
		"..qqq......qqqq...........",
		"..........................",
		"..........................",
	])
	_add(cache, "ship_ronin_0", ronin_pal, ronin_0)
	var ronin_1: PackedStringArray = ronin_0.duplicate()
	ronin_1[7] = "..OYWqkkkkkkkcccccYWWWWWWW"
	ronin_1[8] = "..OYWrkkkkkkkkkckkYLLLLLLq"
	_add(cache, "ship_ronin_1", ronin_pal, ronin_1)

	# STARBLOOM: smiling flower, pink petals, leaf wings and a stem tail
	var bloom_pal: Dictionary = {"q": Color("#4a1838"), "M": Color("#ff8cd8"), "n": Color("#ffc4ec"), "m": Color("#ff6aa8")}
	var bloom_0: PackedStringArray = PackedStringArray([
		"..............qqq.........",
		".............qMMMq........",
		"............qMMnMMq.......",
		".....q...qqqqMnnnMqqqq....",
		"...qqGq.qMMMMMnnnMMMMMq...",
		"..qGGGGqMMnnMMYYYYMnnMMq..",
		".qGGgGGGMnnnMYYYYYYnnnMq..",
		".qqqqqqqMMnnYYYWYYWYnMMq..",
		"OYgggggggMMMYYYNYYNYMMq...",
		"qggggggggMMMYYmYYYYmMMq...",
		".qGGGGGGMMnnOYYYqqYOnMMq..",
		"..qGgGGqMnnnMOYYYYOnnnMq..",
		"...qqGqqMMnnMMYYYYMnnMMq..",
		".....q..qMMMMMnnnMMMMMq...",
		".........qqqqMnnnMqqqq....",
		"............qMMnMMq.......",
		".............qMMMq........",
	])
	_add(cache, "ship_bloom_0", bloom_pal, bloom_0)
	var bloom_1: PackedStringArray = bloom_0.duplicate()
	bloom_1[8] = "YWgggggggMMMYYYNYYNYMMq..."
	_add(cache, "ship_bloom_1", bloom_pal, bloom_1)

	# COMET KNIGHT: white knight jet with an ice-crystal nose and swept wings
	var comet_pal: Dictionary = {"q": Color("#102040"), "c": Color("#c8fcff")}
	var comet_0: PackedStringArray = PackedStringArray([
		".q........................",
		"qSqqq.....................",
		".qSBBqq...................",
		"..qSSSSqq.................",
		"..qSSSSSSqqqqqqqqq...qq...",
		"...qSSSWWWWNCNNNWWqqqcCq..",
		"....qWWWWWWNNNNNWWWWccWCq.",
		".OOOYWWBBBBBBBBBWWWCCCCCCq",
		".OOOYWLLLLLLLLLLLLLWCCCCq.",
		"...qSLLLLLLLLLLLLLLLqCCq..",
		"..qSSSSWLLLLLLLLLWqq.qq...",
		"..qSSSSqqqqqqqqqqq........",
		".qSSSqq...................",
		"qSqBBq....................",
		".q.qq.....................",
	])
	_add(cache, "ship_comet_0", comet_pal, comet_0)
	var comet_1: PackedStringArray = comet_0.duplicate()
	comet_1[7] = "OOOYWWWBBBBBBBBBWWWCCCCCCq"
	comet_1[8] = "OOOYWWLLLLLLLLLLLLLWCCCCq."
	_add(cache, "ship_comet_1", comet_pal, comet_1)

	# COSMIC ORCA: black-and-white space orca with a smile and blush
	var orca_pal: Dictionary = {"q": Color("#05070f"), "n": Color("#2c3c60"), "m": Color("#ff9ccc"), "D": Color("#5a70a0")}
	var orca_0: PackedStringArray = PackedStringArray([
		"............q.............",
		"...........qnq............",
		"q.........qnnnq...........",
		"nq.......qnnnnnqqqq.......",
		"qnq....qqqnnnnnnnnnqqq....",
		"qnnq.qqnDDDDDDDDDDDnnnqq..",
		".qnnqnnnnnnnnnnnnWWWWWnnq.",
		".qnnnnnnnnnnnnnnnWWWWWWnnq",
		"OOYnnnnnnnnnnnnnnnnnnnNnnq",
		"qnnnnnnnnnnWWWWWWWqWWnnmnq",
		"qnqqnnnnWWWWWWWWWWWqqqqWnq",
		"nq..qnnWWWWWWWWWWWWWWWWWq.",
		"q....qqnWWWnnnWWWWWWWWqq..",
		".......qqqnnnWWWWWWqqq....",
		"..........qnqqqqqqq.......",
	])
	_add(cache, "ship_orca_0", orca_pal, orca_0)
	var orca_1: PackedStringArray = orca_0.duplicate()
	orca_1[8] = "OYWnnnnnnnnnnnnnnnnnnnNnnq"
	_add(cache, "ship_orca_1", orca_pal, orca_1)

	# HELIOS LANCER: gold-winged lance jet with a sun emblem
	var lancer_pal: Dictionary = {"q": Color("#4a2a06"), "a": Color("#c88a20")}
	var lancer_0: PackedStringArray = PackedStringArray([
		".qq.......................",
		"qaaqqq....................",
		".qaaYaqq..................",
		".qaaYYYaqq................",
		"..qaaYYYYaqqqqqq..........",
		"..qaaaYWWWWWWWWCqqqq......",
		"...qaWWWWOOOWWCCCYYYqqqqq.",
		".OOOYWWWOYYYOWWCWYWWWWWWWq",
		".OOOYWLLOYYYOLLLLYYYqqqqq.",
		"..qaaLLLLOOOLLLLLLqq......",
		"..qaaYYWWLLLLLWWqq........",
		".qaaYYYaqqqqqqqq..........",
		".qaaYaqq..................",
		"qaaqqq....................",
		".qq.......................",
	])
	_add(cache, "ship_lancer_0", lancer_pal, lancer_0)
	var lancer_1: PackedStringArray = lancer_0.duplicate()
	lancer_1[7] = "OOOYWWWWOYYYOWWCWYWWWWWWWq"
	lancer_1[8] = "OOOYWWLLOYYYOLLLLYYYqqqqq."
	_add(cache, "ship_lancer_1", lancer_pal, lancer_1)

	# EVENT HORIZON: dark core wrapped in a glowing accretion ring
	var horizon_pal: Dictionary = {"q": Color("#0a0418"), "k": Color("#0c0816"), "N": Color("#241838")}
	var horizon_0: PackedStringArray = PackedStringArray([
		"..........................",
		"..........................",
		"..........................",
		".q...........qqqqq........",
		"qKqq........qkkkkkq.......",
		".qPKqq.qqq.qNNNNPkkq.qqq..",
		".qKKKKqMMMqkNNNNNWkkqYYYqq",
		"..qKKMMMMMqNNNNNNNPkqYYYYY",
		"OYqKMMMMqqkNNNNNNNkkkqqYYY",
		"OYqKMMMMqqkkNNNNNkkkkqqYYY",
		".qKKKMMMMMqkkNNNkkkkqYYYYY",
		".qKKqqqMMMMMOOkkkOOOYYYYqq",
		"qKPq...qqqqMOOOOOOOOqqqq..",
		".qq........qqkkkkkqq......",
		".............qqqqq........",
		"..........................",
		"..........................",
	])
	_add(cache, "ship_horizon_0", horizon_pal, horizon_0)
	var horizon_1: PackedStringArray = horizon_0.duplicate()
	horizon_1[8] = "YWqKMMMMqqkNNNNNNNkkkqqYYY"
	horizon_1[9] = "YWqKMMMMqqkkNNNNNkkkkqqYYY"
	_add(cache, "ship_horizon_1", horizon_pal, horizon_1)


static func _build_shots(cache: Dictionary) -> void:
	_add(cache, "bullet_seedpod_0", {"q": Color("#4a1838"), "M": Color("#ff8cd8"), "n": Color("#ffc4ec")}, PackedStringArray([
		"....qqq....",
		"...qMnMq...",
		".qqqMnMqqq.",
		"qMMMMMMMMMq",
		"qMnMYYWMnMq",
		"qMMMYOYMMMq",
		".qMMYYYMMq.",
		".qMnMMMnMq.",
		".qMnMMMnMq.",
		"..qMMqMMq..",
		"...qq.qq...",
	]))
	_add(cache, "bullet_seedpod_1", {"q": Color("#4a1838"), "M": Color("#ff8cd8"), "n": Color("#ffc4ec")}, PackedStringArray([
		"...qq.qq...",
		"..qMMqMMq..",
		".qMnMMMnMq.",
		".qMnMMMnMq.",
		".qMMYYWMMq.",
		"qMMMYOYMMMq",
		"qMnMYYYMnMq",
		"qMMMMMMMMMq",
		".qqqMnMqqq.",
		"...qMnMq...",
		"....qqq....",
	]))
	_add(cache, "bullet_petal", {"M": Color("#ff8cd8"), "n": Color("#ffd8f0")}, PackedStringArray([
		".......",
		".MMMWM.",
		".MMMMnM",
		".MMMMM.",
		".......",
	]))
	_add(cache, "bullet_sonar", {"c": Color("#9cf4ff")}, PackedStringArray([
		"ccWCC...",
		".ccWCC..",
		"..cWWC..",
		"...cWC..",
		"...cWCC.",
		"...ccWC.",
		"...ccWC.",
		"...ccWC.",
		"...ccWC.",
		"...ccWC.",
		"...cWCC.",
		"...cWC..",
		"..cWWC..",
		".ccWCC..",
		"ccWCC...",
	]))
	_add(cache, "bullet_slash", {"m": Color("#ffb0dc"), "M": Color("#ff4ca8")}, PackedStringArray([
		"..mWWM...",
		"..mmWWM..",
		"...mmWM..",
		"....mWMM.",
		"....mWWM.",
		"....mmWM.",
		"....mmWM.",
		"....mmWM.",
		"....mmWM.",
		"....mmWM.",
		"....mWWM.",
		"....mWMM.",
		"...mmWM..",
		"..mmWWM..",
		"..mWWM...",
	]))
	_add(cache, "bullet_pellet", {}, PackedStringArray([
		".OYO.",
		"OYWYO",
		"YWWWY",
		"OYWYO",
		".OYO.",
	]))
	_add(cache, "bullet_pellet_trio", {}, PackedStringArray([
		"........OOO...",
		".......OYYYO..",
		"..OO...OYWYO..",
		".OYYO...OOO...",
		".OWYO.........",
		".OYYO.....OO..",
		"..OO.....OWYO.",
		".........OYYO.",
		"..........OO..",
	]))
	_add(cache, "bullet_rocket", {}, PackedStringArray([
		"..BB.......",
		"OrRRRRRRYW.",
		"YrRRWRRRYWW",
		"OrRRRRRRYW.",
		"..BB.......",
	]))
	_add(cache, "bullet_spark", {}, PackedStringArray([
		"..W..",
		".WWW.",
		"WWWWW",
		".WWW.",
		"..W..",
	]))
	_add(cache, "bullet_orb_0", {"a": Color("#d44cff55"), "P": Color("#b46bff"), "p": Color("#5a2a8c"), "k": Color("#0c0816"), "N": Color("#3a2a5a"), "m": Color("#ff8cf0")}, PackedStringArray([
		".................",
		".....aaaaaaa.....",
		"....aaPmPPPaa....",
		"...aPWpppppPPa...",
		"..aPPppkkkppPPa..",
		".aaPppkkkkkppPaa.",
		".aPppkNkkkkkppPa.",
		".aPpkkkkkkkkkpPa.",
		".aPpkkkkkkkkkpWa.",
		".aPpkkkkkkkkkpPa.",
		".aPppkkkkkkkppPa.",
		".aamppkkkkkppPma.",
		"..aPPppkkkppPPa..",
		"...aPWpppppPPa...",
		"....aaPPPPPaa....",
		".....aaaaaaa.....",
		".................",
	]))
	_add(cache, "bullet_orb_1", {"a": Color("#d44cff55"), "P": Color("#b46bff"), "p": Color("#5a2a8c"), "k": Color("#0c0816"), "N": Color("#3a2a5a"), "m": Color("#ff8cf0")}, PackedStringArray([
		".................",
		".....aaaaaaa.....",
		"....aaPPPPPaa....",
		"...aPPpppppWPa...",
		"..aPPppkkkppPPa..",
		".amPppkkkkkppmaa.",
		".aPppkNkkkkkppPa.",
		".aPpkkkkkkkkkpPa.",
		".aWpkkkkkkkkkpPa.",
		".aPpkkkkkkkkkpPa.",
		".aPppkkkkkkkppPa.",
		".aaPppkkkkkppPaa.",
		"..aPPppkkkppPPa..",
		"...aPPpppppWPa...",
		"....aaPPPmPaa....",
		".....aaaaaaa.....",
		".................",
	]))
	_add(cache, "bullet_comet", {"c": Color("#c8fcff"), "B": Color("#3a8cdc")}, PackedStringArray([
		"................",
		"...........CCC..",
		".........cCCccC.",
		".....ccccCCcWWcC",
		"BBBBBCCCCCCcWWcC",
		".....ccccCCccccC",
		".........cCCccC.",
		"...........CCC..",
		"................",
	]))
	_add(cache, "bullet_twin", {"m": Color("#ff9ce0")}, PackedStringArray([
		".mmWWWW.",
		"mWWWWWWW",
		".mmWWWW.",
	]))
	_add(cache, "orbit_pod_0", {"q": Color("#3a1030"), "A": Color("#ff6ac0"), "b": Color("#ffb0dc")}, PackedStringArray([
		"...qqq...",
		"..qAAAq..",
		".qAWbbAq.",
		"qAbbbbAAq",
		"qAbbbbAAq",
		"qAbbbYAAq",
		".qAAAAAq.",
		"..qAAAq..",
		"...qqq...",
	]))
	_add(cache, "orbit_pod_1", {"q": Color("#0a2a40"), "A": Color("#28c8ff"), "b": Color("#9cf4ff")}, PackedStringArray([
		"...qqq...",
		"..qAAAq..",
		".qAWbbAq.",
		"qAbbbbAAq",
		"qAbbbbAAq",
		"qAbbbYAAq",
		".qAAAAAq.",
		"..qAAAq..",
		"...qqq...",
	]))
	_add(cache, "bullet_tongue", {"q": Color("#5a0a2a"), "r": Color("#b0204e"), "M": Color("#ff6fa8"), "n": Color("#ffd0e4")}, PackedStringArray([
		"...........qqqq.",
		"qqqqqqqqqqqMMMMq",
		"rrrrrrrrrrrMnMMM",
		"MMMMMMMMMMMMMMMM",
		"qqqqqqqqqqqMMMMq",
		"...........qMMq.",
	]))
	_add(cache, "bullet_spit", {"y": Color("#d8f890")}, PackedStringArray([
		"......",
		".WyGG.",
		".GGGG.",
		".GGGG.",
		".GGGG.",
		"......",
	]))
	_add(cache, "bullet_lance", {}, PackedStringArray([
		"....OOOOOOOOOOOO....",
		"..YYYYYYYYYYYYYYYY..",
		"YYWWWWWWWWWWWWWWWWYY",
		"..YYYYYYYYYYYYYYYY..",
		"....OOOOOOOOOOOO....",
	]))
	_add(cache, "badge_frog", {"q": Color("#0c3a1c"), "m": Color("#ff9ccc")}, PackedStringArray([
		"..qqq.qqq..",
		".qWNWqWNWq.",
		".qWWWqWWWq.",
		"qGGGGGGGGGq",
		"qGmGGGGGmGq",
		"qGqqqqqqqGq",
		"qGGGGGGGGGq",
		".qGGGGGGGq.",
		"..qqqqqqq..",
	]))
	_add(cache, "badge_hog", {"q": Color("#4a1426"), "h": Color("#ff9cb4"), "H": Color("#e0607e")}, PackedStringArray([
		"qq.......qq",
		"qhq.....qhq",
		"qhhqqqqqhhq",
		"qhNhhhhhNhq",
		"qhhhHHHhhhq",
		"qhhHqHqHhhq",
		"qWhhHHHhhWq",
		".qhhhhhhhq.",
		"..qqqqqqq..",
	]))
	_add(cache, "badge_gemini", {"q": Color("#2a2a5a"), "A": Color("#ff6ac0"), "B": Color("#28c8ff")}, PackedStringArray([
		".qqq...qqq.",
		"qAAAq.qBBBq",
		"qAWAq.qBWBq",
		"qAAAq.qBBBq",
		".qqq.Y.qqq.",
		"....YYY....",
		"...YYYYY...",
		"....Y.Y....",
		"...........",
	]))
	_add(cache, "badge_hanabi", {}, PackedStringArray([
		"..Y..M..C..",
		"...Y.M.C...",
		"....YMC....",
		"YYYYYWCCCCC",
		"....GWR....",
		"...G.O.R...",
		"..G..O..R..",
		"...........",
		"...........",
	]))
	_add(cache, "badge_ronin", {"q": Color("#16060c")}, PackedStringArray([
		"..Y.....Y..",
		"..YY...YY..",
		"...YYYYY...",
		"....YYY....",
		"...........",
		"qq.........",
		"qrYWWWWWWWW",
		"qq.LLLLLLL.",
		"...........",
	]))
	_add(cache, "badge_bloom", {"q": Color("#4a1838"), "M": Color("#ff8cd8"), "n": Color("#ffc4ec")}, PackedStringArray([
		"...qMMMq...",
		"..qMnnnMq..",
		".qMMYYYMMq.",
		".qMYNYNYMq.",
		".qMYYYYYMq.",
		".qMMYYYMMq.",
		"..qMnnnMq..",
		"...qMMMq...",
		"...........",
	]))
	_add(cache, "badge_comet", {"q": Color("#102040")}, PackedStringArray([
		"...........",
		"........qq.",
		"SS....qCWCq",
		".SSBBqCWWWq",
		"..BBCCCWWCq",
		".SSBBqCCCCq",
		"SS....qCCq.",
		"........q..",
		"...........",
	]))
	_add(cache, "badge_orca", {"q": Color("#05070f"), "n": Color("#2c3c60")}, PackedStringArray([
		"....qq.....",
		"...qnq.....",
		".qqnnnqqq..",
		"qnnnnnWWnq.",
		"qnnnnnnNnnq",
		"qnWWWWWWnnq",
		".qWWWWWWWq.",
		"..qqqqqqq..",
		"...........",
	]))
	_add(cache, "badge_lancer", {}, PackedStringArray([
		".Y...Y...Y.",
		"..Y.OOO.Y..",
		"...OYYYO...",
		"YYOYWWWYOYY",
		"...OYYYO...",
		"..Y.OOO.Y..",
		".Y...Y...Y.",
		"...........",
		"...........",
	]))
	_add(cache, "badge_horizon", {"q": Color("#0a0418"), "k": Color("#0c0816"), "N": Color("#241838")}, PackedStringArray([
		"...qqqqq...",
		"..qkNNkkq..",
		".qkNkkkkkq.",
		"MMOkkkkkOYY",
		".MOOOOOOYY.",
		".qkkkkkkkq.",
		"..qkkkkkq..",
		"...qqqqq...",
		"...........",
	]))


# Builds one texture from rows.
static func _add(cache: Dictionary, key: String, pal: Dictionary, rows: PackedStringArray) -> void:
	var h: int = rows.size()
	var w: int = rows[0].length()
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in range(h):
		var row: String = rows[y]
		for x: int in range(mini(w, row.length())):
			var ch: String = row.substr(x, 1)
			if pal.has(ch):
				img.set_pixel(x, y, pal[ch])
			elif BASE.has(ch):
				img.set_pixel(x, y, BASE[ch])
	cache[key] = ImageTexture.create_from_image(img)
