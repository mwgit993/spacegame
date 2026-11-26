extends "res://scripts/stages/stage_enemy.gd"

# TEMPORARY EXAMPLE ENEMY 1: "orb". Drifts left in a sine wave and fires an aimed pair, with the
# standard charge glint as its telegraph. Shot down, an orb from the wave director splits into
# two small orbs that scatter and fire once each (children: gen 1, no Scrap, and they don't
# split again, which caps the split at 2 per orb).
#
# Shows: movement, fire_timer + fire_cd(), a 2-frame animation, a draw() telegraph, and
# spawn_child() from on_death().

const SPLIT_COUNT: int = 2


func setup() -> void:
	if gen > 0:
		set_texture("example_orb_small")
		fire_timer = 0.6


func tick(delta: float) -> void:
	if gen > 0:
		# A split-off copy: the kick from the split fades into a slow leftward drift.
		vel = vel.lerp(Vector2(-70.0, 0.0), clampf(delta * 1.5, 0.0, 1.0))
		enemy.global_position += vel * delta
		enemy.global_position.y = clampf(enemy.global_position.y, 36.0, 244.0)
		fire_timer -= delta
		if fire_timer <= 0.0 and on_screen(60.0, 460.0):
			fire_timer = 99.0  # one shot each
			shoot_aimed(120.0, bullet_b())
		return
	enemy.global_position.x -= 58.0 * delta
	enemy.global_position.y = clampf(base_y + sin(age * 2.2 + phase) * 30.0, 40.0, 238.0)
	set_texture("example_orb_1" if fire_timer < 0.35 else "example_orb_0")
	fire_timer -= delta
	if fire_timer <= 0.0 and on_screen(80.0, 455.0):
		fire_timer = fire_cd(2.2)
		shoot_aimed(140.0, bullet_b(), -0.08)
		shoot_aimed(140.0, bullet_b(), 0.08)


func draw() -> void:
	if gen == 0:
		draw_glint(Vector2(-6.0, 0.0), fire_timer, 0.35, Color(0.65, 0.55, 1.0))


func on_death() -> void:
	if gen > 0:
		return
	for i: int in range(SPLIT_COUNT):
		var side: float = -1.0 if i == 0 else 1.0
		spawn_child("orb", enemy.global_position + Vector2(0.0, 6.0 * side), Vector2(-30.0, 70.0 * side))
	sparks(enemy.global_position, Color("#a898ff"), 6)
