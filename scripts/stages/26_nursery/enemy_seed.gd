extends "res://scripts/stages/stage_enemy.gd"

# Star seed: an ember adrift in the nebula that grows if it's left alone. Every GROW_TIME on
# screen it swells (GROW_WARN: it pulses and a ring of light closes in on it, the telegraph)
# and comes out one form bigger, tougher (x HP_GROWTH health) and nastier:
#   form 0  seed        drifts, no shots
#   form 1  young star  aimed pairs of star motes
#   form 2  flare star  wide flare fans; after NOVA_DELAY it swells for NOVA_WARN (flashing
#                       rings closing in, the core whitening) and goes nova: a double ring of
#                       shots, and it's gone (no reward).
# A priority target: shoot them while they're small.

enum S { DRIFT, GROW, NOVA }

const GROW_TIME: float = 3.0
const GROW_WARN: float = 0.7
const NOVA_DELAY: float = 3.0
const NOVA_WARN: float = 1.1
const HP_GROWTH: float = 1.7
const RADII: Array[float] = [5.5, 7.5, 9.5]
const KEYS: Array[String] = ["nursery_seed_", "nursery_young_", "nursery_flare_"]
const RING_A: int = 10
const RING_B: int = 5

var state: S = S.DRIFT
var form: int = 0
var timer: float = 0.0
var grow_t: float = GROW_TIME
var target_x: float = 380.0


func setup() -> void:
	target_x = randf_range(250.0, 420.0)
	grow_t = GROW_TIME + fposmod(phase, 3.0) * 0.35
	fire_timer = 1.0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if p.x > target_x:
		p.x -= (72.0 if p.x > 455.0 else 24.0) * delta
	else:
		p.x -= 8.0 * delta
	p.y = base_y + sin(age * 1.1 + phase) * 7.0
	var s: Sprite2D = sprite()
	match state:
		S.DRIFT:
			s.scale = s.scale.lerp(Vector2.ONE, clampf(delta * 10.0, 0.0, 1.0))
			if on_screen(30.0, 462.0):
				grow_t -= delta
			if grow_t <= 0.0:
				if form < 2:
					state = S.GROW
					timer = GROW_WARN
					sfx("shield_hit", -16.0, 0.1)
				else:
					state = S.NOVA
					timer = NOVA_WARN
					sfx("boss_siren", -17.0, 0.0)
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(90.0, 455.0):
				match form:
					0:
						fire_timer = 0.5
					1:
						fire_timer = fire_cd(2.4)
						for k: int in range(2):
							shoot_aimed(145.0, "nursery_shot", (float(k) - 0.5) * 0.14)
						sfx("zap", -17.0, 0.08)
					_:
						fire_timer = fire_cd(2.3)
						var base: float = (player_pos() - p).angle()
						for k2: int in range(4):
							emit_bullet(p, Vector2.from_angle(base + (float(k2) - 1.5) * 0.24) * 135.0, bullet_a())
						sfx("laser", -16.0, 0.08)
		S.GROW:
			timer -= delta
			var k3: float = 1.0 - clampf(timer / GROW_WARN, 0.0, 1.0)
			s.scale = Vector2.ONE * (1.0 + 0.3 * k3 + 0.08 * sin(k3 * 30.0))
			if timer <= 0.0:
				_grow(p)
		S.NOVA:
			timer -= delta
			var k4: float = 1.0 - clampf(timer / NOVA_WARN, 0.0, 1.0)
			s.scale = Vector2.ONE * (1.0 + 0.45 * k4)
			p += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * k4 * 1.5
			if timer <= 0.0:
				enemy.global_position = p
				_nova(p)
				return
	enemy.global_position = p
	var f: int = int(age * (5.0 + float(form) * 2.0)) % 2
	if state == S.NOVA and int(age * 16.0) % 2 == 0:
		f = 1
	set_texture(KEYS[form] + str(f))


func _grow(p: Vector2) -> void:
	form = mini(2, form + 1)
	var old_max: float = enemy.max_hp
	enemy.max_hp = old_max * HP_GROWTH
	enemy.hp += enemy.max_hp - old_max
	for n: Node in enemy.get_children():
		var cs: CollisionShape2D = n as CollisionShape2D
		if cs != null and cs.shape is CircleShape2D:
			(cs.shape as CircleShape2D).radius = RADII[form]
	state = S.DRIFT
	grow_t = GROW_TIME if form < 2 else NOVA_DELAY
	fire_timer = 0.6
	sprite().scale = Vector2(1.3, 1.3)
	sparks(p, Color("#ffd890") if form == 1 else Color("#ff8ad8"), 10)
	sfx("powerup", -18.0, 0.1)


func _nova(p: Vector2) -> void:
	var rot: float = randf() * TAU
	for i: int in range(RING_A):
		emit_bullet(p, Vector2.from_angle(rot + TAU * float(i) / float(RING_A)) * 105.0, "nursery_shot")
	for j: int in range(RING_B):
		emit_bullet(p, Vector2.from_angle(rot + TAU * (float(j) + 0.5) / float(RING_B)) * 70.0, bullet_a())
	sparks(p, Color("#ffffff"), 14)
	sparks(p, Color("#ff8ad8"), 12)
	if enemy.fx != null:
		enemy.fx.spawn_explosion(p, false)
	sfx("explode", -10.0, 0.05)
	leave()


func draw() -> void:
	match state:
		S.DRIFT:
			if form > 0:
				draw_glint(Vector2(-3.0 - float(form), 0.0), fire_timer, 0.35, Color(1.0, 0.75, 0.4) if form == 1 else Color(1.0, 0.45, 0.85))
			if form == 2:
				# the flare star's countdown: a faint ring that tightens as nova nears
				var left: float = clampf(grow_t / NOVA_DELAY, 0.0, 1.0)
				enemy.draw_arc(Vector2.ZERO, 14.0 + 10.0 * left, 0.0, TAU, 24, Color(1.0, 0.5, 0.85, 0.12 + 0.18 * (1.0 - left)), 1.0)
		S.GROW:
			var k: float = 1.0 - clampf(timer / GROW_WARN, 0.0, 1.0)
			var col: Color = Color(1.0, 0.85, 0.5) if form == 0 else Color(0.6, 1.0, 1.0)
			enemy.draw_arc(Vector2.ZERO, lerpf(24.0, RADII[form + 1] + 2.0, k), 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.25 + 0.5 * k), 1.0)
			enemy.draw_circle(Vector2.ZERO, RADII[form] + 4.0 * k, Color(col.r, col.g, col.b, 0.12 + 0.18 * k))
		S.NOVA:
			var k2: float = 1.0 - clampf(timer / NOVA_WARN, 0.0, 1.0)
			var flick: float = 0.5 + 0.5 * float(int(age * 18.0) % 2)
			enemy.draw_circle(Vector2.ZERO, 10.0 + 8.0 * k2, Color(1.0, 0.85, 0.95, (0.12 + 0.3 * k2) * flick))
			enemy.draw_arc(Vector2.ZERO, lerpf(46.0, 14.0, k2), 0.0, TAU, 32, Color(1.0, 0.4, 0.8, 0.35 + 0.45 * k2), 2.0)
			enemy.draw_arc(Vector2.ZERO, lerpf(60.0, 22.0, k2), 0.0, TAU, 32, Color(1.0, 0.9, 1.0, 0.15 + 0.3 * k2), 1.0)
	draw_hp_bar(12.0 + 5.0 * float(form), -9.0 - 3.0 * float(form))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffd890"), 6 + form * 3)
