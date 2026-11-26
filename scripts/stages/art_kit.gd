extends RefCounted

# Image helpers for a module's build_art(), safe to run on a worker thread (they only touch
# the Images you pass in). Same look as the built-in stage enemies (scripts/enemy_art.gd):
# draw the sprite, then outline() adds the 1-px dark edge that keeps it readable on busy
# backgrounds. For big painted bosses, BossPainter's static helpers (_armor_plate, _glow_orb,
# _thick_line, _circle, _rect) also work on any Image.
#
#     const Kit = preload("res://scripts/stages/art_kit.gd")
#     var img: Image = Kit.rows(PackedStringArray(["..AA..", ".ABBA.", "..AA.."]), {"A": c1, "B": c2})
#     out["mystage_thing"] = Kit.outline(img)

const OUTLINE: Color = Color("#0a0c16")


static func blank(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


# A sprite from strings, one character per pixel ("." is transparent).
static func rows(lines: PackedStringArray, pal: Dictionary) -> Image:
	return EnemyArt._rows(lines, pal)


# The sprite with a 1-px dark outline around it (2 px larger each way).
static func outline(img: Image, col: Color = OUTLINE) -> Image:
	var sw: int = img.get_width()
	var sh: int = img.get_height()
	var out: Image = Image.create(sw + 2, sh + 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(0, 0, sw, sh), Vector2i(1, 1))
	for y: int in range(sh + 2):
		for x: int in range(sw + 2):
			if EnemyArt._solid(img, x - 1, y - 1):
				continue
			if EnemyArt._solid(img, x - 2, y - 1) or EnemyArt._solid(img, x, y - 1) or EnemyArt._solid(img, x - 1, y - 2) or EnemyArt._solid(img, x - 1, y):
				out.set_pixel(x, y, col)
	return out


static func put(img: Image, x: int, y: int, col: Color) -> void:
	EnemyArt._put(img, x, y, col)


static func rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	EnemyArt._rect(img, x, y, w, h, col)


static func disc(img: Image, cx: float, cy: float, r: float, col: Color) -> void:
	EnemyArt._disc(img, cx, cy, r, col)


static func line(img: Image, a: Vector2, b: Vector2, col: Color) -> void:
	EnemyArt._line(img, a, b, col)


# A filled ellipse shaded like a ball lit from the upper left: cols = [dark, mid, light, highlight].
static func ball(img: Image, cx: float, cy: float, rx: float, ry: float, cols: Array[Color]) -> void:
	EnemyArt._ball(img, cx, cy, rx, ry, cols)


static func flip_h(img: Image) -> Image:
	var out: Image = img.duplicate() as Image
	out.flip_x()
	return out
