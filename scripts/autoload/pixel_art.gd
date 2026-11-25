extends Node

var _cache: Dictionary = {}
var ui_font: Font = null

const PALETTE: Dictionary = {
	".": Color(0, 0, 0, 0),
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


func _ready() -> void:
	ui_font = load("res://assets/fonts/ff6_font.fnt")
	_build_all()


func tex(key: String) -> Texture2D:
	if not _cache.has(key):
		_build_all()
	return _cache.get(key, _cache.get("scout_space"))


func _make_tex(rows: PackedStringArray, custom_pal: Dictionary = {}) -> ImageTexture:
	var h: int = rows.size()
	var w: int = rows[0].length()
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in range(h):
		var row: String = rows[y]
		for x: int in range(mini(w, row.length())):
			var ch: String = row.substr(x, 1)
			var col: Color = Color(0, 0, 0, 0)
			if custom_pal.has(ch):
				col = custom_pal[ch]
			elif PALETTE.has(ch):
				col = PALETTE[ch]
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _build_all() -> void:
	if not _cache.is_empty():
		return

	# --- Player Ship & Option Orb ---
	_cache["player_idle"] = _make_tex(PackedStringArray([
		"....RRRR..................",
		"....rDDRR.................",
		".....DDSSL................",
		"...NNDDSSLLL..............",
		"..NDDSSSSLLLLLL...........",
		".YOSSSSLLBBCCLLLLWW.......",
		"WYOOWWWLLBCCWWLLLLWWWWWW..",
		"WYOOWWWLLBCCWWLLLLWWWWWWWW",
		"WYOOWWWLLBBCCLLLLWWWWWW...",
		".YOSSSSLLLLLLLLLL.........",
		"..NDDSSSSLLLLLL...........",
		"...NNDDSSLLL..............",
		".....DDSSL................",
		"....rDDRR.................",
		"....RRRR..................",
	]))

	_cache["player_flame_2"] = _make_tex(PackedStringArray([
		"....RRRR..................",
		"....rDDRR.................",
		".....DDSSL................",
		"...NNDDSSLLL..............",
		"..NDDSSSSLLLLLL...........",
		"OYOSSSSLLBBCCLLLLWW.......",
		"YYWWWWLLBCCWWLLLLWWWWWW...",
		"WYWWWWLLBCCWWLLLLWWWWWWWW.",
		"YYWWWWLLBBCCLLLLWWWWWW....",
		"OYOSSSSLLLLLLLLLL.........",
		"..NDDSSSSLLLLLL...........",
		"...NNDDSSLLL..............",
		".....DDSSL................",
		"....rDDRR.................",
		"....RRRR..................",
	]))

	_cache["option_orb"] = _make_tex(PackedStringArray([
		"...OOOOO...",
		"..OOYYYOO..",
		".OOYYYYYOO.",
		"OOYYWWWYYOO",
		"OYYWWWWWYYO",
		"OYYWWWWYYOO",
		"OYYYYYYYYOO",
		"OOYYYYYYYOO",
		".OOYYYYYOO.",
		"..OOOOOOO..",
		"...OOOOO...",
	]))

	# --- Base Enemy Silhouettes (re-paletted & specialized per biome!) ---
	var scout_disc: PackedStringArray = PackedStringArray([
		"....gggggg....",
		"..ggGGGGGGgg..",
		".gGGLLLLLLGGg.",
		"gGGLKKKKKKLGGg",
		"gGLKKYYYYKKLGg",
		"GLKKYYWWYYKKLG",
		"GLKKYWWWWYKKLG",
		"GLKKYYWWYYKKLG",
		"gGLKKYYYYKKLGg",
		"gGGLKKKKKKLGGg",
		".gGGLLLLLLGGg.",
		"..ggGGGGGGgg..",
		"....gggggg....",
	])

	var scout_diamond: PackedStringArray = PackedStringArray([
		"......CC......",
		".....CCCC.....",
		"...CCLLLLCC...",
		"..CCLBBBBLLC..",
		".CCLBYYYYBLCC.",
		"CCLBYYWWYYBLCC",
		"CLBBYWWWWYBBLC",
		"CCLBYYWWYYBLCC",
		".CCLBYYYYBLCC.",
		"..CCLBBBBLLC..",
		"...CCLLLLCC...",
		".....CCCC.....",
		"......CC......",
	])

	var swooper_wing: PackedStringArray = PackedStringArray([
		"..........RRRRRR..",
		"........rrRRRRRRr.",
		"......rrRRRRLLRRRr",
		"...rrrRRRRLLLLLR..",
		".rrRRRRYYLLLLk....",
		"WRRRRRYYWWLLkO....",
		"WWRRRRYYWWLLkYW...",
		"WRRRRRYYLLLLkO....",
		".rrRRRRYYLLLLk....",
		"...rrrRRRRLLLLLR..",
		"......rrRRRRLLRRRr",
		"........rrRRRRRRr.",
		"..........RRRRRR..",
	])

	var swooper_bio_shape: PackedStringArray = PackedStringArray([
		".......ggggGGG....",
		".....ggGGGGYYGG...",
		"...ggGGGYYYYYYG...",
		".ggGGGYYWWLLLL....",
		"GGGGYYWWWWLLg.....",
		"WGGGYYWWLLLLgO....",
		"GGGGYYWWWWLLg.....",
		".ggGGGYYWWLLLL....",
		"...ggGGGYYYYYYG...",
		".....ggGGGGYYGG...",
		".......ggggGGG....",
	])

	var sniper_pod: PackedStringArray = PackedStringArray([
		"....pppppppp....",
		"..ppPPPPPPPPpp..",
		".pPPKKKKKKKKPPp.",
		"pPPKKkNNNNkKKPPp",
		"pPKKkNCCCCNkKPPp",
		"PPKkNCCWWCCNkKPP",
		"MPKkNCWWWWCNkKPP",
		"WMKkNCWWWWCNkKPP",
		"MPKkNCCWWCCNkKPP",
		"PPKkNCCCCNkKKPPp",
		"pPKKkNNNNkKKKPPp",
		"pPPKKKKKKKKKKPPp",
		".pPPPPPPPPPPPPp.",
		"..ppPPPPPPPPpp..",
		"....pppppppp....",
	])

	var cruiser_hull: PackedStringArray = PackedStringArray([
		"..........kkkkkkkkkk........",
		".......kkkKKKKKKKKKKkkk.....",
		"....kkkKKKKLLLLLLLLKKKKkk...",
		"..RRKKKKLLLSSSSSSSSLLLKKKk..",
		".WRRKKKLLSSDDDDDDDDSSLLKKKk.",
		"WWRRKKLLSSDDNNNNNNDDSSLLKKKk",
		"..kkkkLLSSDNNRRRRNNDSSLLKKYO",
		"....kKLLSSDNRRYYRRNDSSLLKKYW",
		"...RRKLLSSDNRYYYYRNDSSLLKKYW",
		".WWRRKLLSSDNRYYYYRNDSSLLKKYO",
		".WWRRKLLSSDNRYYYYRNDSSLLKKYO",
		"...RRKLLSSDNRYYYYRNDSSLLKKYW",
		"....kKLLSSDNRRYYRRNDSSLLKKYW",
		"..kkkkLLSSDNNRRRRNNDSSLLKKYO",
		"WWRRKKLLSSDDNNNNNNDDSSLLKKKk",
		".WRRKKKLLSSDDDDDDDDSSLLKKKk.",
		"..RRKKKKLLLSSSSSSSSLLLKKKk..",
		"....kkkKKKKLLLLLLLLKKKKkk...",
		".......kkkKKKKKKKKKKkkk.....",
		"..........kkkkkkkkkk........",
	])

	# Stage 1: Space
	_cache["scout_space"] = _make_tex(scout_disc)
	_cache["swooper_space"] = _make_tex(swooper_wing)
	_cache["sniper_space"] = _make_tex(sniper_pod)
	_cache["cruiser_space"] = _make_tex(cruiser_hull)

	# Stage 2: Starcruiser Interior (industrial steel + hazard orange + cyan laser cores)
	var pal_mech: Dictionary = {"G": Color("#ff9624"), "g": Color("#8c4408"), "R": Color("#ffaa28"), "r": Color("#7a4410"), "P": Color("#687894"), "p": Color("#323c4f")}
	_cache["scout_mech"] = _make_tex(scout_diamond, {"C": Color("#ff9624"), "B": Color("#4a5870")})
	_cache["swooper_mech"] = _make_tex(swooper_wing, pal_mech)
	_cache["sniper_mech"] = _make_tex(sniper_pod, pal_mech)
	_cache["cruiser_mech"] = _make_tex(cruiser_hull, pal_mech)

	# Stage 3: Planetary Cloud Base (sky-ivory + cobalt + gold aero-craft)
	var pal_aero: Dictionary = {"G": Color("#54c8ff"), "g": Color("#1e6499"), "R": Color("#3ca8ff"), "r": Color("#1b5294"), "P": Color("#dce8ff"), "p": Color("#5c7aa8"), "K": Color("#8ab0e0"), "k": Color("#3c5884")}
	_cache["scout_aero"] = _make_tex(scout_disc, pal_aero)
	_cache["swooper_aero"] = _make_tex(swooper_wing, pal_aero)
	_cache["sniper_aero"] = _make_tex(sniper_pod, pal_aero)
	_cache["cruiser_aero"] = _make_tex(cruiser_hull, pal_aero)

	# Stage 4: Xeno Forest (emerald chitin + bioluminescent lime + magenta venom)
	var pal_bio: Dictionary = {"G": Color("#5eff6e"), "g": Color("#16692b"), "Y": Color("#ff54b8"), "P": Color("#2ec95a"), "p": Color("#115228"), "C": Color("#ffe854"), "K": Color("#2a7a3e"), "k": Color("#123d1f"), "R": Color("#ff4ca8")}
	_cache["scout_bio"] = _make_tex(scout_disc, pal_bio)
	_cache["swooper_bio"] = _make_tex(swooper_bio_shape, pal_bio)
	_cache["sniper_bio"] = _make_tex(sniper_pod, pal_bio)
	_cache["cruiser_bio"] = _make_tex(cruiser_hull, pal_bio)

	# Stage 5: Cryo Glacier (translucent cyan/white crystal + sapphire)
	var pal_ice: Dictionary = {"C": Color("#a8f8ff"), "B": Color("#2890dc"), "Y": Color("#28e8ff"), "R": Color("#64d8ff"), "r": Color("#1e68a8"), "P": Color("#7ce8ff"), "p": Color("#24689c"), "K": Color("#6cb8e6"), "k": Color("#265680")}
	_cache["scout_ice"] = _make_tex(scout_diamond, pal_ice)
	_cache["swooper_ice"] = _make_tex(swooper_wing, pal_ice)
	_cache["sniper_ice"] = _make_tex(sniper_pod, pal_ice)
	_cache["cruiser_ice"] = _make_tex(cruiser_hull, pal_ice)

	# Stage 6: Magma Core (obsidian + molten orange + yellow)
	var pal_fire: Dictionary = {"G": Color("#ff681c"), "g": Color("#7a1c08"), "R": Color("#ff5818"), "r": Color("#6e1808"), "P": Color("#d9381e"), "p": Color("#59120a"), "C": Color("#ffe854"), "K": Color("#4a2e2b"), "k": Color("#241312"), "S": Color("#ff7828"), "D": Color("#8c2814")}
	_cache["scout_fire"] = _make_tex(scout_disc, pal_fire)
	_cache["swooper_fire"] = _make_tex(swooper_wing, pal_fire)
	_cache["sniper_fire"] = _make_tex(sniper_pod, pal_fire)
	_cache["cruiser_fire"] = _make_tex(cruiser_hull, pal_fire)

	# Stage 7: Abyssal Trench (teal-aqua + bioluminescent coral)
	var pal_abyss: Dictionary = {"G": Color("#28f0d4"), "g": Color("#0e6e68"), "Y": Color("#ff78b8"), "P": Color("#1cb8b8"), "p": Color("#0c4f5c"), "K": Color("#1f6e8c"), "k": Color("#0d364d"), "R": Color("#ff6496")}
	_cache["scout_abyss"] = _make_tex(scout_disc, pal_abyss)
	_cache["swooper_abyss"] = _make_tex(swooper_bio_shape, pal_abyss)
	_cache["sniper_abyss"] = _make_tex(sniper_pod, pal_abyss)
	_cache["cruiser_abyss"] = _make_tex(cruiser_hull, pal_abyss)

	# Stage 8: Cyber Nexus (neon magenta + electric cyan + dark violet)
	var pal_cyber: Dictionary = {"C": Color("#ff38d4"), "B": Color("#7a149c"), "Y": Color("#28f8ff"), "R": Color("#ff28c8"), "r": Color("#6e0c7a"), "P": Color("#28e8ff"), "p": Color("#14528c"), "K": Color("#48206e"), "k": Color("#200b38")}
	_cache["scout_cyber"] = _make_tex(scout_diamond, pal_cyber)
	_cache["swooper_cyber"] = _make_tex(swooper_wing, pal_cyber)
	_cache["sniper_cyber"] = _make_tex(sniper_pod, pal_cyber)
	_cache["cruiser_cyber"] = _make_tex(cruiser_hull, pal_cyber)

	# --- 8 Unique Towering 16-Bit Stage Bosses (painted via BossPainter!) ---
	BossPainter.build_all_bosses(_cache)

	# --- Bullets & Pickups ---
	_cache["bullet_vulcan"] = _make_tex(PackedStringArray([
		".OOOOYYYY.",
		"OYYYYWWWWY",
		"OYYYYWWWWY",
		".OOOOYYYY.",
	]))

	_cache["bullet_laser"] = _make_tex(PackedStringArray([
		"BBBBCCCCCCCCWWWWWW",
		"CCCCCCCCWWWWWWWWWW",
		"BBBBCCCCCCCCWWWWWW",
	]))

	_cache["bullet_missile"] = _make_tex(PackedStringArray([
		"..RRLLLL..",
		"YOLLLLLLRR",
		"WWLLLLLLWW",
		"YOLLLLLLRR",
		"..RRLLLL..",
	]))

	_cache["bullet_enemy_pink"] = _make_tex(PackedStringArray([
		"..MM..",
		".MWWM.",
		"MWWWWM",
		"MWWWWM",
		".MWWM.",
		"..MM..",
	]))

	_cache["bullet_enemy_orange"] = _make_tex(PackedStringArray([
		"..OO..",
		".OYYO.",
		"OYWWYO",
		"OYWWYO",
		".OYYO.",
		"..OO..",
	]))

	_cache["bullet_enemy_cyan"] = _make_tex(PackedStringArray([
		"..BB..",
		".BCCB.",
		"BCWWCB",
		"BCWWCB",
		".BCCB.",
		"..BB..",
	]))

	_cache["bullet_enemy_lime"] = _make_tex(PackedStringArray([
		"..gg..",
		".gGGg.",
		"gGWWGg",
		"gGWWGg",
		".gGGg.",
		"..gg..",
	]))

	_cache["pickup_scrap"] = _make_tex(PackedStringArray([
		"....Y....",
		"...YYY...",
		"..YYWYY..",
		".YYWWWYY.",
		"YYWWWWWYY",
		".OYYYYYO.",
		"..OYYYO..",
		"...OOO...",
		"....O....",
	]))

	_cache["pickup_heal"] = _make_tex(PackedStringArray([
		"..ggggggg..",
		".gGGGGGGGg.",
		"gGGWWGWWGGg",
		"gGWWWWWWWGg",
		"gGGWWGWWGGg",
		"gGGGGWGGGGg",
		".gGGGGGGGg.",
		"..ggggggg..",
		"...........",
	]))

	# --- 11x11 Mini HUD Module Icons for the Bottom Upgrade Bar ---
	_cache["badge_option"] = _make_tex(PackedStringArray([
		"...OOOOO...",
		"..OYYYYYO..",
		".OYYWWWYYO.",
		"OYYWWWWWYYO",
		"OYYWWWWYYYO",
		"OYYYYYYYYYO",
		".OYYYYYYYO.",
		"..OOOOOOO..",
		"...........",
	]))

	_cache["badge_spread"] = _make_tex(PackedStringArray([
		".......YYWW",
		"....YYWW...",
		".YYWW......",
		"...........",
		"YYWW...YYWW",
		"...........",
		".YYWW......",
		"....YYWW...",
		".......YYWW",
	]))

	_cache["badge_laser"] = _make_tex(PackedStringArray([
		"...........",
		"..BBBBBB...",
		"BBCCCCCCWW.",
		"CCCCCCCCWWW",
		"CCCCCCCCWWW",
		"BBCCCCCCWW.",
		"..BBBBBB...",
		"...........",
		"...........",
	]))

	_cache["badge_missile"] = _make_tex(PackedStringArray([
		"....RRR....",
		"..YOLLLLRR.",
		".WWWLLLLRRR",
		"WWWWLLLLWWW",
		".WWWLLLLRRR",
		"..YOLLLLRR.",
		"....RRR....",
		"...........",
		"...........",
	]))

	_cache["badge_shield"] = _make_tex(PackedStringArray([
		"..CCCCCCC..",
		".CCLLLLLCC.",
		"CCLBBBBBLLC",
		"CLBBWWWBBCL",
		"CLBBWWWBBCL",
		"CCLBBBBBLLC",
		".CCLLLLLCC.",
		"..CCCCCCC..",
		"...........",
	]))

	_cache["badge_rapid"] = _make_tex(PackedStringArray([
		".....YYYY..",
		"....YYYY...",
		"...YYYY....",
		"..YYYYYYYY.",
		".....YYYY..",
		"....YYYY...",
		"...YYYY....",
		"..YY.......",
		"...........",
	]))

	_cache["badge_thruster"] = _make_tex(PackedStringArray([
		"....GGGG...",
		"..OOYYYYGG.",
		"YYYYWWWWGGG",
		"WWWWWWWWGGG",
		"YYYYWWWWGGG",
		"..OOYYYYGG.",
		"....GGGG...",
		"...........",
		"...........",
	]))

	# --- Upgrade Card Demonstration Diagrams (28x18) ---
	_cache["upg_option"] = _make_tex(PackedStringArray([
		"............................",
		"...OOO......................",
		"..OYYYO.....YYYY..YYYY......",
		"..OYWYO.....................",
		"...OOO......................",
		"...........DDLLL............",
		".........YOLLLLWWWW..YYYY...",
		".........WWLLCCWWWWWW.......",
		".........YOLLLLWWWW..YYYY...",
		"...........DDLLL............",
		"............................",
		".....OOO....................",
		"....OYYYO...YYYY..YYYY......",
		"....OYWYO...................",
		".....OOO....................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_spread"] = _make_tex(PackedStringArray([
		"......................YYWW..",
		"..................YYWW......",
		"..............YYWW..........",
		"............................",
		"...................YYWW.....",
		"...DDLLL.......YYWW.........",
		".YOLLLLWWWW.................",
		".WWLLCCWWWW..YYWW....YYWW...",
		".YOLLLLWWWW.................",
		"...DDLLL.......YYWW.........",
		"...................YYWW.....",
		"............................",
		"..............YYWW..........",
		"..................YYWW......",
		"......................YYWW..",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_laser"] = _make_tex(PackedStringArray([
		"............................",
		"...................gggg.....",
		"..................gGGGGg....",
		"...DDLLL..........gGKKGg....",
		".YOLLLLWWWWBBBBCCCCWWWWCCCCW",
		".WWLLCCWWWWCCCCCCCCWWWWWWWWC",
		".YOLLLLWWWWBBBBCCCCWWWWCCCCW",
		"...DDLLL..........gGKKGg....",
		"..................gGGGGg....",
		"...................gggg.....",
		"............................",
		"........BBBBCCCCCCCCWWWWWWWW",
		"........CCCCCCCCWWWWWWWWWWWW",
		"........BBBBCCCCCCCCWWWWWWWW",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_missile"] = _make_tex(PackedStringArray([
		"............................",
		".........OOOO..RRLLWW.......",
		"......OOO....YOLLLLRR.......",
		"....OO.......WWLLLLWW..pppp.",
		"...O...................pPPp.",
		"..DDLLL................pCCp.",
		"YOLLLLWWWW.............pppp.",
		"WWLLCCWWWW..................",
		"YOLLLLWWWW..................",
		"..DDLLL................pppp.",
		"...O...................pCCp.",
		"....OO.......WWLLLLWW..pPPp.",
		"......OOO....YOLLLLRR..pppp.",
		".........OOOO..RRLLWW.......",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_shield"] = _make_tex(PackedStringArray([
		".......CCCCCCCCCC...........",
		".....CC..........CC.........",
		"...CC..............CC..MM...",
		"..C..................CMWWM..",
		".C.....DDLLL..........CMM...",
		".C...YOLLLLWWWW........C....",
		"C....WWLLCCWWWWWW......C....",
		"C....YOLLLLWWWW........C.MM.",
		".C.....DDLLL..........C.MWWM",
		".C....................C..MM.",
		"..C..................C......",
		"...CC..............CC.......",
		".....CC..........CC.........",
		".......CCCCCCCCCC...........",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_rapid"] = _make_tex(PackedStringArray([
		"..........YYYY..............",
		".........YYYY...............",
		"........YYYY................",
		".......YYYYYYYY.............",
		"..........YYYY...YYWW.YYWW..",
		".........YYYY...............",
		"........YYYY..YYWW.YYWW.YYWW",
		".......YYYY.................",
		"............YYWW.YYWW.YYWW..",
		"............................",
		"..............YYWW.YYWW.YYWW",
		"............................",
		"..........PPPPPPPPPPPP......",
		".........PWWWWWWWWWWWWP.....",
		"..........PPPPPPPPPPPP......",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_thruster"] = _make_tex(PackedStringArray([
		"..CCCCCCCC..................",
		"............................",
		".......WWWWWWWW.............",
		"...............DDLLL........",
		".OOOOYYYYWWWWLLLLLLWWWW.....",
		"YYYYWWWWWWWWWLLCCWWWWWWWW...",
		"OOOOYYYYWWWWLLLLLLWWWW......",
		"...............DDLLL........",
		"....CCCCCCCC................",
		"............................",
		".OOOOYYYYWWWW...............",
		"......WWWWWWWWWW............",
		"............................",
		"...CCCCCCCCCC...............",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_repair"] = _make_tex(PackedStringArray([
		"............................",
		".........gggggg.............",
		"........gGGGGGGg............",
		"........gGGWWGGg............",
		".....ggggGGWWGGgggg.........",
		"....gGGGGWWWWWWGGGGg........",
		"....gGGGGWWWWWWGGGGg........",
		".....ggggGGWWGGgggg.........",
		"........gGGWWGGg............",
		"........gGGGGGGg............",
		".........gggggg.............",
		"............................",
		"....RRRRR..RRRRR..GGGGG.....",
		"....RWWWR..RWWWR..GWWWG.....",
		"....RRRRR..RRRRR..GGGGG.....",
		"............................",
		"............................",
		"............................",
	]))
