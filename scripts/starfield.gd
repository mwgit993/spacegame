class_name StarfieldBg
extends Node2D

# Renders all 8 themed 16-bit parallax stage environments + the Hyperspace Warp Tunnel!
# 0: Outer Orbit, 1: Starcruiser Interior, 2: Planetary Cloud Base, 3: Xeno Forest,
# 4: Cryo Glacier, 5: Magma Core, 6: Abyssal Trench, 7: Cyber Nexus.

const VIEW_W: float = 480.0
const VIEW_H: float = 270.0

var stage_idx: int = 0
var speed_scale: float = 1.0
var hyperspace_active: bool = false
var hyperspace_progress: float = 0.0

var _stars: Array[Dictionary] = []
var _streaks: Array[Dictionary] = []
var _mid_props: Array[Dictionary] = []
var _pillars: Array[Dictionary] = []
var _ambient: Array[Dictionary] = []
var _grid_offset: float = 0.0
var _time_acc: float = 0.0


func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 199406

	var layer_speeds: Array[float] = [58.0, 130.0, 245.0, 395.0]
	var layer_counts: Array[int] = [42, 36, 26, 18]
	for layer: int in range(4):
		for _i: int in range(layer_counts[layer]):
			_stars.append({
				"x": rng.randf_range(0.0, VIEW_W),
				"y": rng.randf_range(20.0, VIEW_H - 14.0),
				"speed": layer_speeds[layer] * rng.randf_range(0.9, 1.16),
				"layer": layer,
			})

	for i: int in range(18):
		_streaks.append({
			"x": rng.randf_range(0.0, VIEW_W),
			"y": rng.randf_range(22.0, VIEW_H - 16.0),
			"len": rng.randf_range(12.0, 28.0),
			"speed": rng.randf_range(480.0, 680.0),
			"alt": (i % 2 == 0),
		})

	for i: int in range(7):
		_mid_props.append({
			"x": float(i) * 82.0,
			"y": rng.randf_range(44.0, 196.0),
			"w": rng.randf_range(46.0, 96.0),
			"h": rng.randf_range(14.0, 28.0),
			"speed": rng.randf_range(65.0, 105.0),
		})

	for i: int in range(10):
		_pillars.append({
			"x": float(i) * 54.0,
			"h": rng.randf_range(14.0, 36.0),
			"top_h": rng.randf_range(10.0, 26.0),
			"w": rng.randf_range(16.0, 32.0),
		})

	for _i: int in range(28):
		_ambient.append({
			"x": rng.randf_range(0.0, VIEW_W),
			"y": rng.randf_range(24.0, VIEW_H - 18.0),
			"vx": rng.randf_range(-120.0, -45.0),
			"vy": rng.randf_range(-28.0, -8.0),
			"phase": rng.randf_range(0.0, TAU),
		})


func set_stage(new_stage_idx: int) -> void:
	stage_idx = posmod(new_stage_idx, 8)


func _process(delta: float) -> void:
	_time_acc += delta
	var warp_mult: float = 3.8 if hyperspace_active else 1.0
	var dt: float = delta * speed_scale * warp_mult

	for s: Dictionary in _stars:
		var nx: float = float(s["x"]) - float(s["speed"]) * dt
		if nx < -80.0:
			nx += VIEW_W + 96.0
			s["y"] = randf_range(20.0, VIEW_H - 14.0)
		s["x"] = nx

	for st: Dictionary in _streaks:
		var nx: float = float(st["x"]) - float(st["speed"]) * dt
		if nx < -140.0:
			nx = VIEW_W + randf_range(10.0, 70.0)
			st["y"] = randf_range(22.0, VIEW_H - 16.0)
		st["x"] = nx

	for m: Dictionary in _mid_props:
		var nx: float = float(m["x"]) - float(m["speed"]) * dt
		var w: float = float(m["w"])
		if nx < -w - 20.0:
			nx = VIEW_W + randf_range(12.0, 48.0)
			m["y"] = randf_range(44.0, 198.0)
		m["x"] = nx

	for p: Dictionary in _pillars:
		var nx: float = float(p["x"]) - 175.0 * dt
		if nx < -42.0:
			nx += 10.0 * 54.0
		p["x"] = nx

	for a: Dictionary in _ambient:
		var ax: float = float(a["x"]) + float(a["vx"]) * delta * speed_scale
		var ay: float = float(a["y"]) + float(a["vy"]) * delta
		if ax < -8.0:
			ax = VIEW_W + 8.0
		if ay < 20.0:
			ay = VIEW_H - 16.0
		elif ay > VIEW_H - 14.0:
			ay = 22.0
		a["x"] = ax
		a["y"] = ay

	_grid_offset = fmod(_grid_offset + 290.0 * dt, 24.0)
	queue_redraw()


