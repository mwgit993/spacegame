extends RefCounted

# SOLAR CORONA sprites. build() runs on a worker thread, so it only paints Images. Every key starts
# with the stage id ("corona_...", "boss_corona_..."). Enemies face left, toward the player.
# Palette: living plasma (white-yellow cores fading to orange and blood red), molten crust with
# glowing seams, and cool steel-blue heat shields. The shots are cool violet / blue-white so they
# read against the warm sky.

const Kit = preload("res://scripts/stages/art_kit.gd")

const FLAME: Array[Color] = [Color("#8a1808"), Color("#e04414"), Color("#ff9a2c"), Color("#ffe48a"), Color("#ffffff")]
const CRUST: Array[Color] = [Color("#240604"), Color("#4a0e06"), Color("#6e1a0a"), Color("#9a2c10")]
const SEAM: Color = Color("#ffb040")
const SEAM_HOT: Color = Color("#fff0b0")
const SHIELD: Array[Color] = [Color("#1c1e2e"), Color("#3a3e5a"), Color("#6a70a0"), Color("#c0c8f0")]
const COOL: Array[Color] = [Color("#3a2c9a"), Color("#6a7cff"), Color("#b8d8ff"), Color("#ffffff")]


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(2):
		out[id + "_wisp_%d" % f] = Kit.outline(_wisp(f, false))
		out[id + "_binary_%d" % f] = Kit.outline(_binary(f))
	out[id + "_wisp_flare"] = Kit.outline(_wisp(0, true))
	out[id + "_serpent_head"] = Kit.outline(_serpent_head(false))
	out[id + "_serpent_bite"] = Kit.outline(_serpent_head(true))
	out[id + "_serpent_body"] = Kit.outline(_serpent_body(5.0))
	out[id + "_serpent_tail"] = Kit.outline(_serpent_body(3.2))
	out[id + "_plasma"] = _plasma_shot()
	out[id + "_spark"] = _spark_shot()
	for f2: int in range(3):
		out["boss_%s_%d" % [id, f2]] = _paint_boss(f2)
	return out


# --- Plasma wisp: a white-hot head trailing three flickering flame tongues -----------------------

static func _wisp(frame: int, flare: bool) -> Image:
	var img: Image = Kit.blank(17, 13)
	var hr: float = 5.4 if flare else 4.4
	# Flame tongues to the right (it drifts left), waving between frames.
	for t: int in range(3):
		var ty: float = 6.5 + float(t - 1) * 2.6
		var wav: float = (1.0 if (frame + t) % 2 == 0 else -1.0) * 0.8
		var length: float = 10.0 - absf(float(t - 1)) * 3.0 + (1.5 if flare else 0.0)
		for i: int in range(int(length)):
			var k: float = float(i) / length
			var x: float = 7.0 + float(i)
			var y: float = ty + sin(k * 3.0 + float(t)) * wav * k * 2.0
			var r: float = (1.0 - k) * 1.8 + 0.4
			var c: Color = FLAME[clampi(3 - int(k * 4.0), 0, 3)]
			Kit.disc(img, x, y, r, c)
	# The head: rings of heat around a white core (blue-white while flaring: it's about to fire).
	var cx: float = 5.5
	var cy: float = 6.5
	Kit.disc(img, cx, cy, hr, FLAME[1])
	Kit.disc(img, cx - 0.3, cy - 0.2, hr * 0.78, FLAME[2])
	Kit.disc(img, cx - 0.5, cy - 0.4, hr * 0.52, FLAME[3])
	if flare:
		Kit.disc(img, cx - 0.6, cy - 0.4, hr * 0.38, COOL[2])
		Kit.disc(img, cx - 0.8, cy - 0.6, 1.2, COOL[3])
	else:
		Kit.disc(img, cx - 0.8, cy - 0.6, 1.3, FLAME[4])
	# Two dark "eyes" give it a face.
	Kit.put(img, int(cx) - 2, int(cy) - 1, CRUST[1])
	Kit.put(img, int(cx) - 2, int(cy) + 1, CRUST[1])
	return img


# --- Flare serpent: a molten-crusted head and body with glowing seams -----------------------------

