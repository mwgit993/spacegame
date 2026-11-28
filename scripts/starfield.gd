class_name StarfieldBg
extends Node2D

# Renders the themed 16-bit parallax stage environments + the Hyperspace Warp Tunnel.
# Built in: 0: Outer Orbit, 1: Starcruiser Interior, 2: Planetary Cloud Base, 3: Xeno Forest,
# 4: Cryo Glacier, 5: Magma Core, 6: Abyssal Trench, 7: Cyber Nexus. Stages 9+ are stage
# modules: their theme key is the stage id, the module paints the still layers
# (paint_background) and a background object (scripts/stages/stage_background.gd) animates
# and draws them through the same cache, prebuild and helpers.
#
# Static layers (sky, skylines, trees, pipes...) are pre-rendered once per stage by
# stage_bg_painter.gd into textures and scrolled at different parallax speeds. Only the animated
# parts (particles, swaying plants, rare "events" such as comets or eruptions) are drawn per
# frame. The next stage's textures are built on a worker thread while the current one plays.
#
# Readability rule: the playfield (y 30..249) stays dark and low in contrast; bright or busy
# detail lives at the top/bottom edges, in far layers, or in short bursts.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const VIEW_W: float = 480.0
const VIEW_H: float = 270.0
const SCROLL_PX: float = 100.0  # a layer with parallax factor 1.0 moves this many px/s at speed_scale 1
const THEMES: Array[String] = ["space", "starcruiser", "planet_base", "forest", "ice", "volcano", "abyss", "cyber"]
const FX_CAP: int = 120

enum Fx { STEAM, SPARK, BOMB, SMOKE, BUBBLE_POP, DROPLET }

var stage_idx: int = 0
var speed_scale: float = 1.0
var hyperspace_active: bool = false
var hyperspace_progress: float = 0.0

var _theme: String = ""
var _scroll: float = 0.0  # accumulated scroll distance in px at parallax factor 1.0
var _life: float = 0.0    # ambient animation clock (slows on pause instead of stopping)
var _ds: float = 0.0      # this frame's scroll step
var _dl: float = 0.0      # this frame's ambient step
var _grid_offset: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _streaks: Array[Dictionary] = []

# Texture cache: theme -> {"tex": Dictionary[String, Texture2D], "meta": Dictionary}
var _cache: Dictionary = {}
var _tex: Dictionary[String, Texture2D] = {}
var _meta: Dictionary = {}
var _pending_theme: String = ""
var _pending_task: int = -1
var _pending_result: Dictionary = {}

# The active stage module's background animator (null on stages 1-8).
var _module_bg: RefCounted = null

# Drifting particle sets (snow, embers, spores, bubbles...).
var _drift_a: Drift = Drift.new()
var _drift_b: Drift = Drift.new()

# Generic per-stage props (asteroids, crates, jellyfish, platforms...).
var _props: Props = Props.new()
var _props_b: Props = Props.new()

# Rare events. Each stage decides what its slots mean.
var _ev_a: Ev = Ev.new()
var _ev_b: Ev = Ev.new()
var _ev_c: Ev = Ev.new()

# Short-lived effect particles shared by all stages (steam, sparks, lava bombs, bubbles).
var _fx_n: int = 0
var _fx_x: PackedFloat32Array = PackedFloat32Array()
var _fx_y: PackedFloat32Array = PackedFloat32Array()
var _fx_vx: PackedFloat32Array = PackedFloat32Array()
var _fx_vy: PackedFloat32Array = PackedFloat32Array()
var _fx_age: PackedFloat32Array = PackedFloat32Array()
var _fx_life: PackedFloat32Array = PackedFloat32Array()
var _fx_par: PackedFloat32Array = PackedFloat32Array()
var _fx_kind: PackedInt32Array = PackedInt32Array()

var _vent_timer: float = 0.0
var _small_timer: float = 0.0
var _glint_idx: PackedInt32Array = PackedInt32Array()
var _glint_t: PackedFloat32Array = PackedFloat32Array()
var _glitch_bands: PackedVector3Array = PackedVector3Array()
var _bolt: PackedVector2Array = PackedVector2Array()


class Drift:
	var x: PackedFloat32Array = PackedFloat32Array()
	var y: PackedFloat32Array = PackedFloat32Array()
	var vx: PackedFloat32Array = PackedFloat32Array()
	var vy: PackedFloat32Array = PackedFloat32Array()
	var ph: PackedFloat32Array = PackedFloat32Array()
	var par: float = 0.0       # how much of the scroll it follows
	var y0: float = 30.0
	var y1: float = 256.0
	var sway: float = 0.0
	var sway_hz: float = 1.0
	var size: float = 1.0
	var blink: float = 0.0     # on/off cycles per second (0 = steady)
	var duty: float = 1.0
	var wind: float = 0.0      # extra horizontal px/s applied to all
	var cols: PackedColorArray = PackedColorArray()

	func setup(n: int, rng: RandomNumberGenerator, vx0: float, vx1: float, vy0: float, vy1: float) -> void:
		x.resize(n)
		y.resize(n)
		vx.resize(n)
		vy.resize(n)
		ph.resize(n)
		for i: int in range(n):
			x[i] = rng.randf_range(0.0, 480.0)
			y[i] = rng.randf_range(y0, y1)
			vx[i] = rng.randf_range(vx0, vx1)
			vy[i] = rng.randf_range(vy0, vy1)
			ph[i] = rng.randf_range(0.0, TAU)

	func clear() -> void:
		x.resize(0)
		y.resize(0)
		vx.resize(0)
		vy.resize(0)
		ph.resize(0)
		cols = PackedColorArray()
		wind = 0.0
		blink = 0.0
		sway = 0.0


class Props:
	var x: PackedFloat32Array = PackedFloat32Array()
	var y: PackedFloat32Array = PackedFloat32Array()
	var f: PackedFloat32Array = PackedFloat32Array()
	var k: PackedInt32Array = PackedInt32Array()
	var p: PackedFloat32Array = PackedFloat32Array()

	func resize(n: int) -> void:
		x.resize(n)
		y.resize(n)
		f.resize(n)
		k.resize(n)
		p.resize(n)


class Ev:
	var on: bool = false
	var t: float = 0.0       # elapsed while on, countdown while off
	var dur: float = 1.0
	var x: float = 0.0
	var y: float = 0.0
	var vx: float = 0.0
	var vy: float = 0.0
	var k: int = 0
	var lo: float = 10.0
	var hi: float = 20.0

	func arm(rng: RandomNumberGenerator, wait_lo: float, wait_hi: float, first_lo: float, first_hi: float) -> void:
		on = false
		lo = wait_lo
		hi = wait_hi
		t = rng.randf_range(first_lo, first_hi)

	# Advances the timer. Returns true on the frame the event should start.
	func tick(dl: float, rng: RandomNumberGenerator) -> bool:
		if on:
			t += dl
			if t >= dur:
				on = false
				t = rng.randf_range(lo, hi)
			return false
		if hi <= 0.0:
			return false
		t -= dl
		if t <= 0.0:
			on = true
			t = 0.0
			return true
		return false


func _ready() -> void:
	_rng.randomize()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 199406
	for i: int in range(18):
		_streaks.append({
			"x": rng.randf_range(0.0, VIEW_W),
			"y": rng.randf_range(22.0, VIEW_H - 16.0),
			"len": rng.randf_range(12.0, 28.0),
			"speed": rng.randf_range(480.0, 680.0),
			"alt": (i % 2 == 0),
		})
	_fx_x.resize(FX_CAP)
	_fx_y.resize(FX_CAP)
	_fx_vx.resize(FX_CAP)
	_fx_vy.resize(FX_CAP)
	_fx_age.resize(FX_CAP)
	_fx_life.resize(FX_CAP)
	_fx_par.resize(FX_CAP)
	_fx_kind.resize(FX_CAP)
	_activate_theme(_theme_for(stage_idx))


func _exit_tree() -> void:
	if _pending_task != -1:
		WorkerThreadPool.wait_for_task_completion(_pending_task)
		_pending_task = -1


## The stage the run plays next (main sets it: the order is shuffled), so its background is
## prebuilt while this one plays. -1 means the one after this in order.
var next_stage_idx: int = -1


func _next_stage() -> int:
	return next_stage_idx if next_stage_idx >= 0 else stage_idx + 1


func set_stage(new_stage_idx: int) -> void:
	stage_idx = StageData.wrap_stage(new_stage_idx)
	var theme: String = _theme_for(stage_idx)
	if theme != _theme:
		_activate_theme(theme)


func _theme_for(idx: int) -> String:
	var id: String = String(StageData.get_stage(idx).get("id", ""))
	if THEMES.has(id) or StageData.is_module_stage(idx):
		return id
	return THEMES[posmod(idx, THEMES.size())]


# Paints a theme's still layers: the built-in painter, or the stage module's. Pure, so it runs
# on the prebuild worker thread too (the module is looked up on the main thread first).
static func _paint_theme(theme: String, module: RefCounted) -> Dictionary:
	if module != null:
		return module.call("paint_background")
	return Painter.build(theme)


# The stage module behind a theme (null for the built-in themes, without asking StageData).
func _theme_module(theme: String) -> RefCounted:
	if THEMES.has(theme):
		return null
	return StageData.get_module_by_id(theme)


# ---------------------------------------------------------------------------------------------
# Texture cache + background prebuild of the next stage
# ---------------------------------------------------------------------------------------------

func _activate_theme(theme: String) -> void:
	if not _cache.has(theme):
		if _pending_task != -1:
			WorkerThreadPool.wait_for_task_completion(_pending_task)
			_pending_task = -1
			_store_theme(_pending_theme, _pending_result)
			_pending_result = {}
		if not _cache.has(theme):
			_store_theme(theme, _paint_theme(theme, _theme_module(theme)))
	var entry: Dictionary = _cache[theme]
	_tex = entry["tex"]
	_meta = entry["meta"]
	_theme = theme
	_module_bg = null
	var module: RefCounted = _theme_module(theme)
	if module != null:
		_module_bg = module.call("create_background")
		_module_bg.set("bg", self)
	_evict_cache()
	_reset_theme_state()


func _store_theme(theme: String, built: Dictionary) -> void:
	var tex: Dictionary[String, Texture2D] = {}
	var meta: Dictionary = {}
	for key: Variant in built.keys():
		var val: Variant = built[key]
		if val is Image:
			tex[String(key)] = ImageTexture.create_from_image(val as Image)
		else:
			meta[String(key)] = val
	_cache[theme] = {"tex": tex, "meta": meta}


func _evict_cache() -> void:
	# Keep the current stage, the next one and the title stage; rebuild the rest on demand.
	var keep: Array[String] = [_theme, _theme_for(_next_stage()), _theme_for(0)]
	for key: Variant in _cache.keys():
		if not keep.has(String(key)):
			_cache.erase(key)


func _thread_build(theme: String, module: RefCounted) -> void:
	_pending_result = _paint_theme(theme, module)


func _poll_prebuild() -> void:
	if _pending_task != -1:
		if WorkerThreadPool.is_task_completed(_pending_task):
			WorkerThreadPool.wait_for_task_completion(_pending_task)
			_pending_task = -1
			_store_theme(_pending_theme, _pending_result)
			_pending_result = {}
		return
	var next_theme: String = _theme_for(_next_stage())
	if not _cache.has(next_theme):
		_pending_theme = next_theme
		_pending_task = WorkerThreadPool.add_task(_thread_build.bind(next_theme, _theme_module(next_theme)), false, "Stage background prebuild")