func _draw() -> void:
	var st: Dictionary = StageData.get_stage(stage_idx)
	var id: String = String(st["id"])

	# 1) Sky Gradient
	draw_rect(Rect2(0.0, 0.0, VIEW_W, VIEW_H), st["sky_top"])
	draw_rect(Rect2(0.0, 110.0, VIEW_W, 160.0), st["sky_mid"])
	draw_rect(Rect2(0.0, 196.0, VIEW_W, 74.0), st["sky_bot"])

	# 2) Biome-Specific Midground Scenery
	match id:
		"space":
			_draw_space_scenery()
		"starcruiser":
			_draw_starcruiser_scenery()
		"planet_base":
			_draw_planet_base_scenery()
		"forest":
			_draw_forest_scenery()
		"ice":
			_draw_ice_scenery()
		"volcano":
			_draw_volcano_scenery()
		"abyss":
			_draw_abyss_scenery()
		"cyber":
			_draw_cyber_scenery()

	# 3) Floor & Optional Ceiling Deck
	_draw_stage_decks(st, id)

	# 4) Hyperspace Warp Tunnel Overlay!
	if hyperspace_active:
		_draw_hyperspace_tunnel()


func _draw_space_scenery() -> void:
	for m: Dictionary in _mid_props:
		var x: float = floorf(float(m["x"]))
		var y: float = floorf(float(m["y"]))
		var w: float = floorf(float(m["w"]))
		var h: float = floorf(float(m["h"]))
		draw_rect(Rect2(x, y, w, h), Color(0.18, 0.08, 0.34, 0.24))
	_draw_fast_stars(Color("#6088d8"), Color("#ffffff"))
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		var ph: float = floorf(float(p["h"]) * 0.55)
		draw_rect(Rect2(px, 258.0 - ph, floorf(float(p["w"])), ph), Color("#132044"))


func _draw_starcruiser_scenery() -> void:
	# Interior corridor conduit pipes & glowing reactor windows
	draw_rect(Rect2(0.0, 62.0, VIEW_W, 6.0), Color("#1e293d"))
	draw_rect(Rect2(0.0, 204.0, VIEW_W, 6.0), Color("#1e293d"))
	for m: Dictionary in _mid_props:
		var x: float = floorf(float(m["x"]))
		draw_rect(Rect2(x, 86.0, 38.0, 92.0), Color("#081424"))
		draw_rect(Rect2(x + 2.0, 88.0, 34.0, 88.0), Color(0.12, 0.65, 0.95, 0.22))
	# Rushing vertical steel I-beams
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		draw_rect(Rect2(px, 28.0, 10.0, 230.0), Color("#1a2233"))
		draw_rect(Rect2(px + 2.0, 28.0, 2.0, 230.0), Color("#2f3e5c"))
	_draw_fast_stars(Color("#ff9624"), Color("#ffe888"))


func _draw_planet_base_scenery() -> void:
	# Giant alien moon & curved bright planetary atmosphere horizon
	draw_circle(Vector2(370.0, 72.0), 28.0, Color(0.55, 0.82, 1.0, 0.28))
	draw_circle(Vector2(364.0, 68.0), 24.0, Color(0.12, 0.28, 0.54, 0.45))
	draw_rect(Rect2(0.0, 224.0, VIEW_W, 34.0), Color(0.45, 0.85, 1.0, 0.22))
	# Fast 16-bit cumulus cloud decks
	for m: Dictionary in _mid_props:
		var x: float = floorf(float(m["x"]))
		var y: float = floorf(float(m["y"]))
		var w: float = floorf(float(m["w"]) * 1.2)
		draw_rect(Rect2(x, y, w, 12.0), Color(0.78, 0.92, 1.0, 0.35))
		draw_rect(Rect2(x + 10.0, y - 5.0, w - 20.0, 8.0), Color(0.92, 0.98, 1.0, 0.42))
	# Surface citadel spires along planet base
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		var ph: float = floorf(float(p["h"]))
		draw_rect(Rect2(px, 258.0 - ph, 14.0, ph), Color("#182c4d"))
		draw_rect(Rect2(px + 5.0, 258.0 - ph - 8.0, 4.0, 8.0), Color("#38689c"))


