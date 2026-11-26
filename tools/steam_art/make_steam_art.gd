extends SceneTree

# Preliminary Steam store & library art, generated from the game's own sprites.
#
# Each asset is laid out on a small "native" pixel canvas, scaled up by a whole number
# with nearest-neighbour filtering, then center-cropped to Steam's exact size, so every
# pixel stays crisp and the art matches the game.
#
# Usage, from the project folder (the output folder defaults to steam/art):
#   godot --headless --path . --script res://tools/steam_art/make_steam_art.gd -- steam/art
#
# Writes (sizes from partner.steamgames.com/doc/store/assets):
#   header_capsule_920x430.png      required, store header
#   small_capsule_462x174.png       required, store lists
#   main_capsule_1232x706.png       front-page feature
#   vertical_capsule_748x896.png    seasonal-sale feature
#   library_capsule_600x900.png     Steam library grid
#   library_hero_3840x1240.png      Steam library banner (no logo; Steam draws the logo on top)
#   library_logo_1280.png           transparent logo for the library banner (1280 wide)
#   app_icon_184x184.png / .jpg     community / app icon
#   shortcut_icon_256x256.png       desktop shortcut icon (Steam makes the .ico from it)

const BAYER4: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

# Chunky 12-px "STAR VIPER" logo letters (3-px stems, 2-px bars). X = filled.
const GLYPHS: Dictionary = {
	"S": [
		"..XXXXXXXX.",
		".XXXXXXXXXX",
		"XXX.....XXX",
		"XXX........",
		"XXXX.......",
		".XXXXXXXX..",
		"..XXXXXXXX.",
		".......XXXX",
		"........XXX",
		"XXX.....XXX",
		"XXXXXXXXXX.",
		".XXXXXXXX..",
	],
	"T": [
		"XXXXXXXXXXX",
		"XXXXXXXXXXX",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
		"....XXX....",
	],
	"A": [
		"...XXXXX...",
		"..XXXXXXX..",
		".XXX...XXX.",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXXXXXXXXXX",
		"XXXXXXXXXXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
	],
	"R": [
		"XXXXXXXXX..",
		"XXXXXXXXXX.",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXXXXXXXXX.",
		"XXXXXXXXX..",
		"XXX...XXX..",
		"XXX....XXX.",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
	],
	"V": [
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		".XXX...XXX.",
		".XXX...XXX.",
		"..XXX.XXX..",
		"..XXX.XXX..",
		"...XXXXX...",
		"....XXX....",
		".....X.....",
	],
	"I": [
		"XXXXXXX",
		"XXXXXXX",
		"..XXX..",
		"..XXX..",
		"..XXX..",
		"..XXX..",
		"..XXX..",
		"..XXX..",
		"..XXX..",
		"..XXX..",
		"XXXXXXX",
		"XXXXXXX",
	],
	"P": [
		"XXXXXXXXX..",
		"XXXXXXXXXX.",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXX.....XXX",
		"XXXXXXXXXX.",
		"XXXXXXXXX..",
		"XXX........",
		"XXX........",
		"XXX........",
		"XXX........",
		"XXX........",
	],
	"E": [
		"XXXXXXXXXX",
		"XXXXXXXXXX",
		"XXX.......",
		"XXX.......",
		"XXX.......",
		"XXXXXXXX..",
		"XXXXXXXX..",
		"XXX.......",
		"XXX.......",
		"XXX.......",
		"XXXXXXXXXX",
		"XXXXXXXXXX",
	],
}

# Chrome fill, one colour per letter row: cyan sky fading to a white horizon, then a
# sharp drop into magenta and down to sunset yellow (the game's own palette family).
const LOGO_FILL: Array[String] = [
	"#2a6cff", "#3a9cff", "#28e8ff", "#8cf4ff", "#dcffff", "#ffffff",
	"#d44cff", "#ff4ca8", "#ff6a7a", "#ff8a50", "#ffb43c", "#ffe854",
]
const LOGO_EXTRUDE: Array[String] = ["#4a1878", "#301050", "#1d0a36"]
const LOGO_OUTLINE: String = "#0b0f24"

