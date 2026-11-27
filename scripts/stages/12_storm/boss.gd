extends "res://scripts/stages/stage_boss.gd"

# STORMCALLER: a weather-control engine. Three patterns, switching every 4 attacks; each phase
# adds bullets and rate_mult shortens the cooldowns.
#   0 LIGHTNING LANCES  strike columns light up at several x positions (one on the player) with a
#                       flickering line and a cloud flash, then bolts fall down exactly there as
#                       fast vertical streams (phase 3 adds an aimed spark spread from the lens)
#   1 CYCLONE           curved spiral arms wheel out of the lens, alternating direction each
#                       volley (phase 2+: a fourth arm)
#   2 HAIL              the top coil lobs a fan of hailstones that arc up and rain down, while the
#                       bottom coil fires a short aimed burst

const LENS: Vector2 = Vector2(-28.0, 0.0)
const COIL_TOP: Vector2 = Vector2(-32.0, -54.0)
const COIL_BOT: Vector2 = Vector2(-32.0, 54.0)
const TOP_Y: float = 26.0

var columns: PackedFloat32Array = PackedFloat32Array()


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			if substep % 2 == 0:
				_mark_columns()
				wait(0.75)
			else:
				_strike(spd_bonus)
				if phase >= 3:
					for k: int in range(-2, 3):
						shoot_aimed_from(pos() + LENS, 165.0 + spd_bonus, bullet_b(), float(k) * 0.14)
				wait(0.6 * rate_mult)
		1:
			var arms: int = 3 if phase < 2 else 4
			var layers: int = 4
			var turn: float = 1.0 if substep % 2 == 0 else -1.0
			for a: int in range(arms):
				for l: int in range(layers):
					var ang: float = spin + TAU * float(a) / float(arms) + turn * float(l) * 0.2
					var v: Vector2 = Vector2.from_angle(ang) * (105.0 + float(l) * 17.0 + spd_bonus * 0.6)
					if v.x < 20.0:
						emit_bullet(pos() + LENS, v, bullet_b())
			spin += 0.55 * turn
			wait(0.9 * rate_mult)
		_:
			var n: int = 4 + phase * 2
			for i: int in range(n):
				var t: float = (float(i) + 0.5) / float(n)
				var ang2: float = PI + lerpf(0.15, 0.9, t)
				var spd: float = lerpf(250.0, 150.0, t) + spd_bonus * 0.4
				var b: GameBullet = emit_bullet(pos() + COIL_TOP, Vector2.from_angle(ang2) * spd, "storm_hail", 3.0)
				if b != null:
					b.gravity_pull = 150.0
			for k2: int in range(2 + phase):
				shoot_aimed_from(pos() + COIL_BOT, 175.0 + spd_bonus + float(k2) * 14.0, bullet_a(), 0.0)
			wait(1.05 * rate_mult)


# Strike columns: one on the player, the rest spread across the open screen.
func _mark_columns() -> void:
	columns.clear()
	var px: float = clampf(player_pos().x, 24.0, 330.0)
	columns.append(px)
	var n: int = 2 + phase
	var lane_w: float = 300.0 / float(n)
	for i: int in range(n):
		var x: float = 30.0 + lane_w * (float(i) + randf_range(0.2, 0.8))
		if absf(x - px) > 26.0:
			columns.append(x)
	RetroSfx.play("boss_hp_tick", -10.0, 0.1)


# Each column becomes a falling bolt: a stack of sparks dropped at staggered speeds, so the
# stream stretches out as it falls.
func _strike(spd_bonus: float) -> void:
	for x: float in columns:
		for k: int in range(5):
			emit_bullet(Vector2(x + float(k % 2) * 2.0 - 1.0, TOP_Y), Vector2(0.0, 300.0 - float(k) * 34.0 + spd_bonus * 0.5), bullet_b())
	columns.clear()
	RetroSfx.play("zap", -8.0, 0.1)


func draw() -> void:
	if not columns.is_empty():
		var k: float = 0.5 + 0.5 * sin(age * 30.0)
		var flick: float = float(int(age * 20.0) % 2)
		for x: float in columns:
			var l: Vector2 = Vector2(x, TOP_Y) - pos()
			# Cloud flash where the bolt will come from.
			boss.draw_circle(l, 6.0 + 2.0 * k, Color(0.75, 0.8, 1.0, 0.3))
			boss.draw_circle(l, 2.5, Color(1.0, 1.0, 0.8, 0.8))
			# Flickering strike line down the column.
			var y: float = 6.0
			while y < 228.0:
				var jx: float = sin(y * 0.3 + age * 40.0) * 1.5
				boss.draw_line(l + Vector2(jx, y), l + Vector2(-jx, y + 5.0), Color(1.0, 0.95, 0.55, 0.16 + 0.22 * flick), 1.0)
				y += 9.0
	# Idle crackle between the coil toroids.
	if int(age * 7.0) % 5 == 0:
		var a0: Vector2 = COIL_TOP + Vector2(-2.0, 10.0)
		var prev: Vector2 = a0
		for s: int in range(1, 6):
			var nx: Vector2 = a0 + Vector2(sin(age * 50.0 + float(s)) * 5.0 - 3.0, float(s) * 6.0)
			boss.draw_line(prev, nx, Color(0.6, 0.85, 1.0, 0.6), 1.0)
			prev = nx