# ---------------------------------------------------------------------------------------------
# Per-theme state
# ---------------------------------------------------------------------------------------------

func _reset_theme_state() -> void:
	_drift_a.clear()
	_drift_b.clear()
	_props.resize(0)
	_props_b.resize(0)
	_ev_a.arm(_rng, 0.0, 0.0, 0.0, 0.0)
	_ev_b.arm(_rng, 0.0, 0.0, 0.0, 0.0)
	_ev_c.arm(_rng, 0.0, 0.0, 0.0, 0.0)
	_fx_n = 0
	_glint_idx.resize(0)
	_glint_t.resize(0)
	_glitch_bands.resize(0)
	match _theme:
		"space":
			# mid asteroids
			_props.resize(9)
			for i: int in range(9):
				_respawn_asteroid(i, _rng.randf_range(0.0, VIEW_W + 120.0))
			# near foreground rocks along the bottom
			_props_b.resize(3)
			for j: int in range(3):
				_props_b.x[j] = float(j) * 260.0 + _rng.randf_range(0.0, 120.0)
				_props_b.y[j] = _rng.randf_range(248.0, 258.0)
				_props_b.k[j] = j % 3
			_ev_a.arm(_rng, 12.0, 24.0, 3.0, 7.0)    # comet
			_ev_b.arm(_rng, 0.35, 1.6, 0.5, 1.0)     # battle flash
			_ev_c.arm(_rng, 2.0, 5.0, 1.0, 3.0)      # laser volley
		"starcruiser":
			_props.resize(5)
			for i2: int in range(5):
				_props.x[i2] = float(i2) * 110.0 + _rng.randf_range(0.0, 60.0)
				_props.k[i2] = _rng.randi_range(0, 1)
			_ev_a.arm(_rng, 24.0, 38.0, 8.0, 14.0)   # red alert
			_ev_b.arm(_rng, 4.0, 10.0, 2.0, 5.0)     # conduit sparks
		"planet_base":
			_ev_a.arm(_rng, 7.0, 14.0, 2.0, 5.0)     # bird flock
			_ev_b.arm(_rng, 18.0, 30.0, 6.0, 12.0)   # airship
			_ev_c.arm(_rng, 13.0, 24.0, 5.0, 9.0)    # distant lightning
		"forest":
			_drift_a.y0 = 34.0
			_drift_a.y1 = 252.0
			_drift_a.setup(40, _rng, -8.0, -2.0, -9.0, -3.0)
			_drift_a.par = 0.35
			_drift_a.sway = 2.0
			_drift_a.sway_hz = 0.9
			_drift_a.cols = PackedColorArray([Color(0.25, 0.6, 0.45, 0.55), Color(0.3, 0.72, 0.55, 0.5), Color(0.2, 0.45, 0.4, 0.6)])
			_drift_b.y0 = 40.0
			_drift_b.y1 = 250.0
			_drift_b.setup(16, _rng, -10.0, 10.0, -6.0, 6.0)
			_drift_b.par = 0.5
			_drift_b.sway = 6.0
			_drift_b.sway_hz = 0.6
			_drift_b.blink = 0.35
			_drift_b.duty = 0.35
			_drift_b.cols = PackedColorArray([Color("#b8f060"), Color("#7cf0a0")])
			_ev_a.arm(_rng, 11.0, 18.0, 4.0, 8.0)    # bioluminescent pulse wave
			_ev_b.arm(_rng, 22.0, 36.0, 9.0, 15.0)   # giant moth
		"ice":
			_drift_a.y0 = 30.0
			_drift_a.y1 = 256.0
			_drift_a.setup(70, _rng, -22.0, -12.0, 10.0, 20.0)
			_drift_a.par = 0.15
			_drift_a.sway = 1.5
			_drift_a.sway_hz = 0.7
			_drift_a.cols = PackedColorArray([Color(0.4, 0.52, 0.72, 0.65), Color(0.48, 0.6, 0.8, 0.55)])
			_drift_b.y0 = 30.0
			_drift_b.y1 = 256.0
			_drift_b.setup(30, _rng, -40.0, -26.0, 30.0, 46.0)
			_drift_b.par = 0.55
			_drift_b.sway = 3.0
			_drift_b.sway_hz = 1.1
			_drift_b.cols = PackedColorArray([Color(0.66, 0.78, 0.92, 0.7), Color(0.55, 0.68, 0.85, 0.7)])
			_glint_idx.resize(4)
			_glint_t.resize(4)
			for g: int in range(4):
				_glint_idx[g] = -1
			_ev_a.arm(_rng, 17.0, 28.0, 8.0, 14.0)   # blizzard gust
		"volcano":
			_drift_a.y0 = 34.0
			_drift_a.y1 = 252.0
			_drift_a.setup(46, _rng, -14.0, 6.0, -48.0, -18.0)
			_drift_a.par = 0.3
			_drift_a.sway = 3.0
			_drift_a.sway_hz = 1.3
			_drift_a.blink = 1.7
			_drift_a.duty = 0.7
			_drift_a.cols = PackedColorArray([Color(1.0, 0.55, 0.15, 0.6), Color(1.0, 0.78, 0.3, 0.5), Color(0.8, 0.25, 0.08, 0.7)])
			_drift_b.y0 = 34.0
			_drift_b.y1 = 252.0
			_drift_b.setup(26, _rng, -12.0, -4.0, 6.0, 14.0)
			_drift_b.par = 0.4
			_drift_b.sway = 2.0
			_drift_b.sway_hz = 0.8
			_drift_b.cols = PackedColorArray([Color(0.22, 0.13, 0.12, 0.8), Color(0.3, 0.18, 0.15, 0.7)])
			_ev_a.arm(_rng, 9.0, 16.0, 3.0, 6.0)     # eruption
		"abyss":
			_drift_a.y0 = 40.0
			_drift_a.y1 = 258.0
			_drift_a.setup(22, _rng, -4.0, 4.0, -34.0, -18.0)
			_drift_a.par = 0.3
			_drift_a.sway = 2.5
			_drift_a.sway_hz = 1.6
			_drift_a.cols = PackedColorArray([Color(0.35, 0.7, 0.85, 0.55), Color(0.5, 0.82, 0.92, 0.45)])
			_drift_b.y0 = 30.0
			_drift_b.y1 = 256.0
			_drift_b.setup(40, _rng, -6.0, -2.0, 3.0, 8.0)
			_drift_b.par = 0.2
			_drift_b.sway = 1.0
			_drift_b.sway_hz = 0.5
			_drift_b.cols = PackedColorArray([Color(0.2, 0.32, 0.42, 0.7), Color(0.26, 0.4, 0.5, 0.6)])
			# drifting jellyfish
			_props.resize(4)
			for i3: int in range(4):
				_props.x[i3] = _rng.randf_range(0.0, VIEW_W)
				_props.y[i3] = _rng.randf_range(60.0, 240.0)
				_props.f[i3] = _rng.randf_range(0.1, 0.22)
				_props.p[i3] = _rng.randf_range(0.0, TAU)
			_ev_a.arm(_rng, 24.0, 38.0, 6.0, 12.0)   # leviathan
			_ev_b.arm(_rng, 9.0, 16.0, 3.0, 6.0)     # fish school
		"cyber":
			_props.resize(14)
			for i4: int in range(14):
				_props.x[i4] = float(i4) * 46.0 + _rng.randf_range(0.0, 30.0)
				_props.f[i4] = _rng.randf_range(18.0, 46.0)
				_props.p[i4] = _rng.randf_range(0.0, 256.0)
			_ev_a.arm(_rng, 5.0, 11.0, 3.0, 6.0)     # glitch
			_ev_b.arm(_rng, 13.0, 22.0, 6.0, 10.0)   # scan sweep
		_:
			if _module_bg != null:
				_module_bg.call("reset")


func _respawn_asteroid(i: int, x: float) -> void:
	_props.x[i] = x
	var r: float = _rng.randf()
	if r < 0.35:
		_props.y[i] = _rng.randf_range(38.0, 74.0)
	elif r < 0.7:
		_props.y[i] = _rng.randf_range(180.0, 226.0)
	else:
		_props.y[i] = _rng.randf_range(74.0, 180.0)
	_props.f[i] = _rng.randf_range(0.4, 0.95)
	_props.k[i] = _rng.randi_range(0, 5)
	_props.p[i] = _rng.randf_range(0.0, 8.0)


# ---------------------------------------------------------------------------------------------
# Update
# ---------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var warp_mult: float = 3.8 if hyperspace_active else 1.0
	var dt: float = delta * speed_scale * warp_mult
	_ds = SCROLL_PX * dt
	_scroll += _ds
	_dl = delta * clampf(0.3 + 0.7 * speed_scale, 0.3, 1.25)
	_life += _dl

	for st: Dictionary in _streaks:
		var nx: float = float(st["x"]) - float(st["speed"]) * dt
		if nx < -140.0:
			nx = VIEW_W + _rng.randf_range(10.0, 70.0)
			st["y"] = _rng.randf_range(22.0, VIEW_H - 16.0)
		st["x"] = nx

	_grid_offset = fmod(_grid_offset + 290.0 * dt, 24.0)

	_drift_update(_drift_a)
	_drift_update(_drift_b)
	_fx_update()
	match _theme:
		"space":
			_update_space()
		"starcruiser":
			_update_starcruiser()
		"planet_base":
			_update_cloud()
		"forest":
			_update_forest()
		"ice":
			_update_ice()
		"volcano":
			_update_volcano()
		"abyss":
			_update_abyss()
		"cyber":
			_update_cyber()
		_:
			if _module_bg != null:
				_module_bg.call("update")
	_poll_prebuild()
	queue_redraw()


func _drift_update(p: Drift) -> void:
	var n: int = p.x.size()
	if n == 0:
		return
	var sdx: float = _ds * p.par
	var span_y: float = p.y1 - p.y0
	for i: int in range(n):
		var nx: float = p.x[i] + (p.vx[i] + p.wind) * _dl - sdx
		var ny: float = p.y[i] + p.vy[i] * _dl
		if nx < -8.0:
			nx += VIEW_W + 16.0
			ny = _rng.randf_range(p.y0, p.y1)
		elif nx > VIEW_W + 8.0:
			nx -= VIEW_W + 16.0
		if ny < p.y0:
			ny += span_y
		elif ny > p.y1:
			ny -= span_y
		p.x[i] = nx
		p.y[i] = ny


func _fx_spawn(kind: int, x: float, y: float, vx: float, vy: float, life: float, par: float) -> void:
	if _fx_n >= FX_CAP:
		return
	var i: int = _fx_n
	_fx_n += 1
	_fx_kind[i] = kind
	_fx_x[i] = x
	_fx_y[i] = y
	_fx_vx[i] = vx
	_fx_vy[i] = vy
	_fx_age[i] = 0.0
	_fx_life[i] = life
	_fx_par[i] = par


