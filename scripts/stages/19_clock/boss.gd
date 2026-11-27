extends "res://scripts/stages/stage_boss.gd"

# CHRONOS COLOSSUS: a clocktower colossus whose attacks follow its clock. The hands, the dial
# glow, the bell glow and the pendulum in its glass case are drawn live by a small overlay node
# on top of the sprite (the AI's own draw() renders behind the sprite). Patterns switch every
# 4 attacks; each phase adds shots and rate_mult shortens the cooldowns.
#   0 HAND VOLLEY  every hand that points forward fires a line of bolts along itself; dotted
#                  guide rays show where each hand will fire. The hands keep turning, so the
#                  lines sweep. Phase 2 adds the ticking red second hand; phase 3 the minute
#                  hand fires from its tail too.
#   1 TOLLING BELL the dial and the bell glow, then the bell tolls: a ring of rivets from the
#                  belfry, and the hour hand jumps an hour. Phase 2+ adds an aimed burst from
#                  the dial.
#   2 PENDULUM     the pendulum bob glows and a fan of spinning saw cogs is flung from the
#                  case (a dotted fan shows the aim); in between, the shoulder gears spit
#                  sprays of rivets.

const DIAL: Vector2 = Vector2(-8.0, -10.0)     # dial centre, local (art.gd DIAL - half size)
const DIAL_R: float = 25.0
const BELL: Vector2 = Vector2(4.0, -45.0)
const PEND_PIVOT: Vector2 = Vector2(-7.0, 23.0)
const PEND_LEN: float = 27.0
const GEARS: Array[Vector2] = [Vector2(30.0, -42.0), Vector2(32.0, 50.0)]
const MIN_W: float = 1.15      # minute hand, rad/s (clockwise)
const HOUR_W: float = 0.32
const TELL: float = 0.4

var overlay: Node2D = null
var hour_steps: int = 0
var min_base: float = 0.0
var hour_base: float = 0.0


class HandsOverlay extends Node2D:
	var ai: RefCounted = null

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ai != null:
			ai.call("draw_overlay", self)


func setup() -> void:
	min_base = randf() * TAU
	hour_base = randf() * TAU
	var o: HandsOverlay = HandsOverlay.new()
	o.ai = self
	boss.add_child(o)
	overlay = o


# --- The clock ---------------------------------------------------------------------------------

func _minute_a() -> float:
	return min_base + age * MIN_W


func _hour_a() -> float:
	return hour_base + age * HOUR_W + float(hour_steps) * TAU / 12.0


# The red second hand ticks a twelfth of a turn four times a second.
func _second_a() -> float:
	return -PI * 0.5 + floorf(age * 4.0) * TAU / 12.0


func _pend_a() -> float:
	return sin(age * 2.6) * 0.33


# Hands that fire in a HAND VOLLEY: [origin offset along the hand, angle].
func _armed_hands() -> Array[float]:
	var out: Array[float] = [_minute_a(), _hour_a()]
	if phase >= 2:
		out.append(_second_a())
	if phase >= 3:
		out.append(_minute_a() + PI)
	return out


func _next_pattern() -> int:
	return pattern if substep < 3 else (pattern + 1) % 3


# The next attack is a PENDULUM saw fan (the even substeps of pattern 2).
func _next_is_fan() -> bool:
	return _next_pattern() == 2 and ((substep + 1) % 4) % 2 == 0


# --- Attacks -----------------------------------------------------------------------------------

func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			var c: Vector2 = pos() + DIAL
			var fired: int = 0
			for a: float in _armed_hands():
				var dir: Vector2 = Vector2.from_angle(a)
				if dir.x > 0.25:
					continue
				fired += 1
				for k: int in range(3):
					shoot_from(c + dir * (DIAL_R + 2.0), dir * (96.0 + float(k) * 30.0 + spd_bonus), bullet_b())
			if fired == 0:
				# Every hand points backwards: the dial fires an aimed bolt line instead.
				for k2: int in range(4):
					shoot_aimed_from(c, 100.0 + float(k2) * 22.0 + spd_bonus, bullet_b())
			shoot_aimed_from(c, 150.0 + spd_bonus, bullet_a())
			RetroSfx.play("laser", -13.0, 0.06)
			wait(0.55 * rate_mult)
		1:
			var b: Vector2 = pos() + BELL
			shoot_ring(12 + phase * 2, 104.0 + spd_bonus * 0.6, "clock_rivet", spin)
			spin += 0.19
			hour_steps += 1
			if phase >= 2:
				for k3: int in [-1, 0, 1]:
					shoot_aimed_from(pos() + DIAL, 160.0 + spd_bonus, bullet_a(), float(k3) * 0.14)
			if phase >= 3:
				shoot_ring(10, 132.0 + spd_bonus * 0.6, bullet_b(), spin + 0.3)
			RetroSfx.play("boss_hp_tick", -6.0, 0.0)
			if boss.fx != null:
				boss.fx.spawn_hit_sparks(b, Color("#ffe070"), 6)
			wait(0.68 * rate_mult)
		_:
			if substep % 2 == 0:
				var origin: Vector2 = _bob_pos()
				var n: int = 4 + phase
				for i: int in range(n):
					var off: float = (float(i) - float(n - 1) * 0.5) * 0.2
					var sb: GameBullet = emit_bullet(origin, (player_pos() - origin).normalized().rotated(off) * (122.0 + spd_bonus), "clock_saw_0", 4.0)
					if sb != null:
						sb.anim_tex_b = "clock_saw_1"
				RetroSfx.play("missile", -10.0, 0.05)
				wait(0.6 * rate_mult)
			else:
				for g: Vector2 in GEARS:
					var gp: Vector2 = pos() + g
					var rot: float = spin
					for j: int in range(10):
						var v: Vector2 = Vector2.from_angle(rot + TAU * float(j) / 10.0) * (110.0 + spd_bonus * 0.6)
						if v.x < 20.0:
							shoot_from(gp, v, "clock_rivet")
				spin += 0.27
				RetroSfx.play("laser", -12.0, 0.1)
				wait(0.58 * rate_mult)


