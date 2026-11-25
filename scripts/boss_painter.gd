class_name BossPainter
extends RefCounted

# Procedural 16-bit SNES/Genesis Pixel-Art Giant Boss Painter.
# Renders 8 completely distinct, towering screen-filling right-side bosses at native 1:1 pixel density!


static func build_all_bosses(cache: Dictionary) -> void:
	cache["boss_space"] = _paint_nemesis_wall()       # Stage 1: Colossal 116x190 Battleship Wall!
	cache["boss_mech"] = _paint_mecha_scorpion()      # Stage 2: Giant Articulated Mecha Scorpion!
	cache["boss_aero"] = _paint_sky_wyvern()          # Stage 3: Winged Mechanical Sky Serpent/Wyvern!
	cache["boss_bio"] = _paint_giant_stag_bug()       # Stage 4: Giant Mutant Stag-Mantis Bug!
	cache["boss_ice"] = _paint_frost_seraph()         # Stage 5: 6-Winged Crystalline Ice Seraph!
	cache["boss_fire"] = _paint_inferno_skull()       # Stage 6: Horned Molten Balrog Mecha-Skull!
	cache["boss_abyss"] = _paint_abyssal_kraken()     # Stage 7: Bioluminescent 6-Tentacle Cyber-Kraken!
	cache["boss_cyber"] = _paint_neon_medusa()        # Stage 8: Neon Medusa Cyber-Gorgon Overmind!


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
static func _paint_nemesis_wall() -> ImageTexture:
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

	# Horizontal panel ribs across the battleship wall
	for ry: int in [46, 68, 122, 144]:
		_rect(img, 32, ry, 78, 3, c_dark)
		_rect(img, 32, ry + 3, 78, 1, c_hi)

	# Upper & Lower Heavy Twin Cannon Batteries jutting out left
	for cy: int in [38, 140]:
		_armor_plate(img, 14, cy, 34, 16, Color("#596e9c"), Color("#c8dcff"), c_sh)
		_rect(img, 2, cy + 3, 14, 4, Color("#dce8ff"))
		_rect(img, 2, cy + 9, 14, 4, Color("#dce8ff"))
		_rect(img, 0, cy + 2, 4, 6, Color("#ff9624"))
		_rect(img, 0, cy + 8, 4, 6, Color("#ff9624"))

	# Upper & Lower Crimson Missile Pods
	for my: int in [62, 116]:
		_armor_plate(img, 20, my, 26, 14, Color("#9e283c"), Color("#ff687c"), Color("#4f101e"))
		_glow_orb(img, 26, my + 7, 3, Color("#ff9624"), Color("#ffe854"), Color.WHITE)

	# Recessed Central Armored Core Chamber & Giant Pulsing Cyan Reactor!
	_armor_plate(img, 24, 78, 52, 34, c_dark, c_sh, Color("#090d1c"))
	_glow_orb(img, 38, 95, 13, Color("#0088cc"), Color("#28e8ff"), Color.WHITE)
	# Protective top/bottom core claws
	_armor_plate(img, 12, 76, 22, 8, c_base, c_hi, c_sh, false)
	_armor_plate(img, 12, 106, 22, 8, c_base, c_hi, c_sh, false)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 2: MECHA SCORPION "SCORPIO-REX" (114x158 - Arched Stinger Tail & Pincers!)
