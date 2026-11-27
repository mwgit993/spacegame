extends "res://scripts/stages/stage_enemy.gd"

# GAS BLOATER: a floating gas sac that drifts and bobs across the bog. Before each puff it swells
# up and its vent glows (SWELL seconds: the telegraph), then it coughs an aimed spread of acid.
# After PUFFS puffs it over-inflates: it glows, trembles and a warning ring pulses around it for
# BURST seconds, then it pops on its own (no reward). Shot down or popped, it leaves a lingering
# toxic cloud: a few slow gas puffs that drift and fade out.

const SWELL: float = 0.85
const PUFFS: int = 3
const BURST: float = 1.15
const CLOUD: int = 5
const SAC: Vector2 = Vector2(0.0, -3.0)   # sac centre, relative to the node
const VENT: Vector2 = Vector2(-7.0, -3.0)

var puffs_left: int = PUFFS
var bursting: float = -1.0
var wob: float = 0.0


func setup() -> void:
	wob = randf() * TAU
	fire_timer = randf_range(0.9, 1.5) + phase * 0.3
	if variant == 1:
		puffs_left = PUFFS - 1


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= (44.0 + sin(age * 1.3 + wob) * 8.0) * delta
	p.y = clampf(base_y + sin(age * 1.6 + wob) * 16.0, 40.0, 232.0)
	enemy.global_position = p
	if bursting >= 0.0:
		bursting -= delta
		set_texture("swamp_bloater_2")
		var s: float = 1.0 + 0.07 * (0.5 + 0.5 * sin(age * 38.0)) * (1.0 - bursting / BURST)
		sprite().scale = Vector2(s, s)
		if bursting <= 0.0:
			sprite().scale = Vector2.ONE
			_cloud(false)
			sparks(p + SAC, Color("#b4ea48"), 8)
			sfx("explode", -15.0, 0.1)
			leave()
		return
	fire_timer -= delta
	var frame: int = 0
	if fire_timer < SWELL:
		frame = 1 if fire_timer > SWELL * 0.45 else 2
	set_texture("swamp_bloater_%d" % frame)
	if fire_timer <= 0.0:
		if on_screen(70.0, 455.0):
			for k: int in range(4):
				shoot_aimed_from(p + VENT, 112.0, bullet_b(), (float(k) - 1.5) * 0.19)
			sfx("missile", -16.0, 0.12)
			puffs_left -= 1
			fire_timer = fire_cd(2.7)
			if puffs_left <= 0:
				bursting = BURST
				sfx("boss_hp_tick", -13.0, 0.2)
		else:
			fire_timer = SWELL


# The lingering toxic cloud: slow puffs drifting apart, fading over their last half second.
func _cloud(deferred: bool) -> void:
	var origin: Vector2 = enemy.global_position + SAC
	var rot: float = randf() * TAU
	for i: int in range(CLOUD):
		var a: float = rot + TAU * float(i) / float(CLOUD) + randf_range(-0.2, 0.2)
		var sp: float = randf_range(12.0, 24.0)
		var b: GameBullet = emit_bullet(origin + Vector2.from_angle(a) * 4.0, Vector2.from_angle(a) * sp + Vector2(-14.0, 0.0), "swamp_gas_0", deferred, 4.5)
		if b != null:
			b.life_left = randf_range(2.4, 3.1)
			b.anim_tex_b = "swamp_gas_1"


func draw() -> void:
	if bursting >= 0.0:
		var k: float = 1.0 - bursting / BURST
		var pulse: float = 0.5 + 0.5 * sin(age * (14.0 + 20.0 * k))
		enemy.draw_arc(SAC, 13.0 + 3.0 * pulse, 0.0, TAU, 20, Color(0.7, 1.0, 0.3, 0.25 + 0.4 * k), 1.0)
		enemy.draw_circle(SAC, 10.0, Color(0.7, 1.0, 0.3, 0.08 + 0.12 * k * pulse))
		return
	if fire_timer < SWELL:
		draw_glint(VENT, fire_timer, SWELL, Color(0.75, 1.0, 0.3))


func on_death() -> void:
	sprite().scale = Vector2.ONE
	_cloud(true)
	sparks(enemy.global_position + SAC, Color("#b4ea48"), 8)