func _bob_pos() -> Vector2:
	return pos() + PEND_PIVOT + Vector2(sin(_pend_a()), cos(_pend_a())) * PEND_LEN


# --- Drawing -----------------------------------------------------------------------------------

# The standard draw() renders behind the sprite: the guide rays and fan previews stick out past
# the silhouette, so they go here.
func draw() -> void:
	var t: float = boss._fire_timer
	var k: float = clampf(1.0 - t / 0.6, 0.0, 1.0)
	var np: int = _next_pattern()
	if np == 0:
		var hands: Array[float] = _armed_hands()
		for a: float in hands:
			var dir: Vector2 = Vector2.from_angle(a)
			if dir.x > 0.25:
				continue
			var col: Color = Color(0.45, 1.0, 0.9, 0.12 + 0.3 * k)
			var d: float = DIAL_R + 8.0
			while d < 300.0:
				var q: Vector2 = DIAL + dir * d
				boss.draw_rect(Rect2(q.floor(), Vector2.ONE), col)
				d += 6.0
	elif _next_is_fan():
		var origin: Vector2 = _bob_pos() - pos()
		var aim: Vector2 = (player_pos() - pos() - origin).normalized()
		for s: int in [-1, 1]:
			var dir2: Vector2 = aim.rotated(float(s) * 0.2 * float(2 + phase) * 0.5)
			var d2: float = 30.0
			while d2 < 120.0:
				boss.draw_rect(Rect2((origin + dir2 * d2).floor(), Vector2.ONE), Color(1.0, 0.85, 0.4, 0.1 + 0.3 * k))
				d2 += 7.0


func draw_overlay(o: Node2D) -> void:
	if boss == null or boss.boss_intro_active or boss._boss_dying:
		return
	var t: float = boss._fire_timer
	var tell: float = clampf(1.0 - t / TELL, 0.0, 1.0)
	var np: int = _next_pattern()
	# Dial and bell glow before a toll.
	if np == 1 and tell > 0.0:
		o.draw_circle(DIAL, DIAL_R, Color(1.0, 0.85, 0.45, 0.22 * tell))
		o.draw_circle(BELL, 5.0 + 4.0 * tell, Color(1.0, 0.9, 0.5, 0.25 + 0.4 * tell))
		o.draw_circle(BELL, 2.0 + 2.0 * tell, Color(1.0, 1.0, 0.85, 0.8 * tell))
	# The pendulum in its case.
	var pa: float = _pend_a()
	var bob: Vector2 = PEND_PIVOT + Vector2(sin(pa), cos(pa)) * PEND_LEN
	o.draw_line(PEND_PIVOT, bob, Color("#c8963a"), 1.0)
	o.draw_circle(PEND_PIVOT, 1.5, Color("#e8c060"))
	var bob_glow: bool = _next_is_fan() and tell > 0.0
	o.draw_circle(bob, 4.0, Color("#5a3a14"))
	o.draw_circle(bob, 3.0, Color("#ffe890") if bob_glow else Color("#d8a848"))
	o.draw_rect(Rect2(bob.x - 1.0, bob.y - 2.0, 1.0, 1.0), Color("#fff8d8"))
	if bob_glow:
		o.draw_circle(bob, 5.0 + 3.0 * tell, Color(1.0, 0.85, 0.4, 0.3 * tell))
	# Hands: hour (broad spade), minute (long), second (thin red, from phase 2).
	var vol: bool = np == 0 and tell > 0.0
	_hand(o, _hour_a(), 14.0, 2.6, Color("#1e1610"), Color("#b8862e"), vol)
	_hand(o, _minute_a(), 21.0, 1.8, Color("#1e1610"), Color("#b8862e"), vol)
	if phase >= 2:
		var sd: Vector2 = Vector2.from_angle(_second_a())
		o.draw_line(DIAL - sd * 6.0, DIAL + sd * 22.0, Color("#c81c18"), 1.0)
		o.draw_circle(DIAL - sd * 6.0, 1.5, Color("#c81c18"))
	if phase >= 3:
		var md: Vector2 = Vector2.from_angle(_minute_a() + PI)
		o.draw_line(DIAL, DIAL + md * 9.0, Color("#1e1610"), 2.0)
	o.draw_circle(DIAL, 3.0, Color("#3a2410"))
	o.draw_circle(DIAL, 2.0, Color("#e8c060"))
	o.draw_rect(Rect2(DIAL.x, DIAL.y, 1.0, 1.0), Color("#5ff2dc"))


func _hand(o: Node2D, a: float, length: float, width: float, col: Color, edge: Color, glow: bool) -> void:
	var dir: Vector2 = Vector2.from_angle(a)
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var pts: PackedVector2Array = PackedVector2Array([
		DIAL - dir * 3.0 + nrm * width * 0.5,
		DIAL + dir * length * 0.55 + nrm * width,
		DIAL + dir * length,
		DIAL + dir * length * 0.55 - nrm * width,
		DIAL - dir * 3.0 - nrm * width * 0.5,
	])
	o.draw_colored_polygon(pts, col)
	o.draw_line(DIAL + dir * 2.0, DIAL + dir * (length - 1.0), Color("#5ff2dc") if glow else edge, 1.0)