# =================================================================================
static func _paint_mecha_scorpion() -> ImageTexture:
	var img: Image = _new_img(114, 158)
	var steel: Color = Color("#5c6b84")
	var steel_hi: Color = Color("#b8c8e2")
	var steel_sh: Color = Color("#2b3446")
	var haz: Color = Color("#e87818")
	var haz_hi: Color = Color("#ffc848")
	var haz_sh: Color = Color("#7a3408")

	# 7-Segment Articulated Mechanical Scorpion Tail arching overhead from rear body to top-left stinger!
	var tail_pts: Array[Vector2] = [
		Vector2(88, 96), Vector2(98, 76), Vector2(98, 52),
		Vector2(86, 32), Vector2(66, 20), Vector2(44, 18), Vector2(24, 26)
	]
	for i: int in range(tail_pts.size()):
		var p: Vector2 = tail_pts[i]
		var col: Color = haz if i % 2 == 0 else steel
		var hi: Color = haz_hi if i % 2 == 0 else steel_hi
		var sh: Color = haz_sh if i % 2 == 0 else steel_sh
		_armor_plate(img, int(p.x) - 9, int(p.y) - 8, 18, 16, col, hi, sh, false)
		_glow_orb(img, int(p.x), int(p.y), 2, Color("#0088cc"), Color("#28e8ff"), Color.WHITE)

	# Glowing Cyan Plasma Stinger Blade at tip of tail!
	_thick_line(img, Vector2(22, 26), Vector2(4, 34), 3, Color("#28e8ff"), Color.WHITE)
	_glow_orb(img, 16, 28, 5, Color("#0088cc"), Color("#28e8ff"), Color.WHITE)

	# 4 Mechanical Arachnid Legs below thorax
	for lx: int in [52, 68, 84, 98]:
		_thick_line(img, Vector2(lx, 114), Vector2(lx - 10, 136), 3, steel, steel_hi)
		_thick_line(img, Vector2(lx - 10, 136), Vector2(lx - 4, 152), 2, haz, haz_hi)

	# Heavy Armored Scorpion Thorax & Head
	_armor_plate(img, 46, 82, 58, 38, steel, steel_hi, steel_sh)
	_armor_plate(img, 34, 88, 26, 26, haz, haz_hi, haz_sh)
	# Glowing Crimson Optic Visor
	_glow_orb(img, 38, 98, 5, Color("#941c2f"), Color("#ff3854"), Color("#ffe888"))

	# Twin Giant Hydraulic Pincer Claws reaching left!
	# Upper Pincer Arm
	_thick_line(img, Vector2(40, 88), Vector2(22, 70), 4, steel, steel_hi)
	_armor_plate(img, 4, 60, 24, 12, haz, haz_hi, haz_sh, false)
	_rect(img, 4, 72, 18, 5, steel_hi) # Lower jaw of upper claw
	# Lower Pincer Arm
	_thick_line(img, Vector2(40, 112), Vector2(22, 126), 4, steel, steel_hi)
	_armor_plate(img, 4, 122, 24, 12, haz, haz_hi, haz_sh, false)
	_rect(img, 4, 116, 18, 5, steel_hi)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 3: SKY SERPENT "VALKYRIE WYVERN" (114x166 - Winged Mechanical Sky Dragon!)
# =================================================================================
static func _paint_sky_wyvern() -> ImageTexture:
	var img: Image = _new_img(114, 166)
	var aero: Color = Color("#3a78c8")
	var aero_hi: Color = Color("#9ce0ff")
	var aero_sh: Color = Color("#1c3d72")
	var gold: Color = Color("#e8a828")
	var gold_hi: Color = Color("#fff088")

	# Sweeping Upper & Lower Feathered Mecha-Wings!
	for feather: int in range(5):
		var fy_top: int = 10 + feather * 11
		var fy_bot: int = 152 - feather * 11
		var fx: int = 44 + feather * 9
		_thick_line(img, Vector2(68, 72), Vector2(fx, fy_top), 4, aero, aero_hi)
		_thick_line(img, Vector2(fx, fy_top), Vector2(fx + 26, fy_top - 4), 3, gold, gold_hi)
		_thick_line(img, Vector2(68, 94), Vector2(fx, fy_bot), 4, aero, aero_hi)
		_thick_line(img, Vector2(fx, fy_bot), Vector2(fx + 26, fy_bot + 4), 3, gold, gold_hi)

	# Serpentine Armored Body & Neck curving forward
	var spine: Array[Vector2] = [Vector2(98, 118), Vector2(82, 98), Vector2(66, 82), Vector2(48, 70), Vector2(32, 74)]
	for p: Vector2 in spine:
		_circle(img, int(p.x), int(p.y), 14, aero_sh)
		_circle(img, int(p.x), int(p.y), 11, aero)
		_circle(img, int(p.x) - 2, int(p.y) - 3, 6, aero_hi)

	# Fierce Horned Dragon Head & Lightning Maw facing left!
	_armor_plate(img, 8, 64, 30, 18, aero, aero_hi, aero_sh, false)
	_thick_line(img, Vector2(28, 64), Vector2(48, 48), 3, gold, gold_hi) # Swept golden horn
	_rect(img, 10, 84, 24, 7, aero_sh) # Lower jaw
	_glow_orb(img, 18, 80, 5, Color("#0088cc"), Color("#7ce8ff"), Color.WHITE) # Lightning breath core
	_glow_orb(img, 22, 70, 3, Color("#d9381e"), Color("#ffe854"), Color.WHITE) # Dragon eye
	# Chest Valkyrie Reactor
	_glow_orb(img, 58, 86, 8, Color("#d97818"), Color("#ffe854"), Color.WHITE)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 4: EMPEROR STAG-MANTIS (112x164 - Giant Mutant Forest Insectoid!)