var _pa: Node
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _out_dir: String = ""


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var rel: String = args[0] if args.size() > 0 else "steam/art"
	_out_dir = rel if rel.is_absolute_path() else ProjectSettings.globalize_path("res://" + rel)
	DirAccess.make_dir_recursive_absolute(_out_dir)

	_pa = load("res://scripts/autoload/pixel_art.gd").new()
	root.add_child(_pa)
	_pa.call("_build_all")

	# On the wide capsules the logo is layered on at a bigger pixel scale than the scene.
	_save(_with_logo(_finish(_header_scene(230, 108), 4, 920, 430), 5, 22, 18), "header_capsule_920x430.png")
	_save(_finish(_small_scene(154, 58), 3, 462, 174), "small_capsule_462x174.png")
	_save(_with_logo(_finish(_main_scene(308, 177), 4, 1232, 706), 6, 34, 30), "main_capsule_1232x706.png")
	_save(_with_logo(_finish(_tall_scene(187, 224, false), 4, 748, 896), 5, -1, 36), "vertical_capsule_748x896.png")
	_save(_finish(_tall_scene(150, 225, true), 4, 600, 900), "library_capsule_600x900.png")
	_save(_finish(_hero_scene(480, 155), 8, 3840, 1240), "library_hero_3840x1240.png")
	_save(_pad_to_width(_upscale(_logo(true, 2), 10), 1280), "library_logo_1280.png")
	var icon: Image = _icon_scene(32, 32)
	_save(_finish(icon, 8, 256, 256), "shortcut_icon_256x256.png")
	var icon184: Image = _finish(icon, 6, 184, 184)
	_save(icon184, "app_icon_184x184.png")
	icon184.convert(Image.FORMAT_RGB8)
	icon184.save_jpg(_out_dir.path_join("app_icon_184x184.jpg"), 0.95)
	print("Steam art written to ", _out_dir)
	quit()


# =========================================================================================
# SCENES (native canvases)
# =========================================================================================

func _header_scene(w: int, h: int) -> Image:
	var c: Image = _space(w, h, 11)
	_stars(c, 12, w * h / 26)
	_planet(c, 30, h + 34, 58, 5)
	_speed_lines(c, 13, 14)
	_blit(c, _img("boss_cyber_0"), w - 96, -26)
	_enemy_fire(c, w - 70, 58, 8, 21)
	_blit(c, _img("cruiser_cyber"), 128, 74)
	_blit(c, _img("scout_cyber"), 112, 52)
	_boom(c, 121, 58, 7)
	_hero_group(c, 28, 60)
	return c


func _small_scene(w: int, h: int) -> Image:
	var c: Image = _space(w, h, 21)
	_stars(c, 22, w * h / 22)
	_planet(c, w - 12, h + 22, 34, 3)
	_speed_lines(c, 23, 8)
	var logo: Image = _logo(false, 0)
	_blit(c, logo, (w - logo.get_width()) / 2, 4)
	_hero_group(c, 6, 34, 3, false)
	_blit(c, _img("scout_cyber"), w - 30, 38)
	_boom(c, w - 40, 44, 4)
	return c


func _main_scene(w: int, h: int) -> Image:
	var c: Image = _space(w, h, 31)
	_stars(c, 32, w * h / 26)
	_planet(c, 46, h + 40, 80, 5)
	_speed_lines(c, 33, 20)
	_blit(c, _img("boss_cyber_0"), w - 124, h / 2 - 87)
	_enemy_fire(c, w - 98, h / 2, 10, 34)
	_blit(c, _img("cruiser_cyber"), 176, 118)
	_blit(c, _img("swooper_cyber"), 150, 40)
	_blit(c, _img("sniper_cyber"), 150, 62)
	_blit(c, _img("scout_cyber"), 214, 140)
	_boom(c, 160, 70, 8)
	_boom(c, 222, 147, 5)
	_hero_group(c, 40, 96)
	_pickups(c, 96, 132, 35)
	return c


func _tall_scene(w: int, h: int, with_logo: bool) -> Image:
	var c: Image = _space(w, h, 41)
	_stars(c, 42, w * h / 24)
	_planet(c, 18, h + 30, 70, 5)
	_speed_lines(c, 43, 16)
	var boss: Image = _img("boss_cyber_0")
	_blit(c, boss, w - boss.get_width() + 10, h / 2 - boss.get_height() / 2 + 6)
	_enemy_fire(c, w - 76, h / 2 + 8, 8, 44)
	_blit(c, _img("swooper_cyber"), 18, h / 2 - 28)
	_boom(c, 26, h / 2 - 22, 5)
	_hero_group(c, 10, h - 62)
	if with_logo:
		var logo: Image = _logo(false, 0)
		_blit(c, logo, (w - logo.get_width()) / 2, 10)
	return c