func _draw_forest_scenery() -> void:
	# Parallax giant alien tree trunks
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		var tw: float = floorf(float(p["w"]) * 0.7)
		draw_rect(Rect2(px, 28.0, tw, 230.0), Color("#0c2418"))
		draw_rect(Rect2(px + 2.0, 28.0, 3.0, 230.0), Color("#18452c"))
	# Canopy leaf clusters
	for m: Dictionary in _mid_props:
		var x: float = floorf(float(m["x"]))
		draw_rect(Rect2(x, 28.0, 56.0, 14.0), Color("#164f2c"))
		draw_rect(Rect2(x + 8.0, 246.0, 56.0, 14.0), Color("#1a5c32"))
	# Glowing floating bio-spores
	for a: Dictionary in _ambient:
		var ax: float = floorf(float(a["x"]))
		var ay: float = floorf(float(a["y"]))
		draw_rect(Rect2(ax, ay, 2.0, 2.0), Color("#6eff9c"))


func _draw_ice_scenery() -> void:
	# Shimmering Aurora Borealis ribbons
	for i: int in range(5):
		var ay: float = 46.0 + float(i) * 8.0 + sin(_time_acc * 2.0 + float(i)) * 4.0
		draw_rect(Rect2(0.0, floorf(ay), VIEW_W, 4.0), Color(0.20, 0.95, 0.78, 0.12))
	# Jagged crystal icebergs & ceiling icicles
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		var ph: float = floorf(float(p["h"]))
		var th: float = floorf(float(p["top_h"]))
		var pts_bot: PackedVector2Array = PackedVector2Array([
			Vector2(px, 258.0), Vector2(px + 12.0, 258.0 - ph), Vector2(px + 24.0, 258.0)
		])
		draw_colored_polygon(pts_bot, Color("#245c8f"))
		var pts_top: PackedVector2Array = PackedVector2Array([
			Vector2(px + 4.0, 28.0), Vector2(px + 12.0, 28.0 + th), Vector2(px + 20.0, 28.0)
		])
		draw_colored_polygon(pts_top, Color("#3478b0"))
	_draw_fast_stars(Color("#88e8ff"), Color("#ffffff"))


func _draw_volcano_scenery() -> void:
	# Volcano cones & jagged obsidian stalactites
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		var ph: float = floorf(float(p["h"]) * 1.1)
		var th: float = floorf(float(p["top_h"]))
		var cone: PackedVector2Array = PackedVector2Array([
			Vector2(px - 8.0, 258.0), Vector2(px + 10.0, 258.0 - ph), Vector2(px + 28.0, 258.0)
		])
		draw_colored_polygon(cone, Color("#2b0d0e"))
		var stal: PackedVector2Array = PackedVector2Array([
			Vector2(px, 28.0), Vector2(px + 9.0, 28.0 + th), Vector2(px + 18.0, 28.0)
		])
		draw_colored_polygon(stal, Color("#361112"))
	# Rising glowing magma embers
	for a: Dictionary in _ambient:
		var ax: float = floorf(float(a["x"]))
		var ay: float = floorf(float(a["y"]))
		draw_rect(Rect2(ax, ay, 2.0, 2.0), Color("#ff9624"))
		draw_rect(Rect2(ax, ay, 1.0, 1.0), Color("#ffe854"))


func _draw_abyss_scenery() -> void:
	# Underwater light shafts
	for i: int in range(4):
		var lx: float = fmod(90.0 + float(i) * 115.0 - _grid_offset * 1.5 + VIEW_W, VIEW_W)
		var beam: PackedVector2Array = PackedVector2Array([
			Vector2(lx, 22.0), Vector2(lx + 26.0, 22.0), Vector2(lx - 18.0, 258.0), Vector2(lx - 48.0, 258.0)
		])
		draw_colored_polygon(beam, Color(0.20, 0.88, 0.92, 0.09))
	# Sunken temple columns
	for p: Dictionary in _pillars:
		var px: float = floorf(float(p["x"]))
		var ph: float = floorf(float(p["h"]))
		draw_rect(Rect2(px, 258.0 - ph, 12.0, ph), Color("#0c324a"))
	# Rising shimmering bubbles
	for a: Dictionary in _ambient:
		var ax: float = floorf(float(a["x"]))
		var ay: float = floorf(float(a["y"]))
		draw_rect(Rect2(ax, ay, 3.0, 3.0), Color(0.35, 0.95, 1.0, 0.55))
		draw_rect(Rect2(ax + 1.0, ay + 1.0, 1.0, 1.0), Color.WHITE)