# =================================================================================
static func _paint_giant_stag_bug() -> ImageTexture:
	var img: Image = _new_img(112, 164)
	var chit: Color = Color("#1e8c42")
	var chit_hi: Color = Color("#6eff8c")
	var chit_sh: Color = Color("#0d4220")
	var amb: Color = Color("#d98818")
	var amb_hi: Color = Color("#ffe868")

	# Translucent Veined Insectoid Wings fanned top & bottom
	for w_i: int in range(3):
		_thick_line(img, Vector2(64, 74), Vector2(96, 18 + w_i * 16), 6, Color("#185c38"), Color("#4cd97c"))
		_thick_line(img, Vector2(64, 90), Vector2(96, 146 - w_i * 16), 6, Color("#185c38"), Color("#4cd97c"))

	# Segmented Chitinous Bug Abdomen (rear right)
	for seg: int in range(4):
		var sx: int = 62 + seg * 10
		var sy: int = 82 + seg * 5
		_circle(img, sx, sy, 17 - seg, chit_sh)
		_circle(img, sx, sy, 14 - seg, chit)
		_circle(img, sx - 2, sy - 3, 6, chit_hi)

	# Armored Thorax & Insect Head
	_circle(img, 48, 82, 18, chit_sh)
	_circle(img, 48, 82, 15, chit)
	_circle(img, 32, 82, 13, chit_sh)
	_circle(img, 32, 82, 10, chit)

	# Giant Glowing Magenta Compound Bug Eyes!
	_glow_orb(img, 26, 73, 6, Color("#7a1458"), Color("#ff38b8"), Color("#ffc8f0"))
	_glow_orb(img, 26, 91, 6, Color("#7a1458"), Color("#ff38b8"), Color("#ffc8f0"))

	# Huge Serrated Stag-Beetle Mandibles & Mantis Raptorial Scythe Forelegs!
	_thick_line(img, Vector2(24, 72), Vector2(4, 58), 3, amb, amb_hi)
	_thick_line(img, Vector2(24, 92), Vector2(4, 106), 3, amb, amb_hi)
	# Upper Mantis Scythe
	_thick_line(img, Vector2(44, 68), Vector2(22, 38), 4, chit, chit_hi)
	_thick_line(img, Vector2(22, 38), Vector2(6, 52), 3, amb, amb_hi)
	# Lower Mantis Scythe
	_thick_line(img, Vector2(44, 96), Vector2(22, 126), 4, chit, chit_hi)
	_thick_line(img, Vector2(22, 126), Vector2(6, 112), 3, amb, amb_hi)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 5: FROST SERAPH TITAN (110x168 - 6-Winged Crystalline Ice Guardian!)
