extends "res://scripts/stages/stage_enemy.gd"

# PLASMA WISP: a flickering fireball that drifts left on a wavering, flame-like path, slowly
# leaning toward the player's height. It sheds short-lived sparks behind it (they hang in the air
# for SPARK_LIFE seconds and fade), and every few seconds it flares: the head swells and turns
# blue-white with a charge glint (the telegraph), then it spits an aimed pair of plasma shots.
# variant 1 weaves wider and sheds a little faster.

const FLARE: float = 0.42
const SPARK_GAP: float = 1.2
const SPARK_LIFE: float = 1.7

var spark_t: float = 0.6


func setup() -> void:
	fire_timer = 1.1 + phase * 0.15
	spark_t = 0.4 + phase * 0.1


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= 62.0 * delta
	base_y = move_toward(base_y, clampf(player_pos().y, 50.0, 226.0), 13.0 * delta)
	var amp: float = 30.0 if variant == 1 else 22.0
	p.y = clampf(base_y + sin(age * 2.5 + phase) * amp + sin(age * 6.1 + phase * 2.0) * 4.0, 40.0, 238.0)
	enemy.global_position = p
	fire_timer -= delta
	if fire_timer < FLARE:
		set_texture("corona_wisp_flare")
	else:
		set_texture("corona_wisp_%d" % (int(age * 11.0) % 2))
	if fire_timer <= 0.0 and on_screen(70.0, 455.0):
		fire_timer = fire_cd(2.8)
		shoot_aimed(140.0, bullet_b(), -0.09)
		shoot_aimed(140.0, bullet_b(), 0.09)
		sfx("laser", -15.0, 0.1)
	spark_t -= delta
	if spark_t <= 0.0 and on_screen(60.0, 466.0):
		spark_t = fire_cd(SPARK_GAP * (0.8 if variant == 1 else 1.0))
		var b: GameBullet = emit_bullet(p + Vector2(8.0, 0.0), Vector2(-18.0, sin(age * 3.7) * 14.0), "corona_spark", false, 2.2)
		if b != null:
			b.life_left = SPARK_LIFE


func draw() -> void:
	draw_glint(Vector2(-3.0, 0.0), fire_timer, FLARE, Color(0.55, 0.65, 1.0))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffb040"), 7)
