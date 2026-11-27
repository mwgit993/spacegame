extends "res://scripts/stages/stage_enemy.gd"

# Egg sac stuck to the floor (variant 0) or the ceiling (variant 1), riding the scroll. It
# doesn't shoot, but once it's on screen it ripens: for its last WARN_WINDOW seconds it glows,
# shakes and cracks, then hatches into LARVAE larvae (children: no Scrap) and is gone without
# a reward. Shoot it first. Never more than LARVA_CAP larvae at once: a ripe egg waits.

const HATCH_TIME: float = 3.6
const WARN_WINDOW: float = 1.4
const LARVAE: int = 3
const LARVA_CAP: int = 8
const SCROLL: float = 40.0
const FLOOR_Y: float = 247.0
const CEIL_Y: float = 39.0

var hatch: float = HATCH_TIME
var ceiling: bool = false


func setup() -> void:
	ceiling = variant == 1
	enemy.global_position.y = CEIL_Y if ceiling else FLOOR_Y
	base_y = enemy.global_position.y
	sprite().flip_v = ceiling
	hatch = HATCH_TIME + randf() * 0.5


func tick(delta: float) -> void:
	enemy.global_position.x -= SCROLL * delta
	if enemy.global_position.x < 448.0:
		hatch -= delta
	var warn: bool = hatch < WARN_WINDOW
	var s: Sprite2D = sprite()
	if warn:
		var urgency: float = 1.0 - maxf(0.0, hatch) / WARN_WINDOW
		var hz: float = 6.0 + 14.0 * urgency
		set_texture("hive_egg_2" if int(age * hz) % 2 == 0 else "hive_egg_1")
		s.rotation = sin(age * 34.0) * 0.14 * urgency
	else:
		set_texture("hive_egg_1" if sin(age * 4.0) > 0.4 else "hive_egg_0")
		s.rotation = 0.0
	if hatch <= 0.0:
		if _larva_count() < LARVA_CAP and on_screen(24.0, 470.0):
			var dir: float = 1.0 if ceiling else -1.0
			for i: int in range(LARVAE):
				var side: float = float(i) - 1.0
				spawn_child("larva", enemy.global_position + Vector2(side * 4.0, dir * 8.0), Vector2(-30.0 + side * 34.0, dir * 95.0))
			sparks(enemy.global_position, Color("#a8f040"), 10)
			sparks(enemy.global_position, Color("#d8c47e"), 6)
			sfx("explode", -15.0, 0.1)
			leave()
		else:
			hatch = 0.6


func _larva_count() -> int:
	var n: int = 0
	for node: Node in enemy.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = node as GameEnemy
		if ge != null and ge.module_kind == "larva" and not ge._dead:
			n += 1
	return n


func draw() -> void:
	if hatch < WARN_WINDOW:
		var urgency: float = 1.0 - maxf(0.0, hatch) / WARN_WINDOW
		var c: Vector2 = Vector2(0.0, 2.0 if ceiling else -2.0)
		enemy.draw_circle(c, 6.0 + 4.0 * urgency, Color(0.6, 1.0, 0.25, 0.08 + 0.16 * urgency))
		enemy.draw_arc(c, 9.0 + 2.0 * sin(age * 18.0), 0.0, TAU, 14, Color(0.7, 1.0, 0.3, 0.2 + 0.4 * urgency), 1.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#d8c47e"), 6)
