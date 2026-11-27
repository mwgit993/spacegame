extends "res://scripts/stages/stage_enemy.gd"

# CLOUD-SKIMMER GUNSHIP: hides in the cloud tops along the bottom (variant 0) or the cloud base
# along the top (variant 1). While hidden (the entrance telegraph, unhittable) its searchlight
# sweeps out of the clouds and the cloud bulges where it will rise. It climbs out, lines up
# (glint on the chin turret plus a dashed sight line at the player), rakes a sweeping 5-round
# burst, does it once more, then sinks back into the clouds.

enum Phase { RISE, AIM, RAKE, PAUSE, SINK }

const WARN: float = 1.0
const HIDE_BOT: float = 266.0
const HIDE_TOP: float = 6.0
const AIM_TIME: float = 0.6
const ROUNDS: int = 5
const ROUND_GAP: float = 0.085
const BURSTS: int = 2
const MUZZLE: Vector2 = Vector2(-11.0, 5.0)

var state: Phase = Phase.RISE
var timer: float = 0.0
var hover_y: float = 200.0
var hide_y: float = HIDE_BOT
var aim_ang: float = PI
var rounds_left: int = 0
var bursts_left: int = BURSTS


func setup() -> void:
	var top: bool = variant == 1
	hide_y = HIDE_TOP if top else HIDE_BOT
	hover_y = randf_range(56.0, 74.0) if top else randf_range(194.0, 212.0)
	enemy.global_position.y = hide_y
	base_y = hide_y
	warn_timer = WARN


func on_wake() -> void:
	state = Phase.RISE
	timer = 0.0
	sfx("missile", -15.0, 0.1)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= 18.0 * delta
	match state:
		Phase.RISE:
			p.y = lerpf(p.y, hover_y, clampf(4.0 * delta, 0.0, 1.0))
			if absf(p.y - hover_y) < 3.0 and on_screen(80.0, 450.0):
				_aim()
		Phase.AIM:
			p.y = hover_y + sin(age * 3.0) * 2.0
			timer -= delta
			if timer <= 0.0:
				state = Phase.RAKE
				rounds_left = ROUNDS
				timer = 0.0
		Phase.RAKE:
			timer -= delta
			if timer <= 0.0:
				var k: float = float(ROUNDS - rounds_left) / float(ROUNDS - 1)
				var sweep: float = lerpf(-0.32, 0.32, k) * (1.0 if variant == 0 else -1.0)
				emit_bullet(p + MUZZLE, Vector2.from_angle(aim_ang + sweep) * 165.0, bullet_a())
				rounds_left -= 1
				timer = ROUND_GAP
				if rounds_left <= 0:
					bursts_left -= 1
					state = Phase.PAUSE if bursts_left > 0 else Phase.SINK
					timer = fire_cd(1.1)
		Phase.PAUSE:
			p.y = hover_y + sin(age * 3.0) * 2.0
			timer -= delta
			if timer <= 0.0:
				_aim()
		Phase.SINK:
			p.y += (hide_y - hover_y) * 0.9 * delta + signf(hide_y - hover_y) * 40.0 * delta
	set_texture("storm_gunship_1" if state == Phase.RAKE else "storm_gunship_0")
	enemy.global_position = p


func _aim() -> void:
	state = Phase.AIM
	timer = AIM_TIME
	aim_ang = (player_pos() - (enemy.global_position + MUZZLE)).angle()
	sfx("boss_hp_tick", -15.0, 0.05)


func draw() -> void:
	if state == Phase.AIM:
		var k: float = 1.0 - timer / AIM_TIME
		var dirv: Vector2 = Vector2.from_angle(aim_ang)
		var col: Color = Color(1.0, 0.9, 0.5, 0.15 + 0.4 * k)
		var d: float = 8.0 + fposmod(age * 70.0, 10.0)
		while d < 300.0:
			var q: Vector2 = MUZZLE + dirv * d
			var g: Vector2 = enemy.global_position + q
			if g.x < 0.0 or g.y < 24.0 or g.y > 258.0:
				break
			enemy.draw_line(q, q + dirv * 4.0, col, 1.0)
			d += 10.0
		draw_glint(MUZZLE, timer, AIM_TIME, Color(1.0, 0.8, 0.3))
	# Searchlight cone from the nose.
	if state != Phase.SINK:
		var sl: float = 0.05 + 0.03 * sin(age * 5.0)
		var tip: Vector2 = Vector2(-16.0, 1.0)
		enemy.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-46.0, -12.0), tip + Vector2(-46.0, 12.0)]), Color(1.0, 0.95, 0.75, sl))
	draw_hp_bar(28.0, -11.0)


# Hidden in the clouds: a searchlight beam sweeping out of them and a bulge where it will rise.
func draw_warning() -> void:
	var k: float = clampf(1.0 - warn_timer / WARN, 0.0, 1.0)
	var out: float = -1.0 if variant == 0 else 1.0
	var edge: Vector2 = Vector2(0.0, (252.0 if variant == 0 else 30.0) - enemy.global_position.y)
	var sweep: float = sin(age * 3.2) * 0.5
	var dirv: Vector2 = Vector2(sin(sweep) * -0.6 - 0.4, out * cos(sweep)).normalized()
	var a: float = 0.06 + 0.1 * k
	enemy.draw_colored_polygon(PackedVector2Array([edge, edge + dirv.rotated(-0.12) * 120.0, edge + dirv.rotated(0.12) * 120.0]), Color(1.0, 0.95, 0.7, a))
	enemy.draw_circle(edge, 2.0 + k * 1.5, Color(1.0, 0.95, 0.75, 0.6 + 0.3 * k))
	# Cloud bulge: a few dim puffs swelling at the edge.
	for i: int in range(3):
		var px: float = (float(i) - 1.0) * 9.0
		enemy.draw_circle(edge + Vector2(px, out * (2.0 + 4.0 * k)), 4.0 + 3.0 * k, Color(0.35, 0.45, 0.55, 0.25 + 0.2 * k))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffb060"), 9)
