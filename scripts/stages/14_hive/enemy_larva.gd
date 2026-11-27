extends "res://scripts/stages/stage_enemy.gd"

# Larva: what an egg hatches into (always a child, so no Scrap). It wriggles out of the egg,
# then squirms toward the ship's height while drifting left, and spits slow shots (charge
# glint first), twice. Eggs cap how many exist (enemy_egg.gd LARVA_CAP).

var shots_left: int = 2


func setup() -> void:
	fire_timer = randf_range(1.1, 1.5)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var want: float = clampf((player_pos().y - p.y) * 1.2, -48.0, 48.0)
	vel.x = lerpf(vel.x, -58.0, clampf(1.6 * delta, 0.0, 1.0))
	vel.y = lerpf(vel.y, want, clampf(1.8 * delta, 0.0, 1.0))
	p += vel * delta
	p.y = clampf(p.y + sin(age * 9.0) * 0.5, 34.0, 244.0)
	enemy.global_position = p
	set_texture("hive_larva_0" if int(age * 8.0) % 2 == 0 else "hive_larva_1")
	fire_timer -= delta
	if shots_left > 0 and fire_timer <= 0.0 and on_screen(70.0, 460.0):
		shots_left -= 1
		fire_timer = fire_cd(1.6)
		shoot_aimed(100.0, bullet_b())


func draw() -> void:
	if shots_left > 0:
		draw_glint(Vector2(-7.0, 0.0), fire_timer, 0.3, Color(0.7, 1.0, 0.3))