static func _serpent_head(bite: bool) -> Image:
	var img: Image = Kit.blank(20, 14)
	# Skull: an elongated crust ball, snout to the left.
	Kit.ball(img, 11.0, 7.0, 8.0, 5.5, CRUST)
	Kit.ball(img, 5.0, 7.5 if not bite else 6.0, 5.0, 3.2, CRUST)
	# Glowing seams across the crust.
	Kit.line(img, Vector2(9, 3), Vector2(12, 6), SEAM)
	Kit.line(img, Vector2(12, 6), Vector2(16, 5), SEAM)
	Kit.line(img, Vector2(13, 9), Vector2(17, 10), SEAM)
	Kit.put(img, 12, 6, SEAM_HOT)
	# Horn crest of flame on the back of the head.
	for i: int in range(4):
		Kit.line(img, Vector2(12 + i * 2, 2), Vector2(14 + i * 2, 0), FLAME[2 if i % 2 == 0 else 1])
	# Eye: cool blue-white.
	Kit.disc(img, 8.0, 5.0, 1.5, COOL[2])
	Kit.put(img, 7, 5, COOL[3])
	# Jaw: open on the bite frame, with fire inside.
	if bite:
		Kit.rect(img, 1, 8, 9, 3, FLAME[1])
		Kit.rect(img, 2, 9, 7, 1, FLAME[3])
		Kit.ball(img, 5.0, 11.0, 4.5, 1.8, CRUST)
		for tx: int in range(2, 9, 2):
			Kit.put(img, tx, 8, SEAM_HOT)
	else:
		Kit.line(img, Vector2(1, 9), Vector2(8, 9), CRUST[0])
		Kit.put(img, 3, 9, SEAM)
	return img


static func _serpent_body(r: float) -> Image:
	var s: int = int(ceilf(r * 2.0)) + 1
	var img: Image = Kit.blank(s, s)
	var c: float = float(s) * 0.5
	Kit.ball(img, c, c, r, r, CRUST)
	# A ring of seam glow and a hot core showing through.
	Kit.disc(img, c + 0.5, c + 0.5, r * 0.45, SEAM)
	Kit.disc(img, c + 0.3, c + 0.3, r * 0.22, SEAM_HOT)
	Kit.put(img, int(c - r * 0.5), int(c), SEAM)
	return img


# --- Binary drone: a heat-shield sphere with a blue-white plasma band (red-hot when enraged) ------

static func _binary(frame: int) -> Image:
	var img: Image = Kit.blank(16, 16)
	var rage: bool = frame == 1
	var shell: Array[Color] = SHIELD
	var band: Array[Color] = COOL
	if rage:
		shell = [Color("#2e0e0a"), Color("#6a1e10"), Color("#a83818"), Color("#ffb070")]
		band = [FLAME[1], FLAME[2], FLAME[3], FLAME[4]]
	Kit.ball(img, 8.0, 8.0, 7.0, 7.0, shell)
	# Equator band of plasma.
	Kit.rect(img, 1, 7, 14, 2, band[1])
	Kit.rect(img, 2, 7, 12, 1, band[2])
	Kit.rect(img, 5, 7, 5, 1, band[3])
	# Vents on the shell.
	for vx: int in [4, 8, 12]:
		Kit.put(img, vx, 4, SHIELD[0] if not rage else SEAM)
		Kit.put(img, vx, 11, SHIELD[0] if not rage else SEAM)
	# The core eye at the front.
	Kit.disc(img, 3.5, 8.0, 2.0, band[1])
	Kit.put(img, 3, 7, band[3])
	if rage:
		Kit.line(img, Vector2(9, 2), Vector2(11, 5), SEAM_HOT)
		Kit.line(img, Vector2(6, 13), Vector2(9, 11), SEAM_HOT)
	return img


# --- Shots -----------------------------------------------------------------------------------------

# A violet / blue-white plasma ball (StageData "bullet_b").
static func _plasma_shot() -> Image:
	var img: Image = Kit.blank(8, 8)
	Kit.disc(img, 4.0, 4.0, 3.9, Color(0.42, 0.3, 1.0, 0.55))
	Kit.disc(img, 4.0, 4.0, 3.0, COOL[1])
	Kit.disc(img, 4.0, 4.0, 2.0, COOL[2])
	Kit.disc(img, 3.7, 3.7, 1.1, COOL[3])
	return img