func _fx_update() -> void:
	var i: int = 0
	while i < _fx_n:
		var age: float = _fx_age[i] + _dl
		if age >= _fx_life[i] or _fx_x[i] < -30.0:
			_fx_n -= 1
			_fx_kind[i] = _fx_kind[_fx_n]
			_fx_x[i] = _fx_x[_fx_n]
			_fx_y[i] = _fx_y[_fx_n]
			_fx_vx[i] = _fx_vx[_fx_n]
			_fx_vy[i] = _fx_vy[_fx_n]
			_fx_age[i] = _fx_age[_fx_n]
			_fx_life[i] = _fx_life[_fx_n]
			_fx_par[i] = _fx_par[_fx_n]
			continue
		_fx_age[i] = age
		var kind: int = _fx_kind[i]
		if kind == Fx.SPARK or kind == Fx.BOMB or kind == Fx.DROPLET:
			_fx_vy[i] += 150.0 * _dl
		elif kind == Fx.STEAM or kind == Fx.SMOKE:
			_fx_vx[i] *= 1.0 - 1.5 * _dl
			_fx_vy[i] *= 1.0 - 1.2 * _dl
		_fx_x[i] += _fx_vx[i] * _dl - _ds * _fx_par[i]
		_fx_y[i] += _fx_vy[i] * _dl
		i += 1


func _update_space() -> void:
	for i: int in range(_props.x.size()):
		var nx: float = _props.x[i] - _ds * _props.f[i]
		_props.p[i] += _dl * (0.6 + _props.f[i] * 1.2)
		if nx < -24.0:
			_respawn_asteroid(i, VIEW_W + 24.0 + _rng.randf_range(0.0, 140.0))
		else:
			_props.x[i] = nx
	for j: int in range(_props_b.x.size()):
		var nx2: float = _props_b.x[j] - _ds * 2.4
		if nx2 < -40.0:
			nx2 += VIEW_W + 80.0 + _rng.randf_range(60.0, 360.0)
			_props_b.y[j] = _rng.randf_range(248.0, 258.0)
			_props_b.k[j] = _rng.randi_range(0, 2)
		_props_b.x[j] = nx2
	if _ev_a.tick(_dl, _rng):
		_ev_a.x = VIEW_W + 20.0
		_ev_a.y = _rng.randf_range(40.0, 96.0)
		_ev_a.vx = -_rng.randf_range(120.0, 165.0)
		_ev_a.vy = _rng.randf_range(10.0, 28.0)
		_ev_a.dur = 6.0
	if _ev_a.on:
		_ev_a.x += _ev_a.vx * _dl - _ds * 0.05
		_ev_a.y += _ev_a.vy * _dl
		if _ev_a.x < -80.0:
			_ev_a.t = _ev_a.dur
	if _ev_b.tick(_dl, _rng):
		_ev_b.dur = 0.45
		_ev_b.k = _rng.randi_range(0, 2)
		_ev_b.x = _rng.randf_range(-16.0, 16.0)
		_ev_b.y = _rng.randf_range(-8.0, 8.0)
	if _ev_c.tick(_dl, _rng):
		_ev_c.dur = 0.22
		_ev_c.k = _rng.randi_range(0, 2)


func _update_starcruiser() -> void:
	for i: int in range(_props.x.size()):
		var nx: float = _props.x[i] - _ds - 14.0 * _dl
		if nx < -20.0:
			nx += VIEW_W + _rng.randf_range(40.0, 220.0)
			_props.k[i] = _rng.randi_range(0, 1)
		_props.x[i] = nx
	_ev_a.dur = 4.5
	_ev_a.tick(_dl, _rng)
	if _ev_b.tick(_dl, _rng):
		_ev_b.dur = 0.8
		var sx: float = _rng.randf_range(120.0, 460.0)
		for _s: int in range(9):
			_fx_spawn(Fx.SPARK, sx, 47.0, _rng.randf_range(-50.0, 30.0), _rng.randf_range(-30.0, 20.0), _rng.randf_range(0.35, 0.7), 1.0)
	# steam bursts from the pipe vents
	_vent_timer -= _dl
	if _vent_timer <= 0.0:
		_vent_timer = _rng.randf_range(0.6, 1.6)
		var top: bool = _rng.randf() < 0.55
		var vents: PackedVector2Array = _meta.get("vents_top" if top else "vents_bot", PackedVector2Array())
		if not vents.is_empty():
			var v: Vector2 = vents[_rng.randi_range(0, vents.size() - 1)]
			var o: float = _off(1.0, 512.0)
			var sx2: float = _wrap_x(v.x, o, 512.0)
			if sx2 > 0.0 and sx2 < VIEW_W:
				var base_y: float = 28.0 + v.y if top else 226.0 + v.y
				var dir: float = 1.0 if top else -1.0
				for _p: int in range(7):
					_fx_spawn(Fx.STEAM, sx2 + _rng.randf_range(-2.0, 2.0), base_y, _rng.randf_range(-12.0, 12.0), dir * _rng.randf_range(16.0, 34.0), _rng.randf_range(1.0, 1.8), 1.0)


func _update_cloud() -> void:
	if _ev_a.tick(_dl, _rng):
		_ev_a.x = VIEW_W + 20.0
		_ev_a.y = _rng.randf_range(56.0, 138.0)
		_ev_a.vx = -_rng.randf_range(34.0, 52.0)
		_ev_a.k = _rng.randi_range(5, 9)
		_ev_a.dur = 30.0
	if _ev_a.on:
		_ev_a.x += _ev_a.vx * _dl - _ds * 0.2
		_ev_a.y += sin(_life * 0.7) * 3.0 * _dl
		if _ev_a.x < -80.0:
			_ev_a.t = _ev_a.dur
	if _ev_b.tick(_dl, _rng):
		_ev_b.x = VIEW_W + 10.0
		_ev_b.y = _rng.randf_range(80.0, 118.0)
		_ev_b.dur = 120.0
	if _ev_b.on:
		_ev_b.x += -9.0 * _dl - _ds * 0.07
		if _ev_b.x < -80.0:
			_ev_b.t = _ev_b.dur
	if _ev_c.tick(_dl, _rng):
		_ev_c.dur = 0.55
		_ev_c.x = _rng.randf_range(40.0, 400.0)
		_bolt.clear()
		var bx: float = _ev_c.x + 40.0
		var by: float = 168.0
		_bolt.append(Vector2(bx, by))
		while by < 208.0:
			by += _rng.randf_range(5.0, 10.0)
			bx += _rng.randf_range(-6.0, 6.0)
			_bolt.append(Vector2(floorf(bx), floorf(by)))


func _update_forest() -> void:
	if _ev_a.tick(_dl, _rng):
		_ev_a.dur = 3.4
	if _ev_b.tick(_dl, _rng):
		_ev_b.x = VIEW_W + 20.0
		_ev_b.y = _rng.randf_range(60.0, 120.0)
		_ev_b.dur = 60.0
	if _ev_b.on:
		_ev_b.x += -26.0 * _dl - _ds * 0.12
		if _ev_b.x < -40.0:
			_ev_b.t = _ev_b.dur


func _update_ice() -> void:
	if _ev_a.tick(_dl, _rng):
		_ev_a.dur = 4.0
	var gust: float = 0.0
	if _ev_a.on:
		gust = sin(clampf(_ev_a.t / _ev_a.dur, 0.0, 1.0) * PI)
	_drift_a.wind = -150.0 * gust
	_drift_b.wind = -230.0 * gust
	# crystal glints
	var glints: PackedVector2Array = _meta.get("glints", PackedVector2Array())
	for g: int in range(_glint_idx.size()):
		if _glint_idx[g] >= 0:
			_glint_t[g] += _dl
			if _glint_t[g] > 0.5:
				_glint_idx[g] = -1
	_small_timer -= _dl
	if _small_timer <= 0.0 and not glints.is_empty():
		_small_timer = _rng.randf_range(0.12, 0.35)
		var gi: int = _rng.randi_range(0, glints.size() - 1)
		var o: float = _off(0.45, 768.0)
		var sx: float = _wrap_x(glints[gi].x, o, 768.0)
		if sx > 4.0 and sx < VIEW_W - 4.0:
			for s: int in range(_glint_idx.size()):
				if _glint_idx[s] < 0:
					_glint_idx[s] = gi
					_glint_t[s] = 0.0
					break


func _update_volcano() -> void:
	if _ev_a.tick(_dl, _rng):
		_ev_a.dur = 2.6
		var craters: PackedVector2Array = _meta.get("craters", PackedVector2Array())
		_ev_a.k = -1
		if not craters.is_empty():
			var o: float = _off(0.04, 768.0)
			var start: int = _rng.randi_range(0, craters.size() - 1)
			for n: int in range(craters.size()):
				var c: Vector2 = craters[(start + n) % craters.size()]
				var sx: float = _wrap_x(c.x, o, 768.0)
				if sx > 20.0 and sx < VIEW_W - 20.0:
					_ev_a.k = (start + n) % craters.size()
					_ev_a.x = sx
					_ev_a.y = 128.0 + c.y
					break
		if _ev_a.k >= 0:
			for _b: int in range(12):
				_fx_spawn(Fx.BOMB, _ev_a.x, _ev_a.y, _rng.randf_range(-34.0, 34.0), _rng.randf_range(-115.0, -60.0), _rng.randf_range(1.2, 2.0), 0.04)
			for _s: int in range(6):
				_fx_spawn(Fx.SMOKE, _ev_a.x + _rng.randf_range(-3.0, 3.0), _ev_a.y - 2.0, _rng.randf_range(-6.0, 6.0), _rng.randf_range(-24.0, -12.0), _rng.randf_range(2.0, 3.2), 0.04)
		else:
			_ev_a.on = false
			_ev_a.t = 2.0
	# lava bubbles popping on the lake
	_small_timer -= _dl
	if _small_timer <= 0.0:
		_small_timer = _rng.randf_range(0.18, 0.5)
		_fx_spawn(Fx.BUBBLE_POP, _rng.randf_range(0.0, VIEW_W), _rng.randf_range(238.0, 254.0), 0.0, 0.0, 0.7, 1.2)
	# finished bubbles throw droplets
	for i: int in range(_fx_n):
		if _fx_kind[i] == Fx.BUBBLE_POP and _fx_age[i] + _dl >= _fx_life[i] and _fx_life[i] > 0.0:
			_fx_life[i] = -1.0
			for _d: int in range(3):
				_fx_spawn(Fx.DROPLET, _fx_x[i], _fx_y[i] - 2.0, _rng.randf_range(-16.0, 16.0), _rng.randf_range(-40.0, -22.0), 0.45, 1.2)


func _update_abyss() -> void:
	for i: int in range(_props.x.size()):
		var nx: float = _props.x[i] - _ds * _props.f[i]
		var ny: float = _props.y[i] - (5.0 + 4.0 * maxf(0.0, sin(_life * 1.6 + _props.p[i]))) * _dl
		if ny < 40.0:
			ny = 262.0
		if nx < -14.0:
			nx += VIEW_W + 28.0
		_props.x[i] = nx
		_props.y[i] = ny
	if _ev_a.tick(_dl, _rng):
		_ev_a.x = VIEW_W + 10.0
		_ev_a.y = _rng.randf_range(84.0, 140.0)
		_ev_a.dur = 200.0
	if _ev_a.on:
		_ev_a.x += -11.0 * _dl - _ds * 0.05
		_ev_a.y += sin(_life * 0.4) * 2.0 * _dl
		if _ev_a.x < -140.0:
			_ev_a.t = _ev_a.dur
	if _ev_b.tick(_dl, _rng):
		_ev_b.x = -30.0
		_ev_b.y = _rng.randf_range(70.0, 190.0)
		_ev_b.dur = 60.0
		_ev_b.k = _rng.randi_range(10, 16)
	if _ev_b.on:
		_ev_b.x += 58.0 * _dl - _ds * 0.3
		if _ev_b.x > VIEW_W + 80.0 or _ev_b.x < -200.0:
			_ev_b.t = _ev_b.dur


