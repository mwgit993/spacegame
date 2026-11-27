extends "res://scripts/stages/stage_boss.gd"

# MAELSTROM KRAKEN: a storm-scarred giant squid wrapped around a wrecked mast. Three patterns,
# switching every 4 attacks; each phase adds shots and rate_mult shortens the cooldowns.
#   0 TENTACLE LASH  ripples race along a lane (one at your height; two from phase 2), then an
#                    arm lashes through it: a crescent wave of spray sweeps the whole lane. The
#                    first attack of the pattern is a spit from the beak while it marks the lane.
#   1 GEYSERS        foam rings bubble up at marked columns along the sea (one under you), then
#                    each erupts into a spout of water that climbs and rains back down.
#   2 MAELSTROM      a whirlpool turns in front of the beak and sprays a turning spiral of drops;
#                    phase 3 adds a slower counter-spiral.

const BEAK: Vector2 = Vector2(-30.0, 29.0)
const LASH_X: float = -58.0
const WATER_Y: float = 246.0
const LASH_WAIT: float = 0.95
const GEYSER_WAIT: float = 1.0

var lanes: PackedFloat32Array = PackedFloat32Array()     # world y of the next lash lanes
var columns: PackedFloat32Array = PackedFloat32Array()   # world x of the next geysers
var mark_time: float = 1.0


func attack(rate_mult: float, spd_bonus: float) -> void:
	# Anything still marked from the last attack goes off first (also across a pattern change).
	if not lanes.is_empty():
		_lash(spd_bonus)
	if not columns.is_empty():
		_erupt(spd_bonus)
	match pattern:
		0:
			if substep == 0:
				_spit(spd_bonus, 5)
			if substep < 3:
				_mark_lanes()
				mark_time = LASH_WAIT * rate_mult
				wait(mark_time)
			else:
				if phase >= 3:
					_spit(spd_bonus, 3)
				wait(0.6 * rate_mult)
		1:
			if substep == 0:
				_spit(spd_bonus, 3 + phase)
			if substep < 3:
				_mark_columns()
				mark_time = GEYSER_WAIT * rate_mult
				wait(mark_time)
			else:
				_spit(spd_bonus, 3 + phase)
				wait(0.6 * rate_mult)
		_:
			var arms: int = 3 + phase
			var origin: Vector2 = pos() + BEAK + Vector2(-8.0, 0.0)
			for a: int in range(arms * 2):
				var ang: float = spin + TAU * float(a) / float(arms * 2)
				var v: Vector2 = Vector2.from_angle(ang) * (112.0 + spd_bonus * 0.6)
				if v.x < 30.0:
					emit_bullet(origin, v, "ocean_drop")
			if phase >= 3:
				for a2: int in range(5):
					var ang2: float = -spin * 1.3 + TAU * float(a2) / 5.0
					var v2: Vector2 = Vector2.from_angle(ang2) * (88.0 + spd_bonus * 0.4)
					if v2.x < 20.0:
						shoot_from(origin, v2, bullet_a())
			spin += 0.27
			wait(0.44 * rate_mult)


# An aimed fan of droplets from the beak.
func _spit(spd_bonus: float, n: int) -> void:
	for i: int in range(n):
		var off: float = (float(i) - float(n - 1) * 0.5) * 0.14
		shoot_aimed_from(pos() + BEAK, 150.0 + spd_bonus * 0.7, bullet_b(), off)
	RetroSfx.play("missile", -12.0, 0.08)


func _mark_lanes() -> void:
	lanes.clear()
	var py: float = clampf(player_pos().y, 46.0, 230.0)
	lanes.append(py)
	if phase >= 2:
		var other: float = py + (78.0 if py < 138.0 else -78.0)
		lanes.append(clampf(other, 46.0, 230.0))
	RetroSfx.play("boss_hp_tick", -12.0, 0.05)


# A crescent wave of spray sweeping along each marked lane.
func _lash(spd_bonus: float) -> void:
	var spd: float = 150.0 + spd_bonus * 0.6
	for y: float in lanes:
		for j: int in range(-4, 5):
			var p: Vector2 = Vector2(pos().x + LASH_X + absf(float(j)) * 3.0, y + float(j) * 4.6)
			emit_bullet(p, Vector2(-spd, float(j) * 5.0), "ocean_drop")
	lanes.clear()
	RetroSfx.play("explode", -12.0, 0.1)
	if boss.fx != null:
		boss.fx.add_shake(2.0)