# The wisp's short-lived spark (pale lavender, so it can't be mistaken for a background ember).
static func _spark_shot() -> Image:
	var img: Image = Kit.blank(6, 6)
	Kit.disc(img, 3.0, 3.0, 2.9, Color(0.75, 0.6, 1.0, 0.55))
	Kit.disc(img, 3.0, 3.0, 1.8, Color("#d8ccff"))
	Kit.put(img, 2, 2, Color.WHITE)
	Kit.put(img, 3, 3, Color.WHITE)
	return img


# --- Boss: SUNFORGE CITADEL --------------------------------------------------------------------------
# A solar-collector fortress: an armoured citadel behind a great focusing lens, ringed by six mirror
# petals. Frame 0 petals folded, frame 1 half open, frame 2 (attack) fanned wide with the lens
# white-hot. Glowing radiator fins and gold trim on the hull.

const BW: int = 124
const BH: int = 150
const LENS: Vector2 = Vector2(38.0, 75.0)


static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BW, BH)
	var gold: Color = Color("#c8901e")
	var gold_hi: Color = Color("#ffe07a")
	var gold_sh: Color = Color("#6a4410")
	var hull: Color = Color("#3a2c3e")
	var hull_hi: Color = Color("#7a6a88")
	var hull_sh: Color = Color("#1a1220")
	var hot: bool = frame == 2

	# Radiator fins on the back (right): a stack of plates with heat glowing between them.
	for i: int in range(9):
		var fy: int = 22 + i * 12
		var glow: Color = Color("#ff6a1a") if (i + frame) % 3 != 0 else Color("#ffb040")
		BossPainter._rect(img, 92, fy + 7, 30, 3, glow.darkened(0.2) if not hot else glow)
		BossPainter._armor_plate(img, 90, fy, 34, 7, hull, hull_hi, hull_sh, false)
	# Citadel hull: stacked armour with gold trim.
	BossPainter._armor_plate(img, 58, 18, 40, 114, hull_sh, hull, Color("#0c0810"))
	BossPainter._armor_plate(img, 62, 30, 32, 90, hull, hull_hi, hull_sh)
	for ty: int in [30, 74, 118]:
		BossPainter._rect(img, 62, ty, 32, 2, gold)
		BossPainter._rect(img, 62, ty, 32, 1, gold_hi)
	# Spires top and bottom with collector panels.
	for sp: Vector2i in [Vector2i(70, 2), Vector2i(70, 124)]:
		BossPainter._armor_plate(img, sp.x, sp.y, 16, 22, hull, hull_hi, hull_sh)
		BossPainter._rect(img, sp.x + 3, sp.y + 4, 10, 14, Color("#1a2a5a"))
		for gy: int in range(sp.y + 5, sp.y + 18, 3):
			BossPainter._rect(img, sp.x + 4, gy, 8, 1, Color("#4a6ab8"))
		BossPainter._glow_orb(img, sp.x + 8, sp.y + (0 if sp.y < 50 else 22), 2, Color("#6e1024"), Color("#ffb040") if hot else Color("#ff6a1a"), Color.WHITE)
	# Solar-cell panels on the hull face, between the gold bands.
	for py: int in [34, 78]:
		BossPainter._rect(img, 65, py, 13, 36, Color("#10183a"))
		for gy: int in range(py + 1, py + 36, 4):
			for gx: int in range(66, 77, 4):
				BossPainter._rect(img, gx, gy, 3, 3, Color("#2a4890") if (gx + gy) % 8 != 0 else Color("#4a78c8"))
		BossPainter._px(img, 67, py + 2, Color("#c8e0ff"))
	# Hull windows: a column of furnace slits.
	for wy: int in range(36, 116, 8):
		BossPainter._rect(img, 81, wy, 8, 3, Color("#120a08"))
		BossPainter._rect(img, 82, wy + 1, 6, 1, Color("#ffd27a") if (wy / 8 + frame) % 2 == 0 else Color("#ff8a2a"))
	# Energy conduits from the hull to the radiator stack, pulsing with the frame.
	for cy: int in [50, 75, 100]:
		BossPainter._rect(img, 90, cy, 4, 2, Color("#2a1408"))
		BossPainter._rect(img, 90, cy, 4, 1, Color("#ffb040") if (cy / 25 + frame) % 2 == 0 else Color("#c84a10"))

	# Mirror petals around the lens: six panels fanning out; wider and longer as the frame opens.
	var spread: float = 0.0 if frame == 0 else (0.16 if frame == 1 else 0.38)
	var reach: float = 30.0 if frame == 0 else (34.0 if frame == 1 else 42.0)
	var base_angles: Array[float] = [-0.62, 0.62, -1.25, 1.25, -1.95, 1.95]
	for p: int in range(6):
		var a: float = PI + base_angles[p] * (1.0 + spread)
		var length: float = reach - float(p / 2) * 4.0
		_petal(img, LENS, a, 14.0, 14.0 + length, 7.0 + float(p / 2), hot)
	# The focusing lens: gold rim, concentric glass rings, a burning core.
	BossPainter._circle(img, int(LENS.x), int(LENS.y), 19, gold_sh)
	BossPainter._circle(img, int(LENS.x), int(LENS.y), 17, gold)
	BossPainter._circle(img, int(LENS.x) - 1, int(LENS.y) - 1, 16, gold_hi)
	BossPainter._circle(img, int(LENS.x), int(LENS.y), 15, Color("#2a1440"))
	var core_r: int = 8 if frame == 0 else (9 if frame == 1 else 12)
	BossPainter._circle(img, int(LENS.x), int(LENS.y), 13, Color("#5a2a6a"))
	BossPainter._glow_orb(img, int(LENS.x), int(LENS.y), core_r, Color("#c84a10"), Color("#ffb040") if not hot else Color("#ffe48a"), Color.WHITE)
	# Glass ring highlights.
	for ang_i: int in range(10):
		var aa: float = -2.6 + float(ang_i) * 0.12
		BossPainter._px(img, int(LENS.x + cos(aa) * 13.0), int(LENS.y + sin(aa) * 13.0), Color("#d8c8ff"))
	BossPainter._px(img, int(LENS.x) - 4, int(LENS.y) - 5, Color.WHITE)
	# Struts from the lens rim into the hull.
	BossPainter._thick_line(img, LENS + Vector2(14.0, -12.0), Vector2(64.0, 46.0), 2, hull, hull_hi)
	BossPainter._thick_line(img, LENS + Vector2(14.0, 12.0), Vector2(64.0, 104.0), 2, hull, hull_hi)
	BossPainter._thick_line(img, LENS + Vector2(18.0, 0.0), Vector2(62.0, 75.0), 3, gold, gold_hi)
	return img


