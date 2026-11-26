extends RefCounted

# Base class of a stage-module boss AI. The module's create_boss() returns one per boss fight.
# A boss script starts with:
#
#     extends "res://scripts/stages/stage_boss.gd"
#
# GameEnemy runs everything the built-in bosses share: the teleport intro and HP-bar fill, the
# bob and sway, idle/attack frame animation (<boss_tex>_0/_1 idle, _2 attack), the three
# phases (66% and 33% HP, with a shield flash), the damage cap that stops it melting in two
# seconds, escorts from phase 2, the death sequence and the rewards. The AI only decides the
# attacks: attack() is called each time the previous attack's cooldown runs out, and must set
# the next one with wait().
#
# Bosses ignore the difficulty table: their shot speeds are absolute (no shot_speed scaling).

var boss: GameEnemy

var phase: int:      # 1 (100-66% HP), 2 (66-33%), 3 (33-0%)
	get:
		return boss.boss_phase
var pattern: int:    # cycles 0, 1, 2 every 4 attacks (like the built-in bosses)
	get:
		return boss._boss_pattern
var substep: int:    # 0-3 within the current pattern
	get:
		return boss._boss_substep
var spin: float:     # free rotation state for rings and spirals
	get:
		return boss._boss_spin
	set(v):
		boss._boss_spin = v
var age: float:      # seconds since the fight began
	get:
		return boss._age


# Once, when the boss spawns.
func setup() -> void:
	pass


# One attack. rate_mult shortens cooldowns in later phases (1.0, 0.78, 0.62); spd_bonus is the
# built-in bosses' extra bullet speed (18 per phase after the first, plus 5 per stage index).
func attack(rate_mult: float, _spd_bonus: float) -> void:
	wait(1.0 * rate_mult)


# Extra telegraphs, in the boss's local space (boss.draw_circle(), boss.draw_line()...). Called
# after the standard boss drawing, once the intro is over. Like the built-in charge glint it
# renders behind the boss sprite, so draw outside the silhouette.
func draw() -> void:
	pass


# --- Helpers ---------------------------------------------------------------------------------------

func wait(seconds: float) -> void:
	boss._fire_timer = seconds


func pos() -> Vector2:
	return boss.global_position


func player_pos() -> Vector2:
	return boss._player_pos()


func bullet_a() -> String:
	return boss._bullet_a


func bullet_b() -> String:
	return boss._bullet_b


func shoot_from(origin: Vector2, velocity: Vector2, tex_key: String) -> void:
	boss._shoot_from(origin, velocity, tex_key)


func shoot_aimed_from(origin: Vector2, speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	boss._shoot_aimed_from(origin, speed, tex_key, angle_offset)


func shoot_spread_from(origin: Vector2, count: int, step_angle: float, speed: float, tex_key: String) -> void:
	boss._shoot_from_spread(origin, count, step_angle, speed, tex_key)


# A ring around the boss (only the shots heading left, toward the player, are fired).
func shoot_ring(count: int, speed: float, tex_key: String, rot_offset: float) -> void:
	boss._shoot_ring(count, speed, tex_key, rot_offset)


func emit_bullet(origin: Vector2, velocity: Vector2, tex_key: String, hit_radius: float = 2.5) -> GameBullet:
	return boss._emit_bullet(origin, velocity, tex_key, false, hit_radius)
