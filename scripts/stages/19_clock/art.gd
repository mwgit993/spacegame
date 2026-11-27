extends RefCounted

# CLOCKWORK sprites. build() runs on a worker thread, so it only paints Images. Every key starts
# with the stage id ("clock_...", "boss_clock_..."). Enemies face left, toward the player.
# Palette: polished brass and copper, verdigris teal, ivory dials, blued steel, with teal-white
# "aether" shots that stand out against the warm brass background.

const Kit = preload("res://scripts/stages/art_kit.gd")
const Painter = preload("res://scripts/stage_bg_painter.gd")

# Brass ramp, dark to light.
const BRASS: Array[Color] = [Color("#3a2410"), Color("#7a5220"), Color("#b8862e"), Color("#e8c060"), Color("#fff0b0")]
const COPPER: Array[Color] = [Color("#3a160c"), Color("#7a3418"), Color("#b85a2c"), Color("#e89058")]
const VERD: Array[Color] = [Color("#12302c"), Color("#22605a"), Color("#3c9a8a"), Color("#86d8c4")]
const STEEL: Array[Color] = [Color("#22262e"), Color("#4a5260"), Color("#8a96a4"), Color("#d8e2ea"), Color("#ffffff")]
const IVORY: Color = Color("#ecdfc0")
const IVORY_D: Color = Color("#bfae88")
const IRON: Color = Color("#1c1a1e")
const AETHER: Color = Color("#5ff2dc")
const AETHER_W: Color = Color("#e4fff8")
const AMBER: Color = Color("#ffb848")

const BLADE_FRAMES: int = 9
const BLADE_MAX: float = 0.9   # radians covered by the blade frames, -BLADE_MAX..BLADE_MAX


static func build(id: String) -> Dictionary:
	var out: Dictionary = {}
	for f: int in range(8):
		out[id + "_cog_%d" % f] = Kit.outline(_cog(float(f % 4) * 0.5, f >= 4))
	for f2: int in range(3):
		out[id + "_boiler_%d" % f2] = Kit.outline(_boiler(f2))
	for f3: int in range(BLADE_FRAMES):
		var ang: float = lerpf(-BLADE_MAX, BLADE_MAX, float(f3) / float(BLADE_FRAMES - 1))
		out[id + "_blade_%d" % f3] = Kit.outline(_blade(ang))
	out[id + "_shot"] = _glow_shot(7, AETHER, AETHER_W)
	out[id + "_rivet"] = _rivet()
	out[id + "_shard"] = _shard()
	out[id + "_spark"] = _glow_shot(5, Color("#ffe070"), Color.WHITE)
	for f4: int in range(2):
		out[id + "_shell_%d" % f4] = Kit.outline(_shell(f4))
		out[id + "_saw_%d" % f4] = Kit.outline(_saw(f4))
	for f5: int in range(3):
		out["boss_%s_%d" % [id, f5]] = _paint_boss(f5)
	return out


# --- Shared gear rasteriser --------------------------------------------------------------------
# A gear lit from the upper left: `teeth` teeth between r_root and r_tip (pointed when sharp),
# a body ramp, a recessed hub and round lightening holes. rot is in tooth steps (0..1 = one
# tooth), so frames covering one step loop seamlessly.

