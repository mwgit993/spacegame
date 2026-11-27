extends "res://scripts/stages/stage_enemy.gd"

# Hover-bike gang member: races straight across the screen, weaving a little. Variant 0 comes
# in from the right; variant 1 comes up from behind, announced by a blinking arrow at the left
# edge (the entrance telegraph). Each makes a drive-by: a short charge glint, then a shot
# at the ship, twice (the gang's leader, slot 0, fires a 5-way spread instead).

const SPEED_IN: float = 185.0
const SPEED_BEHIND: float = 170.0
const CHARGE: float = 0.3

var behind: bool = false
var shot: int = 0        # 0 waiting, 1 charging, 2 done
var volleys: int = 2
var charge_t: float = 0.0
var leader: bool = false


func setup() -> void:
	behind = variant == 1
	leader = int(phase) == 0
	if behind:
		warn_timer = 0.9
		enemy.global_position.x = -30.0
		sprite().flip_h = true


func on_wake() -> void:
	sfx("missile", -14.0, 0.1)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var dir: float = 1.0 if behind else -1.0
	p.x += dir * (SPEED_BEHIND if behind else SPEED_IN) * delta
	p.y = clampf(base_y + sin(age * 3.2 + phase * 1.3) * 9.0, 38.0, 240.0)
	enemy.global_position = p
	set_texture("metro_biker_0" if int(age * 14.0) % 2 == 0 else "metro_biker_1")
	var px: float = player_pos().x
	match shot:
		0:
			var ready: bool = (not behind and p.x - px < 230.0 and p.x - px > 90.0) or (behind and p.x - px > 40.0)
			if ready and on_screen(20.0, 460.0):
				shot = 1
				charge_t = CHARGE
		1:
			charge_t -= delta
			if charge_t <= 0.0:
				volleys -= 1
				shot = 2 if volleys <= 0 else 1
				charge_t = 0.32
				var muzzle: Vector2 = p + Vector2(8.0 * dir, -2.0)
				if leader:
					for k: int in [-2, -1, 0, 1, 2]:
						shoot_aimed_from(muzzle, 140.0, bullet_b(), float(k) * 0.16)
				else:
					shoot_aimed_from(muzzle, 150.0, bullet_b())
				sfx("laser", -16.0, 0.1)


func draw() -> void:
	var dir: float = 1.0 if behind else -1.0
	# exhaust streaks
	for i: int in range(3):
		var tx: float = -dir * (12.0 + float(i) * 6.0)
		enemy.draw_rect(Rect2(tx - 2.0, 2.0, 4.0, 1.0), Color(1.0, 0.25, 0.6, 0.35 - 0.1 * float(i)))
	if shot == 1:
		draw_glint(Vector2(8.0 * dir, -2.0), charge_t, CHARGE, Color(1.0, 0.85, 0.3))


func draw_warning() -> void:
	if int(warn_timer * 10.0) % 2 == 0:
		var lx: float = 6.0 - enemy.global_position.x
		var col: Color = Color("#ff3c9c")
		enemy.draw_colored_polygon(PackedVector2Array([Vector2(lx, -6.0), Vector2(lx + 7.0, 0.0), Vector2(lx, 6.0)]), col)
		enemy.draw_colored_polygon(PackedVector2Array([Vector2(lx + 6.0, -6.0), Vector2(lx + 13.0, 0.0), Vector2(lx + 6.0, 6.0)]), Color("#30f0e0"))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff3c9c"), 6)