func _hero_scene(w: int, h: int) -> Image:
	var c: Image = _space(w, h, 51)
	_stars(c, 52, w * h / 26)
	_planet(c, 120, h + 70, 110, 5)
	_planet_small(c, 300, 30, 9)
	_speed_lines(c, 53, 26)
	_blit(c, _img("boss_cyber_0"), w - 132, h / 2 - 87)
	_enemy_fire(c, w - 106, h / 2, 12, 61)
	_blit(c, _img("cruiser_cyber"), 300, 96)
	_blit(c, _img("swooper_cyber"), 330, 26)
	_blit(c, _img("sniper_cyber"), 268, 52)
	_blit(c, _img("scout_cyber"), 352, 120)
	_blit(c, _img("scout_cyber"), 240, 118)
	_boom(c, 276, 59, 8)
	_boom(c, 246, 125, 5)
	_hero_group(c, 150, 72)
	_blit(c, _img("ship_neko_0"), 108, 40)
	_blit(c, _img("ship_phantom_0"), 104, 110)
	_lasers(c, 136, 44, 3)
	_lasers(c, 132, 114, 3)
	_pickups(c, 200, 30, 62)
	return c


func _icon_scene(w: int, h: int) -> Image:
	var c: Image = _space(w, h, 61)
	_stars(c, 62, 22)
	_planet(c, 4, h + 6, 18, 3)
	var ship: Image = _img("player_flame_2")
	_blit(c, ship, (w - ship.get_width()) / 2 + 1, (h - ship.get_height()) / 2)
	return c


# The player's Viper with its engine flame, two option orbs and a volley of lasers.
func _hero_group(c: Image, x: int, y: int, laser_count: int = 4, orbs: bool = true) -> void:
	_blit(c, _img("player_flame_2"), x, y)
	_lasers(c, x + 28, y + 6, laser_count)
	if orbs:
		_blit(c, _img("option_orb"), x + 4, y - 15)
		_blit(c, _img("option_orb"), x + 4, y + 19)
		_lasers(c, x + 16, y - 11, maxi(1, laser_count - 1))
		_lasers(c, x + 16, y + 23, maxi(1, laser_count - 1))


func _lasers(c: Image, x: int, y: int, count: int) -> void:
	var laser: Image = _img("bullet_laser")
	for i: int in range(count):
		_blit(c, laser, x + i * 24, y)


func _pickups(c: Image, x: int, y: int, seed_val: int) -> void:
	_rng.seed = seed_val
	var keys: Array[String] = ["pickup_xp_big", "pickup_xp_med", "pickup_xp_small", "pickup_xp_med"]
	for i: int in range(keys.size()):
		_blit(c, _img(keys[i]), x + i * 13 + _rng.randi_range(-2, 2), y + _rng.randi_range(-5, 5))


# A fan of enemy bullets (red danger halo + pink core, as in the game) heading left from (x, y).
func _enemy_fire(c: Image, x: int, y: int, count: int, seed_val: int) -> void:
	_rng.seed = seed_val
	var glow: Image = _img("bullet_enemy_glow_0")
	var core: Image = _img("bullet_enemy_pink")
	for i: int in range(count):
		var ang: float = PI + _rng.randf_range(-0.6, 0.6)
		var dist: float = 12.0 + float(i) * 58.0 / float(maxi(1, count - 1)) + _rng.randf_range(-4.0, 4.0)
		var bx: int = x + int(cos(ang) * dist)
		var by: int = y + int(sin(ang) * dist)
		_blit(c, glow, bx - 8, by - 8)
		_blit(c, core, bx - 3, by - 3)


# =========================================================================================
# PAINTING HELPERS
# =========================================================================================

func _bayer(x: int, y: int) -> float:
	return (float(BAYER4[(y & 3) * 4 + (x & 3)]) + 0.5) / 16.0