func _update_cyber() -> void:
	if _ev_a.tick(_dl, _rng):
		_ev_a.dur = _rng.randf_range(0.22, 0.45)
		_glitch_bands.clear()
		for _b: int in range(_rng.randi_range(3, 6)):
			var sh: float = _rng.randf_range(6.0, 22.0)
			if _rng.randf() < 0.5:
				sh = -sh
			_glitch_bands.append(Vector3(_rng.randf_range(36.0, 200.0), _rng.randf_range(2.0, 10.0), sh))
	if _ev_b.tick(_dl, _rng):
		_ev_b.dur = 1.8


# ---------------------------------------------------------------------------------------------
# Draw helpers
# ---------------------------------------------------------------------------------------------

func _t(key: String) -> Texture2D:
	return _tex.get(key, null)


# Integer scroll offset of a layer of width w.
func _off(factor: float, w: float) -> float:
	return floorf(fposmod(_scroll * factor, w))


# Screen x of a texture-space x on a layer scrolled by `o` (may be off screen).
func _wrap_x(tex_x: float, o: float, w: float) -> float:
	var sx: float = fposmod(tex_x - o, w)
	if sx > VIEW_W + 48.0:
		sx -= w
	return sx


# Horizontal band of a tileable texture: rows src_y..src_y+h drawn at dst_y, wrapped,
# showing screen columns x0..x1. offset is the texture x at screen x 0.
func _band(tex: Texture2D, dst_y: float, src_y: float, h: float, offset: float, x0: float = 0.0, x1: float = VIEW_W, mod: Color = Color.WHITE) -> void:
	var w: float = float(tex.get_width())
	var u: float = fposmod(floorf(offset) + x0, w)
	var sx: float = x0
	var guard: int = 0
	while sx < x1 and guard < 8:
		var run: float = minf(w - u, x1 - sx)
		draw_texture_rect_region(tex, Rect2(sx, dst_y, run, h), Rect2(u, src_y, run, h), mod)
		sx += run
		u = 0.0
		guard += 1


func _layer(key: String, y: float, factor: float, mod: Color = Color.WHITE, extra: float = 0.0) -> void:
	var tex: Texture2D = _t(key)
	if tex == null:
		return
	_band(tex, y, 0.0, float(tex.get_height()), _scroll * factor + extra, 0.0, VIEW_W, mod)


# Line-scrolled layer: horizontal bands whose speed interpolates from f_top to f_bot.
func _layer_rows(key: String, y: float, band_h: int, f_top: float, f_bot: float, mod: Color = Color.WHITE) -> void:
	var tex: Texture2D = _t(key)
	if tex == null:
		return
	var h: int = tex.get_height()
	var r: int = 0
	while r < h:
		var bh: int = mini(band_h, h - r)
		var t: float = float(r) / float(maxi(1, h - 1))
		_band(tex, y + float(r), float(r), float(bh), _scroll * lerpf(f_top, f_bot, t), 0.0, VIEW_W, mod)
		r += bh


# Layer with a per-band sine wobble (heat shimmer, water).
func _layer_wobble(key: String, y: float, factor: float, band_h: int, amp: float, freq: float, speed: float, from_row: int = 0) -> void:
	var tex: Texture2D = _t(key)
	if tex == null:
		return
	var h: int = tex.get_height()
	var base: float = floorf(_scroll * factor)
	if from_row > 0:
		_band(tex, y, 0.0, float(from_row), base)
	var r: int = from_row
	while r < h:
		var bh: int = mini(band_h, h - r)
		var k: float = float(r - from_row) / float(maxi(1, h - from_row))
		var wob: float = roundf(sin(_life * speed + float(r) * freq) * amp * (0.4 + 0.6 * k))
		_band(tex, y + float(r), float(r), float(bh), base + wob)
		r += bh


func _drift_draw(p: Drift, streak: float = 1.0) -> void:
	var n: int = p.x.size()
	var nc: int = p.cols.size()
	if n == 0 or nc == 0:
		return
	for i: int in range(n):
		if p.blink > 0.0 and fposmod(_life * p.blink + p.ph[i] * 0.159, 1.0) > p.duty:
			continue
		var x: float = p.x[i]
		if p.sway > 0.0:
			x += sin(_life * p.sway_hz + p.ph[i]) * p.sway
		draw_rect(Rect2(floorf(x), floorf(p.y[i]), p.size * streak, p.size), p.cols[i % nc])


func _fx_draw() -> void:
	for i: int in range(_fx_n):
		var kind: int = _fx_kind[i]
		var a: float = clampf(_fx_age[i] / maxf(0.001, absf(_fx_life[i])), 0.0, 1.0)
		var x: float = floorf(_fx_x[i])
		var y: float = floorf(_fx_y[i])
		match kind:
			Fx.STEAM:
				var r: float = floorf(1.0 + a * 5.0)
				var al: float = 0.22 * (1.0 - a)
				draw_rect(Rect2(x - r, y - floorf(r * 0.7), r * 2.0, floorf(r * 1.4) + 1.0), Color(0.62, 0.68, 0.78, al))
				draw_rect(Rect2(x - floorf(r * 0.5), y - floorf(r * 0.4), r, floorf(r * 0.8) + 1.0), Color(0.75, 0.8, 0.88, al))
			Fx.SPARK:
				var c: Color = Color("#ffe890") if a < 0.4 else Color("#ff9a40")
				draw_rect(Rect2(x, y, 1.0, 1.0), c)
				draw_rect(Rect2(x - floorf(_fx_vx[i] * 0.02), y - floorf(_fx_vy[i] * 0.02), 1.0, 1.0), Color(1.0, 0.5, 0.2, 0.5 * (1.0 - a)))
			Fx.BOMB:
				var c2: Color = Color(1.0, 0.62, 0.22, 0.85 * (1.0 - a * 0.6))
				draw_rect(Rect2(x, y, 2.0, 2.0), c2)
				draw_rect(Rect2(x - floorf(_fx_vx[i] * 0.03), y - floorf(_fx_vy[i] * 0.03), 1.0, 1.0), Color(0.75, 0.2, 0.06, 0.6))
			Fx.SMOKE:
				var r2: float = floorf(2.0 + a * 7.0)
				draw_rect(Rect2(x - r2, y - r2, r2 * 2.0, r2 * 2.0), Color(0.12, 0.05, 0.05, 0.45 * (1.0 - a)))
			Fx.BUBBLE_POP:
				var r3: float = floorf(1.0 + a * 2.5)
				draw_rect(Rect2(x - r3, y - r3 + 1.0, r3 * 2.0 + 1.0, r3), Color("#ff9a34"))
				draw_rect(Rect2(x - r3 + 1.0, y - r3, r3 * 2.0 - 1.0, 1.0), Color("#ffd060"))
			Fx.DROPLET:
				draw_rect(Rect2(x, y, 1.0, 1.0), Color(1.0, 0.7, 0.25, 1.0 - a))


func _draw() -> void:
	var st: Dictionary = StageData.get_stage(stage_idx)
	if _tex.is_empty():
		draw_rect(Rect2(0.0, 0.0, VIEW_W, VIEW_H), st["sky_top"])
	else:
		match _theme:
			"space":
				_draw_space()
			"starcruiser":
				_draw_starcruiser()
			"planet_base":
				_draw_cloud()
			"forest":
				_draw_forest()
			"ice":
				_draw_ice()
			"volcano":
				_draw_volcano()
			"abyss":
				_draw_abyss()
			"cyber":
				_draw_cyber()
			_:
				if _module_bg != null:
					_module_bg.call("draw")

	_draw_stage_decks(st, _theme)

	if hyperspace_active:
		_draw_hyperspace_tunnel()


# ---------------------------------------------------------------------------------------------
# 1) OUTER ORBIT
# ---------------------------------------------------------------------------------------------

func _draw_space() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	_layer("nebula", 34.0, 0.02)
	_layer("stars_far", 22.0, 0.05)

	# twinkling far stars
	var o_far: float = _off(0.05, 512.0)
	for i: int in range(22):
		var tx: float = fposmod(float(i) * 97.3 + 13.0, 512.0)
		var sx: float = _wrap_x(tx, o_far, 512.0)
		if sx < 0.0 or sx > VIEW_W:
			continue
		var sy: float = 36.0 + fposmod(float(i) * 61.7, 200.0)
		var tw: float = sin(_life * (1.3 + float(i % 5) * 0.4) + float(i))
		if tw > 0.55:
			draw_rect(Rect2(floorf(sx), sy, 1.0, 1.0), Color("#8898d0"))
			if tw > 0.9:
				draw_rect(Rect2(floorf(sx) - 1.0, sy, 3.0, 1.0), Color(0.45, 0.52, 0.8, 0.55))
				draw_rect(Rect2(floorf(sx), sy - 1.0, 1.0, 3.0), Color(0.45, 0.52, 0.8, 0.55))
		elif tw > 0.0:
			draw_rect(Rect2(floorf(sx), sy, 1.0, 1.0), Color("#3a4678"))

	_draw_space_giant()
	_draw_space_battle()
	_layer("stars_mid", 22.0, 0.14)
	_layer("belt", 38.0, 0.28)
	_layer("belt", 186.0, 0.2, Color(0.8, 0.8, 0.9, 0.85), 311.0)
	_draw_space_comet()

	var atl: Texture2D = _t("asteroids")
	for i2: int in range(_props.x.size()):
		var frame: int = posmod(int(_props.p[i2]), 8)
		var f: float = _props.f[i2]
		var shade: float = lerpf(0.55, 1.0, (f - 0.4) / 0.55)
		draw_texture_rect_region(atl, Rect2(floorf(_props.x[i2]) - 12.0, floorf(_props.y[i2]) - 12.0, 24.0, 24.0),
			Rect2(float(_props.k[i2] * 24), float(frame * 24), 24.0, 24.0), Color(shade, shade, shade * 1.05, 1.0))

	_draw_space_planet()

	var near: Texture2D = _t("near_rocks")
	for j: int in range(_props_b.x.size()):
		draw_texture_rect_region(near, Rect2(floorf(_props_b.x[j]) - 24.0, floorf(_props_b.y[j]) - 22.0, 48.0, 44.0),
			Rect2(float(_props_b.k[j] * 48), 0.0, 48.0, 44.0))

	# dim speed streaks
	if speed_scale > 0.6 and not hyperspace_active:
		for st: Dictionary in _streaks:
			var c: Color = Color("#6a80c0") if bool(st["alt"]) else Color("#3a4c88")
			draw_rect(Rect2(floorf(float(st["x"])), floorf(float(st["y"])), floorf(float(st["len"])), 1.0), Color(c.r, c.g, c.b, 0.32))


func _draw_space_giant() -> void:
	var giant: Texture2D = _t("giant")
	var gx: float = floorf(fposmod(318.0 - _scroll * 0.004 + 140.0, 640.0) - 140.0)
	var gy: float = 22.0
	draw_texture(giant, Vector2(gx, gy))
	# specks orbiting in the ring (the ring slowly turns)
	var ring: Vector4 = _meta.get("giant_ring", Vector4(50.0, 10.0, -0.17, 17.0))
	var cx: float = gx + 66.0
	var cy: float = gy + 36.0
	for i: int in range(16):
		var th: float = float(i) * TAU / 16.0 + _life * 0.06 + sin(float(i) * 3.1) * 0.2
		var q: float = 0.62 + 0.3 * fposmod(float(i) * 0.37, 1.0)
		var dx: float = cos(th) * ring.x * q
		var dy: float = sin(th) * ring.y * q
		var py: float = dy + dx * ring.z
		if dy < 0.0 and dx * dx + py * py < ring.w * ring.w:
			continue
		var bright: bool = dy > 0.0
		draw_rect(Rect2(floorf(cx + dx), floorf(cy + py), 1.0, 1.0), Color("#7c747c") if bright else Color("#3c3842"))


