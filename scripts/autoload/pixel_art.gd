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


func _make_enemy_bullet_glow(size: int, mid_r: float, outer_r: float) -> ImageTexture:
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: float = float(size - 1) * 0.5
	for y: int in range(size):
		for x: int in range(size):
			var d: float = Vector2(float(x) - center, float(y) - center).length()
			var col: Color = Color(0.0, 0.0, 0.0, 0.0)
			if d <= 3.4:
				# High-contrast dark crimson backing so bullets pop even against bright lava or sky!
				col = Color(0.26, 0.0, 0.05, 0.90)
			elif d <= mid_r:
				# Bright vivid danger-red inner halo
				col = Color(1.0, 0.10, 0.18, 0.76)
			elif d <= outer_r:
				# Soft pulsing scarlet outer aura
				var t: float = (d - mid_r) / maxf(0.01, outer_r - mid_r)
				col = Color(1.0, 0.06, 0.14, lerpf(0.46, 0.0, t))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


## One frame of a spinning XP cell, w x h: a terminal cap, a metal case with rims top and bottom
## and a glowing core with a glint. Frame 0 is face on, 1 and 3 turning, 2 edge on.
func _make_xp_cell(w: int, h: int, core: Color, core_dk: Color, case_lt: Color, case_dk: Color, frame: int) -> ImageTexture:
	var turned: int = w - 2 * floori(w / 4.0)
	var fw: int = [w, turned, 3, turned][frame]
	var x0: int = floori((w - fw) / 2.0)
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ink: Color = Color("#141a2c")
	var cap: int = 1 if fw <= 3 else 3
	var cap_x: int = floori((w - cap) / 2.0)
	for x: int in range(cap_x, cap_x + cap):
		img.set_pixel(x, 0, case_lt)
	var top: int = 1
	var bot: int = h - 1
	for y: int in range(top, h):
		for x: int in range(x0, x0 + fw):
			var edge_x: bool = x == x0 or x == x0 + fw - 1
			var edge_y: bool = y == top or y == bot
			if edge_x and edge_y:
				continue
			var col: Color
			if edge_x or edge_y:
				col = ink
			elif y == top + 1:
				col = case_lt
			elif y == bot - 1:
				col = case_dk
			elif fw > 3 and x == x0 + 1:
				col = case_lt
			elif fw > 3 and x == x0 + fw - 2:
				col = case_dk
			else:
				var k: float = float(y - top - 2) / float(maxi(1, bot - top - 4))
				col = core.lerp(core_dk, clampf(k * 1.3 - 0.25, 0.0, 1.0))
			img.set_pixel(x, y, col)
	# The glint slides across as it turns.
	var gx: int = [x0 + 2, x0 + 1, x0 + 1, x0 + fw - 3][frame] if fw > 3 else x0 + 1
	img.set_pixel(gx, top + 2, Color.WHITE)
	if h >= 11:
		img.set_pixel(gx, top + 3, Color.WHITE)
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

	_cache["option_yarn"] = _make_tex(PackedStringArray([
		"...MMMMM...",
		"..MMWWWMM..",
		".MWWMMMWWM.",
		"MWMMYYYMMWM",
		"MWMYYWYYMWM",
		"MWMMYYYMMWM",
		".MWWMMMWWM.",
		"..MMWWWMM..M",
		"...MMMMM..MM",
	]))

	# --- 6 Unlockable Playable Starships (2 animated frames each!) ---
	# 1) SCARAB BIO-CRUISER (Living emerald-magenta xeno beetle!)
	_cache["ship_beetle_0"] = _make_tex(PackedStringArray([
		".....ggggg................",
		"...ggGGGGGGg..............",
		"..gGGMMGGGGGGg............",
		".gGMMWWMMGGGGGGg..YYY.....",
		"MGGMMWWMMGGGGGGGGYYWWYY...",
		"WGGGGGGGGGGCCWWWWGG.......",
		"MWWGGGGGGCCCCWWWWGGGGYY...",
		"WGGGGGGGGGGCCWWWWGG.......",
		"MGGMMWWMMGGGGGGGGYYWWYY...",
		".gGMMWWMMGGGGGGg..YYY.....",
		"..gGGMMGGGGGGg............",
		"...ggGGGGGGg..............",
		".....ggggg................",
	]))
	_cache["ship_beetle_1"] = _make_tex(PackedStringArray([
		"....gggggg................",
		"..ggGGGGGGGg..............",
		".gGGMMGGGGGGGg....YYY.....",
		".gGMMWWMMGGGGGGg..YYWWYY..",
		"WGGMMWWMMGGGGGGGGGG.......",
		"MWWGGGGGGGGCCWWWWGGGGYY...",
		"WWWGGGGGGCCCCWWWWGGGGWW...",
		"MWWGGGGGGGGCCWWWWGGGGYY...",
		"WGGMMWWMMGGGGGGGGGG.......",
		".gGMMWWMMGGGGGGg..YYWWYY..",
		".gGGMMGGGGGGGg....YYY.....",
		"..ggGGGGGGGg..............",
		"....gggggg................",
	]))

	# 2) CHRONO PHANTOM (Forward-swept stealth phase needle-wing!)
	_cache["ship_phantom_0"] = _make_tex(PackedStringArray([
		"..........NNNNCCCC........",
		"........NNDDCCCCCCWW......",
		"......NNDDCCCCCCCCWWWW....",
		"...NNNDDSSLLBBCCCC........",
		".CCWWDDSSLLLBBCCWWWW......",
		"CWWWWNNDDLLLCCWWWWWWWWYYYY",
		".CCWWDDSSLLLBBCCWWWW......",
		"...NNNDDSSLLBBCCCC........",
		"......NNDDCCCCCCCCWWWW....",
		"........NNDDCCCCCCWW......",
		"..........NNNNCCCC........",
	]))
	_cache["ship_phantom_1"] = _make_tex(PackedStringArray([
		"..........NNNNCCCC........",
		"........NNDDCCCCCCWW......",
		"......NNDDCCCCCCCCWWWW....",
		"...NNNDDSSLLBBCCCC........",
		"BCCWWDDSSLLLBBCCWWWW......",
		"WWWWWNNDDLLLCCWWWWWWWWWWWW",
		"BCCWWDDSSLLLBBCCWWWW......",
		"...NNNDDSSLLBBCCCC........",
		"......NNDDCCCCCCCCWWWW....",
		"........NNDDCCCCCCWW......",
		"..........NNNNCCCC........",
	]))

	# 3) TITAN GUNSHIP (Twin-prow heavy siege corvette!)
	_cache["ship_dread_0"] = _make_tex(PackedStringArray([
		"..kkkkOOOOOO..............",
		".YOOKKOOOOLLLLWW..........",
		"WYYOKKSSLLLLLLLLWWWW......",
		".kkkkKSSDDDDSSSSLLLLWW....",
		"...kKKSSDDCCWWDDSSLL......",
		".YOOKKSSDDCCWWDDSSLLWWWW..",
		"WYYOKKSSDDDDSSSSLLLLWWWW..",
		".kkkkKSSDDDDSSSSLLLLWW....",
		"WYYOKKSSLLLLLLLLWWWW......",
		".YOOKKOOOOLLLLWW..........",
		"..kkkkOOOOOO..............",
	]))
	_cache["ship_dread_1"] = _make_tex(PackedStringArray([
		"..kkkkOOOOOO..............",
		"YYWWKKOOOOLLLLWW..........",
		"WWWWKKSSLLLLLLLLWWWW......",
		".kkkkKSSDDDDSSSSLLLLWW....",
		"...kKKSSDDCCWWDDSSLL......",
		"YYWWKKSSDDCCWWDDSSLLWWWW..",
		"WWWWKKSSDDDDSSSSLLLLWWWW..",
		".kkkkKSSDDDDSSSSLLLLWW....",
		"WWWWKKSSLLLLLLLLWWWW......",
		"YYWWKKOOOOLLLLWW..........",
		"..kkkkOOOOOO..............",
	]))

	# 4) COSMIC SAUCER X-99 (Spinning neon-domed alien UFO!)
	_cache["ship_saucer_0"] = _make_tex(PackedStringArray([
		"........CCCCCC............",
		"......CCWWWWWWCC..........",
		".....CWWCCWWWWWWC.........",
		"...KKKCCCCCCCCCCKKK.......",
		".KKLLLSSSSSSSSSSLLLKK.....",
		"KLLGGSSYYSSSSGGSSYYLLK....",
		"WWWWWWWWWWWWWWWWWWWWWW....",
		".KKDDDDDDDDDDDDDDDDKK.....",
		"...KKKKGGGGGGGGKKKK.......",
		"......GG..YY..GG..........",
	]))
	_cache["ship_saucer_1"] = _make_tex(PackedStringArray([
		"........CCCCCC............",
		"......CCWWWWWWCC..........",
		".....CWWWWCCWWWWC.........",
		"...KKKCCCCCCCCCCKKK.......",
		".KKLLLSSSSSSSSSSLLLKK.....",
		"KLLYYSSGGSSSSYYSSGGLLK....",
		"CCCCCCCCCCCCCCCCCCCCCC....",
		".KKDDDDDDDDDDDDDDDDKK.....",
		"...KKKKCCCCCCCCKKKK.......",
		"......CC..GG..CC..........",
	]))

	# 5) OCULARIS VOID-SPAWN (Floating cosmic eyeball w/ writhing tentacles!)
	_cache["ship_eyeball_0"] = _make_tex(PackedStringArray([
		"..pppp....pppppp..........",
		"ppPPPpp..pPPPPPPpp........",
		"....ppPPpPPWWWWPPPp.......",
		".ppp..pPPPWWWWWWWRRp......",
		"pPPPppPPWWWWWWWRRMMRp.....",
		"....pPPPWWWWWWWRMWWMR.....",
		".ppp.pPPWWWWWWWRRMMRp.....",
		"pPPPp.pPPPWWWWWWWRRp......",
		"....ppPPpPPWWWWPPPp.......",
		"..pppp...pPPPPPPpp........",
		"ppPPPp....pppppp..........",
	]))
	_cache["ship_eyeball_1"] = _make_tex(PackedStringArray([
		"ppPPPp....pppppp..........",
		"..pppp...pPPPPPPpp........",
		".ppp..pPpPPWWWWPPPp.......",
		"pPPPpp..pPWWWWWWWRRp......",
		"....ppPPWWWWWWWRRMMRp.....",
		".ppppPPPWWWWWWWRMWWMR.....",
		"pPPP..pPWWWWWWWRRMMRp.....",
		"....pppPPPWWWWWWWRRp......",
		"..pppp..pPPWWWWPPPp.......",
		"ppPPPp...pPPPPPPpp........",
		"..........pppppp..........",
	]))

	# 6) S.S. MEOW-ZER: a chibi white kitten ship. Big round head, pink ears, big shiny eyes,
	# blush, a pink collar with a gold bell, paws reaching forward and a curled tail; a little
	# jet flame flickers behind it. q = plum outline, m = blush.
	var neko_pal: Dictionary = {"q": Color("#4a1f45"), "m": Color("#ff9ccc")}
	var neko_rows: PackedStringArray = PackedStringArray([
		"...........q...........q..",
		"..........qWq.qqqqqqq.qWq.",
		"....q.....qMWqWWWWWWWqWMq.",
		"...qMq....qWMWWWWWWWWWMWq.",
		"..qWMq....qWWWWWWWWWWWWWq.",
		"..qWq.....qWWWWWWWWWWWWWq.",
		".qWq.....qWWWWNNWWWWNNWWWq",
		".qWq.....qWWWNWNWWWNWNWWWq",
		".qWq..qqqqWWWNNNWWWNNNWWWq",
		".qWWqqWWWWWWWCNWWMWCNWWWWq",
		"..qWWWWLWLWmmWWWqWqWWWmmWq",
		"..OqWWWLWLWWWWWWWqWWWWWWq.",
		"OOYqWWWWWWWWWWWWWWWWWWWWq.",
		"..O.qWWWWWWWMMMMMYMMMMqq..",
		"...qWWWWWWWWWqWWYYYWWqqqq.",
		"....qqqqqqqqq.qqqqqqqWWWWq",
		".....................qqqq.",
	])
	_cache["ship_neko_0"] = _make_tex(neko_rows, neko_pal)
	# Frame 1 only changes the jet flame, so the kitten itself never jitters.
	var neko_rows_1: PackedStringArray = neko_rows.duplicate()
	neko_rows_1[11] = "..YqWWWLWLWWWWWWWqWWWWWWq."
	neko_rows_1[12] = "OYWqWWWWWWWWWWWWWWWWWWWWq."
	neko_rows_1[13] = "..Y.qWWWWWWWMMMMMYMMMMqq.."
	_cache["ship_neko_1"] = _make_tex(neko_rows_1, neko_pal)

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

	# --- Stage-signature enemies and their special shots (painted via EnemyArt) ---
	EnemyArt.build_all(_cache)
	# --- The 10 hangar-expansion ships, their shots and badges (ShipArt) ---
	ShipArt.build_all(_cache)

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

	_cache["bullet_wave"] = _make_tex(PackedStringArray([
		"..gggGG..",
		".gGGYYWW.",
		"gGYYWW...",
		"GYYWW....",
		"GYWW.....",
		"GYWW.....",
		"GYYWW....",
		"gGYYWW...",
		".gGGYYWW.",
		"..gggGG..",
	]))

	_cache["bullet_prism"] = _make_tex(PackedStringArray([
		"...MM...",
		"..MPPM..",
		".MPWWPM.",
		"MPWWWWPM",
		"MPWWWWPM",
		".MPWWPM.",
		"..MPPM..",
		"...MM...",
	]))

	_cache["bullet_tesla"] = _make_tex(PackedStringArray([
		"..PP..CC..WW",
		"PPCCWWCCWWWW",
		"..WWWWWWWWWW",
		"PPCCWWCCWWWW",
		"..PP..CC..WW",
	]))

	_cache["bullet_plasma"] = _make_tex(PackedStringArray([
		"..rrrrr..",
		".rROOOOr.",
		"rROYYYYOr",
		"ROYYWWYYO",
		"ROYWWWWYO",
		"ROYYWWYYO",
		"rROYYYYOr",
		".rROOOOr.",
		"..rrrrr..",
	]))

	_cache["bullet_dart"] = _make_tex(PackedStringArray([
		".ggGGGG.",
		"GGWWWWWW",
		".ggGGGG.",
	]))

	_cache["bullet_flank"] = _make_tex(PackedStringArray([
		".OOYYYY.",
		"YYWWWWWW",
		"YYWWWWWW",
		".OOYYYY.",
	]))

	_cache["bullet_bomb"] = _make_tex(PackedStringArray([
		"..ppppp..",
		".pPPPPPp.",
		"pPPMMMMPp",
		"PPMWWWMPP",
		"PPMWWWMPP",
		"pPPMMMMPp",
		".pPPPPPp.",
		"..ppppp..",
	]))

	_cache["addon_sawblade"] = _make_tex(PackedStringArray([
		"....CC.....",
		"...CWWC..C.",
		".C..CC..CWC",
		"CWC.LL.CC..",
		".CCLLLLLLC.",
		"..LLWWWWLL.",
		".CLLLLLLCC.",
		"..CC.LL.CWC",
		"CWC..CC..C.",
		".C..CWWC...",
		".....CC....",
	]))

	# --- Exotic Ship Signature Projectiles (Flying Space Cats, Bio-Waves, Abduction Rings, Ocular Gaze!) ---
	# Flying space cats (S.S. MEOW-ZER): big leaping kittens with a bold outline, ears, eyes and a
	# tail, drawn upright so they read as cats at full speed. Frame 1 only moves the legs and tail.
	# Three coats from the same rows: orange tabby, snow white and blue tabby
	# (O = fur, o = stripes, c = muzzle/paws, m = blush).
	var cat_rows_0: PackedStringArray = PackedStringArray([
		"........k........k..",
		".......kOk......kOk.",
		".......kMOkkkkkkOMk.",
		"..kk...kOOOOOOOOOOk.",
		".kOOk..kONNOOOONNOk.",
		".kOk...kONNOOOONNOk.",
		"..kOk.kkmOOOMMOOOmk.",
		"...kOOOOOccckkcccOk.",
		"...kOoOoOOccccccckk.",
		"...kOoOoOkkkkkkkkcck",
		"kcckkkkkk.......kkk.",
		".kk.................",
	])
	var cat_rows_1: PackedStringArray = PackedStringArray([
		"........k........k..",
		".......kOk......kOk.",
		".......kMOkkkkkkOMk.",
		".......kOOOOOOOOOOk.",
		".kk....kONNOOOONNOk.",
		"kOOk...kONNOOOONNOk.",
		".kOOk.kkmOOOMMOOOmk.",
		"..kOOOOOOccckkcccOk.",
		"...kOoOoOOccccccckk.",
		"...kOoOoOkkkkkkkk...",
		"..kcckkkkk....kcck..",
		"...kk..........kk...",
	])
	var cat_coats: Dictionary = {
		"bullet_cat": {"O": Color("#ff9624"), "o": Color("#d86a10"), "c": Color("#fff4dc"), "m": Color("#ff9ccc")},
		"bullet_cat_snow": {"O": Color("#ffffff"), "o": Color("#b8c4e0"), "c": Color("#ffffff"), "m": Color("#ff9ccc")},
		"bullet_cat_blue": {"O": Color("#8ca6d8"), "o": Color("#3b5284"), "c": Color("#ffffff"), "m": Color("#ff9ccc")},
	}
	for coat: String in cat_coats.keys():
		var coat_pal: Dictionary = cat_coats[coat]
		_cache[coat + "_0"] = _make_tex(cat_rows_0, coat_pal)
		_cache[coat + "_1"] = _make_tex(cat_rows_1, coat_pal)

	_cache["bullet_biowave"] = _make_tex(PackedStringArray([
		"...ggGGG..",
		".ggGGMMWW.",
		"gGGMMWW...",
		"GMMWW.....",
		"GMWW......",
		"GMMWW.....",
		"gGGMMWW...",
		".ggGGMMWW.",
		"...ggGGG..",
	]))

	_cache["bullet_rail"] = _make_tex(PackedStringArray([
		"CCCCYYYYWWWWWWWWWW",
		"YYYYWWWWWWWWWWWWWW",
		"CCCCYYYYWWWWWWWWWW",
	]))

	_cache["bullet_flak"] = _make_tex(PackedStringArray([
		"..kkkkk..",
		".kKOOOOk.",
		"kKOYYYYOk",
		"KOYWWWWYO",
		"kKOYYYYOk",
		".kKOOOOk.",
		"..kkkkk..",
	]))

	_cache["bullet_ufo_ring"] = _make_tex(PackedStringArray([
		"..GGGGGG..",
		".GGCCCCGG.",
		"GGCWWWWCGG",
		"GCWW..WWCG",
		"GCWW..WWCG",
		"GGCWWWWCGG",
		".GGCCCCGG.",
		"..GGGGGG..",
	]))

	_cache["bullet_eyeball"] = _make_tex(PackedStringArray([
		"..ppppp..",
		".pPWWWPp.",
		"pPWWWWWRp",
		"PWWWWRMMR",
		"PWWWWRWWR",
		"pPWWWWWRp",
		".pPWWWPp.",
		"..ppppp..",
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

	_cache["bullet_enemy_glow_0"] = _make_enemy_bullet_glow(16, 5.2, 7.8)
	_cache["bullet_enemy_glow_1"] = _make_enemy_bullet_glow(18, 6.0, 8.8)

	# XP: little energy cells spinning on their long axis (Matthew wanted a look of their own; the
	# old blue gems were too like Ball x Pit's). Small cells are green, medium amber, big magenta
	# in a gold case. Frames _0.._3; the plain key is frame 0.
	var cells: Dictionary = {
		"small": [7, 9, PALETTE["G"], PALETTE["g"], PALETTE["L"], PALETTE["K"]],
		"med": [9, 11, PALETTE["Y"], PALETTE["O"], PALETTE["L"], PALETTE["K"]],
		"big": [11, 13, PALETTE["M"], PALETTE["p"], PALETTE["Y"], PALETTE["O"]],
	}
	for size_key: String in cells.keys():
		var c: Array = cells[size_key]
		for f: int in range(4):
			_cache["pickup_xp_%s_%d" % [size_key, f]] = _make_xp_cell(int(c[0]), int(c[1]), c[2], c[3], c[4], c[5], f)
		_cache["pickup_xp_" + size_key] = _cache["pickup_xp_%s_0" % size_key]

	_cache["pickup_scrap"] = _cache["pickup_xp_small"]

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

	_cache["badge_vulcan"] = _make_tex(PackedStringArray([
		"...........",
		"..OOYYYYWW.",
		"..YYYYWWWW.",
		"...........",
		"...........",
		"..OOYYYYWW.",
		"..YYYYWWWW.",
		"...........",
		"...........",
	]))

	_cache["badge_wave"] = _make_tex(PackedStringArray([
		".....GGYYWW",
		"...GGYYWW..",
		"..GYYWW....",
		".GYWW......",
		".GYWW......",
		"..GYYWW....",
		"...GGYYWW..",
		".....GGYYWW",
		"...........",
	]))

	_cache["badge_prism"] = _make_tex(PackedStringArray([
		"....MMM....",
		"...MPWPM...",
		"..MPWWWPM..",
		".MPWWWWWM..",
		"..MPWWWPM..",
		"...MPWPM...",
		"....MMM....",
		"...........",
		"...........",
	]))

	_cache["badge_tesla"] = _make_tex(PackedStringArray([
		"......CCWW.",
		"....PPCC...",
		"..PPCCWW...",
		"PPCCWWWWWW.",
		"....CCWW...",
		"..PPCC.....",
		"PPCC.......",
		"...........",
		"...........",
	]))

	_cache["badge_plasma"] = _make_tex(PackedStringArray([
		"...rrrrr...",
		"..rROOOOr..",
		".rROYYYYOr.",
		".ROYWWWWYO.",
		".ROYWWWWYO.",
		".rROYYYYOr.",
		"..rROOOOr..",
		"...rrrrr...",
		"...........",
	]))

	_cache["badge_flank"] = _make_tex(PackedStringArray([
		"YY.........",
		".YY....LLWW",
		"..YY.DDLLLL",
		"WWYYLLLLWWW",
		"..YY.DDLLLL",
		".YY....LLWW",
		"YY.........",
		"...........",
		"...........",
	]))

	_cache["badge_blades"] = _make_tex(PackedStringArray([
		"....CC.....",
		".C..CWC..C.",
		"CWC.LLL.CWC",
		"..CLLWLLC..",
		"..CLWWWL...",
		"..CLLWLLC..",
		"CWC.LLL.CWC",
		".C..CWC..C.",
		"....CC.....",
	]))

	_cache["badge_turret"] = _make_tex(PackedStringArray([
		".......GGWW",
		".....GGWW..",
		"...GGGG....",
		"..GLLLLG...",
		".GLLWWLLG..",
		"KKKKKKKKKK.",
		"DDDDDDDDDD.",
		"...........",
		"...........",
	]))

	_cache["badge_bomb"] = _make_tex(PackedStringArray([
		"...ppppp...",
		"..pPMMMPp..",
		".pPMWWWMPp.",
		".pPMWWWMPp.",
		"..pPMMMPp..",
		"...ppppp...",
		".MM.PPP.MM.",
		"...........",
		"...........",
	]))

	_cache["badge_nova"] = _make_tex(PackedStringArray([
		"...CCCCC...",
		".CC..Y..CC.",
		"C...YYY...C",
		"C..YYWYY..C",
		"C...YYY...C",
		".CC..Y..CC.",
		"...CCCCC...",
		"...........",
		"...........",
	]))

	_cache["badge_ship"] = _make_tex(PackedStringArray([
		"...DD......",
		"..DLLL.....",
		".YOLLLLWW..",
		"WWLLCCWWWWW",
		".YOLLLLWW..",
		"..DLLL.....",
		"...DD......",
		"...........",
		"...........",
	]))

	# The S.S. MEOW-ZER kitten's face (skill-tree node and pause-screen badge).
	_cache["badge_cat"] = _make_tex(PackedStringArray([
		".q.......q.",
		"qMq.....qMq",
		"qWMqqqqqMWq",
		"qWWWWWWWWWq",
		"qWNWWWWWNWq",
		"qmNWWMWWNmq",
		"qWWWqWqWWWq",
		".qWWWWWWWq.",
		"..qqqqqqq..",
	]), {"q": Color("#4a1f45"), "m": Color("#ff9ccc")})

	_cache["badge_scrap"] = _make_tex(PackedStringArray([
		"....YYY....",
		"...YYYYY...",
		"..YYWWWYY..",
		".YYWWWWWYY.",
		"..OYYYYYO..",
		"...OYYYO...",
		"....OOO....",
		"...........",
		"...........",
	]))

	_cache["badge_xp"] = _make_tex(PackedStringArray([
		"....CCC....",
		"..CCCCCCC..",
		".CCCWWWCCC.",
		"CCWWWWWWWCC",
		".BCCWWWCBB.",
		"..BBBBBBB..",
		"....BBB....",
		"...........",
		"...........",
	]))

	_cache["badge_crit"] = _make_tex(PackedStringArray([
		".....Y.....",
		"..Y..Y..Y..",
		"...YYYYY...",
		"YYYYWWWYYYY",
		"...YYYYY...",
		"..Y..Y..Y..",
		".....Y.....",
		"...........",
		"...........",
	]))

	_cache["badge_revive"] = _make_tex(PackedStringArray([
		".YY.....YY.",
		"YYOO...OOYY",
		"YYOYYYYYOYY",
		".YYOYYYOYY.",
		"..YYWWWWW..",
		"...YYYYY...",
		"....YYY....",
		"...........",
		"...........",
	]))

	_cache["badge_reroll"] = _make_tex(PackedStringArray([
		"..PPPPPPP..",
		".PWWWWWWWP.",
		".PWWPPWWWP.",
		".PWWWWWWWP.",
		".PWWWPWWWP.",
		".PWWWWWWWP.",
		"..PPPPPPP..",
		"...........",
		"...........",
	]))

	_cache["badge_weird"] = _make_tex(PackedStringArray([
		"...MMMMM...",
		".MMCCCCCmm.",
		"MCCWWWWWCCM",
		"MCWWPPPWWCM",
		"MCCWWWWWCCM",
		".MMCCCCCmm.",
		"...MMMMM...",
		"...........",
		"...........",
	]))

	_cache["badge_bio"] = _make_tex(PackedStringArray([
		"...ggggg...",
		".ggGGGGGgg.",
		"gGGMMWMMGGg",
		"gGMWWWWWWGg",
		"gGGMMWMMGGg",
		".ggGGGGGgg.",
		"...ggggg...",
		"...........",
		"...........",
	]))

	_cache["badge_ufo"] = _make_tex(PackedStringArray([
		"...CCCCC...",
		"..CWWWWWC..",
		".KCCCCCCCK.",
		"GGGGGGGGGGG",
		".KDDDDDDDK.",
		"..GG...GG..",
		"...........",
		"...........",
		"...........",
	]))

	_cache["badge_eye"] = _make_tex(PackedStringArray([
		"..ppppppp..",
		".pPWWWWWPp.",
		"pPWWWRRWWPp",
		"PWWWRWWWRWP",
		"pPWWWRRWWPp",
		".pPWWWWWPp.",
		"..ppppppp..",
		"...........",
		"...........",
	]))

	_cache["upg_overclock"] = _make_tex(PackedStringArray([
		"............................",
		".............YY.............",
		"............YYYY............",
		"...DDLLL...YYYYYY..YYWW.....",
		".YOLLLLWWWW..YY.......YYWW..",
		".WWLLCCWWWW..YY..YYYYWWWWWWW",
		".YOLLLLWWWW..YY.......YYWW..",
		"...DDLLL.....YY....YYWW.....",
		"............................",
		".......YYYY..YYYY..YYYY.....",
		".......YWWY..YWWY..YWWY.....",
		".......YYYY..YYYY..YYYY.....",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
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

	_cache["upg_wave"] = _make_tex(PackedStringArray([
		"............................",
		"..............GGYYWW........",
		"............GGYYWW..........",
		"...........GYWW......GGYYWW.",
		"...DDLLL...GYWW....GGYYWW...",
		".YOLLLLWWWW.GGYYWW..GYWW....",
		".WWLLCCWWWW...GGYYWWGYWW....",
		".YOLLLLWWWW.GGYYWW..GGYYWW..",
		"...DDLLL...GYWW.......GGYYWW",
		"...........GYWW.............",
		"............GGYYWW..........",
		"..............GGYYWW........",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_prism"] = _make_tex(PackedStringArray([
		"CCCCCCCCCCCCCCCCCCCCCCCCCCCC",
		"...............MM...........",
		".............MPWWPM.........",
		"...........MM..MM..MM.......",
		".........MM..........MM.....",
		"..DDLLL.MM............MPWPM.",
		"YOLLLLWWWW..............MM..",
		"WWLLCCWWWW..................",
		"YOLLLLWWWW..........MM......",
		"..DDLLL...........MPWWPM....",
		"................MM..MM......",
		"..............MM............",
		"............MPWPM...........",
		"CCCCCCCCCCCCCCCCCCCCCCCCCCCC",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_tesla"] = _make_tex(PackedStringArray([
		"............................",
		"....................gggg....",
		"...................gGGGGg...",
		"................WW..gggg....",
		"..DDLLL.......CCWW..........",
		"YOLLLLWWWWPPCCWW............",
		"WWLLCCWWWWWWWWWWCC..........",
		"YOLLLLWWWWPPCC..WWCC........",
		"..DDLLL...........WWCC......",
		"....................WWgggg..",
		".....................gGGGGg.",
		"......................gggg..",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_plasma"] = _make_tex(PackedStringArray([
		"............................",
		"..................OOOOOO....",
		"................OOYYYYYYOO..",
		"...............OYYWWWWWWYYO.",
		"..DDLLL.......rROYYWWWWYYORr",
		"YOLLLLWWWW..rROYWYWWWWWWYWYO",
		"WWLLCCWWWW..ROYWWYWWWWWWYWYO",
		"YOLLLLWWWW..rROYWYWWWWWWYWYO",
		"..DDLLL.......rROYYWWWWYYORr",
		"...............OYYWWWWWWYYO.",
		"................OOYYYYYYOO..",
		"..................OOOOOO....",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_flank"] = _make_tex(PackedStringArray([
		"............................",
		"....YYWW....................",
		"......YYWW..................",
		"........YYWW................",
		"............DDLLL...........",
		"..........YOLLLLWWWW..YYWW..",
		".WWYYYY...WWLLCCWWWW........",
		"..........YOLLLLWWWW..YYWW..",
		"............DDLLL...........",
		"........YYWW................",
		"......YYWW..................",
		"....YYWW....................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_blades"] = _make_tex(PackedStringArray([
		"...........CC...............",
		".........CCWWCC.............",
		"...........CC...............",
		".....CC..........CC.........",
		"...CCWWCC......CCWWCC.......",
		".....CC..DDLLL...CC.........",
		".......YOLLLLWWWW...........",
		".......WWLLCCWWWW...........",
		".......YOLLLLWWWW...........",
		".....CC..DDLLL...CC.........",
		"...CCWWCC......CCWWCC.......",
		".....CC..........CC.........",
		"...........CC...............",
		".........CCWWCC.............",
		"...........CC...............",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_turret"] = _make_tex(PackedStringArray([
		"......................gggg..",
		"...................WWgGGGGg.",
		".................GGWW.gggg..",
		"...............GG...........",
		"............GGWW............",
		"........GGGG................",
		".......GLLWWG...............",
		".......DDLLL................",
		".....YOLLLLWWWW.............",
		".....WWLLCCWWWW.............",
		".....YOLLLLWWWW.............",
		".......DDLLL................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_bomb"] = _make_tex(PackedStringArray([
		"............................",
		"..DDLLL.....................",
		"YOLLLLWWWW..................",
		"WWLLCCWWWW..................",
		"YOLLLLWWWW..................",
		"..DDLLL.....................",
		"......ppppp.................",
		".....pPMWMPp................",
		"......ppppp...PPPPPPPP......",
		"............PPMMMMMMMMPP....",
		"...........PMMWWWWWWWWMMP...",
		"............PPMMMMMMMMPP....",
		"..............PPPPPPPP......",
		"DDDDDDDDDDDDDDDDDDDDDDDDDDDD",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	_cache["upg_nova"] = _make_tex(PackedStringArray([
		"........CCCCCCCCCCCC........",
		".....CCC............CCC.....",
		"...CC.....YYYYYYYY.....CC...",
		"..C.....YY........YY.....C..",
		".C.....Y....DDLLL...Y.....C.",
		".C....Y...YOLLLLWWWW.Y....C.",
		"C.....Y...WWLLCCWWWW.Y.....C",
		"C.....Y...YOLLLLWWWW.Y.....C",
		".C....Y.....DDLLL....Y....C.",
		".C.....Y............Y.....C.",
		"..C.....YY........YY.....C..",
		"...CC.....YYYYYYYY.....CC...",
		".....CCC............CCC.....",
		"........CCCCCCCCCCCC........",
		"............................",
		"............................",
		"............................",
		"............................",
	]))

	# --- UI: bouncing cursor over the selected level-up draft card ---
	_cache["ui_cursor_down"] = _make_tex(PackedStringArray([
		"NNNNNNNNNNN",
		"NWWWWWWWWWN",
		".NYYYYYYYN.",
		"..NYYYYYN..",
		"...NYOYN...",
		"....NON....",
		".....N.....",
	]))

	_build_draft_card_icons()


# --- DRAFT CARD upgrades (unlocked in the Skill Tree): 11x9 badges, projectiles, and 28x18 card art ---
func _build_draft_card_icons() -> void:
	var badges: Dictionary = {
		"badge_seek": [
			".......RRR.",
			"......RWWWR",
			"....Y.RW.WR",
			"...Y..RWWWR",
			"..Y....RRR.",
			".Y.........",
			".Y.........",
			"WW.........",
			"...........",
		],
		"badge_shrapnel": [
			"........OO.",
			"....OO.....",
			"LLW.....YY.",
			"LLWW.YY....",
			"LLW.....YY.",
			"....OO.....",
			"........OO.",
			"...........",
			"...........",
		],
		"badge_berserk": [
			".RR...RR...",
			"RRRR.RRRR..",
			"RWRRRRRRR..",
			"RRRRRRRRR.Y",
			".RRRRRRR.YO",
			"..RRRRR..OY",
			"...RRR...YO",
			"....R......",
			"...........",
		],
		"badge_execute": [
			"...LLLLL...",
			"..LLLLLLL..",
			".LLkkLkkLL.",
			".LLkkLkkLL.",
			".LLLLkLLLL.",
			"..LLLLLLL..",
			"...L.L.L...",
			"...........",
			"...........",
		],
		"badge_ambush": [
			".....R.....",
			"...RRRRR...",
			"..R..Y..R..",
			"RRR..Y..RRR",
			"..R.....R..",
			"...RRYRR...",
			".....R.....",
			"...........",
			"...........",
		],
		"badge_cryo": [
			".....C.....",
			"..C..C..C..",
			"...C.W.C...",
			"....WWW....",
			"CCWWWLWWWCC",
			"....WWW....",
			"...C.W.C...",
			"..C..C..C..",
			".....C.....",
		],
		"badge_napalm": [
			".....R.....",
			"....ROR....",
			"...ROOR..R.",
			"..ROOYOR.R.",
			".ROOYYYORR.",
			".ROYYWYYOR.",
			".ROYWWWYOR.",
			"..ROYWYOR..",
			"...RRRRR...",
		],
		"badge_leech": [
			".GG...GG...",
			"GGGG.GGGG..",
			"GWGGGGGGG..",
			"GGGGGGGGG..",
			".GGGGGGG...",
			"..GGGGG..R.",
			"...GGG..RRR",
			"....G...RRR",
			".........R.",
		],
		"badge_reflect": [
			"CC.........",
			"CLC......Y.",
			"CLC.......Y",
			"CLCWWWWWWWW",
			"CLC.......Y",
			"CLC......Y.",
			"CC.........",
			"...........",
			"...........",
		],
		"badge_last_stand": [
			"...YYYYY...",
			"..Y.....Y..",
			".Y..RRR..Y.",
			".Y..RWR..Y.",
			".Y..RRR..Y.",
			"..Y.....Y..",
			"...YYYYY...",
			"...........",
			"...........",
		],
		"badge_chrono": [
			"...CCCCC...",
			"..C.....C..",
			".C...W...C.",
			".C...W...C.",
			".C...WWW.C.",
			"..C.....C..",
			"...CCCCC...",
			"...........",
			"...........",
		],
		"badge_graze": [
			"RRWW.......",
			"...........",
			"..DDLLL....",
			"YOLLLLWWWW.",
			"..DDLLL....",
			"...........",
			".......WWRR",
			"...........",
			"...........",
		],
		"badge_aura": [
			"..P.PPP.P..",
			".P.......P.",
			"P..DDLL...P",
			"P.YLLLWW..P",
			"P..DDLL...P",
			".P.......P.",
			"..P.PPP.P..",
			"...........",
			"...........",
		],
		"badge_chain": [
			".O.O.......",
			"..OYO......",
			"OOYWYOO....",
			"..OYO..O.O.",
			".O.O.O..OYO",
			".....OOOYWY",
			"........OYO",
			".......O.O.",
			"...........",
		],
		"badge_orbital": [
			"....YWY....",
			"....YWY....",
			"....YWY....",
			"....YWY....",
			"...YWWWY...",
			"..O.YWY.O..",
			".O..RRR..O.",
			"...RRRRR...",
			"...........",
		],
		"badge_mines": [
			".....K.....",
			"..K.KKK.K..",
			"...KkRkK...",
			".KKkRWRkKK.",
			"...KkRkK...",
			"..K.KKK.K..",
			".....K.....",
			"...........",
			"...........",
		],
		"badge_salvage": [
			"..SS...SS..",
			".S.......S.",
			"S..YYYY...S",
			"S.YOOOOY..S",
			"..YOWWOY...",
			"...YYYY....",
			"...........",
			"...........",
			"...........",
		],
	}
	for key: String in badges.keys():
		var rows: Array = badges[key]
		_cache[key] = _make_tex(PackedStringArray(rows))

	_cache["bullet_mine"] = _make_tex(PackedStringArray([
		"....K....",
		"..K.K.K..",
		"...kRk...",
		"KKkRWRkKK",
		"...kRk...",
		"..K.K.K..",
		"....K....",
	]))

	_cache["bullet_shard"] = _make_tex(PackedStringArray([
		".OYY.",
		"OYWWW",
		".OYY.",
	]))

	# Draft card art (28x18) = the upgrade's badge drawn at 2x, centered.
	var card_badges: Dictionary = {
		"upg_homing": "badge_seek",
		"upg_shrapnel": "badge_shrapnel",
		"upg_crit": "badge_crit",
		"upg_berserk": "badge_berserk",
		"upg_execute": "badge_execute",
		"upg_ambush": "badge_ambush",
		"upg_cryo": "badge_cryo",
		"upg_napalm": "badge_napalm",
		"upg_leech": "badge_leech",
		"upg_reflect": "badge_reflect",
		"upg_last_stand": "badge_last_stand",
		"upg_chrono": "badge_chrono",
		"upg_graze": "badge_graze",
		"upg_aura": "badge_aura",
		"upg_chain": "badge_chain",
		"upg_orbital": "badge_orbital",
		"upg_mines": "badge_mines",
		"upg_salvage": "badge_salvage",
	}
	for upg_key: String in card_badges.keys():
		var badge_tex: ImageTexture = _cache[String(card_badges[upg_key])]
		_cache[upg_key] = _make_card_from_badge(badge_tex.get_image())


func _make_card_from_badge(badge: Image) -> ImageTexture:
	var card: Image = Image.create(28, 18, false, Image.FORMAT_RGBA8)
	var bw: int = badge.get_width()
	var bh: int = badge.get_height()
	var ox: int = (28 - bw * 2) / 2
	var oy: int = maxi(0, (18 - bh * 2) / 2)
	for y: int in range(bh):
		for x: int in range(bw):
			var col: Color = badge.get_pixel(x, y)
			if col.a <= 0.0:
				continue
			for dy: int in range(2):
				for dx: int in range(2):
					var px: int = ox + x * 2 + dx
					var py: int = oy + y * 2 + dy
					if px >= 0 and px < 28 and py >= 0 and py < 18:
						card.set_pixel(px, py, col)
	return ImageTexture.create_from_image(card)