static func _gear(img: Image, cx: float, cy: float, teeth: int, r_root: float, r_tip: float, rot: float, ramp: Array[Color], sharp: bool, holes: int, hub_r: float) -> void:
	var step: float = TAU / float(teeth)
	var off: float = rot * step
	var x0: int = maxi(0, floori(cx - r_tip - 1.0))
	var x1: int = mini(img.get_width() - 1, ceili(cx + r_tip + 1.0))
	var y0: int = maxi(0, floori(cy - r_tip - 1.0))
	var y1: int = mini(img.get_height() - 1, ceili(cy + r_tip + 1.0))
	var light: Vector2 = Vector2(-0.7, -0.7)
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1):
			var d: Vector2 = Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - cy)
			var r: float = d.length()
			if r > r_tip:
				continue
			var a: float = atan2(d.y, d.x)
			var u: float = fposmod(a - off, step) / step   # 0..1 across one tooth period
			var dc: float = absf(u - 0.5) * 2.0              # 0 at tooth centre, 1 between teeth
			var solid: bool = r <= r_root
			if not solid:
				var t: float = (r - r_root) / maxf(0.5, r_tip - r_root)
				var half: float = (0.55 * (1.0 - t)) if sharp else (0.5 - 0.12 * t)
				solid = dc < half
			if not solid:
				continue
			# Round lightening holes (they turn with the gear) and the hub recess.
			if holes > 0 and r > hub_r + 1.5 and r < r_root - 1.8:
				var hs: float = TAU / float(holes)
				var ua: float = fposmod(a - off + hs * 0.5, hs) - hs * 0.5
				var mid_r: float = (hub_r + r_root) * 0.5
				var hr: float = (r_root - hub_r) * 0.32
				var hp: Vector2 = Vector2(cos(ua) * r - mid_r, sin(ua) * r)
				if hp.length() < hr:
					if hp.y > hr * 0.35:
						img.set_pixel(x, y, ramp[0])
					continue
			var shade: float = d.normalized().dot(light) if r > 0.5 else 0.0
			var idx: int = 2
			if r < hub_r:
				idx = 3 if shade > 0.0 else 1
			elif r < hub_r + 1.2:
				idx = 0
			elif r > r_root - 1.2:
				idx = 3 if shade > 0.2 else (1 if shade < -0.4 else 2)
				if r > r_root and shade > 0.6 and ramp.size() > 4:
					idx = 4
			else:
				idx = 2 if shade > -0.45 else 1
			img.set_pixel(x, y, ramp[clampi(idx, 0, ramp.size() - 1)])


# --- Cog drone: a spiked brass cog with a teal lens in the hub -----------------------------------

static func _cog(rot: float, hot: bool) -> Image:
	var img: Image = Kit.blank(19, 19)
	var ramp: Array[Color] = BRASS
	if hot:
		ramp = [Color("#5a2a10"), Color("#b0602a"), Color("#e8a048"), Color("#ffe090"), Color("#ffffff")]
	_gear(img, 9.5, 9.5, 8, 6.0, 9.2, rot, ramp, true, 4, 2.6)
	Kit.disc(img, 9.5, 9.5, 2.4, IRON)
	Kit.disc(img, 9.5, 9.5, 1.6, AETHER_W if hot else AETHER)
	Kit.put(img, 8, 8, Color.WHITE)
	return img


# --- Steam cannon: a hovering boiler with a gauge, a stack and a cannon ---------------------------
# Frame 0/1 idle (jet flicker), 2 firing (barrel recoiled, muzzle flash).

