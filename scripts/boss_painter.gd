class_name BossPainter
extends RefCounted

# Procedural 16-bit SNES/Genesis Pixel-Art Giant Boss Painter.
# Renders 8 completely distinct, towering screen-filling right-side bosses at native 1:1 pixel density,
# each with 3 animated frames (_0 = idle A, _1 = idle B / windup, _2 = attack / roar / signature pose)!


static func build_all_bosses(cache: Dictionary) -> void:
	for f: int in range(3):
		var suf: String = "_%d" % f
		cache["boss_space" + suf] = _paint_nemesis_wall(f)     # Stage 1: Colossal 116x190 Battleship Wall!
		cache["boss_mech" + suf] = _paint_mecha_scorpion(f)    # Stage 2: Giant Articulated Mecha Scorpion!
		cache["boss_aero" + suf] = _paint_sky_wyvern(f)        # Stage 3: Winged Mechanical Sky Serpent/Wyvern!
		cache["boss_bio" + suf] = _paint_giant_stag_bug(f)     # Stage 4: Giant Mutant Stag-Mantis Bug!
		cache["boss_ice" + suf] = _paint_frost_seraph(f)       # Stage 5: 6-Winged Crystalline Ice Seraph!
		cache["boss_fire" + suf] = _paint_inferno_skull(f)     # Stage 6: Horned Molten Balrog Mecha-Skull!
		cache["boss_abyss" + suf] = _paint_abyssal_kraken(f)   # Stage 7: Bioluminescent 6-Tentacle Cyber-Kraken!
		cache["boss_cyber" + suf] = _paint_neon_medusa(f)      # Stage 8: Neon Medusa Cyber-Gorgon Overmind!

	for base_key: String in ["boss_space", "boss_mech", "boss_aero", "boss_bio", "boss_ice", "boss_fire", "boss_abyss", "boss_cyber"]:
		cache[base_key] = cache[base_key + "_0"]


static func _new_img(w: int, h: int) -> Image:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)


static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	var x0: int = maxi(0, x)
	var y0: int = maxi(0, y)
	var x1: int = mini(img.get_width(), x + w)
	var y1: int = mini(img.get_height(), y + h)
	for py: int in range(y0, y1):
		for px: int in range(x0, x1):
			img.set_pixel(px, py, col)


# Draws a 16-bit beveled metallic armor plate with dark outline, top/left highlight, bottom/right shadow & corner rivets
static func _armor_plate(img: Image, x: int, y: int, w: int, h: int, base: Color, hi: Color, sh: Color, rivets: bool = true) -> void:
	var out: Color = sh.darkened(0.55)
	_rect(img, x, y, w, h, out)
	_rect(img, x + 1, y + 1, w - 2, h - 2, base)
	_rect(img, x + 1, y + 1, w - 3, 2, hi)
	_rect(img, x + 1, y + 1, 2, h - 3, hi)
	_rect(img, x + 2, y + h - 3, w - 3, 2, sh)
	_rect(img, x + w - 3, y + 2, 2, h - 3, sh)
	if rivets and w >= 10 and h >= 10:
		_px(img, x + 3, y + 3, out)
		_px(img, x + w - 4, y + 3, out)
		_px(img, x + 3, y + h - 4, out)
		_px(img, x + w - 4, y + h - 4, out)