# =================================================================================
static func _paint_frost_seraph() -> ImageTexture:
	var img: Image = _new_img(110, 168)
	var ice: Color = Color("#3ca8e8")
	var ice_hi: Color = Color("#d4faff")
	var ice_sh: Color = Color("#184e84")

	# 6 Razor-Sharp Crystalline Seraph Wings radiating top, mid, and bottom!
	var wing_tips: Array[Vector2] = [
		Vector2(88, 12), Vector2(102, 42), Vector2(104, 72),
		Vector2(104, 96), Vector2(102, 126), Vector2(88, 156),
		Vector2(28, 22), Vector2(28, 146),
	]
	for tip: Vector2 in wing_tips:
		_thick_line(img, Vector2(56, 84), tip, 5, ice, ice_hi)

	# Faceted Diamond Armor Body & Crowned Ice Helm
	_armor_plate(img, 38, 52, 38, 64, ice, ice_hi, ice_sh)
	_armor_plate(img, 34, 34, 28, 22, ice_hi, Color.WHITE, ice)
	# Crown of 3 Icicle Horns
	_thick_line(img, Vector2(42, 34), Vector2(34, 14), 2, ice_hi, Color.WHITE)
	_thick_line(img, Vector2(48, 32), Vector2(48, 10), 3, ice_hi, Color.WHITE)
	_thick_line(img, Vector2(54, 34), Vector2(62, 16), 2, ice_hi, Color.WHITE)

	# Floating Left Ice Lance Shield & Blazing Sapphire Core
	_armor_plate(img, 12, 66, 16, 36, ice, Color.WHITE, ice_sh, false)
	_glow_orb(img, 52, 84, 11, Color("#0066cc"), Color("#54f0ff"), Color.WHITE)

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 6: INFERNO SKULL "BALROG" (112x168 - Horned Molten Mecha-Skull Colossus!)
# =================================================================================
static func _paint_inferno_skull() -> ImageTexture:
	var img: Image = _new_img(112, 168)
	var obs: Color = Color("#4a2624")
	var obs_hi: Color = Color("#8c483c")
	var obs_sh: Color = Color("#210d0d")
	var bone: Color = Color("#b86848")
	var bone_hi: Color = Color("#f4b888")

	# Massive Sweeping Obsidian Demon Ram Horns (Top & Bottom)!
	_thick_line(img, Vector2(58, 52), Vector2(84, 20), 7, obs, obs_hi)
	_thick_line(img, Vector2(84, 20), Vector2(44, 10), 5, obs, Color("#ff7828"))
	_thick_line(img, Vector2(44, 10), Vector2(18, 24), 3, Color("#ff7828"), Color("#ffe854"))

	_thick_line(img, Vector2(58, 116), Vector2(84, 148), 7, obs, obs_hi)
	_thick_line(img, Vector2(84, 148), Vector2(44, 158), 5, obs, Color("#ff7828"))
	_thick_line(img, Vector2(44, 158), Vector2(18, 144), 3, Color("#ff7828"), Color("#ffe854"))

	# Towering Craggy Cranium & Fanged Jaw
	_circle(img, 60, 74, 32, obs_sh)
	_circle(img, 58, 74, 29, bone)
	_circle(img, 52, 64, 18, bone_hi)
	# Open Lower Magma Jaw + Fangs
	_armor_plate(img, 24, 96, 48, 28, obs, bone, obs_sh, false)
	_rect(img, 26, 86, 36, 14, Color("#ff4814")) # Molten throat glow!
	for fang_x: int in [26, 36, 46, 56]:
		_rect(img, fang_x, 84, 4, 7, Color.WHITE)
		_rect(img, fang_x + 2, 93, 4, 6, Color.WHITE)

	# Blazing Furnace Eye Sockets!
	_glow_orb(img, 36, 68, 8, Color("#b81c0c"), Color("#ff8818"), Color("#ffffaa"))
	_glow_orb(img, 56, 72, 6, Color("#b81c0c"), Color("#ff8818"), Color("#ffffaa"))

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 7: ABYSSAL KRAKEN "CHARYBDIS" (114x168 - 6-Tentacle Bioluminescent Kraken!)
# =================================================================================
static func _paint_abyssal_kraken() -> ImageTexture:
	var img: Image = _new_img(114, 168)
	var teal: Color = Color("#168896")
	var teal_hi: Color = Color("#54f4e8")
	var teal_sh: Color = Color("#093b4a")

	# 6 Writhing Mechanical-Organic Tentacles reaching left across the screen!
	var tent_rows: Array[int] = [22, 46, 70, 98, 122, 146]
	for t_i: int in range(tent_rows.size()):
		var ty: int = tent_rows[t_i]
		var mid_y: int = ty + (-10 if t_i % 2 == 0 else 10)
		_thick_line(img, Vector2(56, 84), Vector2(32, mid_y), 5, teal, teal_hi)
		_thick_line(img, Vector2(32, mid_y), Vector2(8, ty), 3, teal, Color("#ff68b8"))
		_glow_orb(img, 8, ty, 3, Color("#941c68"), Color("#ff54b8"), Color.WHITE)

	# Giant Armored Cephalopod Mantle Hood on the Right
	_circle(img, 76, 84, 34, teal_sh)
	_circle(img, 76, 84, 30, teal)
	_circle(img, 72, 74, 18, teal_hi)
	_armor_plate(img, 46, 58, 36, 52, teal, teal_hi, teal_sh)

	# Giant Hypnotic Bioluminescent Kraken Eye!
	_glow_orb(img, 54, 84, 13, Color("#941c68"), Color("#ffe854"), Color.WHITE)
	_rect(img, 52, 74, 4, 20, Color("#1a0624")) # Vertical Kraken slit pupil!

	return ImageTexture.create_from_image(img)