static func _boiler(frame: int) -> Image:
	var img: Image = Kit.blank(32, 27)
	var recoil: int = 2 if frame == 2 else 0
	# Cannon barrel (left), behind the drum.
	Kit.rect(img, 1 + recoil, 13, 9, 5, STEEL[1])
	Kit.rect(img, 1 + recoil, 13, 9, 1, STEEL[2])
	Kit.rect(img, 1 + recoil, 17, 9, 1, STEEL[0])
	Kit.rect(img, 0 + recoil, 12, 3, 7, BRASS[2])
	Kit.rect(img, 0 + recoil, 12, 3, 1, BRASS[3])
	Kit.rect(img, 0 + recoil, 18, 3, 1, BRASS[1])
	Kit.put(img, 0 + recoil, 15, IRON)
	Kit.put(img, 0 + recoil, 14, IRON)
	if frame == 2:
		Kit.disc(img, 1.0, 15.0, 2.2, Color("#fff0b0"))
		Kit.put(img, 0, 15, Color.WHITE)
	# Boiler drum: a horizontal cylinder lit from above.
	var drum_cols: Array[Color] = [BRASS[3], BRASS[3], BRASS[2], BRASS[2], BRASS[2], BRASS[2], BRASS[1], BRASS[1], BRASS[1], BRASS[0]]
	for y: int in range(9, 23):
		var c: Color = drum_cols[clampi(int(float(y - 9) / 14.0 * float(drum_cols.size())), 0, drum_cols.size() - 1)]
		var inset: int = 1 if (y == 9 or y == 22) else 0
		Kit.rect(img, 8 + inset, y, 20 - inset * 2, 1, c)
	Kit.rect(img, 9, 10, 18, 1, BRASS[4])
	# Copper bands with rivets.
	for bx: int in [11, 18, 25]:
		Kit.rect(img, bx, 9, 2, 14, COPPER[2])
		Kit.rect(img, bx, 9, 1, 14, COPPER[3])
		Kit.rect(img, bx + 1, 18, 1, 5, COPPER[1])
		for ry: int in [11, 15, 19]:
			Kit.put(img, bx, ry, BRASS[4])
	# Rounded drum ends.
	Kit.rect(img, 7, 11, 1, 10, BRASS[1])
	Kit.rect(img, 28, 11, 1, 10, BRASS[0])
	# Pressure gauge housing on top (needle drawn live by the behaviour).
	Kit.disc(img, 16.5, 5.5, 5.0, BRASS[1])
	Kit.disc(img, 16.0, 5.0, 4.5, BRASS[3])
	Kit.disc(img, 16.5, 5.5, 3.6, IVORY)
	Kit.put(img, 14, 3, Color.WHITE)
	# red zone arc on the dial (upper right)
	Kit.put(img, 19, 4, Color("#d83020"))
	Kit.put(img, 19, 5, Color("#d83020"))
	Kit.put(img, 18, 3, Color("#d83020"))
	Kit.put(img, 14, 7, Color("#5a8a3a"))
	Kit.put(img, 15, 8, Color("#5a8a3a"))
	Kit.rect(img, 15, 9, 3, 1, BRASS[0])
	# Safety valve and stack (right).
	Kit.rect(img, 24, 3, 3, 6, COPPER[2])
	Kit.rect(img, 24, 3, 1, 6, COPPER[3])
	Kit.rect(img, 23, 2, 5, 2, BRASS[3])
	Kit.rect(img, 23, 3, 5, 1, BRASS[1])
	# Teal lamp window on the drum face.
	Kit.rect(img, 20, 13, 3, 4, IRON)
	Kit.rect(img, 21, 14, 1, 2, AETHER if frame != 2 else AETHER_W)
	# Twin steam thrusters underneath.
	for nx: int in [12, 22]:
		Kit.rect(img, nx, 23, 4, 2, STEEL[1])
		Kit.rect(img, nx, 23, 4, 1, STEEL[2])
		var flame: Color = Color("#c8f0ff") if (frame == 1) else Color("#88b8d8")
		Kit.rect(img, nx + 1, 25, 2, 1 + (1 if frame == 1 else 0), flame)
	# Exhaust stub at the back.
	Kit.rect(img, 29, 14, 3, 3, STEEL[1])
	Kit.rect(img, 29, 14, 3, 1, STEEL[2])
	return img


# --- Pendulum blade: a crescent axe head on a brass collar, pre-rotated -----------------------------

