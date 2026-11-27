extends "res://scripts/stages/stage_enemy.gd"

# Acid guard: an armoured soldier that hovers at the right edge, following the ship's height.
# Before each attack its mandibles open and its acid gland swells (the telegraph); it then
# either lobs an acid glob that arcs onto the ship's position and bursts into a spray where it
# hits the floor, or spits a 5-way fan. Its carapace halves damage, but while its mouth is
# open it takes 1.5x. After SPITS attacks it backs off the screen.

enum S { HOLD, OPEN, SPIT, LEAVE }

const OPEN_TIME: float = 0.8
const SPITS: int = 5
const GLOB_GRAVITY: float = 190.0
const MOUTH: Vector2 = Vector2(-13.0, 2.0)

var state: S = S.HOLD
var timer: float = 0.0
var target_x: float = 410.0
var spits_left: int = SPITS
var lob_next: bool = true


func setup() -> void:
	target_x = randf_range(388.0, 432.0)
	fire_timer = 1.5
	lob_next = variant == 0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	if state == S.LEAVE:
		p.x -= 72.0 * delta
		p.y += sin(age * 2.0) * 12.0 * delta
	else:
		p.x = lerpf(p.x, target_x, clampf(2.2 * delta, 0.0, 1.0))
		var want_y: float = clampf(player_pos().y, 52.0, 218.0)
		p.y = lerpf(p.y, want_y, clampf((0.4 if state == S.HOLD else 0.15) * delta, 0.0, 1.0)) + sin(age * 2.2) * 6.0 * delta
	match state:
		S.HOLD:
			fire_timer -= delta
			if fire_timer <= OPEN_TIME and on_screen(100.0, 455.0):
				state = S.OPEN
				set_texture("hive_guard_1")
				sfx("boss_hp_tick", -15.0, 0.1)
		S.OPEN:
			fire_timer -= delta
			if fire_timer <= 0.0:
				_spit(p)
				state = S.SPIT
				timer = 0.45
				spits_left -= 1
		S.SPIT:
			timer -= delta
			if timer <= 0.0:
				set_texture("hive_guard_0")
				if spits_left <= 0:
					state = S.LEAVE
				else:
					state = S.HOLD
					fire_timer = fire_cd(1.45)
	enemy.global_position = p


func _spit(p: Vector2) -> void:
	var mouth: Vector2 = p + MOUTH
	if lob_next:
		# A glob on a ballistic arc through the ship's current position.
		var target: Vector2 = player_pos()
		var dx: float = minf(-40.0, target.x - mouth.x)
		var t: float = clampf(absf(dx) / 160.0, 0.8, 1.6)
		var v: Vector2 = Vector2(dx / t, (target.y - mouth.y - 0.5 * GLOB_GRAVITY * t * t) / t)
		var b: GameBullet = emit_bullet(mouth, v / enemy._shot_mult, "hive_glob", false, 3.5)
		if b != null:
			b.gravity_pull = GLOB_GRAVITY
			b.floor_burst = 5
			b.burst_tex = bullet_b()
			b.burst_speed = 86.0
	else:
		for k: int in [-2, -1, 0, 1, 2]:
			shoot_aimed_from(mouth, 136.0, bullet_b(), float(k) * 0.17)
	lob_next = not lob_next
	sparks(mouth, Color("#a8f040"), 4)
	sfx("missile", -13.0, 0.08)


func modify_damage(dmg: float) -> float:
	if state == S.OPEN or state == S.SPIT:
		return dmg * 1.5
	return dmg * 0.5


func draw() -> void:
	if state == S.OPEN:
		var k: float = clampf(1.0 - fire_timer / OPEN_TIME, 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(age * 30.0)
		enemy.draw_circle(MOUTH + Vector2(1.0, 0.0), 2.0 + 3.5 * k, Color(0.6, 1.0, 0.2, 0.18 + 0.25 * k * pulse))
		enemy.draw_circle(MOUTH + Vector2(1.0, 0.0), 1.0 + 1.5 * k, Color(0.9, 1.0, 0.6, 0.6 + 0.3 * k))
		enemy.draw_circle(Vector2(6.0, -2.0), 3.0 + 2.0 * k, Color(0.6, 1.0, 0.2, 0.12 + 0.12 * pulse))
	draw_hp_bar(24.0, -15.0)


func on_death() -> void:
	sparks(enemy.global_position + MOUTH, Color("#a8f040"), 8)
	sparks(enemy.global_position, Color("#c07a66"), 6)