# Deep-space backdrop: a dithered navy-to-violet gradient with dithered nebula clouds.
func _space(w: int, h: int, seed_val: int) -> Image:
	var stops: Array[Color] = [Color("#04060f"), Color("#080c22"), Color("#120f36"), Color("#221246")]
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var neb: FastNoiseLite = FastNoiseLite.new()
	neb.seed = seed_val
	neb.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	neb.fractal_type = FastNoiseLite.FRACTAL_FBM
	neb.fractal_octaves = 4
	neb.frequency = 0.022
	var wisp: FastNoiseLite = FastNoiseLite.new()
	wisp.seed = seed_val + 101
	wisp.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	wisp.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	wisp.fractal_octaves = 3
	wisp.frequency = 0.03
	var neb_cols: Array[Color] = [Color("#1c1450"), Color("#2e1966"), Color("#4a2284")]
	var wisp_cols: Array[Color] = [Color("#0e2a58"), Color("#15467a")]
	for y: int in range(h):
		for x: int in range(w):
			var b: float = _bayer(x, y)
			var t: float = float(y) / float(maxi(1, h - 1))
			var f: float = t * float(stops.size() - 1)
			var i0: int = mini(int(f), stops.size() - 2)
			var col: Color = stops[i0 + 1] if (f - float(i0)) > b else stops[i0]
			# Nebula concentrated along a diagonal band across the canvas.
			var band: float = clampf(1.0 - absf(t - (0.75 - 0.5 * float(x) / float(w))) * 2.4, 0.0, 1.0)
			var d: float = (b - 0.5) * 0.07
			var n: float = (neb.get_noise_2d(float(x), float(y)) * 0.5 + 0.5) * (0.55 + 0.45 * band)
			var wv: float = (wisp.get_noise_2d(float(x), float(y)) * 0.5 + 0.5) * band
			if wv + d > 0.80:
				col = wisp_cols[1] if wv + d > 0.88 else wisp_cols[0]
			if n + d > 0.50:
				col = neb_cols[0]
			if n + d > 0.58:
				col = neb_cols[1]
			if n + d > 0.66:
				col = neb_cols[2]
			img.set_pixel(x, y, col)
	return img


func _stars(img: Image, seed_val: int, count: int) -> void:
	_rng.seed = seed_val
	var w: int = img.get_width()
	var h: int = img.get_height()
	for i: int in range(count):
		var x: int = _rng.randi_range(0, w - 1)
		var y: int = _rng.randi_range(0, h - 1)
		var r: float = _rng.randf()
		if r < 0.62:
			img.set_pixel(x, y, Color("#3b5284"))
		elif r < 0.90:
			img.set_pixel(x, y, Color("#8ca6d8"))
		elif r < 0.975:
			img.set_pixel(x, y, Color("#ffffff"))
		else:
			# Four-point sparkle.
			img.set_pixel(x, y, Color("#ffffff"))
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_px(img, x + o.x, y + o.y, Color("#a8f4ff"))
				_px(img, x + o.x * 2, y + o.y * 2, Color("#3b5284"))


func _speed_lines(img: Image, seed_val: int, count: int) -> void:
	_rng.seed = seed_val
	var w: int = img.get_width()
	var h: int = img.get_height()
	for i: int in range(count):
		var y: int = _rng.randi_range(0, h - 1)
		var x0: int = _rng.randi_range(-10, w - 10)
		var length: int = _rng.randi_range(6, 26)
		for k: int in range(length):
			var col: Color = Color("#3b5284") if k > length / 3 else Color("#1d294a")
			_px(img, x0 + k, y, col)