static func _blade(ang: float) -> Image:
	var img: Image = Kit.blank(34, 34)
	var c: Vector2 = Vector2(17.0, 17.0)
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	for i: int in range(15):
		var a: float = lerpf(0.32, PI - 0.32, float(i) / 14.0)
		outer.append(Vector2(cos(a) * 14.5, -8.0 + sin(a) * 14.0))
	for i2: int in range(15):
		var a2: float = lerpf(PI - 0.42, 0.42, float(i2) / 14.0)
		inner.append(Vector2(cos(a2) * 11.0, -13.5 + sin(a2) * 10.5))
	var poly: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in outer:
		poly.append(c + p.rotated(ang))
	for p2: Vector2 in inner:
		poly.append(c + p2.rotated(ang))
	Painter.poly(img, poly, STEEL[1])
	# Lighter bevel just inside the cutting edge and a bright edge line.
	var bevel: PackedVector2Array = PackedVector2Array()
	for i3: int in range(15):
		var a3: float = lerpf(0.4, PI - 0.4, float(i3) / 14.0)
		bevel.append(c + Vector2(cos(a3) * 13.0, -8.0 + sin(a3) * 12.4).rotated(ang))
	for i4: int in range(15):
		var a4: float = lerpf(PI - 0.5, 0.5, float(i4) / 14.0)
		bevel.append(c + Vector2(cos(a4) * 11.0, -11.0 + sin(a4) * 10.5).rotated(ang))
	Painter.poly(img, bevel, STEEL[2])
	for i5: int in range(13):
		var a5: float = lerpf(0.45, PI - 0.45, float(i5) / 12.0)
		var q: Vector2 = c + Vector2(cos(a5) * 14.0, -8.0 + sin(a5) * 13.5).rotated(ang)
		Kit.put(img, int(q.x), int(q.y), STEEL[3] if i5 % 4 != 0 else STEEL[4])
	# Spine and collar (where the rod attaches), brass.
	var stem_a: Vector2 = c + Vector2(0.0, -10.0).rotated(ang)
	var stem_b: Vector2 = c + Vector2(0.0, -3.0).rotated(ang)
	for k: int in range(-1, 2):
		var side: Vector2 = Vector2(float(k), 0.0).rotated(ang)
		Kit.line(img, stem_a + side, stem_b + side, BRASS[2] if k <= 0 else BRASS[1])
	var collar: Vector2 = c + Vector2(0.0, -11.0).rotated(ang)
	Kit.disc(img, collar.x, collar.y, 2.6, BRASS[1])
	Kit.disc(img, collar.x - 0.4, collar.y - 0.4, 1.8, BRASS[3])
	Kit.put(img, int(collar.x), int(collar.y), IRON)
	return img


# --- Shots -------------------------------------------------------------------------------------------

static func _glow_shot(size: int, col: Color, core: Color) -> Image:
	var img: Image = Kit.blank(size, size)
	var h: float = float(size) * 0.5
	Kit.disc(img, h, h, h, Color(col.r, col.g, col.b, 0.45))
	Kit.disc(img, h, h, h * 0.68, col)
	Kit.disc(img, h, h, h * 0.34, core)
	return img


static func _rivet() -> Image:
	return Kit.rows(PackedStringArray([
		".TTT.",
		"TWWWT",
		"TWHWT",
		"TWWWT",
		".TTT.",
	]), {"T": AETHER, "W": AETHER_W, "H": Color.WHITE})


static func _shard() -> Image:
	return Kit.rows(PackedStringArray([
		"..T..",
		".TWT.",
		"TWHWT",
		".TWT.",
		"..T..",
	]), {"T": Color("#ff7ad0"), "W": Color("#ffd0f0"), "H": Color.WHITE})


# Heavy shell: an iron ball with a brass band and a sputtering fuse.
static func _shell(frame: int) -> Image:
	var img: Image = Kit.blank(10, 10)
	Kit.ball(img, 5.0, 5.5, 4.2, 4.2, [Color("#14121a"), Color("#3a3644"), Color("#6a6478"), Color("#b8b0c8")])
	Kit.rect(img, 1, 5, 8, 1, BRASS[2])
	Kit.put(img, 2, 5, BRASS[4])
	Kit.put(img, 6, 1, Color("#ffe070") if frame == 0 else Color.WHITE)
	Kit.put(img, 7, 0, Color("#ff9040") if frame == 0 else Color("#ffe070"))
	if frame == 1:
		Kit.put(img, 5, 0, Color("#ffe070"))
	return img


