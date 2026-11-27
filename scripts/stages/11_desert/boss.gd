extends "res://scripts/stages/stage_boss.gd"

# SPHINX ENGINE "ANKHERA": a mechanical sphinx. Three patterns, switching every 4 attacks; each
# phase adds shots and rate_mult shortens the cooldowns.
#   0 EYE BEAMS   the eyes take turns firing an aimed spread (the next eye glows first);
#                 from phase 2 the mouth adds a slow glyph to each side
#   1 SAND TIDE   ripples spread on the dunes at marked spots (one under the player), then sand
#                 geysers erupt from exactly there and rain back down
#   2 GLYPH RINGS rings of glyph shards from the ankh core with a gap that sweeps up and down;
#                 phase 3 fires a second, slower ring inside the first

const EYE_L: Vector2 = Vector2(-26.0, -37.0)
const EYE_R: Vector2 = Vector2(-12.0, -37.0)
const MOUTH: Vector2 = Vector2(-20.0, -19.0)
const ANKH: Vector2 = Vector2(2.0, 18.0)
const FLOOR: float = 254.0

var marks: PackedFloat32Array = PackedFloat32Array()


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			var eye: Vector2 = EYE_L if substep % 2 == 0 else EYE_R
			var n: int = 3 + phase
			for k: int in range(n):
				var a: float = (float(k) - float(n - 1) * 0.5) * 0.13
				shoot_aimed_from(pos() + eye, 178.0 + spd_bonus, bullet_a(), a)
			if phase >= 2:
				for s: float in [-0.36, 0.36]:
					shoot_aimed_from(pos() + MOUTH, 125.0 + spd_bonus * 0.5, bullet_b(), s)
			wait(0.66 * rate_mult)
		1:
			if substep % 2 == 0:
				_mark_floor()
				wait(0.8)
			else:
				_erupt()
				wait(0.6 * rate_mult)
		_:
			var count: int = 11 + phase * 2
			_glyph_ring(count, 112.0 + spd_bonus * 0.6, spin, PI + sin(age * 0.9) * 0.55)
			if phase >= 3:
				_glyph_ring(count - 2, 82.0 + spd_bonus * 0.4, -spin + 0.2, PI - sin(age * 0.9) * 0.55)
			spin += 0.31
			wait(0.85 * rate_mult)


# One ring from the ankh core, leftward half only (like the built-in rings), with a 2-shot gap
# around gap_ang.
func _glyph_ring(count: int, speed: float, rot: float, gap_ang: float) -> void:
	var origin: Vector2 = pos() + ANKH
	for i: int in range(count):
		var a: float = rot + TAU * float(i) / float(count)
		var v: Vector2 = Vector2.from_angle(a) * speed
		if v.x >= 35.0:
			continue
		if absf(angle_difference(a, gap_ang)) < TAU / float(count) * 1.05:
			continue
		shoot_from(origin, v, bullet_b())


func _mark_floor() -> void:
	marks.clear()
	var n: int = 3 + phase
	var px: float = clampf(player_pos().x, 24.0, 330.0)
	marks.append(px)
	var lane_w: float = 300.0 / float(n)
	for i: int in range(n):
		var x: float = 30.0 + lane_w * (float(i) + randf_range(0.2, 0.8))
		if absf(x - px) > 24.0:
			marks.append(x)
	RetroSfx.play("boss_hp_tick", -10.0, 0.1)


func _erupt() -> void:
	for x: float in marks:
		for k: int in range(4):
			var b: GameBullet = emit_bullet(Vector2(x + float(k % 2) * 3.0 - 1.5, FLOOR), Vector2(randf_range(-12.0, 12.0), -(250.0 - float(k) * 36.0)), "desert_sand", 3.0)
			if b != null:
				b.gravity_pull = 200.0
	marks.clear()
	RetroSfx.play("explode", -10.0, 0.1)


func draw() -> void:
	# The eye about to fire glows.
	if pattern == 0 and boss._fire_timer < 0.3:
		var eye: Vector2 = EYE_L if (substep + 1) % 2 == 0 else EYE_R
		var k: float = 1.0 - boss._fire_timer / 0.3
		boss.draw_circle(eye + Vector2(-6.0, 0.0), 2.0 + 4.0 * k, Color(0.3, 1.0, 0.9, 0.25 + 0.35 * k))
	if marks.is_empty():
		return
	var pulse: float = 0.5 + 0.5 * sin(age * 24.0)
	for x: float in marks:
		var l: Vector2 = Vector2(x, FLOOR) - pos()
		boss.draw_set_transform(l, 0.0, Vector2(1.0, 0.3))
		for i: int in range(3):
			var r: float = fposmod(age * 22.0 + float(i) * 6.0, 18.0)
			boss.draw_arc(Vector2.ZERO, r + 2.0, 0.0, TAU, 18, Color(1.0, 0.78, 0.45, 0.6 * (1.0 - r / 20.0)), 1.0)
		boss.draw_circle(Vector2.ZERO, 4.0 + 2.0 * pulse, Color(0.15, 0.07, 0.06, 0.6))
		boss.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for j: int in range(4):
			var t: float = fposmod(age * 3.2 + float(j) * 0.25, 1.0)
			boss.draw_rect(Rect2(l.x + float(j - 2) * 3.0, l.y - t * 16.0 + t * t * 12.0, 1.0, 1.0), Color(0.95, 0.75, 0.45, 0.9 * (1.0 - t)))