# A banded gas giant lit from the upper left, with a thin atmosphere rim.
func _planet(img: Image, cx: int, cy: int, r: int, seed_val: int) -> void:
	var cols: Array[Color] = [Color("#140c2c"), Color("#2a1450"), Color("#4a2070"), Color("#7a2a8c"), Color("#c03c9a"), Color("#ff7aa8")]
	var bands: FastNoiseLite = FastNoiseLite.new()
	bands.seed = seed_val
	bands.frequency = 0.06
	var light: Vector3 = Vector3(-0.62, -0.55, 0.56).normalized()
	var rim: float = 1.0 + 1.6 / float(r)
	for y: int in range(cy - r - 2, cy + r + 3):
		for x: int in range(cx - r - 2, cx + r + 3):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx: float = float(x - cx) / float(r)
			var dy: float = float(y - cy) / float(r)
			var d2: float = dx * dx + dy * dy
			if d2 > 1.0:
				if d2 < rim * rim and (dx * light.x + dy * light.y) > -0.1 and _bayer(x, y) < 0.75:
					img.set_pixel(x, y, Color("#28e8ff") if (dx * light.x + dy * light.y) > 0.45 else Color("#0088cc"))
				continue
			var nz: float = sqrt(1.0 - d2)
			var lum: float = Vector3(dx, dy, nz).dot(light)
			var wobble: float = bands.get_noise_2d(float(x) * 0.6, float(y) * 2.2)
			var stripe: float = sin((dy * 9.0 + wobble * 1.4)) * 0.11
			var v: float = clampf(lum * 0.62 + 0.38 + stripe + (_bayer(x, y) - 0.5) * 0.16, 0.0, 0.999)
			img.set_pixel(x, y, cols[int(v * float(cols.size()))])


func _planet_small(img: Image, cx: int, cy: int, r: int) -> void:
	var cols: Array[Color] = [Color("#0d1a33"), Color("#16406a"), Color("#1f78a8"), Color("#5ad4f0")]
	var light: Vector3 = Vector3(-0.62, -0.55, 0.56).normalized()
	for y: int in range(cy - r, cy + r + 1):
		for x: int in range(cx - r, cx + r + 1):
			var dx: float = float(x - cx) / float(r)
			var dy: float = float(y - cy) / float(r)
			var d2: float = dx * dx + dy * dy
			if d2 > 1.0:
				continue
			var lum: float = Vector3(dx, dy, sqrt(1.0 - d2)).dot(light)
			var v: float = clampf(lum * 0.6 + 0.4 + (_bayer(x, y) - 0.5) * 0.2, 0.0, 0.999)
			_px(img, x, y, cols[int(v * float(cols.size()))])


# Pixel explosion: white core, yellow and orange rings, a dithered red edge and sparks.
func _boom(img: Image, cx: int, cy: int, r: int) -> void:
	for y: int in range(cy - r - 1, cy + r + 2):
		for x: int in range(cx - r - 1, cx + r + 2):
			var d: float = Vector2(x - cx, y - cy).length() / float(r)
			var b: float = _bayer(x, y)
			if d < 0.35:
				_px(img, x, y, Color("#ffffff"))
			elif d < 0.6:
				_px(img, x, y, Color("#ffe854"))
			elif d < 0.85:
				_px(img, x, y, Color("#ff9624"))
			elif d < 1.05 and b < 0.6:
				_px(img, x, y, Color("#f03c4e"))
			elif d < 1.2 and b < 0.18:
				_px(img, x, y, Color("#941c2f"))
	_rng.seed = cx * 31 + cy
	for i: int in range(r + 3):
		var a: float = _rng.randf() * TAU
		var dist: float = float(r) * _rng.randf_range(1.3, 2.0)
		_px(img, cx + int(cos(a) * dist), cy + int(sin(a) * dist), Color("#ffe854") if i % 2 == 0 else Color("#ff9624"))


