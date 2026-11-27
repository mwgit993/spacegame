extends "res://scripts/stages/stage_enemy.gd"

# MIRROR MIMIC: a negative copy of your own ship. It slides in, then copies your movement as a
# reflection: variant 0 mirrors your height about the centre line (you go up, it goes down);
# variant 1 reflects you through the centre of the screen (height AND distance: come closer and
# it comes closer, held back at x 270). It lags a little behind, like a delayed reflection.
#   - Every time your paths cross (it and you on the same line), its sight locks: a dotted line
#     runs from its nose along the line for LOCK seconds, then it fires a 3-shot stream down it.
#   - Between crossings it fires a mirrored pair: one shot at you and one at your reflection,
#     with the standard charge glint as the telegraph.
# After LIFE seconds it stops copying you and dives off to the left.

const AXIS: float = 139.5
const LOCK: float = 0.32
const LIFE: float = 10.0
const FOLLOW: float = 2.6
const MAX_SPEED: float = 150.0
const ALIGN: float = 10.0

var target_x: float = 400.0
var lock_t: float = -1.0
var cross_cd: float = 0.6
var last_side: float = 0.0
var leaving: bool = false


func setup() -> void:
	target_x = randf_range(360.0, 430.0)
	fire_timer = 1.1 + phase * 0.3


func _mirror_target() -> Vector2:
	var pp: Vector2 = player_pos()
	var ty: float = clampf(2.0 * AXIS - pp.y, 40.0, 238.0)
	var tx: float = target_x
	if variant == 1:
		tx = clampf(480.0 - pp.x, 270.0, 440.0)
	return Vector2(tx, ty)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var pp: Vector2 = player_pos()
	if not leaving and age > LIFE:
		leaving = true
		lock_t = -1.0
	if leaving:
		vel = vel.lerp(Vector2(-190.0, 0.0), clampf(delta * 2.0, 0.0, 1.0))
		p += vel * delta
		set_texture("mirror_mimic_0")
		enemy.global_position = p
		return
	# Copy the player as a reflection, lagging a little.
	var want: Vector2 = _mirror_target()
	var step: Vector2 = (want - p) * clampf(FOLLOW * delta, 0.0, 1.0)
	if step.length() > MAX_SPEED * delta:
		step = step.normalized() * MAX_SPEED * delta
	p += step
	enemy.global_position = p

	# Crossing the player's line locks the sight.
	cross_cd -= delta
	var side: float = signf(p.y - pp.y)
	var crossed: bool = last_side != 0.0 and side != last_side
	if lock_t < 0.0 and cross_cd <= 0.0 and on_screen(90.0, 450.0) and (crossed or absf(p.y - pp.y) < ALIGN * 0.5):
		lock_t = LOCK
		sfx("boss_hp_tick", -15.0, 0.1)
	last_side = side if side != 0.0 else last_side
	if lock_t >= 0.0:
		lock_t -= delta
		if lock_t < 0.0:
			cross_cd = 1.1
			for k: int in range(3):
				var b: GameBullet = emit_bullet(p + Vector2(-13.0, 0.0), Vector2(-(150.0 + 14.0 * float(k)), 0.0), "mirror_sliver", false, 2.5)
				if b != null:
					b.rotation = PI
			sfx("laser", -14.0, 0.06)

	# The mirrored pair.
	fire_timer -= delta
	set_texture("mirror_mimic_1" if fire_timer < 0.4 or lock_t >= 0.0 else "mirror_mimic_0")
	if fire_timer <= 0.0:
		if on_screen(90.0, 455.0):
			fire_timer = fire_cd(2.25)
			var nose: Vector2 = p + Vector2(-12.0, 0.0)
			shoot_aimed_from(nose, 132.0, bullet_b())
			var refl: Vector2 = Vector2(pp.x, 2.0 * AXIS - pp.y)
			var dir: Vector2 = (refl - nose).normalized()
			emit_bullet(nose, dir * 132.0, bullet_b())
		else:
			fire_timer = 0.5


func draw() -> void:
	if leaving:
		return
	draw_glint(Vector2(-13.0, 0.0), fire_timer, 0.4, Color(1.0, 0.45, 0.3))
	var dy: float = absf(enemy.global_position.y - player_pos().y)
	var a: float = 0.0
	if lock_t >= 0.0:
		a = 0.35 + 0.35 * (1.0 - lock_t / LOCK)
	elif dy < 26.0 and cross_cd <= 0.0:
		a = 0.12 * (1.0 - dy / 26.0)
	if a > 0.0:
		# The sight along its line: a dotted cyan/magenta pair, solid during the lock.
		var x: float = -16.0
		var limit: float = -enemy.global_position.x
		while x > limit:
			enemy.draw_rect(Rect2(floorf(x), -1.0, 1.0, 1.0), Color(0.35, 0.95, 1.0, a))
			enemy.draw_rect(Rect2(floorf(x), 1.0, 1.0, 1.0), Color(1.0, 0.4, 0.85, a))
			x -= 3.0 if lock_t < 0.0 else 1.0
		if lock_t >= 0.0:
			enemy.draw_circle(Vector2(-14.0, 0.0), 2.0 + 2.0 * (1.0 - lock_t / LOCK), Color(1.0, 1.0, 1.0, 0.6))


func on_death() -> void:
	sparks(enemy.global_position, Color("#9fe8ff"), 5)
	sparks(enemy.global_position, Color("#ff7ae8"), 4)
