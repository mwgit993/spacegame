extends "res://scripts/stages/stage_enemy.gd"

# MIRROR SHARD: chrome slivers that always come in mirrored pairs, one above the centre line
# (variant 0) and its reflection below it (variant 1). Each weaves across the centre line on a
# cosine path, so the pair meets on the line, swaps sides and meets again. A moment before each
# meeting the shard flashes white and a diamond closes in on the crossing point (the
# telegraph); on the line, each fires its half of a fan (the upper shard the upward-left half,
# the lower one the downward-left half), so a full pair always throws a symmetric fan. The
# swing narrows as they go: the pair converges on the line.

const AXIS: float = 139.5
const OMEGA: float = 2.05        # rad/s: a crossing every PI / OMEGA = 1.53 s
const SPEED: float = 74.0
const TELL: float = 0.34

var amp0: float = 40.0
var t: float = 0.0
var next_cross: float = 0.0
var spin: float = 0.0


func setup() -> void:
	amp0 = base_y - AXIS
	if absf(amp0) < 8.0:
		amp0 = -18.0 if variant == 0 else 18.0
	next_cross = PI * 0.5 / OMEGA
	spin = randf() * 4.0
	if gen > 0:
		fire_timer = 99.0


func _y_at(tt: float) -> float:
	var shrink: float = 0.5 + 0.5 * exp(-tt / 5.0)
	return AXIS + amp0 * shrink * cos(OMEGA * tt)


func tick(delta: float) -> void:
	t += delta
	var p: Vector2 = enemy.global_position
	p.x -= SPEED * delta
	p.y = clampf(_y_at(t), 34.0, 245.0)
	enemy.global_position = p
	var until: float = next_cross - t
	if until < TELL and until > 0.0:
		set_texture("mirror_shard_4")
	else:
		spin += delta * 9.0
		set_texture("mirror_shard_%d" % (int(spin) % 4))
	if t >= next_cross:
		next_cross += PI / OMEGA
		if on_screen(70.0, 462.0):
			_fan()


# This shard's half of the pair's fan: upper shards fire up-left, lower ones down-left, plus
# one shot straight left from the upper shard (so a pair fires 5 symmetric shots).
func _fan() -> void:
	var s: float = -1.0 if variant == 0 else 1.0
	var o: Vector2 = enemy.global_position
	for a: float in [0.2, 0.5]:
		emit_bullet(o, Vector2(-1.0, 0.0).rotated(a * s) * 118.0, bullet_b())
	if variant == 0:
		emit_bullet(o, Vector2(-125.0, 0.0), "mirror_sliver")
	sfx("boss_hp_tick", -18.0, 0.2)


func draw() -> void:
	var until: float = next_cross - t
	if until < TELL and until > 0.0:
		# A diamond closing in on the spot where the pair will meet.
		var k: float = until / TELL
		var cross: Vector2 = Vector2(-SPEED * until, AXIS - enemy.global_position.y)
		var r: float = 3.0 + 9.0 * k
		var c: Color = Color(0.9, 0.98, 1.0, 0.55 * (1.0 - k) + 0.1)
		var pts: PackedVector2Array = PackedVector2Array([cross + Vector2(-r, 0.0), cross + Vector2(0.0, -r), cross + Vector2(r, 0.0), cross + Vector2(0.0, r), cross + Vector2(-r, 0.0)])
		enemy.draw_polyline(pts, c, 1.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#e8f6ff"), 4)
