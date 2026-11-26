extends RefCounted

# TEMPORARY EXAMPLE STAGE: sprites. build() runs on a worker thread, so it only paints Images
# (no textures, no PixelArt, no nodes). Every key starts with the stage id (or "boss_<id>").
# Enemies face left, toward the player; Kit.outline() adds the dark edge the built-in stage
# enemies have.

const Kit = preload("res://scripts/stages/art_kit.gd")

const VIOLET: Array[Color] = [Color("#2a2060"), Color("#4b3aa8"), Color("#8a7cff"), Color("#d6d0ff")]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}

	# Orb (2 frames: eye dim / lit) and the smaller copy it splits into.
	for f: int in range(2):
		var orb: Image = Kit.blank(13, 13)
		Kit.ball(orb, 6.5, 6.5, 6.0, 6.0, VIOLET)
		Kit.disc(orb, 4.5, 6.5, 2.2, Color("#160c2c"))
		Kit.disc(orb, 4.5, 6.5, 1.2, Color("#ff4c68") if f == 0 else Color("#ffe854"))
		out[id + "_orb_%d" % f] = Kit.outline(orb)
	var small: Image = Kit.blank(9, 9)
	Kit.ball(small, 4.5, 4.5, 4.0, 4.0, VIOLET)
	Kit.disc(small, 3.0, 4.5, 1.2, Color("#ff4c68"))
	out[id + "_orb_small"] = Kit.outline(small)

	# Lancer (frame 0 cruising, frame 1 dashing with a long flame).
	var pal: Dictionary = {
		"D": Color("#22264a"), "M": Color("#4a5490"), "L": Color("#8c9ad8"), "H": Color("#dce4ff"),
		"C": Color("#28e8ff"), "R": Color("#ff5a38"), "Y": Color("#ffe854"), "W": Color("#ffffff"),
	}
	var body: PackedStringArray = PackedStringArray([
		"......DDDD..........",
		"...DDMMMMMMDD.......",
		"DDMMLLLLHHMMMMDDR...",
		"MMLLHHCCHHLLMMMMRY..",
		"DDMMLLLLHHMMMMDDR...",
		"...DDMMMMMMDD.......",
		"......DDDD..........",
	])
	out[id + "_lancer_0"] = Kit.outline(Kit.rows(body, pal))
	var dash: PackedStringArray = body.duplicate()
	dash[2] = "DDMMLLLLHHMMMMDDRRYY"
	dash[3] = "MMLLHHCCHHLLMMMMRYWW"
	dash[4] = "DDMMLLLLHHMMMMDDRRYY"
	out[id + "_lancer_1"] = Kit.outline(Kit.rows(dash, pal))

	# The stage's own enemy shot (StageData "bullet_b"): a small violet glow.
	var shot: Image = Kit.blank(7, 7)
	Kit.disc(shot, 3.5, 3.5, 3.5, Color(0.55, 0.45, 1.0, 0.45))
	Kit.disc(shot, 3.5, 3.5, 2.4, Color("#a898ff"))
	Kit.disc(shot, 3.5, 3.5, 1.2, Color.WHITE)
	out[id + "_shot"] = shot

	# The boss: frames _0 and _1 idle, _2 attacking (GameEnemy picks the frame).
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = _paint_boss(f2)
	return out


# "TEMPLATE CORE": an armoured pillar with a big lens and two arms that open to fire.
# BossPainter's static helpers paint on any Image.
static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(96, 152)
	var base: Color = Color("#4b3aa8")
	var hi: Color = Color("#a898ff")
	var sh: Color = Color("#231a55")
	BossPainter._armor_plate(img, 44, 6, 48, 140, sh, base, Color("#120c2e"))
	BossPainter._armor_plate(img, 30, 26, 52, 100, base, hi, sh)
	var spread: int = 0 if frame == 0 else (3 if frame == 1 else 9)
	for arm_y: int in [20 - spread, 112 + spread]:
		BossPainter._armor_plate(img, 8, arm_y, 40, 20, Color("#5a4cc0"), Color("#d6d0ff"), sh)
		BossPainter._rect(img, 2, arm_y + 7, 10, 6, Color("#dce4ff"))
		if frame == 2:
			BossPainter._glow_orb(img, 4, arm_y + 10, 4, Color("#7a3cff"), Color("#d6d0ff"), Color.WHITE)
	BossPainter._armor_plate(img, 18, 56, 44, 40, Color("#120c2e"), sh, Color("#08061a"))
	var lens_r: int = 14 if frame == 0 else (15 if frame == 1 else 17)
	BossPainter._glow_orb(img, 38, 76, lens_r, Color("#5a2cc8"), Color("#a898ff"), Color.WHITE)
	BossPainter._circle(img, 34, 76, 4, Color("#160c2c"))
	BossPainter._circle(img, 34, 76, 2, Color("#ff4c68") if frame < 2 else Color("#ffe854"))
	return img
