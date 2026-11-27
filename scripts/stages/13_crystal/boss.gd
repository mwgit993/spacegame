extends "res://scripts/stages/stage_boss.gd"

# PRISM HYDRA "SPECTRA": a split geode with three crystal heads (rose, emerald, gold). Three
# patterns, switching every 4 attacks; each phase adds shots and rate_mult shortens cooldowns.
#   0 HEAD BEAMS   the heads take turns firing an aimed spread in their own colour; the next
#                  head's mouth glows before it fires. Phase 3: the other two heads add a shot.
#   1 SPLIT ORBS   the middle head spits slow blinking orbs (a ring tightens around each); a
#                  second later each bursts into a full ring of rainbow shards
#   2 SPECTRUM     the core sprays a turning spiral of rainbow shards

const MOUTHS: Array[Vector2] = [Vector2(-53.0, -45.0), Vector2(-61.0, 1.0), Vector2(-53.0, 47.0)]
const CORE: Vector2 = Vector2(-2.0, 0.0)
const ORB_DELAY: float = 1.0

var orbs: Array[GameBullet] = []


func attack(rate_mult: float, spd_bonus: float) -> void:
	match pattern:
		0:
			var head: int = substep % 3
			var n: int = 3 + phase
			for i: int in range(n):
				var off: float = (float(i) - float(n - 1) * 0.5) * 0.13
				shoot_aimed_from(pos() + MOUTHS[head], 165.0 + spd_bonus, "crystal_shard_%d" % head, off)
			if phase >= 3:
				for h2: int in range(3):
					if h2 != head:
						shoot_aimed_from(pos() + MOUTHS[h2], 175.0 + spd_bonus, "crystal_shard_%d" % h2, 0.0)
			wait(0.62 * rate_mult)
		1:
			_burst_orbs(spd_bonus)
			if substep < 3:
				var count: int = 1 if phase == 1 else 2
				for c: int in range(count):
					var off2: float = 0.0 if count == 1 else (-0.3 if c == 0 else 0.3)
					var origin: Vector2 = pos() + MOUTHS[1]
					var dir: Vector2 = (player_pos() - origin).normalized().rotated(off2)
					var b: GameBullet = emit_bullet(origin, dir * 82.0, "crystal_orb_0", 5.0)
					if b != null:
						b.anim_tex_b = "crystal_orb_1"
						orbs.append(b)
				RetroSfx.play("shield_hit", -12.0, 0.1)
			wait(ORB_DELAY)
		_:
			var arms: int = 5 + phase
			var origin2: Vector2 = pos() + CORE
			for a: int in range(arms * 2):
				var ang: float = spin + TAU * float(a) / float(arms * 2)
				var v: Vector2 = Vector2.from_angle(ang) * (128.0 + spd_bonus)
				if v.x < 30.0:
					shoot_from(origin2, v, "crystal_shard_%d" % (a % 3))
			spin += 0.23
			wait(0.5 * rate_mult)


# Each pending orb bursts into a ring of rainbow shards where it is now.
func _burst_orbs(spd_bonus: float) -> void:
	var n: int = 8 + phase * 2
	for b: GameBullet in orbs:
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			continue
		var rot: float = randf() * TAU
		for i: int in range(n):
			emit_bullet(b.global_position, Vector2.from_angle(rot + TAU * float(i) / float(n)) * (100.0 + spd_bonus * 0.5), "crystal_shard_%d" % (i % 3))
		b.queue_free()
	orbs.clear()


func draw() -> void:
	# Pending orbs: a ring closing in on each one as its burst nears.
	if not orbs.is_empty():
		var k: float = clampf(1.0 - boss._fire_timer / ORB_DELAY, 0.0, 1.0)
		for b: GameBullet in orbs:
			if is_instance_valid(b) and not b.is_queued_for_deletion():
				var l: Vector2 = b.global_position - pos()
				boss.draw_arc(l, lerpf(18.0, 7.0, k), 0.0, TAU, 20, Color(1.0, 0.75, 0.95, 0.25 + 0.45 * k), 1.0)
	# Head beams: the next head's mouth glows in its colour.
	if pattern == 0 and boss._fire_timer > 0.0 and boss._fire_timer < 0.35:
		var head: int = (substep + 1) % 3
		var cols: Array[Color] = [Color(1.0, 0.35, 0.45), Color(0.35, 1.0, 0.55), Color(1.0, 0.8, 0.3)]
		var c: Color = cols[head]
		var t: float = 1.0 - boss._fire_timer / 0.35
		boss.draw_circle(MOUTHS[head], 2.0 + 4.0 * t, Color(c.r, c.g, c.b, 0.5))
		boss.draw_circle(MOUTHS[head], 1.0 + 2.0 * t, Color(1.0, 1.0, 0.9, 0.9))