# One mirror petal: a tapered panel from r0 to r1 along `ang`, silver-blue glass in a gold frame,
# with a white streak of reflected sunlight (brighter on the attack frame).
static func _petal(img: Image, hub: Vector2, ang: float, r0: float, r1: float, half_w: float, hot: bool) -> void:
	# Every pixel in the bounding box is tested in petal space (along / across the axis), so the
	# rotated panel has no holes.
	var d: Vector2 = Vector2.from_angle(ang)
	var n: Vector2 = Vector2(-d.y, d.x)
	var ext: float = r1 + half_w + 2.0
	var glass_hi: Color = Color("#8ab0e8") if not hot else Color("#c8e0ff")
	var streak: Color = Color("#e8f0ff") if not hot else Color.WHITE
	for y: int in range(int(hub.y - ext), int(hub.y + ext) + 1):
		for x: int in range(int(hub.x - ext), int(hub.x + ext) + 1):
			var v: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5) - hub
			var along: float = v.dot(d)
			if along < r0 or along > r1:
				continue
			var k: float = (along - r0) / maxf(1.0, r1 - r0)
			var w: float = half_w * (0.55 + 0.45 * sin(k * PI * 0.9 + 0.3))
			var across: float = v.dot(n)
			var aa: float = absf(across)
			if aa > w + 1.0:
				continue
			var col: Color
			if aa > w:
				col = Color("#6a4410")
			elif aa > w - 1.0 or along > r1 - 1.0:
				col = Color("#c8901e")
			elif across < -w * 0.33:
				col = Color("#3a5aa0")
			elif across < w * 0.33:
				col = glass_hi
				if absf(across + w * 0.33 - 1.0) < 0.5 and k > 0.1 and k < 0.9:
					col = streak
			else:
				col = Color("#5a7cc0")
			BossPainter._px(img, x, y, col)
	var tip: Vector2 = hub + d * (r1 + 1.0)
	BossPainter._px(img, int(tip.x), int(tip.y), Color("#ffe07a"))
