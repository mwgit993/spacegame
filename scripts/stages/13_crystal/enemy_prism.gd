extends "res://scripts/stages/stage_enemy.gd"

# PRISM TURRET: a crystal cluster on the floor (variant 0) or the ceiling (variant 1), riding
# the cave scroll. Its three facets light up one after another (the telegraph; a faint aim line
# shows in the last moment), then it fires a white-gold bolt at the player that splits into
# three rainbow shards after a short flight. Shot down, any bolt still in flight splits at once.

const FLOOR_Y: float = 248.0
const CEIL_Y: float = 36.0
const SCROLL: float = 40.0
const CHARGE: float = 0.9
const SPLIT_AFTER: float = 0.42
const SPLIT_SPREAD: float = 0.3
const BOLT_SPEED: float = 150.0
const SHARD_SPEED: float = 128.0

var bolts: Array[GameBullet] = []
var bolt_age: PackedFloat32Array = PackedFloat32Array()
var up: float = -1.0   # direction the crystals point: -1 up (floor), +1 down (ceiling)


func setup() -> void:
	up = 1.0 if variant == 1 else -1.0
	enemy.global_position.y = CEIL_Y if variant == 1 else FLOOR_Y
	base_y = enemy.global_position.y
	sprite().flip_v = variant == 1
	fire_timer = 1.2


func _tip() -> Vector2:
	return enemy.global_position + Vector2(-1.0, up * 9.0)


func tick(delta: float) -> void:
	enemy.global_position.x -= SCROLL * delta
	fire_timer -= delta
	var lit: int = 0
	if fire_timer < CHARGE:
		lit = clampi(int((1.0 - fire_timer / CHARGE) * 3.0) + 1, 1, 3)
	set_texture("crystal_prism_%d" % lit)
	if fire_timer <= 0.0:
		if on_screen(60.0, 455.0):
			fire_timer = fire_cd(2.4)
			var dir: Vector2 = (player_pos() - _tip()).normalized()
			var b: GameBullet = emit_bullet(_tip(), dir * BOLT_SPEED, "crystal_shot", false, 3.0)
			if b != null:
				bolts.append(b)
				bolt_age.append(0.0)
			sfx("laser", -14.0, 0.08)
		else:
			fire_timer = CHARGE   # replay the whole charge once it's back on screen
	var i: int = 0
	while i < bolts.size():
		var b2: GameBullet = bolts[i]
		if not is_instance_valid(b2) or b2.is_queued_for_deletion():
			bolts.remove_at(i)
			bolt_age.remove_at(i)
			continue
		bolt_age[i] += delta
		if bolt_age[i] >= SPLIT_AFTER:
			_split(b2, false)
			bolts.remove_at(i)
			bolt_age.remove_at(i)
			continue
		i += 1


func _split(b: GameBullet, deferred: bool) -> void:
	var d: Vector2 = b.velocity.normalized()
	for k: int in range(3):
		emit_bullet(b.global_position, d.rotated(float(k - 1) * SPLIT_SPREAD) * SHARD_SPEED, "crystal_shard_%d" % k, deferred, 2.5)
	sparks(b.global_position, Color("#fff2c0"), 3)
	b.queue_free()


func draw() -> void:
	if fire_timer > 0.0 and fire_timer < CHARGE:
		var tip: Vector2 = Vector2(-1.0, up * 9.0)
		draw_glint(tip, fire_timer, CHARGE, Color(1.0, 0.85, 0.35))
		if fire_timer < 0.35:
			var dir: Vector2 = (player_pos() - _tip()).normalized()
			var a: float = 0.18 + 0.2 * (1.0 - fire_timer / 0.35)
			var dist: float = 10.0
			while dist < 150.0:
				var q: Vector2 = tip + dir * dist
				enemy.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(1.0, 0.9, 0.5, a))
				dist += 7.0


func on_death() -> void:
	for b: GameBullet in bolts:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			_split(b, true)
	bolts.clear()
	sparks(enemy.global_position, Color("#b07ae8"), 8)