# =================================================================================
# STAGE 8: NEON MEDUSA OVERMIND (112x174 - Cyber-Gorgon Visage & Serpent Cables!)
# =================================================================================
static func _paint_neon_medusa() -> ImageTexture:
	var img: Image = _new_img(112, 174)
	var chrome: Color = Color("#58388c")
	var chrome_hi: Color = Color("#d8b8ff")
	var chrome_sh: Color = Color("#241046")
	var neon_pink: Color = Color("#ff28c8")
	var neon_cyan: Color = Color("#28f8ff")

	# 8 Coiling Fiber-Optic Neon Serpent "Hair" Cables with glowing Viper Heads!
	var snakes: Array[Vector2] = [
		Vector2(24, 16), Vector2(52, 10), Vector2(84, 20), Vector2(18, 44),
		Vector2(18, 130), Vector2(24, 158), Vector2(52, 164), Vector2(84, 154),
	]
	for i: int in range(snakes.size()):
		var tip: Vector2 = snakes[i]
		var col: Color = neon_pink if i % 2 == 0 else neon_cyan
		var mid: Vector2 = Vector2(58, 87).lerp(tip, 0.55) + Vector2(0, -12 if i < 4 else 12)
		_thick_line(img, Vector2(62, 87), mid, 4, chrome, col)
		_thick_line(img, mid, tip, 3, col, Color.WHITE)
		# Cyber-serpent head at tip
		_glow_orb(img, int(tip.x), int(tip.y), 5, chrome_sh, col, Color.WHITE)

	# Geometric Neon Halo Ring behind Overmind Head
	for ang_i: int in range(24):
		var a: float = TAU * float(ang_i) / 24.0
		_circle(img, 64 + int(cos(a) * 38.0), 87 + int(sin(a) * 38.0), 2, neon_cyan)

	# Sleek Android / Cyber-Gorgon Faceplate & Visor
	_circle(img, 60, 84, 25, chrome_sh)
	_circle(img, 60, 84, 22, chrome)
	_circle(img, 56, 76, 14, chrome_hi)
	_armor_plate(img, 44, 96, 28, 18, chrome, chrome_hi, chrome_sh, false)

	# Blazing Neon-Pink Synthwave Visor across her eyes ("NEON MEDUSA"!)
	_rect(img, 34, 76, 38, 10, Color("#4a0846"))
	_rect(img, 36, 78, 34, 6, neon_pink)
	_rect(img, 38, 80, 28, 2, Color.WHITE)
	# Third-Eye Forehead Diamond Core
	_glow_orb(img, 50, 64, 5, Color("#0088cc"), neon_cyan, Color.WHITE)

	return ImageTexture.create_from_image(img)