# Builds the "STAR VIPER" logo at 1x on a transparent canvas: chrome-gradient italic
# letters, a 3-px purple extrusion, a dark outline and a couple of glints.
# `pad` adds transparent margin on every side.
func _logo(underline: bool, pad: int) -> Image:
	var text: String = "STAR VIPER"
	var glyph_h: int = 12
	var slant: int = 3
	var extrude: int = LOGO_EXTRUDE.size()
	var text_w: int = 0
	for i: int in range(text.length()):
		var ch: String = text.substr(i, 1)
		text_w += 6 if ch == " " else (String(GLYPHS[ch][0]).length() + 2)
	text_w -= 2
	var m: int = 1 + pad # outline + caller padding
	var under_h: int = 4 if underline else 0
	var w: int = text_w + slant + m * 2
	var h: int = glyph_h + extrude + under_h + m * 2
	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	var pen: int = m
	for i: int in range(text.length()):
		var ch: String = text.substr(i, 1)
		if ch == " ":
			pen += 6
			continue
		var rows: Array = GLYPHS[ch]
		for ry: int in range(glyph_h):
			var row: String = rows[ry]
			var shear: int = (glyph_h - 1 - ry) / 4 # italic: upper rows lean right
			for rx: int in range(row.length()):
				if row.substr(rx, 1) == "X":
					mask[(m + ry) * w + pen + rx + shear] = 1
		pen += String(rows[0]).length() + 2

	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Extrusion (drawn first, from the deepest layer up).
	for k: int in range(extrude, 0, -1):
		var ecol: Color = Color(LOGO_EXTRUDE[k - 1])
		for y: int in range(h - k):
			for x: int in range(w):
				if mask[y * w + x] == 1:
					img.set_pixel(x, y + k, ecol)
	# Chrome fill.
	for y: int in range(h):
		for x: int in range(w):
			if mask[y * w + x] == 1:
				img.set_pixel(x, y, Color(LOGO_FILL[clampi(y - m, 0, glyph_h - 1)]))
	# Laser underline: fades in from the left, bright bolt head on the right.
	if underline:
		var uy: int = m + glyph_h + extrude + 2
		for x: int in range(m + 2, m + text_w + slant - 1):
			var t: float = float(x - m) / float(text_w)
			var ucol: Color = Color("#0088cc") if t < 0.45 else (Color("#28e8ff") if t < 0.85 else Color("#ffffff"))
			if t > 0.2 or _bayer(x, uy) < t * 5.0:
				img.set_pixel(x, uy, ucol)
	# Dark outline around everything drawn so far.
	var outline: Color = Color(LOGO_OUTLINE)
	var src: Image = img.duplicate() as Image
	for y: int in range(h):
		for x: int in range(w):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				var nx: int = x + o.x
				var ny: int = y + o.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.0:
					img.set_pixel(x, y, outline)
					break
	# Glints on the top-left of the S and the top of the I.
	_glint(img, m + 3, m + 1)
	_glint(img, m + _letter_x(text, 6) + 4, m)
	return img


# x offset of letter `idx` in `text` within the logo (before the outline margin).
func _letter_x(text: String, idx: int) -> int:
	var x: int = 0
	for i: int in range(idx):
		var ch: String = text.substr(i, 1)
		x += 6 if ch == " " else (String(GLYPHS[ch][0]).length() + 2)
	return x


func _glint(img: Image, x: int, y: int) -> void:
	_px(img, x, y, Color("#ffffff"))
	for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		_px(img, x + o.x, y + o.y, Color("#ffffff"))
		_px(img, x + o.x * 2, y + o.y * 2, Color("#dcffff"))


# =========================================================================================
# IMAGE UTILITIES
# =========================================================================================

func _img(key: String) -> Image:
	var tex: Texture2D = _pa.call("tex", key)
	var im: Image = tex.get_image()
	im.convert(Image.FORMAT_RGBA8)
	return im


func _blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))


func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)


func _upscale(src: Image, s: int) -> Image:
	var out: Image = src.duplicate() as Image
	out.resize(src.get_width() * s, src.get_height() * s, Image.INTERPOLATE_NEAREST)
	return out


# Center `src` on a transparent canvas exactly `w` pixels wide.
func _pad_to_width(src: Image, w: int) -> Image:
	var out: Image = Image.create(w, src.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i((w - src.get_width()) / 2, 0))
	return out


# Scale a native canvas by `s` and center-crop it to exactly w x h.
func _finish(native: Image, s: int, w: int, h: int) -> Image:
	var big: Image = _upscale(native, s)
	var ox: int = (big.get_width() - w) / 2
	var oy: int = (big.get_height() - h) / 2
	return big.get_region(Rect2i(ox, oy, w, h))


# Draw the logo onto a finished (full-size) image at its own pixel scale.
# x = -1 centers it horizontally.
func _with_logo(img: Image, logo_scale: int, x: int, y: int) -> Image:
	var logo: Image = _upscale(_logo(false, 0), logo_scale)
	var lx: int = (img.get_width() - logo.get_width()) / 2 if x < 0 else x
	_blit(img, logo, lx, y)
	return img


func _save(img: Image, file_name: String) -> void:
	var path: String = _out_dir.path_join(file_name)
	var err: Error = img.save_png(path)
	if err != OK:
		push_error("Could not write %s (error %d)" % [path, err])
	else:
		print("  ", file_name, "  ", img.get_width(), "x", img.get_height())