static func _circle(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	var r2: int = r * r
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if dx * dx + dy * dy <= r2:
				_px(img, cx + dx, cy + dy, col)


static func _glow_orb(img: Image, cx: int, cy: int, r: int, outer: Color, mid: Color, inner: Color) -> void:
	_circle(img, cx, cy, r + 1, outer.darkened(0.45))
	_circle(img, cx, cy, r, outer)
	_circle(img, cx, cy, maxi(1, int(float(r) * 0.68)), mid)
	_circle(img, cx - 1, cy - 1, maxi(1, int(float(r) * 0.36)), inner)


static func _thick_line(img: Image, a: Vector2, b: Vector2, radius: int, col: Color, hi: Color) -> void:
	var steps: int = maxi(1, int(a.distance_to(b)))
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		_circle(img, int(p.x), int(p.y), radius + 1, col.darkened(0.55))
	for i: int in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		_circle(img, int(p.x), int(p.y), radius, col)
		if radius >= 2:
			_circle(img, int(p.x) - 1, int(p.y) - 1, maxi(1, radius - 2), hi)


# =================================================================================
# STAGE 1: NEMESIS DREADNOUGHT WALL (116x190 - Towering Right-Screen Battleship!)
# =================================================================================
static func _paint_nemesis_wall(frame: int = 0) -> ImageTexture:
	var w: int = 116
	var h: int = 190
	var img: Image = _new_img(w, h)
	var c_base: Color = Color("#465c8c")
	var c_hi: Color = Color("#9eb8e8")
	var c_sh: Color = Color("#243254")
	var c_dark: Color = Color("#161f38")

	# Massive rear dreadnought superstructure spanning nearly top-to-bottom on the right
	_armor_plate(img, 58, 4, 56, 182, c_dark, c_base, Color("#0d1324"))
	_armor_plate(img, 42, 14, 68, 162, c_sh, c_base, c_dark)
	_armor_plate(img, 30, 28, 66, 134, c_base, c_hi, c_sh)

	# Horizontal panel ribs & animated cycling warning beacons across the battleship wall
	var rib_ys: Array[int] = [46, 68, 122, 144]
	for idx: int in range(rib_ys.size()):
		var ry: int = rib_ys[idx]
		_rect(img, 32, ry, 78, 3, c_dark)
		_rect(img, 32, ry + 3, 78, 1, c_hi)
		var beacon_col: Color = Color("#ff3854") if ((idx + frame) % 2 == 0) else Color("#ff9624")
		_glow_orb(img, 52 + (frame * 6), ry + 1, 2, Color("#6e1024"), beacon_col, Color.WHITE)

	# Upper & Lower Heavy Twin Cannon Batteries (barrels recoil & flash on frame 2!)
	var barrel_recoil: int = 5 if frame == 2 else (1 if frame == 1 else 0)
	for cy: int in [38, 140]:
		_armor_plate(img, 14, cy, 34, 16, Color("#596e9c"), Color("#c8dcff"), c_sh)
		_rect(img, 2 + barrel_recoil, cy + 3, 14 - barrel_recoil, 4, Color("#dce8ff"))
		_rect(img, 2 + barrel_recoil, cy + 9, 14 - barrel_recoil, 4, Color("#dce8ff"))
		_rect(img, barrel_recoil, cy + 2, 4, 6, Color("#ff9624"))
		_rect(img, barrel_recoil, cy + 8, 4, 6, Color("#ff9624"))
		if frame == 2:
			_glow_orb(img, 4, cy + 5, 4, Color("#ff5818"), Color("#ffe854"), Color.WHITE)
			_glow_orb(img, 4, cy + 11, 4, Color("#ff5818"), Color("#ffe854"), Color.WHITE)

	# Upper & Lower Crimson Missile Pods (hatch glow intensifies on frames 1 & 2)
	var pod_r: int = 4 if frame >= 1 else 3
	for my: int in [62, 116]:
		_armor_plate(img, 20, my, 26, 14, Color("#9e283c"), Color("#ff687c"), Color("#4f101e"))
		_glow_orb(img, 26, my + 7, pod_r, Color("#ff4c28"), Color("#ffe854"), Color.WHITE)

	# Recessed Central Armored Core Chamber & Giant Pulsing Cyan Reactor!
	_armor_plate(img, 24, 78, 52, 34, c_dark, c_sh, Color("#090d1c"))
	var core_r: int = 13 if frame == 0 else (14 if frame == 1 else 16)
	var core_outer: Color = Color("#28b8ff") if frame == 2 else Color("#0088cc")
	_glow_orb(img, 38, 95, core_r, core_outer, Color("#28e8ff"), Color.WHITE)

	# Animated protective top/bottom core claws ratcheting open!
	var claw_open: int = 0 if frame == 0 else (3 if frame == 1 else 7)
	_armor_plate(img, 12, 76 - claw_open, 22, 8, c_base, c_hi, c_sh, false)
	_armor_plate(img, 12, 106 + claw_open, 22, 8, c_base, c_hi, c_sh, false)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 2: MECHA SCORPION "SCORPIO-REX" (114x158 - Arched Stinger Tail & Pincers!)
# =================================================================================
static func _paint_mecha_scorpion(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(114, 158)
	var steel: Color = Color("#5c6b84")
	var steel_hi: Color = Color("#b8c8e2")
	var steel_sh: Color = Color("#2b3446")
	var haz: Color = Color("#e87818")
	var haz_hi: Color = Color("#ffc848")
	var haz_sh: Color = Color("#7a3408")

	# 7-Segment Articulated Mechanical Scorpion Tail (coils higher on frame 1, whips forward on frame 2!)
	var tail_pts: Array[Vector2] = [
		Vector2(88, 96), Vector2(98, 76), Vector2(98, 52),
		Vector2(86, 32), Vector2(66, 20), Vector2(44, 18), Vector2(24, 26)
	]
	if frame == 1:
		tail_pts = [
			Vector2(88, 96), Vector2(100, 74), Vector2(102, 48),
			Vector2(90, 26), Vector2(70, 14), Vector2(48, 12), Vector2(30, 18)
		]
	elif frame == 2:
		tail_pts = [
			Vector2(88, 96), Vector2(94, 74), Vector2(88, 50),
			Vector2(74, 32), Vector2(54, 24), Vector2(34, 28), Vector2(16, 38)
		]

	for i: int in range(tail_pts.size()):
		var p: Vector2 = tail_pts[i]
		var col: Color = haz if i % 2 == 0 else steel
		var hi: Color = haz_hi if i % 2 == 0 else steel_hi
		var sh: Color = haz_sh if i % 2 == 0 else steel_sh
		_armor_plate(img, int(p.x) - 9, int(p.y) - 8, 18, 16, col, hi, sh, false)
		_glow_orb(img, int(p.x), int(p.y), 2, Color("#0088cc"), Color("#28e8ff"), Color.WHITE)

	# Glowing Cyan Plasma Stinger Blade at tip of tail!
	var tip_pt: Vector2 = tail_pts[6]
	var blade_end: Vector2 = tip_pt + (Vector2(-14, 10) if frame == 2 else Vector2(-18, 8))
	_thick_line(img, tip_pt - Vector2(2, 0), blade_end, 4 if frame == 2 else 3, Color("#28e8ff"), Color.WHITE)
	_glow_orb(img, int(tip_pt.x) - 6, int(tip_pt.y) + 2, 7 if frame == 2 else 5, Color("#0088cc"), Color("#28e8ff"), Color.WHITE)

	# 4 Mechanical Arachnid Legs scuttling with alternating gait!
	var leg_xs: Array[int] = [52, 68, 84, 98]
	for idx: int in range(leg_xs.size()):
		var lx: int = leg_xs[idx]
		var step_shift: int = (-4 if (idx + frame) % 2 == 0 else 4) if frame != 0 else 0
		_thick_line(img, Vector2(lx, 114), Vector2(lx - 10 + step_shift, 136), 3, steel, steel_hi)
		_thick_line(img, Vector2(lx - 10 + step_shift, 136), Vector2(lx - 4 + step_shift, 152), 2, haz, haz_hi)

	# Heavy Armored Scorpion Thorax & Head
	_armor_plate(img, 46, 82, 58, 38, steel, steel_hi, steel_sh)
	_armor_plate(img, 34, 88, 26, 26, haz, haz_hi, haz_sh)
	# Glowing Crimson Optic Visor
	_glow_orb(img, 38, 98, 6 if frame == 2 else 5, Color("#941c2f"), Color("#ff3854"), Color.WHITE if frame == 2 else Color("#ffe888"))

	# Twin Giant Hydraulic Pincer Claws (open wide in frame 1, snap forward in frame 2!)
	var claw_x: int = 0 if frame == 2 else 4
	var jaw_gap: int = 4 if frame == 1 else (0 if frame == 2 else 2)
	# Upper Pincer Arm
	_thick_line(img, Vector2(40, 88), Vector2(22, 68), 4, steel, steel_hi)
	_armor_plate(img, claw_x, 58 - jaw_gap, 24, 12, haz, haz_hi, haz_sh, false)
	_rect(img, claw_x, 70 + jaw_gap, 18, 5, steel_hi)
	# Lower Pincer Arm
	_thick_line(img, Vector2(40, 112), Vector2(22, 128), 4, steel, steel_hi)
	_armor_plate(img, claw_x, 124 + jaw_gap, 24, 12, haz, haz_hi, haz_sh, false)
	_rect(img, claw_x, 118 - jaw_gap, 18, 5, steel_hi)
	if frame == 2:
		_glow_orb(img, 6, 70, 4, Color("#ff6818"), Color("#ffe854"), Color.WHITE)
		_glow_orb(img, 6, 123, 4, Color("#ff6818"), Color("#ffe854"), Color.WHITE)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 3: SKY SERPENT "VALKYRIE WYVERN" (114x166 - Winged Mechanical Sky Dragon!)
# =================================================================================
static func _paint_sky_wyvern(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(114, 166)
	var aero: Color = Color("#3a78c8")
	var aero_hi: Color = Color("#9ce0ff")
	var aero_sh: Color = Color("#1c3d72")
	var gold: Color = Color("#e8a828")
	var gold_hi: Color = Color("#fff088")

	# Sweeping Upper & Lower Feathered Mecha-Wings flapping across 3 frames!
	var wing_fold: int = 0 if frame == 0 else (14 if frame == 1 else -4)
	var wing_fwd: int = -10 if frame == 2 else (4 if frame == 1 else 0)
	for feather: int in range(5):
		var fy_top: int = 12 + wing_fold + feather * 10
		var fy_bot: int = 150 - wing_fold - feather * 10
		var fx: int = 44 + wing_fwd + feather * 9
		_thick_line(img, Vector2(68, 72), Vector2(fx, fy_top), 4, aero, aero_hi)
		_thick_line(img, Vector2(fx, fy_top), Vector2(fx + 26, fy_top - 4), 3, gold, gold_hi)
		_thick_line(img, Vector2(68, 94), Vector2(fx, fy_bot), 4, aero, aero_hi)
		_thick_line(img, Vector2(fx, fy_bot), Vector2(fx + 26, fy_bot + 4), 3, gold, gold_hi)

	# Serpentine Armored Body & Neck undulating
	var neck_wave: int = 3 if frame == 1 else (-2 if frame == 2 else 0)
	var spine: Array[Vector2] = [
		Vector2(98, 118 - neck_wave),
		Vector2(82, 98 + neck_wave),
		Vector2(66, 82),
		Vector2(48, 70 - neck_wave),
		Vector2(32, 74),
	]
	for p: Vector2 in spine:
		_circle(img, int(p.x), int(p.y), 14, aero_sh)
		_circle(img, int(p.x), int(p.y), 11, aero)
		_circle(img, int(p.x) - 2, int(p.y) - 3, 6, aero_hi)

	# Fierce Horned Dragon Head & Lightning Maw (jaw opens wide to roar lightning on frame 2!)
	var jaw_drop: int = 0 if frame == 0 else (3 if frame == 1 else 8)
	_armor_plate(img, 8, 64, 30, 18, aero, aero_hi, aero_sh, false)
	_thick_line(img, Vector2(28, 64), Vector2(48, 48), 3, gold, gold_hi)
	_rect(img, 10, 82 + jaw_drop, 24, 7, aero_sh)
	_glow_orb(img, 16, 80 + jaw_drop / 2, 8 if frame == 2 else 5, Color("#0088cc"), Color("#7ce8ff"), Color.WHITE)
	_glow_orb(img, 22, 70, 4 if frame == 2 else 3, Color("#d9381e"), Color("#ffe854"), Color.WHITE)
	# Chest Valkyrie Reactor
	_glow_orb(img, 58, 86, 10 if frame == 2 else 8, Color("#d97818"), Color("#ffe854"), Color.WHITE)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 4: EMPEROR STAG-MANTIS (112x164 - Giant Mutant Forest Insectoid!)
# =================================================================================
static func _paint_giant_stag_bug(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(112, 164)
	var chit: Color = Color("#1e8c42")
	var chit_hi: Color = Color("#6eff8c")
	var chit_sh: Color = Color("#0d4220")
	var amb: Color = Color("#d98818")
	var amb_hi: Color = Color("#ffe868")

	# Translucent Veined Insectoid Wings buzzing rapidly!
	var buzz_y: int = 8 if frame == 1 else (-4 if frame == 2 else 0)
	for w_i: int in range(3):
		_thick_line(img, Vector2(64, 74), Vector2(96, 18 + buzz_y + w_i * 16), 6, Color("#185c38"), Color("#4cd97c"))
		_thick_line(img, Vector2(64, 90), Vector2(96, 146 - buzz_y - w_i * 16), 6, Color("#185c38"), Color("#4cd97c"))

	# Segmented Chitinous Bug Abdomen breathing
	var ab_lift: int = -3 if frame == 1 else (3 if frame == 2 else 0)
	for seg: int in range(4):
		var sx: int = 62 + seg * 10
		var sy: int = 82 + seg * 5 + (ab_lift if seg >= 2 else 0)
		_circle(img, sx, sy, 17 - seg, chit_sh)
		_circle(img, sx, sy, 14 - seg, chit)
		_circle(img, sx - 2, sy - 3, 6, chit_hi)

	# Armored Thorax & Insect Head
	_circle(img, 48, 82, 18, chit_sh)
	_circle(img, 48, 82, 15, chit)
	_circle(img, 32, 82, 13, chit_sh)
	_circle(img, 32, 82, 10, chit)

	# Giant Glowing Magenta Compound Bug Eyes!
	var eye_r: int = 7 if frame == 2 else 6
	_glow_orb(img, 26, 73, eye_r, Color("#7a1458"), Color("#ff38b8"), Color.WHITE if frame == 2 else Color("#ffc8f0"))
	_glow_orb(img, 26, 91, eye_r, Color("#7a1458"), Color("#ff38b8"), Color.WHITE if frame == 2 else Color("#ffc8f0"))

	# Serrated Stag-Beetle Mandibles & Mantis Raptorial Scythe Forelegs (cock back in frame 1, slash in frame 2!)
	var mand_open: int = 6 if frame == 2 else (2 if frame == 1 else 0)
	_thick_line(img, Vector2(24, 72), Vector2(4, 58 - mand_open), 3, amb, amb_hi)
	_thick_line(img, Vector2(24, 92), Vector2(4, 106 + mand_open), 3, amb, amb_hi)

	var elbow_up: Vector2 = Vector2(22, 38) if frame == 0 else (Vector2(28, 30) if frame == 1 else Vector2(14, 48))
	var tip_up: Vector2 = Vector2(6, 52) if frame == 0 else (Vector2(12, 44) if frame == 1 else Vector2(2, 68))
	var elbow_dn: Vector2 = Vector2(22, 126) if frame == 0 else (Vector2(28, 134) if frame == 1 else Vector2(14, 116))
	var tip_dn: Vector2 = Vector2(6, 112) if frame == 0 else (Vector2(12, 120) if frame == 1 else Vector2(2, 96))
	_thick_line(img, Vector2(44, 68), elbow_up, 4, chit, chit_hi)
	_thick_line(img, elbow_up, tip_up, 4 if frame == 2 else 3, amb, Color.WHITE if frame == 2 else amb_hi)
	_thick_line(img, Vector2(44, 96), elbow_dn, 4, chit, chit_hi)
	_thick_line(img, elbow_dn, tip_dn, 4 if frame == 2 else 3, amb, Color.WHITE if frame == 2 else amb_hi)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 5: FROST SERAPH TITAN (110x168 - 6-Winged Crystalline Ice Guardian!)
# =================================================================================
static func _paint_frost_seraph(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(110, 168)
	var ice: Color = Color("#3ca8e8")
	var ice_hi: Color = Color("#d4faff")
	var ice_sh: Color = Color("#184e84")

	# 6 Razor-Sharp Crystalline Seraph Wings breathing & flaring!
	var spread: int = 0 if frame == 0 else (5 if frame == 1 else -5)
	var wing_tips: Array[Vector2] = [
		Vector2(88, 12 + spread), Vector2(102, 42 + spread / 2), Vector2(104, 72),
		Vector2(104, 96), Vector2(102, 126 - spread / 2), Vector2(88, 156 - spread),
		Vector2(28 - (6 if frame == 2 else 0), 22 + spread), Vector2(28 - (6 if frame == 2 else 0), 146 - spread),
	]
	var wing_hi: Color = Color.WHITE if frame == 2 else ice_hi
	for tip: Vector2 in wing_tips:
		_thick_line(img, Vector2(56, 84), tip, 6 if frame == 2 else 5, ice, wing_hi)
		if frame == 2:
			_glow_orb(img, int(tip.x), int(tip.y), 3, Color("#0088cc"), Color("#7ce8ff"), Color.WHITE)

	# Faceted Diamond Armor Body & Crowned Ice Helm
	_armor_plate(img, 38, 52, 38, 64, ice, ice_hi, ice_sh)
	_armor_plate(img, 34, 34, 28, 22, ice_hi, Color.WHITE, ice)
	# Crown of 3 Icicle Horns
	_thick_line(img, Vector2(42, 34), Vector2(34, 14), 2, ice_hi, Color.WHITE)
	_thick_line(img, Vector2(48, 32), Vector2(48, 10), 3, ice_hi, Color.WHITE)
	_thick_line(img, Vector2(54, 34), Vector2(62, 16), 2, ice_hi, Color.WHITE)

	# Floating Left Ice Lance Shield (hovers & thrusts forward on frame 2!) & Blazing Sapphire Core
	var shield_x: int = 12 if frame == 0 else (9 if frame == 1 else 3)
	var shield_y: int = 66 if frame != 1 else 63
	_armor_plate(img, shield_x, shield_y, 16, 36, ice, Color.WHITE, ice_sh, false)
	_glow_orb(img, 52, 84, 14 if frame == 2 else (12 if frame == 1 else 11), Color("#0066cc"), Color("#54f0ff"), Color.WHITE)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 6: INFERNO SKULL "BALROG" (112x168 - Horned Molten Mecha-Skull Colossus!)
# =================================================================================
static func _paint_inferno_skull(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(112, 168)
	var obs: Color = Color("#4a2624")
	var obs_hi: Color = Color("#8c483c")
	var obs_sh: Color = Color("#210d0d")
	var bone: Color = Color("#b86848")
	var bone_hi: Color = Color("#f4b888")

	# Massive Sweeping Obsidian Demon Ram Horns (ignite brighter on frames 1 & 2!)
	var horn_tip_col: Color = Color.WHITE if frame == 2 else Color("#ffe854")
	_thick_line(img, Vector2(58, 52), Vector2(84, 20), 7, obs, obs_hi)
	_thick_line(img, Vector2(84, 20), Vector2(44, 10), 5, obs, Color("#ff7828"))
	_thick_line(img, Vector2(44, 10), Vector2(18, 24), 4 if frame == 2 else 3, Color("#ff7828"), horn_tip_col)

	_thick_line(img, Vector2(58, 116), Vector2(84, 148), 7, obs, obs_hi)
	_thick_line(img, Vector2(84, 148), Vector2(44, 158), 5, obs, Color("#ff7828"))
	_thick_line(img, Vector2(44, 158), Vector2(18, 144), 4 if frame == 2 else 3, Color("#ff7828"), horn_tip_col)

	# Towering Craggy Cranium
	_circle(img, 60, 74, 32, obs_sh)
	_circle(img, 58, 74, 29, bone)
	_circle(img, 52, 64, 18, bone_hi)

	# Animated Hinged Magma Jaw (unhinges wide to roar molten fire on frame 2!)
	var jaw_open: int = 0 if frame == 0 else (5 if frame == 1 else 13)
	_rect(img, 26, 84, 36, 12 + jaw_open, Color("#ff4814"))
	if frame >= 1:
		_glow_orb(img, 36, 90 + jaw_open / 2, 6 + frame * 2, Color("#ff5814"), Color("#ffe854"), Color.WHITE)
	_armor_plate(img, 24, 93 + jaw_open, 48, 28, obs, bone, obs_sh, false)
	for fang_x: int in [26, 36, 46, 56]:
		_rect(img, fang_x, 83, 4, 7, Color.WHITE)
		_rect(img, fang_x + 2, 90 + jaw_open, 4, 6, Color.WHITE)

	# Blazing Furnace Eye Sockets!
	var eye_r: int = 10 if frame == 2 else (9 if frame == 1 else 8)
	_glow_orb(img, 36, 68, eye_r, Color("#b81c0c"), Color("#ff8818"), Color.WHITE if frame == 2 else Color("#ffffaa"))
	_glow_orb(img, 56, 72, eye_r - 2, Color("#b81c0c"), Color("#ff8818"), Color.WHITE if frame == 2 else Color("#ffffaa"))

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 7: ABYSSAL KRAKEN "CHARYBDIS" (114x168 - 6-Tentacle Bioluminescent Kraken!)
# =================================================================================
static func _paint_abyssal_kraken(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(114, 168)
	var teal: Color = Color("#168896")
	var teal_hi: Color = Color("#54f4e8")
	var teal_sh: Color = Color("#093b4a")

	# 6 Writhing Mechanical-Organic Tentacles undulating & lunging forward!
	var tent_rows: Array[int] = [22, 46, 70, 98, 122, 146]
	for t_i: int in range(tent_rows.size()):
		var ty: int = tent_rows[t_i]
		var wave_dir: int = -1 if ((t_i + frame) % 2 == 0) else 1
		var mid_y: int = ty + wave_dir * (4 if frame == 2 else 11)
		var tip_x: int = 2 if frame == 2 else (11 if frame == 1 else 8)
		var tip_y: int = ty + (wave_dir * -5 if frame == 1 else 0)
		_thick_line(img, Vector2(56, 84), Vector2(32, mid_y), 5, teal, teal_hi)
		_thick_line(img, Vector2(32, mid_y), Vector2(tip_x, tip_y), 3, teal, Color("#ff68b8"))
		_glow_orb(img, tip_x, tip_y, 5 if frame == 2 else 3, Color("#941c68"), Color("#ff54b8"), Color.WHITE)

	# Giant Armored Cephalopod Mantle Hood pumping/breathing on the Right
	var mantle_r: int = 32 if frame == 1 else 30
	_circle(img, 76, 84, mantle_r + 4, teal_sh)
	_circle(img, 76, 84, mantle_r, teal)
	_circle(img, 72, 74, 18, teal_hi)
	_armor_plate(img, 46, 58, 36, 52, teal, teal_hi, teal_sh)

	# Giant Hypnotic Bioluminescent Kraken Eye!
	_glow_orb(img, 54, 84, 15 if frame == 2 else 13, Color("#941c68"), Color("#ffe854"), Color.WHITE)
	var pupil_w: int = 6 if frame == 2 else 4
	_rect(img, 54 - pupil_w / 2, 74, pupil_w, 20, Color("#1a0624"))

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 8: NEON MEDUSA OVERMIND (112x174 - Cyber-Gorgon Visage & Serpent Cables!)
# =================================================================================
static func _paint_neon_medusa(frame: int = 0) -> ImageTexture:
	var img: Image = _new_img(112, 174)
	var chrome: Color = Color("#58388c")
	var chrome_hi: Color = Color("#d8b8ff")
	var chrome_sh: Color = Color("#241046")
	var neon_pink: Color = Color("#ff28c8")
	var neon_cyan: Color = Color("#28f8ff")

	# 8 Coiling Fiber-Optic Neon Serpent "Hair" Cables slithering & striking!
	var snakes: Array[Vector2] = [
		Vector2(24, 16), Vector2(52, 10), Vector2(84, 20), Vector2(18, 44),
		Vector2(18, 130), Vector2(24, 158), Vector2(52, 164), Vector2(84, 154),
	]
	for i: int in range(snakes.size()):
		var base_tip: Vector2 = snakes[i]
		var strike_off: Vector2 = Vector2(-10, 0) if frame == 2 else (Vector2(3, -5 if i % 2 == 0 else 5) if frame == 1 else Vector2.ZERO)
		var tip: Vector2 = base_tip + strike_off
		var col: Color = neon_pink if i % 2 == 0 else neon_cyan
		var coil_dir: int = (-12 if i < 4 else 12) * (-1 if frame == 1 else 1)
		var mid: Vector2 = Vector2(58, 87).lerp(tip, 0.55) + Vector2(0, coil_dir)
		_thick_line(img, Vector2(62, 87), mid, 4, chrome, col)
		_thick_line(img, mid, tip, 3, col, Color.WHITE)
		_glow_orb(img, int(tip.x), int(tip.y), 6 if frame == 2 else 5, chrome_sh, col, Color.WHITE)

	# Rotating Geometric Neon Halo Ring behind Overmind Head
	var halo_shift: float = float(frame) * (TAU / 72.0)
	for ang_i: int in range(24):
		var a: float = halo_shift + TAU * float(ang_i) / 24.0
		var h_col: Color = neon_pink if (frame == 2 and ang_i % 2 == 0) else neon_cyan
		_circle(img, 64 + int(cos(a) * 38.0), 87 + int(sin(a) * 38.0), 3 if frame == 2 else 2, h_col)

	# Sleek Android / Cyber-Gorgon Faceplate & Visor
	_circle(img, 60, 84, 25, chrome_sh)
	_circle(img, 60, 84, 22, chrome)
	_circle(img, 56, 76, 14, chrome_hi)
	_armor_plate(img, 44, 96, 28, 18, chrome, chrome_hi, chrome_sh, false)

	# Blazing Neon-Pink Synthwave Visor across her eyes ("NEON MEDUSA"!)
	var visor_grow: int = 2 if frame == 2 else 0
	_rect(img, 34, 76 - visor_grow, 38, 10 + visor_grow * 2, Color("#4a0846"))
	_rect(img, 36, 78 - visor_grow, 34, 6 + visor_grow * 2, neon_pink)
	_rect(img, 38, 80 - visor_grow / 2, 28, 2 + visor_grow, Color.WHITE)
	# Third-Eye Forehead Diamond Core
	_glow_orb(img, 50, 64, 7 if frame == 2 else 5, Color("#0088cc"), neon_cyan, Color.WHITE)

	return ImageTexture.create_from_image(img)