func _draw_cyber_scenery() -> void:
	# Neon circuit monoliths & fast data packets
	for m: Dictionary in _mid_props:
		var x: float = floorf(float(m["x"]))
		var y: float = floorf(float(m["y"]))
		draw_rect(Rect2(x, y, 42.0, 2.0), Color(0.16, 0.92, 1.0, 0.45))
		draw_rect(Rect2(x, y, 4.0, 14.0), Color(1.0, 0.22, 0.82, 0.40))
	_draw_fast_stars(Color("#28e8ff"), Color("#ff4cd4"))


func _draw_fast_stars(mid_col: Color, bright_col: Color) -> void:
	for s: Dictionary in _stars:
		var sx: float = floorf(float(s["x"]))
		var sy: float = floorf(float(s["y"]))
		var layer: int = int(s["layer"])
		if layer == 3:
			draw_rect(Rect2(sx, sy, clampf(4.0 * speed_scale, 2.0, 8.0), 1.0), bright_col)
		elif layer == 2:
			draw_rect(Rect2(sx, sy, 2.0, 1.0), mid_col)
		else:
			draw_rect(Rect2(sx, sy, 1.0, 1.0), Color(mid_col.r, mid_col.g, mid_col.b, 0.55))

	if speed_scale > 0.6:
		for st: Dictionary in _streaks:
			var sx: float = floorf(float(st["x"]))
			var sy: float = floorf(float(st["y"]))
			var sl: float = floorf(float(st["len"]))
			var c: Color = bright_col if bool(st["alt"]) else mid_col
			draw_rect(Rect2(sx, sy, sl, 1.0), Color(c.r, c.g, c.b, 0.50))


func _draw_stage_decks(st: Dictionary, id: String) -> void:
	var fill: Color = st["deck_fill"]
	var line_col: Color = st["deck_line"]

	# Bottom deck / terrain flush with bottom of screen (y = 258..270)
	var deck_y: float = 258.0
	draw_rect(Rect2(0.0, deck_y, VIEW_W, 12.0), fill)
	draw_line(Vector2(0.0, deck_y), Vector2(VIEW_W, deck_y), line_col, 1.0)

	var gx: float = -_grid_offset
	while gx < VIEW_W + 24.0:
		var ix: float = floorf(gx)
		if id == "volcano":
			draw_rect(Rect2(ix, deck_y + 1.0, 12.0, 3.0), Color("#ffe854"))
		else:
			draw_line(Vector2(ix, deck_y + 1.0), Vector2(ix - 8.0, 270.0), line_col.darkened(0.35), 1.0)
		gx += 24.0

	# Top ceiling deck on enclosed stages (sits cleanly below y = 19..22 XP bar)
	if bool(st["has_ceiling"]):
		var ceil_y: float = 28.0
		draw_rect(Rect2(0.0, 22.0, VIEW_W, 6.0), fill)
		draw_line(Vector2(0.0, ceil_y), Vector2(VIEW_W, ceil_y), line_col, 1.0)
		var cx: float = -_grid_offset
		while cx < VIEW_W + 24.0:
			var icx: float = floorf(cx)
			draw_line(Vector2(icx, 23.0), Vector2(icx + 8.0, ceil_y), line_col.darkened(0.35), 1.0)
			cx += 24.0


func _draw_hyperspace_tunnel() -> void:
	var intensity: float = sin(clampf(hyperspace_progress, 0.0, 1.0) * PI)
	for st: Dictionary in _streaks:
		var sx: float = floorf(float(st["x"]))
		var sy: float = floorf(float(st["y"]))
		var warp_len: float = float(st["len"]) * (2.5 + 4.5 * intensity)
		var col: Color = Color("#ffffff") if bool(st["alt"]) else Color("#28e8ff")
		draw_rect(Rect2(sx, sy, warp_len, 2.0), Color(col.r, col.g, col.b, 0.85 * intensity))

	# Peak hyperspace flash right when jumping into the new stage!
	var flash: float = maxf(0.0, 1.0 - absf(hyperspace_progress - 0.55) * 5.5)
	if flash > 0.01:
		draw_rect(Rect2(0.0, 19.0, VIEW_W, VIEW_H - 19.0), Color(0.82, 0.96, 1.0, flash * 0.88))
