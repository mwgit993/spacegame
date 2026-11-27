extends "res://scripts/stages/stage_enemy.gd"

# PENDULUM BLADE: a crescent axe blade on a long brass rod, hung from a carriage that runs along
# the ceiling rail. It lowers on its rod while it rolls in, then hauls the blade back toward the
# player's side; meanwhile a dotted arc marks the whole sweep (the telegraph, blinking faster
# as the release nears). Released, it swings like a clock pendulum: the blade is the hitbox
# (ramming it hurts), and at each end of a swing it flings a spread of sparks at the player.
# After SWINGS half-swings it winds the rod back up and leaves. variant 1 hangs shorter.

enum Phase { DROP, ARM, SWING, RISE }

const RAIL_Y: float = 30.0
const SCROLL: float = 34.0
const AMP: float = 0.72
const PERIOD: float = 2.1
const DROP_T: float = 0.9
const ARM_T: float = 1.1
const SWINGS: int = 6
const RELEASE_X: float = 425.0

var state: Phase = Phase.DROP
var timer: float = 0.0
var pivot: Vector2 = Vector2(500.0, RAIL_Y)
var length: float = 132.0
var cur_len: float = 10.0
var theta: float = 0.0
var swing_t: float = 0.0
var ends: int = 0
var gear_rot: float = 0.0


func setup() -> void:
	length = 108.0 if variant == 1 else 132.0
	pivot = Vector2(enemy.global_position.x, RAIL_Y)
	cur_len = 10.0
	timer = DROP_T
	_place()


func _place() -> void:
	enemy.global_position = pivot + Vector2(sin(theta), cos(theta)) * cur_len
	var f: int = clampi(roundi((-theta + 0.9) / 1.8 * 8.0), 0, 8)
	set_texture("clock_blade_%d" % f)


func tick(delta: float) -> void:
	pivot.x -= SCROLL * delta
	match state:
		Phase.DROP:
			timer -= delta
			cur_len = lerpf(length, 10.0, clampf(timer / DROP_T, 0.0, 1.0))
			gear_rot += delta * 9.0
			if timer <= 0.0 and pivot.x < RELEASE_X + 30.0:
				state = Phase.ARM
				timer = ARM_T
				sfx("boss_hp_tick", -14.0, 0.0)
		Phase.ARM:
			timer -= delta
			var k: float = 1.0 - clampf(timer / ARM_T, 0.0, 1.0)
			theta = -AMP * (k * k * (3.0 - 2.0 * k))
			gear_rot -= delta * 5.0
			if timer <= 0.0 and pivot.x < RELEASE_X:
				state = Phase.SWING
				swing_t = 0.0
				ends = 0
				sfx("missile", -15.0, 0.05)
			elif timer <= 0.0:
				timer = 0.0
		Phase.SWING:
			swing_t += delta
			var w: float = TAU / PERIOD
			theta = -AMP * cos(w * swing_t)
			var half: int = int(swing_t * w / PI)
			if half > ends:
				ends = half
				_fling()
				if ends >= SWINGS:
					state = Phase.RISE
		Phase.RISE:
			swing_t += delta
			theta = -AMP * cos(TAU / PERIOD * swing_t) * maxf(0.0, cur_len / length)
			cur_len -= 70.0 * delta
			gear_rot += delta * 9.0
			if cur_len <= 8.0:
				leave()
				return
	_place()


func _fling() -> void:
	var p: Vector2 = enemy.global_position
	for k: float in [-0.5, 0.5]:
		shoot_aimed_from(p, 118.0, "clock_spark", k * 0.24)
	sparks(p, Color("#ffe070"), 4)
	sfx("laser", -16.0, 0.12)


func draw() -> void:
	var pv: Vector2 = pivot - enemy.global_position
	var ang: float = -theta
	var collar: Vector2 = Vector2(0.0, -11.0).rotated(ang)
	# The sweep arc while it lowers and hauls back: dotted, blinking faster near the release.
	if state == Phase.DROP or state == Phase.ARM:
		var k: float = (1.0 - timer / ARM_T) if state == Phase.ARM else 0.0
		var blink: float = 0.5 + 0.5 * sin(age * (8.0 + 22.0 * k))
		var col: Color = Color(1.0, 0.82, 0.4, 0.16 + 0.22 * blink * (0.4 + 0.6 * k))
		var n: int = 26
		for i: int in range(n + 1):
			var a: float = lerpf(-AMP, AMP, float(i) / float(n))
			var q: Vector2 = pv + Vector2(sin(a), cos(a)) * length
			enemy.draw_rect(Rect2(q.floor(), Vector2(2.0, 2.0) if i % 13 == 0 else Vector2.ONE), col)
	# Rod: a dark core with a brass edge, from the collar up to the carriage.
	enemy.draw_line(collar, pv, Color("#2a1808"), 3.0)
	enemy.draw_line(collar, pv, Color("#c8963a"), 1.0)
	# The carriage on the ceiling rail with a little winding gear.
	enemy.draw_rect(Rect2(pv.x - 6.0, pv.y - 2.0, 12.0, 6.0), Color("#3a2410"))
	enemy.draw_rect(Rect2(pv.x - 5.0, pv.y - 2.0, 10.0, 2.0), Color("#e0b85a"))
	enemy.draw_circle(pv + Vector2(0.0, 3.0), 3.0, Color("#7a5220"))
	for s: int in range(4):
		var ga: float = gear_rot + PI * 0.5 * float(s)
		var gp: Vector2 = pv + Vector2(0.0, 3.0) + Vector2.from_angle(ga) * 3.0
		enemy.draw_rect(Rect2(gp.floor(), Vector2.ONE), Color("#ffe890"))
	enemy.draw_circle(pv + Vector2(0.0, 3.0), 1.0, Color("#5ff2dc"))
	# A glint runs along the edge at the bottom of each swing.
	if state == Phase.SWING and absf(theta) < 0.12:
		enemy.draw_circle(Vector2(0.0, 5.0).rotated(ang), 3.0, Color(1.0, 1.0, 1.0, 0.45))
	draw_hp_bar(22.0, -22.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#d8e2ea"), 8)
	sparks(enemy.global_position, Color("#e8c060"), 5)
