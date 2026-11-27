extends "res://scripts/stages/stage_boss.gd"

# MEGA EXCAVATOR "MAWGRINDER": a bucket-wheel excavator. Three patterns, switching every 4
# attacks; each phase adds rocks and rate_mult shortens the cooldowns.
#   0 ORE SPRAY  the wheel flings a fan of ore rocks up and over; they arc down across the cave
#                (phase 3 adds an aimed pair from the cab)
#   1 CRUSHER    the jaw spits a shotgun cone at the player (phase 3: a second, offset cone)
#   2 CAVE-IN    dust puffs and warning chevrons mark spots on the ceiling (one above the
#                player), then rocks drop from exactly there

const WHEEL: Vector2 = Vector2(-30.0, -36.0)
const JAW: Vector2 = Vector2(-48.0, 35.0)
const CEIL: float = 34.0

var marks: PackedFloat32Array = PackedFloat32Array()
var mark_t: float = 0.0


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			var n: int = 4 + phase * 2
			var origin: Vector2 = pos() + WHEEL
			for i: int in range(n):
				var t: float = (float(i) + 0.5) / float(n)
				var ang: float = PI + lerpf(0.2, 0.95, t) + sin(spin + float(i)) * 0.05
				var spd: float = lerpf(235.0, 150.0, t) + spd_bonus * 0.5
				var b: GameBullet = emit_bullet(origin, Vector2.from_angle(ang) * spd, bullet_b(), 3.0)
				if b != null:
					b.gravity_pull = 140.0
			spin += 0.7
			if phase >= 3:
				for k: int in [-1, 1]:
					shoot_aimed_from(pos() + Vector2(-20.0, -50.0), 170.0 + spd_bonus, bullet_a(), float(k) * 0.08)
			wait(1.0 * rate_mult)
		1:
			var cones: int = 2 if phase >= 3 else 1
			for c: int in range(cones):
				var n2: int = 5 + phase * 2
				var off: float = 0.0 if c == 0 else 0.42 * (1.0 if substep % 2 == 0 else -1.0)
				for i2: int in range(n2):
					var t2: float = (float(i2) / float(n2 - 1)) - 0.5
					var spd2: float = 150.0 + float((i2 * 37) % 5) * 12.0 + spd_bonus
					shoot_aimed_from(pos() + JAW, spd2, bullet_a(), off + t2 * 0.6)
			wait(0.9 * rate_mult)
		_:
			if substep % 2 == 0:
				_mark_ceiling()
				wait(0.75)
			else:
				_drop_rocks()
				wait(0.55 * rate_mult)


func _mark_ceiling() -> void:
	marks.clear()
	mark_t = 0.0
	var n: int = 3 + phase
	var px: float = clampf(player_pos().x, 30.0, 330.0)
	marks.append(px)
	var lane_w: float = 300.0 / float(n)
	for i: int in range(n):
		var x: float = 40.0 + lane_w * (float(i) + randf_range(0.2, 0.8))
		if absf(x - px) > 22.0:
			marks.append(x)
	RetroSfx.play("boss_hp_tick", -10.0, 0.1)


func _drop_rocks() -> void:
	for x: float in marks:
		for k: int in [0, 1 if int(x) % 2 == 0 else -1]:
			var b: GameBullet = emit_bullet(Vector2(x + float(k) * 7.0, CEIL + absf(float(k)) * 2.0), Vector2(float(k) * 14.0, 46.0 - absf(float(k)) * 16.0), bullet_b(), 3.0)
			if b != null:
				b.gravity_pull = 250.0
	marks.clear()
	RetroSfx.play("explode", -10.0, 0.1)


func draw() -> void:
	if marks.is_empty():
		return
	var k: float = 0.5 + 0.5 * sin(age * 26.0)
	for x: float in marks:
		var l: Vector2 = Vector2(x, CEIL) - pos()
		boss.draw_circle(l + Vector2(0.0, 2.0), 5.0 + 2.0 * k, Color(0.55, 0.45, 0.32, 0.35))
		var col: Color = Color(1.0, 0.75, 0.2, 0.55 + 0.4 * k)
		boss.draw_colored_polygon(PackedVector2Array([l + Vector2(-4.0, 8.0), l + Vector2(4.0, 8.0), l + Vector2(0.0, 13.0)]), col)
		boss.draw_colored_polygon(PackedVector2Array([l + Vector2(-4.0, 15.0), l + Vector2(4.0, 15.0), l + Vector2(0.0, 20.0)]), Color(col.r, col.g, col.b, col.a * 0.6))
		var y: float = 24.0 + fposmod(age * 90.0, 12.0)
		while y < 222.0:
			boss.draw_line(l + Vector2(0.0, y), l + Vector2(0.0, y + 4.0), Color(1.0, 0.75, 0.2, 0.18), 1.0)
			y += 12.0
