extends "res://scripts/stages/stage_background.gd"

# TEMPORARY EXAMPLE BACKGROUND: a night proving ground. paint() (static, worker thread) paints
# the still layers once; the instance animates them every frame: blinking beacons on the far
# mesas, drifting dust, and a tracer that streaks across the sky now and then.
#
# Layers: "sky" 480x270 (drawn at 0,0), "far" 512x96 mesas at y 150 (parallax 0.1), "near"
# 512x34 ground strip at y 224 (parallax 0.9). Tileable layers wrap x around their width, so
# they can scroll forever. The playfield (y 30-249) stays dark; the bright bits are small.

const Painter = preload("res://scripts/stage_bg_painter.gd")

const FAR_Y: float = 150.0
const NEAR_Y: float = 224.0

var _tracer_x: float = -1.0
var _tracer_y: float = 60.0
var _tracer_wait: float = 3.0


static func paint() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 909
	var out: Dictionary = {}

	var sky: Image = Painter.new_img(480, 270)
	sky.fill(Color("#0a0a1c"))
	Painter.vgrad(sky, 22, 258, PackedColorArray([Color("#0a0a1c"), Color("#100f28"), Color("#151434"), Color("#1b1a42"), Color("#21204e")]), 0.45)
	# A dim ringed planet in the upper sky.
	Painter.ellipse(sky, 372.0, 66.0, 34.0, 8.0, Color("#2a2a5a"))
	Painter.disc(sky, 372.0, 66.0, 20.0, Color("#26244e"))
	Painter.disc(sky, 366.0, 61.0, 14.0, Color("#2e2c5c"))
	Painter.ellipse(sky, 372.0, 68.0, 34.0, 2.0, Color("#3a3874"))
	for i: int in range(60):
		Painter.px(sky, rng.randi_range(0, 479), rng.randi_range(24, 140), Color("#5a58a0") if i % 3 == 0 else Color("#34336a"))
	out["sky"] = sky

	# Far mesas: a tileable skyline from a periodic profile, with a lit rim.
	var far: Image = Painter.new_img(512, 96)
	var prof: PackedFloat32Array = Painter.profile(512, rng, 4, 3, 0.55)
	var beacons: PackedVector2Array = PackedVector2Array()
	for x: int in range(512):
		var top: int = int(20.0 + (1.0 - prof[x]) * 56.0)
		Painter.rect(far, x, top, 1, 96 - top, Color("#14132e"))
		Painter.px(far, x, top, Color("#2c2a5e"))
		if x % 64 == 20:
			beacons.append(Vector2(float(x), float(top - 2)))
	out["far"] = far
	out["beacons"] = beacons

	# Near ground strip with target posts.
	var near: Image = Painter.new_img(512, 34)
	Painter.rect(near, 0, 20, 512, 14, Color("#0e0d22"))
	Painter.rect(near, 0, 20, 512, 1, Color("#2a2850"))
	for post_x: int in range(8, 512, 64):
		Painter.rect(near, post_x, 4, 3, 16, Color("#1e1c40"))
		Painter.rect(near, post_x - 3, 4, 9, 2, Color("#3a3874"))
	out["near"] = near
	return out


func reset() -> void:
	drift_a.y0 = 34.0
	drift_a.y1 = 250.0
	drift_a.setup(28, rng, -14.0, -6.0, -3.0, 3.0)
	drift_a.par = 0.3
	drift_a.sway = 2.0
	drift_a.sway_hz = 0.8
	drift_a.cols = PackedColorArray([Color(0.45, 0.42, 0.8, 0.45), Color(0.35, 0.33, 0.66, 0.55)])
	_tracer_x = -1.0
	_tracer_wait = rng.randf_range(2.0, 4.0)


func update() -> void:
	if _tracer_x < 0.0:
		_tracer_wait -= dl
		if _tracer_wait <= 0.0:
			_tracer_x = 500.0
			_tracer_y = rng.randf_range(36.0, 110.0)
	else:
		_tracer_x -= 420.0 * dl
		if _tracer_x < -40.0:
			_tracer_x = -1.0
			_tracer_wait = rng.randf_range(5.0, 9.0)


func draw() -> void:
	bg.draw_texture(tex("sky"), Vector2.ZERO)
	if _tracer_x >= 0.0:
		bg.draw_rect(Rect2(floorf(_tracer_x), _tracer_y, 24.0, 1.0), Color(0.75, 0.7, 1.0, 0.5))
	layer("far", FAR_Y, 0.1)
	var o: float = off(0.1, 512.0)
	var beacons: PackedVector2Array = meta.get("beacons", PackedVector2Array())
	for i: int in range(beacons.size()):
		var bx: float = wrap_x(beacons[i].x, o, 512.0)
		if bx < 0.0 or bx > 480.0:
			continue
		if fposmod(life * 0.9 + float(i) * 0.37, 1.0) < 0.4:
			bg.draw_rect(Rect2(floorf(bx), FAR_Y + beacons[i].y, 1.0, 1.0), Color("#ff4c68"))
	drift_draw(drift_a)
	layer("near", NEAR_Y, 0.9)