func _mark_columns() -> void:
	columns.clear()
	var n: int = 2 + phase
	columns.append(clampf(player_pos().x + randf_range(-6.0, 6.0), 26.0, 330.0))
	var tries: int = 0
	while columns.size() < n and tries < 40:
		tries += 1
		var x: float = randf_range(26.0, 340.0)
		var ok: bool = true
		for c: float in columns:
			if absf(c - x) < 44.0:
				ok = false
				break
		if ok:
			columns.append(x)
	RetroSfx.play("boss_hp_tick", -13.0, 0.1)


# Each marked column erupts into a spout that climbs and rains back down.
func _erupt(spd_bonus: float) -> void:
	var g: float = 190.0
	for x: float in columns:
		for k: int in range(5):
			var v: Vector2 = Vector2(randf_range(-26.0, 18.0), -(176.0 + float(k) * 26.0 + spd_bonus * 0.3))
			var b: GameBullet = emit_bullet(Vector2(x + randf_range(-3.0, 3.0), WATER_Y), v, "ocean_drop")
			if b != null:
				b.gravity_pull = g
		if boss.fx != null:
			boss.fx.spawn_hit_sparks(Vector2(x, WATER_Y - 2.0), Color("#c8f4ff"), 6)
	columns.clear()
	RetroSfx.play("explode", -13.0, 0.1)


func draw() -> void:
	var o: Vector2 = pos()
	var left: float = -o.x
	var k: float = clampf(1.0 - boss._fire_timer / maxf(0.01, mark_time), 0.0, 1.0)
	# Lash lanes: ripple dashes racing left along the lane, brightening as the lash nears.
	for y: float in lanes:
		var ly: float = floorf(y - o.y)
		var a: float = 0.16 + 0.4 * k
		for r: int in range(12):
			var rx: float = LASH_X - 4.0 - fposmod(age * 210.0 + float(r) * 34.0, 408.0)
			if rx < left:
				continue
			boss.draw_rect(Rect2(floorf(rx), ly, 9.0, 1.0), Color(0.75, 0.95, 1.0, a))
			boss.draw_rect(Rect2(floorf(rx) + 2.0, ly - 1.0, 4.0, 1.0), Color(0.75, 0.95, 1.0, a * 0.5))
		boss.draw_rect(Rect2(left, ly - 18.0, LASH_X - left, 1.0), Color(0.55, 0.85, 1.0, 0.07 + 0.12 * k))
		boss.draw_rect(Rect2(left, ly + 18.0, LASH_X - left, 1.0), Color(0.55, 0.85, 1.0, 0.07 + 0.12 * k))
	# Geyser columns: foam rings bubbling up where the sea will erupt, and a faint rising guide.
	for x: float in columns:
		var c: Vector2 = Vector2(floorf(x - o.x), floorf(WATER_Y - o.y))
		boss.draw_set_transform(c, 0.0, Vector2(1.0, 0.32))
		for i: int in range(2):
			var rr: float = fposmod(age * 22.0 + float(i) * 8.0, 16.0) * (0.6 + 0.6 * k)
			boss.draw_arc(Vector2.ZERO, rr + 3.0, 0.0, TAU, 16, Color(0.8, 0.96, 1.0, 0.6 * (1.0 - rr / 20.0)), 1.0)
		boss.draw_circle(Vector2.ZERO, 3.0 + 6.0 * k, Color(0.85, 0.97, 1.0, 0.25 + 0.3 * k))
		boss.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var top: float = c.y - (40.0 + 110.0 * k)
		var yy: float = c.y - 6.0
		while yy > top:
			boss.draw_rect(Rect2(c.x, floorf(yy), 1.0, 2.0), Color(0.8, 0.95, 1.0, 0.12 + 0.3 * k))
			yy -= 7.0
		for j: int in range(3):
			var t: float = fposmod(age * 3.0 + float(j) * 0.33, 1.0)
			boss.draw_rect(Rect2(c.x + float(j * 3 - 3), c.y - (t * 12.0 - t * t * 8.0) * (0.5 + k), 1.0, 1.0), Color(0.9, 0.98, 1.0, 0.8 * (1.0 - t)))
	# Maelstrom: a whirlpool turning in front of the beak while the spiral runs.
	if pattern == 2:
		var w: Vector2 = BEAK + Vector2(-16.0, 0.0)
		for arm: int in range(3):
			var pts: PackedVector2Array = PackedVector2Array()
			for s: int in range(8):
				var ang: float = age * 6.0 + float(arm) * TAU / 3.0 + float(s) * 0.5
				pts.append(w + Vector2.from_angle(ang) * (3.0 + float(s) * 1.6))
			boss.draw_polyline(pts, Color(0.6, 0.95, 1.0, 0.45), 1.0)