func _draw_space_battle() -> void:
	var ships: Texture2D = _t("ships")
	var pos: PackedVector2Array = PackedVector2Array()
	var src_y: PackedFloat32Array = PackedFloat32Array([0.0, 10.0, 18.0])
	var src_w: PackedFloat32Array = PackedFloat32Array([32.0, 24.0, 17.0])
	var ys: PackedFloat32Array = PackedFloat32Array([72.0, 88.0, 100.0])
	for k: int in range(3):
		var fx: float = float(k) * 70.0 + 120.0 + _life * (3.0 + float(k)) - _scroll * 0.05
		var sx: float = floorf(fposmod(fx, 1100.0) - 300.0)
		var sy: float = ys[k] + floorf(sin(_life * 0.3 + float(k)) * 2.0)
		pos.append(Vector2(sx, sy))
		if sx > -40.0 and sx < VIEW_W + 10.0:
			draw_texture_rect_region(ships, Rect2(sx, sy, src_w[k], 8.0), Rect2(0.0, src_y[k], src_w[k], 8.0))
	# laser volley between two ships
	if _ev_c.on:
		var a: Vector2 = pos[_ev_c.k] + Vector2(src_w[_ev_c.k] * 0.6, 3.0)
		var b: Vector2 = pos[(_ev_c.k + 1) % 3] + Vector2(10.0, 3.0)
		if a.x > -20.0 and a.x < VIEW_W + 20.0 and b.x > -20.0 and b.x < VIEW_W + 20.0:
			var al: float = 0.55 * (1.0 - _ev_c.t / _ev_c.dur)
			draw_line(a, b, Color(1.0, 0.3, 0.45, al), 1.0)
	# explosion flash near a ship
	if _ev_b.on:
		var p: Vector2 = pos[_ev_b.k] + Vector2(10.0 + _ev_b.x, 3.0 + _ev_b.y)
		if p.x > 0.0 and p.x < VIEW_W:
			var u: float = _ev_b.t / _ev_b.dur
			var r: float = floorf(1.0 + u * 4.0)
			var c: Color = Color(1.0, 0.85, 0.55, 1.0 - u).lerp(Color(1.0, 0.35, 0.15, 1.0 - u), u)
			if u < 0.25:
				draw_rect(Rect2(floorf(p.x) - 1.0, floorf(p.y) - 1.0, 3.0, 3.0), Color(1.0, 0.92, 0.7, 0.9))
			draw_rect(Rect2(floorf(p.x) - r, floorf(p.y), 1.0, 1.0), c)
			draw_rect(Rect2(floorf(p.x) + r, floorf(p.y), 1.0, 1.0), c)
			draw_rect(Rect2(floorf(p.x), floorf(p.y) - r, 1.0, 1.0), c)
			draw_rect(Rect2(floorf(p.x), floorf(p.y) + r, 1.0, 1.0), c)


func _draw_space_comet() -> void:
	if not _ev_a.on:
		return
	var hx: float = floorf(_ev_a.x)
	var hy: float = floorf(_ev_a.y)
	var dir: Vector2 = Vector2(_ev_a.vx, _ev_a.vy).normalized()
	var tail_cols: Array[Color] = [Color("#7ec8ec"), Color("#4a92c8"), Color("#305ea0"), Color("#223e78")]
	for i: int in range(1, 30):
		if (i * 7) % 5 == 0 and i > 6:
			continue
		var p: Vector2 = Vector2(hx, hy) - dir * float(i) * 1.6
		var c: Color = tail_cols[mini(3, i / 7)]
		draw_rect(Rect2(floorf(p.x), floorf(p.y), 2.0 if i < 10 else 1.0, 1.0), c)
		if i % 3 == 0 and i < 24:
			# dust tail curving away
			var q: Vector2 = p + Vector2(0.0, float(i) * 0.25)
			draw_rect(Rect2(floorf(q.x), floorf(q.y), 1.0, 1.0), Color(0.62, 0.55, 0.42, 0.55))
	draw_rect(Rect2(hx - 1.0, hy - 1.0, 4.0, 4.0), Color(0.45, 0.7, 0.9, 0.45))
	draw_rect(Rect2(hx, hy, 2.0, 2.0), Color("#cfeefc"))


func _draw_space_planet() -> void:
	var surf: Texture2D = _t("surface")
	var arc: Vector3 = _meta.get("planet_arc", Vector3(240.0, 958.0, 740.0))
	for y: int in range(218, 258):
		var dy: float = arc.y - (float(y) + 0.5)
		var hw: float = sqrt(maxf(0.0, arc.z * arc.z - dy * dy))
		var x0: float = maxf(0.0, ceilf(arc.x - hw))
		var x1: float = minf(VIEW_W, floorf(arc.x + hw))
		if x1 <= x0:
			continue
		var t: float = float(y - 218) / 40.0
		_band(surf, float(y), float(clampi(y - 214, 0, 43)), 1.0, _scroll * lerpf(0.06, 0.3, t), x0, x1)
	draw_texture(_t("planet_over"), Vector2(0.0, 210.0))


# ---------------------------------------------------------------------------------------------
# 2) STARCRUISER
# ---------------------------------------------------------------------------------------------

func _draw_starcruiser() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	var o_hall: float = _off(0.15, 640.0)
	_layer("hall", 64.0, 0.15)

	# pulsing reactor cores with energy rising through the slit
	var cores: PackedVector2Array = _meta.get("cores", PackedVector2Array())
	for k: int in range(cores.size()):
		var sx: float = _wrap_x(cores[k].x, o_hall, 640.0)
		if sx < -10.0 or sx > VIEW_W + 10.0:
			continue
		var pulse: float = 0.5 + 0.5 * sin(_life * 2.3 + float(k) * 1.7)
		draw_rect(Rect2(floorf(sx) - 2.0, 64.0, 4.0, 150.0), Color(1.0, 0.5, 0.15, 0.08 + 0.1 * pulse))
		draw_rect(Rect2(floorf(sx) - 6.0, 64.0, 12.0, 150.0), Color(1.0, 0.45, 0.1, 0.03 + 0.03 * pulse))
		for b: int in range(2):
			var by: float = 214.0 - fposmod(_life * 34.0 + float(k) * 47.0 + float(b) * 75.0, 150.0)
			draw_rect(Rect2(floorf(sx) - 1.0, floorf(by), 2.0, 5.0), Color(1.0, 0.72, 0.35, 0.35))

	# pumping pistons between the reactors
	var pistons: PackedVector2Array = _meta.get("pistons", PackedVector2Array())
	for k2: int in range(pistons.size()):
		var px: float = _wrap_x(pistons[k2].x, o_hall, 640.0)
		if px < -12.0 or px > VIEW_W + 12.0:
			continue
		var ext: float = floorf(12.0 + 10.0 * sin(_life * 2.6 + float(k2) * 1.3))
		var top: float = 64.0 + pistons[k2].y
		draw_rect(Rect2(floorf(px) - 2.0, top - ext, 4.0, ext), Color("#222c3e"))
		draw_rect(Rect2(floorf(px) - 1.0, top - ext, 1.0, ext), Color("#3a4862"))
		draw_rect(Rect2(floorf(px) - 7.0, top - ext - 3.0, 14.0, 3.0), Color("#2a3448"))

	# catwalk running lights
	var hl: PackedVector3Array = _meta.get("hall_lights", PackedVector3Array())
	var light_cols: Array[Color] = [Color("#c87a24"), Color("#2aa8c8"), Color("#c83a4a")]
	for i: int in range(hl.size()):
		var lx: float = _wrap_x(hl[i].x, o_hall, 640.0)
		if lx < 0.0 or lx > VIEW_W:
			continue
		if fposmod(_life * 0.9 - float(i) * 0.13, 1.0) < 0.5:
			draw_rect(Rect2(floorf(lx), 64.0 + hl[i].y, 2.0, 1.0), light_cols[int(hl[i].z)])

	# red alert: the hall glows red through the windows
	if _ev_a.on:
		var u: float = _ev_a.t / _ev_a.dur
		var env: float = clampf(minf(u * 6.0, (1.0 - u) * 6.0), 0.0, 1.0)
		var flash: float = 0.5 + 0.5 * sin(_ev_a.t * 7.0)
		draw_rect(Rect2(0.0, 64.0, VIEW_W, 150.0), Color(1.0, 0.08, 0.06, 0.13 * env * flash))

	var o_wall: float = _off(0.5, 512.0)
	_layer("wall", 46.0, 0.5)
	var wl: PackedVector3Array = _meta.get("wall_lights", PackedVector3Array())
	var wcols: Array[Color] = [Color("#ff4a3a"), Color("#3ae070"), Color("#ffb03a"), Color("#3ad0ff")]
	for i2: int in range(wl.size()):
		var wx: float = _wrap_x(wl[i2].x, o_wall, 512.0)
		if wx < 0.0 or wx > VIEW_W:
			continue
		var kind: int = int(wl[i2].z)
		var on: bool
		if kind == 0:
			on = fposmod(_life * 0.7 + float(i2) * 0.31, 1.0) < 0.35
		else:
			on = fposmod(_life * (0.8 + float(i2 % 4) * 0.45) + float(i2) * 0.57, 1.0) < 0.6
		if on:
			draw_rect(Rect2(floorf(wx), 46.0 + wl[i2].y, 2.0, 2.0 if kind == 0 else 1.0), wcols[kind])

	_layer("pipes_top", 28.0, 1.0)
	_layer("pipes_bot", 226.0, 1.0)

	# crates riding the conveyor
	var crates: Texture2D = _t("crates")
	for c: int in range(_props.x.size()):
		var kk: int = _props.k[c]
		var cw: float = 13.0 if kk == 0 else 12.0
		draw_texture_rect_region(crates, Rect2(floorf(_props.x[c]), 216.0, cw, 10.0), Rect2(0.0 if kk == 0 else 14.0, 0.0, cw, 10.0))

	_fx_draw()

	# alert beacons on the ceiling pipes
	var o_pipe: float = _off(1.0, 512.0)
	for b2: int in range(3):
		var bx: float = _wrap_x(float(b2) * 170.0 + 85.0, o_pipe, 512.0)
		if bx < -40.0 or bx > VIEW_W + 40.0:
			continue
		var lamp: Vector2 = Vector2(floorf(bx), 46.0)
		if _ev_a.on:
			var ang: float = _ev_a.t * 6.0 + float(b2)
			var dir: float = cos(ang)
			draw_rect(Rect2(lamp.x - 1.0, lamp.y, 4.0, 2.0), Color("#ff3a2a") if dir > 0.0 else Color("#a02018"))
			var reach: float = 70.0
			var tip_x: float = lamp.x + 1.0 + dir * reach
			var fan: PackedVector2Array = PackedVector2Array([lamp + Vector2(1.0, 2.0), Vector2(tip_x - 10.0, lamp.y + 60.0), Vector2(tip_x + 10.0, lamp.y + 60.0)])
			draw_colored_polygon(fan, Color(1.0, 0.2, 0.1, 0.07 * absf(dir)))
		else:
			draw_rect(Rect2(lamp.x - 1.0, lamp.y, 4.0, 2.0), Color("#4a2010"))

	# foreground bulkhead posts
	var bk: Texture2D = _t("bulkhead")
	for k3: int in range(2):
		var px2: float = floorf(fposmod(-_scroll * 2.2 + float(k3) * 560.0, 1120.0) - 60.0)
		if px2 > -50.0 and px2 < VIEW_W:
			draw_texture(bk, Vector2(px2, 28.0))