# Boss saw cog: a small toothed blade, two frames half a tooth apart.
static func _saw(frame: int) -> Image:
	var img: Image = Kit.blank(11, 11)
	_gear(img, 5.5, 5.5, 6, 3.4, 5.4, 0.5 * float(frame), [Color("#5a3010"), Color("#c08a30"), Color("#f0c860"), Color("#fff4c0"), Color.WHITE], true, 0, 1.2)
	Kit.disc(img, 5.5, 5.5, 1.3, AETHER_W)
	return img


# --- Boss: CHRONOS COLOSSUS ------------------------------------------------------------------------
# A clocktower colossus: a great ivory dial in a brass bezel as its face (the hands, the dial glow
# and the pendulum in its glass case are drawn live by boss.gd on top of this), a verdigris spire
# with a bell in the belfry, shoulder gears, piston arms and a geared skirt with steam jets.
# Frames: 0/1 idle (gears a half tooth apart, bell swaying), 2 attacking (bell lit, knobs lit).

const BOSS_W: int = 112
const BOSS_H: int = 156
const DIAL: Vector2 = Vector2(48.0, 68.0)   # dial centre in the image (boss.gd mirrors this)
const DIAL_R: float = 25.0
const CASE: Rect2i = Rect2i(36, 100, 26, 38) # pendulum case