# ---------------------------------------------------------------------------------------------
# 3) CLOUD BASE
# ---------------------------------------------------------------------------------------------

func _draw_cloud() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	var ra: float = 0.5 + 0.5 * sin(_life * 0.33)
	draw_texture(_t("rays_0"), Vector2(0.0, 28.0), Color(1.0, 1.0, 1.0, ra))
	draw_texture(_t("rays_1"), Vector2(0.0, 28.0), Color(1.0, 1.0, 1.0, 1.0 - ra))

	_layer("mountains", 178.0, 0.03)
	# distant storm lightning over the horizon
	if _ev_c.on:
		var u: float = _ev_c.t
		var lit: bool = u < 0.08 or (u > 0.18 and u < 0.26) or (u > 0.34 and u < 0.38)
		if lit:
			draw_rect(Rect2(_ev_c.x, 164.0, 160.0, 78.0), Color(0.75, 0.85, 1.0, 0.09))
			if _bolt.size() > 1:
				draw_polyline(_bolt, Color(0.7, 0.8, 0.98, 0.75), 1.0)

	var bob: float = floorf(sin(_life * 0.45) * 1.5)
	_layer("islands", 96.0 + bob, 0.06)
	_layer("clouds_far", 62.0, 0.1)

	# bird flock
	if _ev_a.on:
		var n: int = _ev_a.k
		for i: int in range(n):
			var row: float = float(i - n / 2)
			var bx: float = floorf(_ev_a.x + absf(row) * 7.0 + sin(float(i) * 2.3) * 2.0)
			var by: float = floorf(_ev_a.y + row * 4.0 + sin(_life * 1.3 + float(i)) * 1.5)
			var c: Color = Color("#11284c")
			if int(_life * 7.0 + float(i) * 0.7) % 2 == 0:
				draw_rect(Rect2(bx, by + 1.0, 1.0, 1.0), c)
				draw_rect(Rect2(bx + 1.0, by, 1.0, 1.0), c)
				draw_rect(Rect2(bx + 2.0, by + 1.0, 1.0, 1.0), c)
			else:
				draw_rect(Rect2(bx, by, 3.0, 1.0), c)
				draw_rect(Rect2(bx + 1.0, by + 1.0, 1.0, 1.0), c)

	# airship crossing the far sky
	if _ev_b.on:
		var ax: float = floorf(_ev_b.x)
		var ay: float = floorf(_ev_b.y + sin(_life * 0.5) * 2.0)
		var frame: int = int(_life * 12.0) % 2
		draw_texture_rect_region(_t("airship"), Rect2(ax, ay, 72.0, 24.0), Rect2(0.0, float(frame * 24), 72.0, 24.0))
		if fposmod(_life, 1.4) < 0.18:
			draw_rect(Rect2(ax + 33.0, ay + 1.0, 2.0, 1.0), Color("#ff4a4a"))

	_layer("clouds_mid", 118.0, 0.32)

	# hovering sky platforms
	var plat: Texture2D = _t("platform")
	for k: int in range(2):
		var px: float = floorf(fposmod(float(k) * 380.0 + 300.0 - _scroll * 0.3, 760.0) - 140.0)
		if px < -70.0 or px > VIEW_W:
			continue
		var py: float = floorf(150.0 + float(k) * 16.0 + sin(_life * 0.9 + float(k) * 2.0) * 2.5)
		draw_texture(plat, Vector2(px, py))
		var fl: float = 0.35 + 0.25 * sin(_life * 23.0 + float(k))
		draw_rect(Rect2(px + 28.0, py + 32.0, 8.0, 2.0), Color(0.48, 0.9, 1.0, fl))
		draw_rect(Rect2(px + 30.0, py + 34.0, 4.0, 1.0), Color(0.48, 0.9, 1.0, fl * 0.5))
		var blink: bool = fposmod(_life * 0.8 + float(k) * 0.5, 1.0) < 0.5
		draw_rect(Rect2(px + 3.0, py + 22.0, 1.0, 1.0), Color("#ff5a5a") if blink else Color("#5a2020"))
		draw_rect(Rect2(px + 60.0, py + 22.0, 1.0, 1.0), Color("#205a20") if blink else Color("#5aff7a"))

	_layer("sea_far", 190.0, 0.45)
	_layer("cloud_sea", 208.0, 0.85)
	_layer("sea_near", 232.0, 1.6)


# ---------------------------------------------------------------------------------------------
# 4) XENO FOREST
# ---------------------------------------------------------------------------------------------

func _draw_forest() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	_layer("far", 28.0, 0.08)

	# bioluminescent pulse wave rolling through the far trees
	if _ev_a.on:
		var u: float = _ev_a.t / _ev_a.dur
		var bx: float = floorf(-60.0 + u * 600.0)
		var far: Texture2D = _t("far")
		var o_far: float = _off(0.08, 640.0)
		for s: int in range(3):
			var w: float = 18.0 - float(s) * 5.0
			var x0: float = maxf(0.0, bx - w)
			var x1: float = minf(VIEW_W, bx + w)
			if x1 > x0:
				_band(far, 28.0, 0.0, 230.0, o_far, x0, x1, Color(1.6 + float(s) * 0.5, 3.0 + float(s), 2.6 + float(s), 0.45))

	var sh: float = 0.55 + 0.45 * sin(_life * 0.4)
	draw_texture(_t("shafts"), Vector2(0.0, 28.0), Color(1.0, 1.0, 1.0, sh))

	# giant moth fluttering through the far canopy
	if _ev_b.on:
		var mx: float = floorf(_ev_b.x)
		var my: float = floorf(_ev_b.y + sin(_life * 2.2) * 8.0)
		var frame: int = int(_life * 9.0) % 2
		draw_texture_rect_region(_t("moth"), Rect2(mx, my, 22.0, 14.0), Rect2(float(frame * 22), 0.0, 22.0, 14.0))

	var o_mid: float = _off(0.4, 768.0)
	_layer("mid", 28.0, 0.4)
	var glows: PackedVector3Array = _meta.get("glows", PackedVector3Array())
	for i: int in range(glows.size()):
		var gx: float = _wrap_x(glows[i].x, o_mid, 768.0)
		if gx < 0.0 or gx > VIEW_W:
			continue
		var a: float = 0.35 + 0.35 * sin(_life * 1.4 + glows[i].x * 0.07)
		draw_rect(Rect2(floorf(gx), 28.0 + glows[i].y, 1.0, 1.0), Color(0.3, 1.0, 0.85, a))
	var spots: PackedVector3Array = _meta.get("spots", PackedVector3Array())
	var spot_cols: Array[Color] = [Color(0.85, 0.45, 1.0), Color(1.0, 0.45, 0.85), Color(0.45, 1.0, 0.85)]
	for i2: int in range(spots.size()):
		var sx: float = _wrap_x(spots[i2].x, o_mid, 768.0)
		if sx < 0.0 or sx > VIEW_W:
			continue
		var c: Color = spot_cols[int(spots[i2].z)]
		c.a = 0.45 + 0.45 * sin(_life * 1.9 + float(i2) * 1.3)
		draw_rect(Rect2(floorf(sx), 28.0 + floorf(spots[i2].y), 1.0, 1.0), c)

	_drift_draw(_drift_a)

	var o_can: float = _off(0.65, 640.0)
	_layer("canopy", 28.0, 0.65)
	# hanging glow vines
	var vines: PackedVector2Array = _meta.get("vines", PackedVector2Array())
	var pts: PackedVector2Array = PackedVector2Array()
	for v: int in range(vines.size()):
		var vx: float = _wrap_x(vines[v].x, o_can, 640.0)
		if vx < -10.0 or vx > VIEW_W + 10.0:
			continue
		var length: float = 18.0 + fposmod(float(v) * 23.0, 34.0)
		var segs: int = 6
		pts.clear()
		var base: Vector2 = Vector2(floorf(vx), 28.0 + vines[v].y)
		for s2: int in range(segs + 1):
			var t: float = float(s2) / float(segs)
			var sway: float = sin(_life * 1.1 + float(v) * 1.7 + t * 2.0) * t * 4.0
			pts.append(Vector2(floorf(base.x + sway) + 0.5, floorf(base.y + t * length) + 0.5))
		draw_polyline(pts, Color("#0f3a20"), 1.0)
		var tip: Vector2 = pts[segs]
		var pulse: float = 0.5 + 0.5 * sin(_life * 2.0 + float(v))
		draw_rect(Rect2(tip.x - 1.5, tip.y - 0.5, 3.0, 3.0), Color(0.3, 1.0, 0.75, 0.18 * pulse))
		draw_rect(Rect2(tip.x - 0.5, tip.y + 0.5, 2.0, 2.0), Color(0.4, 1.0, 0.8, 0.45 + 0.4 * pulse))

	_drift_draw(_drift_b)

	var o_und: float = _off(0.95, 640.0)
	_layer("under", 222.0, 0.95)
	# swaying glow plants
	var plants: PackedVector3Array = _meta.get("plants", PackedVector3Array())
	var pcols: Array[Color] = [Color(0.35, 1.0, 0.85), Color(1.0, 0.4, 0.85), Color(0.75, 1.0, 0.35)]
	for p: int in range(plants.size()):
		var px: float = _wrap_x(plants[p].x, o_und, 640.0)
		if px < -6.0 or px > VIEW_W + 6.0:
			continue
		var h: float = plants[p].y
		var sway2: float = sin(_life * 1.4 + float(p) * 0.9) * 3.0
		var base2: Vector2 = Vector2(floorf(px) + 0.5, 257.5)
		var top: Vector2 = Vector2(floorf(px + sway2) + 0.5, floorf(257.0 - h) + 0.5)
		draw_line(base2, top, Color("#123a20"), 1.0)
		var c2: Color = pcols[int(plants[p].z)]
		var pulse2: float = 0.5 + 0.5 * sin(_life * 2.4 + float(p) * 1.1)
		draw_rect(Rect2(top.x - 2.5, top.y - 2.5, 5.0, 5.0), Color(c2.r, c2.g, c2.b, 0.12 + 0.1 * pulse2))
		draw_rect(Rect2(top.x - 1.5, top.y - 1.5, 3.0, 3.0), Color(c2.r * 0.6, c2.g * 0.6, c2.b * 0.6, 0.9))
		draw_rect(Rect2(top.x - 0.5, top.y - 0.5, 1.0, 1.0), Color(c2.r, c2.g, c2.b, 0.6 + 0.4 * pulse2))


# ---------------------------------------------------------------------------------------------
# 5) CRYO GLACIER
# ---------------------------------------------------------------------------------------------

func _draw_ice() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	var gust: float = 0.0
	if _ev_a.on:
		gust = sin(clampf(_ev_a.t / _ev_a.dur, 0.0, 1.0) * PI)
	_draw_aurora(32.0, 0.02, 0.0, Color(1.0, 1.0, 1.0, 1.0 - gust * 0.6), 0.0)
	_draw_aurora(48.0, 0.035, 256.0, Color(0.8, 0.7, 1.15, 0.55 - gust * 0.3), 2.1)

	_layer("mountains", 146.0, 0.04)
	var wins: PackedVector2Array = _meta.get("citadel_windows", PackedVector2Array())
	var o_m: float = _off(0.04, 768.0)
	for i: int in range(wins.size()):
		var wx: float = _wrap_x(wins[i].x, o_m, 768.0)
		if wx < 0.0 or wx > VIEW_W:
			continue
		if fposmod(_life * 0.25 + float(i) * 0.37, 1.0) < 0.6:
			draw_rect(Rect2(floorf(wx), 146.0 + wins[i].y, 1.0, 1.0), Color("#7ad0ff"))

	_drift_draw(_drift_a, 1.0 + gust * 4.0)

	var o_ice: float = _off(0.45, 768.0)
	_layer("ice", 28.0, 0.45)
	var glints: PackedVector2Array = _meta.get("glints", PackedVector2Array())
	for g: int in range(_glint_idx.size()):
		if _glint_idx[g] < 0:
			continue
		var gp: Vector2 = glints[_glint_idx[g]]
		var gx: float = floorf(_wrap_x(gp.x, o_ice, 768.0))
		var gy: float = floorf(28.0 + gp.y)
		var s: float = sin(clampf(_glint_t[g] / 0.5, 0.0, 1.0) * PI)
		var arm: float = floorf(1.0 + s * 2.0)
		var ca: Color = Color(0.55, 0.85, 1.0, 0.8 * s)
		draw_rect(Rect2(gx - arm, gy, arm * 2.0 + 1.0, 1.0), ca)
		draw_rect(Rect2(gx, gy - arm, 1.0, arm * 2.0 + 1.0), ca)
		draw_rect(Rect2(gx, gy, 1.0, 1.0), Color(0.92, 0.99, 1.0, s))

	_drift_draw(_drift_b, 1.0 + gust * 5.0)

	# blizzard haze streaks racing past
	if gust > 0.05:
		for k: int in range(5):
			var hx: float = floorf(fposmod(-_life * 520.0 + float(k) * 157.0, 720.0) - 120.0)
			var hy: float = 50.0 + float(k) * 41.0 + floorf(sin(float(k) * 2.7) * 12.0)
			draw_rect(Rect2(hx, hy, 140.0, 3.0), Color(0.8, 0.9, 1.0, 0.05 * gust))
			draw_rect(Rect2(hx + 30.0, hy + 3.0, 80.0, 2.0), Color(0.8, 0.9, 1.0, 0.035 * gust))

	_layer("near", 236.0, 1.3)


func _draw_aurora(y: float, factor: float, extra: float, mod: Color, phase: float) -> void:
	var tex: Texture2D = _t("aurora")
	if tex == null or mod.a <= 0.01:
		return
	var w: float = float(tex.get_width())
	var h: float = float(tex.get_height())
	var o: float = floorf(fposmod(_scroll * factor + extra + _life * 3.0, w))
	var slice: float = 4.0
	var sx: float = 0.0
	while sx < VIEW_W:
		var u: float = fposmod(o + sx, w)
		var wave: float = sin(_life * 0.55 + sx * 0.012 + phase) * 5.0 + sin(_life * 0.29 + sx * 0.031 + phase * 2.0) * 3.0
		var dy: float = floorf(y + wave)
		var run: float = minf(slice, w - u)
		draw_texture_rect_region(tex, Rect2(sx, dy, run, h), Rect2(u, 0.0, run, h), mod)
		if run < slice:
			draw_texture_rect_region(tex, Rect2(sx + run, dy, slice - run, h), Rect2(0.0, 0.0, slice - run, h), mod)
		sx += slice


# ---------------------------------------------------------------------------------------------
# 6) MAGMA CORE
# ---------------------------------------------------------------------------------------------

func _draw_volcano() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	# eruption sky flicker
	if _ev_a.on and _ev_a.k >= 0:
		var u: float = _ev_a.t / _ev_a.dur
		var fl: float = maxf(0.0, 1.0 - u * 3.0)
		if fl > 0.0:
			draw_rect(Rect2(0.0, 28.0, VIEW_W, 208.0), Color(1.0, 0.35, 0.1, 0.06 * fl))
			draw_circle(Vector2(_ev_a.x, _ev_a.y), 6.0 + u * 30.0, Color(1.0, 0.45, 0.12, 0.16 * fl))

	_layer_wobble("volcanoes", 128.0, 0.04, 3, 1.4, 0.45, 3.2, 40)
	_fx_draw_kind_far()
	_layer("cliffs", 34.0, 0.1)

	# lava falls (flowing texture down each fall in the cliffs)
	var flow: Texture2D = _t("flow")
	var falls: PackedVector3Array = _meta.get("falls", PackedVector3Array())
	var o_cl: float = _off(0.1, 640.0)
	for f: int in range(falls.size()):
		var fx: float = floorf(_wrap_x(falls[f].x, o_cl, 640.0))
		if fx < -8.0 or fx > VIEW_W + 8.0:
			continue
		var top: float = 34.0 + falls[f].y
		var bot: float = 34.0 + falls[f].z
		var scroll_v: float = fposmod(_life * 46.0 + float(f) * 20.0, 64.0)
		var y: float = top
		var src: float = 64.0 - floorf(scroll_v)
		while y < bot:
			var run: float = minf(64.0 - src, bot - y)
			draw_texture_rect_region(flow, Rect2(fx - 4.0, y, 8.0, run), Rect2(0.0, src, 8.0, run))
			y += run
			src = 0.0
		var pg: float = 0.5 + 0.5 * sin(_life * 3.0 + float(f))
		draw_rect(Rect2(fx - 7.0, top, 14.0, bot - top), Color(1.0, 0.35, 0.08, 0.04 + 0.02 * pg))
		draw_rect(Rect2(fx - 10.0, bot - 1.0, 20.0, 3.0), Color(1.0, 0.45, 0.12, 0.14 + 0.1 * pg))

	_drift_draw(_drift_b)
	_layer("rocks", 28.0, 0.45)

	# heat glow above the lava lake
	var gl: float = 0.5 + 0.5 * sin(_life * 1.7)
	draw_rect(Rect2(0.0, 222.0, VIEW_W, 6.0), Color(1.0, 0.35, 0.08, 0.04 + 0.02 * gl))
	draw_rect(Rect2(0.0, 228.0, VIEW_W, 6.0), Color(1.0, 0.4, 0.1, 0.08 + 0.04 * gl))
	_layer_rows("lava", 234.0, 2, 0.9, 1.8)
	_fx_draw()
	_drift_draw(_drift_a)


# Lava bombs and smoke belong to the far volcano layer, so they draw before the cliffs.
func _fx_draw_kind_far() -> void:
	for i: int in range(_fx_n):
		var kind: int = _fx_kind[i]
		if kind != Fx.BOMB and kind != Fx.SMOKE:
			continue
		var a: float = clampf(_fx_age[i] / maxf(0.001, absf(_fx_life[i])), 0.0, 1.0)
		var x: float = floorf(_fx_x[i])
		var y: float = floorf(_fx_y[i])
		if kind == Fx.BOMB:
			draw_rect(Rect2(x, y, 2.0, 2.0), Color(1.0, 0.6, 0.2, 0.8 * (1.0 - a * 0.7)))
			draw_rect(Rect2(x - floorf(_fx_vx[i] * 0.03), y - floorf(_fx_vy[i] * 0.03), 1.0, 1.0), Color(0.75, 0.2, 0.06, 0.55))
		else:
			var r: float = floorf(2.0 + a * 8.0)
			draw_rect(Rect2(x - r, y - r, r * 2.0, r * 2.0), Color(0.1, 0.04, 0.04, 0.5 * (1.0 - a)))


# ---------------------------------------------------------------------------------------------
# 7) ABYSSAL TRENCH
# ---------------------------------------------------------------------------------------------

func _draw_abyss() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)
	var ra: float = 0.5 + 0.5 * sin(_life * 0.27)
	var sway: float = floorf(sin(_life * 0.21) * 7.0)
	draw_texture(_t("rays_0"), Vector2(sway, 26.0), Color(1.0, 1.0, 1.0, ra))
	draw_texture(_t("rays_1"), Vector2(-sway, 26.0), Color(1.0, 1.0, 1.0, 1.0 - ra))
	var caus: Texture2D = _t("caustics")
	_band(caus, 26.0, 0.0, 22.0, _life * 9.0 + _scroll * 0.05)
	_band(caus, 26.0, 0.0, 22.0, -_life * 6.0 + _scroll * 0.05 + 200.0, 0.0, VIEW_W, Color(1.0, 1.0, 1.0, 0.6))

	# leviathan gliding far behind the ruins
	if _ev_a.on:
		var frame: int = int(_life * 0.9) % 2
		draw_texture_rect_region(_t("whale"), Rect2(floorf(_ev_a.x), floorf(_ev_a.y), 128.0, 40.0), Rect2(0.0, float(frame * 40), 128.0, 40.0))

	var o_city: float = _off(0.04, 768.0)
	_layer_wobble("city", 106.0, 0.04, 6, 1.0, 0.75, 1.1)
	var wins: PackedVector2Array = _meta.get("windows", PackedVector2Array())
	for i: int in range(wins.size()):
		var wx: float = _wrap_x(wins[i].x, o_city, 768.0)
		if wx < 0.0 or wx > VIEW_W:
			continue
		var ph: float = fposmod(_life * 0.22 + float(i) * 0.61, 1.0)
		if ph < 0.4:
			var a: float = sin(ph / 0.4 * PI)
			draw_rect(Rect2(floorf(wx), 106.0 + wins[i].y, 2.0, 2.0), Color(0.2, 0.85, 0.8, 0.75 * a))

	# jellyfish drifting upward
	var jel: Texture2D = _t("jelly")
	for j: int in range(_props.x.size()):
		var frame2: int = 0 if sin(_life * 1.6 + _props.p[j]) > 0.0 else 1
		var jx: float = floorf(_props.x[j])
		var jy: float = floorf(_props.y[j])
		draw_texture_rect_region(jel, Rect2(jx, jy, 12.0, 18.0), Rect2(float(frame2 * 12), 0.0, 12.0, 18.0))
		var gl: float = 0.3 + 0.25 * sin(_life * 1.6 + _props.p[j])
		draw_rect(Rect2(jx + 5.0, jy + 3.0, 2.0, 2.0), Color(0.6, 0.5, 1.0, gl))

	# fish school sweeping past
	if _ev_b.on:
		for f: int in range(_ev_b.k):
			var fx: float = floorf(_ev_b.x - float(f % 5) * 9.0 - float(f / 5) * 4.0)
			var fy: float = floorf(_ev_b.y + float(f / 5) * 6.0 + sin(_life * 2.0 + float(f) * 0.6) * 4.0 + float(f % 5) * 2.0)
			draw_rect(Rect2(fx, fy, 3.0, 1.0), Color("#164a5e"))
			draw_rect(Rect2(fx + 2.0, fy, 1.0, 1.0), Color("#3a8aa0"))
			draw_rect(Rect2(fx - 1.0, fy - 1.0 if int(_life * 6.0 + float(f)) % 2 == 0 else fy + 1.0, 1.0, 1.0), Color("#164a5e"))

	_drift_draw(_drift_b)

	var o_bed: float = _off(0.35, 768.0)
	# kelp swaying up from the seabed; all stalks are batched into four multiline calls
	var kelp: PackedVector3Array = _meta.get("kelp", PackedVector3Array())
	var edge_segs: PackedVector2Array = PackedVector2Array()
	var core_segs: PackedVector2Array = PackedVector2Array()
	var leaf_segs: PackedVector2Array = PackedVector2Array()
	var leaf_shadow: PackedVector2Array = PackedVector2Array()
	for k: int in range(kelp.size()):
		var kx: float = _wrap_x(kelp[k].x, o_bed, 768.0)
		if kx < -20.0 or kx > VIEW_W + 20.0:
			continue
		var base_y: float = 204.0 + kelp[k].y
		var h: float = kelp[k].z
		var segs: int = int(h / 8.0)
		var prev: Vector2 = Vector2.ZERO
		for s: int in range(segs + 1):
			var t: float = float(s) / float(segs)
			var sw: float = sin(_life * 0.8 + float(k) * 1.3 + t * 2.4) * t * 9.0
			var p: Vector2 = Vector2(floorf(kx + sw) + 0.5, floorf(base_y - t * h) + 0.5)
			if s > 0:
				edge_segs.append(prev)
				edge_segs.append(p)
				edge_segs.append(prev + Vector2(2.0, 0.0))
				edge_segs.append(p + Vector2(2.0, 0.0))
				core_segs.append(prev + Vector2(1.0, 0.0))
				core_segs.append(p + Vector2(1.0, 0.0))
				if s < segs:
					var side: float = 1.0 if s % 2 == 0 else -1.0
					var root: Vector2 = p + Vector2(1.0 + side, 0.0)
					leaf_segs.append(root)
					leaf_segs.append(root + Vector2(side * 5.0, -3.0))
					leaf_shadow.append(root + Vector2(0.0, 1.0))
					leaf_shadow.append(root + Vector2(side * 5.0, -2.0))
			prev = p
	if not edge_segs.is_empty():
		draw_multiline(edge_segs, Color("#0b2f22"), 1.0)
		draw_multiline(core_segs, Color("#15513a"), 1.0)
	if not leaf_segs.is_empty():
		draw_multiline(leaf_shadow, Color("#0c3526"), 1.0)
		draw_multiline(leaf_segs, Color("#124632"), 1.0)

	_layer("seabed", 204.0, 0.35)
	var anem: PackedVector3Array = _meta.get("anemones", PackedVector3Array())
	for a2: int in range(anem.size()):
		var ax: float = _wrap_x(anem[a2].x, o_bed, 768.0)
		if ax < 0.0 or ax > VIEW_W:
			continue
		var pulse: float = 0.5 + 0.5 * sin(_life * 1.5 + float(a2) * 1.9)
		var c: Color = Color(0.35, 1.0, 0.75) if anem[a2].z < 0.5 else Color(0.75, 0.45, 1.0)
		var ay: float = 204.0 + anem[a2].y - 4.0
		for t2: int in range(3):
			draw_rect(Rect2(floorf(ax) - 2.0 + float(t2) * 2.0, ay - float(t2 % 2), 1.0, 1.0), Color(c.r, c.g, c.b, 0.35 + 0.5 * pulse))

	_drift_draw(_drift_a)