static func _paint_boss(frame: int) -> Image:
	var img: Image = BossPainter._new_img(BOSS_W, BOSS_H)
	var sh: Color = Color("#2a1a0c")
	var base: Color = Color("#8a6224")
	var hi: Color = Color("#e0b85a")
	var lit: bool = frame == 2

	# Back steam pipes and stack.
	for px: int in [94, 101]:
		BossPainter._rect(img, px, 34, 5, 110, Color("#1a0e08"))
		BossPainter._rect(img, px + 1, 34, 3, 110, COPPER[1])
		BossPainter._rect(img, px + 1, 34, 1, 110, COPPER[2])
		for fy: int in range(42, 140, 18):
			BossPainter._rect(img, px - 1, fy, 7, 3, BRASS[1])
			BossPainter._rect(img, px - 1, fy, 7, 1, BRASS[3])
	# Tower trunk.
	BossPainter._armor_plate(img, 26, 30, 68, 112, sh, base, Color("#140a04"))
	BossPainter._armor_plate(img, 30, 34, 60, 104, base, hi, sh)
	# Vertical fluting on the trunk.
	for fx: int in range(74, 88, 4):
		BossPainter._rect(img, fx, 40, 1, 92, Color("#5a3e16"))
		BossPainter._rect(img, fx + 1, 40, 1, 92, Color("#c09440"))

	# Spire roof (verdigris copper) with a finial, and the belfry with its bell.
	for ry: int in range(0, 22):
		var hw: int = int(float(ry) * 1.15) + 1
		var cxr: int = 60
		BossPainter._rect(img, cxr - hw, ry + 2, hw * 2, 1, VERD[1] if ry % 4 != 3 else VERD[0])
		BossPainter._rect(img, cxr - hw, ry + 2, maxi(1, hw / 2), 1, VERD[2])
		BossPainter._px(img, cxr - hw, ry + 2, VERD[3])
	BossPainter._rect(img, 59, 0, 2, 3, BRASS[3])
	BossPainter._circle(img, 60, 1, 1, BRASS[4])
	BossPainter._armor_plate(img, 40, 22, 40, 20, sh, base, Color("#140a04"))
	BossPainter._rect(img, 46, 25, 28, 15, Color("#120a06"))
	BossPainter._rect(img, 47, 24, 26, 1, Color("#120a06"))
	# Arch top of the belfry opening.
	BossPainter._rect(img, 48, 23, 24, 1, Color("#120a06"))
	var sway: int = 0 if frame == 0 else (1 if frame == 1 else -1)
	var bell_c: Color = Color("#ffd870") if lit else BRASS[2]
	for by: int in range(0, 11):
		var bw: int = 3 + int(float(by) * 0.55)
		BossPainter._rect(img, 60 - bw + sway, 27 + by, bw * 2, 1, bell_c if by > 1 else BRASS[1])
		BossPainter._px(img, 60 - bw + sway, 27 + by, BRASS[4] if lit else BRASS[3])
	BossPainter._rect(img, 54 + sway, 38, 12, 1, BRASS[1])
	BossPainter._px(img, 60 + sway * 2, 39, IRON)
	if lit:
		BossPainter._circle(img, 60, 33, 2, Color.WHITE)

	# Shoulder gears (half a tooth apart between the idle frames).
	var gr: float = 0.5 if frame == 1 else 0.0
	_gear(img, 86.0, 36.0, 12, 12.0, 15.5, gr, [Color("#2a1808"), Color("#6a4818"), Color("#a87c30"), Color("#e8c060"), Color("#fff0b0")], false, 5, 3.5)
	_gear(img, 88.0, 128.0, 12, 12.0, 15.5, 0.5 - gr, [Color("#2a1808"), Color("#6a4818"), Color("#a87c30"), Color("#e8c060"), Color("#fff0b0")], false, 5, 3.5)
	BossPainter._circle(img, 86, 36, 2, AETHER if not lit else AETHER_W)
	BossPainter._circle(img, 88, 128, 2, AETHER if not lit else AETHER_W)

	# Piston arms reaching forward above and below the dial.
	var reach: int = 0 if frame == 0 else (2 if frame == 1 else 6)
	for arm_y: int in [36, 92]:
		BossPainter._armor_plate(img, 12 - reach, arm_y, 26, 12, Color("#6a4818"), hi, sh)
		BossPainter._rect(img, 4 - reach, arm_y + 4, 10, 4, STEEL[2])
		BossPainter._rect(img, 4 - reach, arm_y + 4, 10, 1, STEEL[3])
		BossPainter._rect(img, 2 - reach, arm_y + 2, 4, 8, BRASS[2])
		BossPainter._rect(img, 2 - reach, arm_y + 2, 1, 8, BRASS[4])
		if lit:
			BossPainter._glow_orb(img, 3 - reach, arm_y + 6, 3, Color("#2a9a8a"), AETHER, Color.WHITE)

	# The dial: an ornate brass bezel with 12 knobs, an ivory face, ticks and a chapter ring.
	var dc: Vector2i = Vector2i(int(DIAL.x), int(DIAL.y))
	BossPainter._circle(img, dc.x, dc.y, int(DIAL_R) + 6, Color("#1a0e06"))
	BossPainter._circle(img, dc.x, dc.y, int(DIAL_R) + 5, BRASS[1])
	BossPainter._circle(img, dc.x - 1, dc.y - 1, int(DIAL_R) + 4, BRASS[3])
	BossPainter._circle(img, dc.x, dc.y, int(DIAL_R) + 3, BRASS[2])
	BossPainter._circle(img, dc.x, dc.y, int(DIAL_R) + 1, Color("#3a2410"))
	for k: int in range(12):
		var a: float = -PI * 0.5 + TAU * float(k) / 12.0
		var kp: Vector2 = DIAL + Vector2(cos(a), sin(a)) * (DIAL_R + 5.0)
		var knob: Color = (Color("#ffe890") if lit else BRASS[3])
		BossPainter._circle(img, int(kp.x), int(kp.y), 2, Color("#2a1808"))
		BossPainter._circle(img, int(kp.x), int(kp.y), 1, knob)
	# Ivory face with a soft rim shadow (lower right) and highlight (upper left).
	for y: int in range(dc.y - int(DIAL_R), dc.y + int(DIAL_R) + 1):
		for x: int in range(dc.x - int(DIAL_R), dc.x + int(DIAL_R) + 1):
			var d: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5) - DIAL
			var r: float = d.length()
			if r > DIAL_R:
				continue
			var col: Color = IVORY
			if r > DIAL_R - 2.5 and d.x + d.y > 0.0:
				col = IVORY_D
			elif r > DIAL_R - 2.5:
				col = Color("#fff6dc")
			if lit:
				col = col.lerp(Color("#ffe8a0"), 0.25)
			img.set_pixel(x, y, col)
	# Chapter ring and ticks.
	for t: int in range(60):
		var a2: float = -PI * 0.5 + TAU * float(t) / 60.0
		var dir: Vector2 = Vector2(cos(a2), sin(a2))
		if t % 5 == 0:
			var big: bool = t % 15 == 0
			for rr: int in range(int(DIAL_R) - (7 if big else 5), int(DIAL_R) - 2):
				var p: Vector2 = DIAL + dir * float(rr)
				BossPainter._px(img, int(p.x), int(p.y), Color("#2a1c14"))
				if big:
					var p2: Vector2 = p + Vector2(-dir.y, dir.x)
					BossPainter._px(img, int(p2.x), int(p2.y), Color("#2a1c14"))
		else:
			var pm: Vector2 = DIAL + dir * (DIAL_R - 3.0)
			BossPainter._px(img, int(pm.x), int(pm.y), Color("#8a7a62"))
	# Inner ornament ring.
	for t2: int in range(48):
		var a3: float = TAU * float(t2) / 48.0
		var pr: Vector2 = DIAL + Vector2(cos(a3), sin(a3)) * 11.0
		if t2 % 2 == 0:
			BossPainter._px(img, int(pr.x), int(pr.y), Color("#b8a682"))
	# Verdigris lunette under the dial.
	BossPainter._rect(img, 30, 96, 40, 3, VERD[0])
	BossPainter._rect(img, 30, 96, 40, 1, VERD[2])

	# Pendulum case: dark glass with a brass frame (the pendulum swings live inside).
	BossPainter._armor_plate(img, CASE.position.x - 3, CASE.position.y - 3, CASE.size.x + 6, CASE.size.y + 6, BRASS[1], BRASS[3], sh)
	BossPainter._rect(img, CASE.position.x, CASE.position.y, CASE.size.x, CASE.size.y, Color("#0c0a10"))
	for gy: int in range(CASE.position.y + 2, CASE.position.y + CASE.size.y - 1, 5):
		BossPainter._px(img, CASE.position.x + 2, gy, Color("#2c3a40"))
	BossPainter._rect(img, CASE.position.x + 1, CASE.position.y + 1, 1, CASE.size.y - 2, Color("#24323a"))

	# Geared skirt with steam jets.
	for sx: int in range(30, 92, 6):
		BossPainter._rect(img, sx, 142, 4, 6, BRASS[1])
		BossPainter._rect(img, sx, 142, 4, 1, BRASS[3])
		BossPainter._px(img, sx, 143, BRASS[4])
	BossPainter._rect(img, 28, 140, 66, 3, Color("#2a1a0c"))
	for jx: int in [40, 58, 76]:
		BossPainter._rect(img, jx, 148, 6, 4, STEEL[1])
		BossPainter._rect(img, jx, 148, 6, 1, STEEL[2])
		var jet: Color = Color("#d8f4ff") if frame != 0 else Color("#9ac4dc")
		BossPainter._rect(img, jx + 1, 152, 4, 2 + (2 if lit else 0), jet)
	# Amber porthole lamps on the trunk.
	for ly: int in [50, 76, 102, 128]:
		BossPainter._circle(img, 80, ly, 3, Color("#1a0e06"))
		BossPainter._circle(img, 80, ly, 2, AMBER if (lit or (ly / 26 + frame) % 2 == 0) else Color("#a06020"))
		BossPainter._px(img, 79, ly - 1, Color("#fff0c0"))
	return img