# ---------------------------------------------------------------------------------------------
# 8) CYBER NEXUS
# ---------------------------------------------------------------------------------------------

func _draw_cyber() -> void:
	draw_texture(_t("sky"), Vector2.ZERO)

	# falling data streams in the far layer
	var gl: Texture2D = _t("glyphs")
	for i: int in range(_props.x.size()):
		var gx: float = floorf(fposmod(_props.x[i] - _scroll * 0.08, 640.0) - 80.0)
		if gx < -8.0 or gx > VIEW_W:
			continue
		var off: float = fposmod(_props.p[i] + _life * _props.f[i], 256.0)
		var y: float = 34.0
		var src: float = 256.0 - floorf(off)
		var a: float = 0.28 + 0.2 * fposmod(float(i) * 0.37, 1.0)
		while y < 200.0:
			var run: float = minf(256.0 - src, 200.0 - y)
			draw_texture_rect_region(gl, Rect2(gx, y, 8.0, run), Rect2(0.0, src, 8.0, run), Color(1.0, 1.0, 1.0, a))
			y += run
			src = 0.0

	var o_city: float = _off(0.05, 768.0)
	_layer("city", 90.0, 0.05)
	# hologram towers flicker
	var holo: PackedVector4Array = _meta.get("holo", PackedVector4Array())
	for h: int in range(holo.size()):
		var hx: float = _wrap_x(holo[h].x, o_city, 768.0)
		if hx < -50.0 or hx > VIEW_W:
			continue
		var ph: float = fposmod(_life * 0.37 + float(h) * 0.71, 1.0)
		if ph < 0.06:
			draw_rect(Rect2(floorf(hx), 90.0 + holo[h].y, holo[h].z, holo[h].w), Color(0.06, 0.02, 0.15, 0.7))
		elif ph < 0.12:
			draw_rect(Rect2(floorf(hx), 90.0 + holo[h].y, holo[h].z, holo[h].w), Color(0.2, 0.6, 1.0, 0.1))
	var blinks: PackedVector2Array = _meta.get("blinks", PackedVector2Array())
	for b: int in range(blinks.size()):
		var bx: float = _wrap_x(blinks[b].x, o_city, 768.0)
		if bx < 0.0 or bx > VIEW_W:
			continue
		if fposmod(_life * 0.8 + float(b) * 0.43, 1.0) < 0.3:
			draw_rect(Rect2(floorf(bx), 90.0 + blinks[b].y, 1.0, 1.0), Color("#ff4cd4") if b % 2 == 0 else Color("#4cf0ff"))

	# scan sweep
	if _ev_b.on:
		var sx: float = floorf(-20.0 + _ev_b.t / _ev_b.dur * 520.0)
		draw_rect(Rect2(sx, 62.0, 1.0, 144.0), Color(0.3, 0.95, 1.0, 0.35))
		draw_rect(Rect2(sx - 4.0, 62.0, 4.0, 144.0), Color(0.3, 0.95, 1.0, 0.08))
		draw_rect(Rect2(sx - 14.0, 62.0, 10.0, 144.0), Color(0.3, 0.95, 1.0, 0.035))

	_draw_cyber_grid()

	# glitch: slices of the background tear sideways with RGB ghosts
	if _ev_a.on:
		var sky: Texture2D = _t("sky")
		var city: Texture2D = _t("city")
		for g: int in range(_glitch_bands.size()):
			var band: Vector3 = _glitch_bands[g]
			var jitter: float = floorf(band.z * (0.6 + 0.4 * sin(_life * 40.0 + float(g))))
			draw_texture_rect_region(sky, Rect2(jitter, band.x, VIEW_W, band.y), Rect2(0.0, band.x, VIEW_W, band.y))
			if band.x > 90.0 and band.x + band.y < 206.0:
				_band(city, band.x, band.x - 90.0, band.y, o_city - jitter)
			draw_rect(Rect2(0.0, band.x, VIEW_W, band.y), Color(1.0, 0.2, 0.75, 0.06))
			draw_rect(Rect2(jitter + 3.0, band.x, VIEW_W, 1.0), Color(0.2, 0.95, 1.0, 0.18))
		for n: int in range(6):
			var nx: float = floorf(fposmod(float(n) * 131.0 + _life * 900.0, VIEW_W))
			var ny: float = floorf(40.0 + fposmod(float(n) * 59.0 + _life * 300.0, 160.0))
			draw_rect(Rect2(nx, ny, 6.0 + float(n % 3) * 4.0, 2.0), Color(0.3, 1.0, 0.95, 0.22) if n % 2 == 0 else Color(1.0, 0.3, 0.8, 0.22))

	# dim data streaks
	if speed_scale > 0.6 and not hyperspace_active:
		for st: Dictionary in _streaks:
			var c: Color = Color("#ff4cd4") if bool(st["alt"]) else Color("#28c8ff")
			draw_rect(Rect2(floorf(float(st["x"])), floorf(float(st["y"])), floorf(float(st["len"])), 1.0), Color(c.r, c.g, c.b, 0.16))


func _draw_cyber_grid() -> void:
	# Perspective floor (y 206..258) and ceiling (y 28..62): horizontal lines fixed, the
	# depth lines slide faster near the viewer so the plane reads as receding.
	var hor: float = 206.0
	var floor_c: Color = Color(0.55, 0.12, 0.6, 0.45)
	draw_rect(Rect2(0.0, hor, VIEW_W, 1.0), Color(1.0, 0.25, 0.75, 0.55))
	draw_rect(Rect2(0.0, hor - 1.0, VIEW_W, 1.0), Color(1.0, 0.25, 0.75, 0.15))
	var ys: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(1, 9):
		var t: float = pow(float(i) / 8.0, 1.7)
		var y: float = floorf(hor + 52.0 * t)
		ys.append(y)
		draw_rect(Rect2(0.0, y, VIEW_W, 1.0), floor_c)
	var o: float = fposmod(_scroll * 0.6, 24.0)
	for j: int in range(-12, 13):
		var d: float = float(j) * 24.0 - o
		var a: Vector2 = Vector2(240.0 + d + 0.5, hor + 0.5)
		var b: Vector2 = Vector2(240.0 + d * 3.2 + 0.5, 258.5)
		draw_line(a, b, floor_c, 1.0)
	# pulses racing along the floor lines
	for k: int in range(5):
		var row: int = 2 + (k * 3) % 6
		var px: float = floorf(fposmod(_life * (90.0 + float(k) * 25.0) + float(k) * 113.0, 600.0) - 60.0)
		var py: float = ys[row]
		draw_rect(Rect2(px, py, 6.0, 1.0), Color("#ff8ae0"))
		draw_rect(Rect2(px - 10.0, py, 10.0, 1.0), Color(1.0, 0.35, 0.8, 0.45))

	var ceil_h: float = 62.0
	var ceil_c: Color = Color(0.15, 0.45, 0.75, 0.45)
	draw_rect(Rect2(0.0, ceil_h, VIEW_W, 1.0), Color(0.2, 0.8, 1.0, 0.4))
	for i2: int in range(1, 6):
		var t2: float = pow(float(i2) / 5.0, 1.7)
		draw_rect(Rect2(0.0, floorf(ceil_h - 34.0 * t2), VIEW_W, 1.0), ceil_c)
	for j2: int in range(-12, 13):
		var d2: float = float(j2) * 24.0 - o
		draw_line(Vector2(240.0 + d2 + 0.5, ceil_h + 0.5), Vector2(240.0 + d2 * 2.4 + 0.5, 28.5), ceil_c, 1.0)


# ---------------------------------------------------------------------------------------------
# Deck + hyperspace (unchanged layout: floor y 258..270, ceiling y 22..28)
# ---------------------------------------------------------------------------------------------

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

	# Chasing running lights on the metal decks
	if id == "space" or id == "starcruiser" or id == "cyber":
		var lit_c: Color = line_col.lightened(0.35)
		var dim_c: Color = Color(line_col.r, line_col.g, line_col.b, 0.35)
		var lx: float = -fposmod(_scroll * 2.9, 48.0)
		var li: int = 0
		var chase: int = int(_life * 8.0)
		while lx < VIEW_W:
			var on: bool = posmod(chase - li, 6) == 0
			draw_rect(Rect2(floorf(lx) + 20.0, 264.0, 3.0, 1.0), lit_c if on else dim_c)
			lx += 48.0
			li += 1

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
