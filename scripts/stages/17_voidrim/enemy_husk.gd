extends "res://scripts/stages/stage_enemy.gd"

# Time-frozen husk: a ship-corpse caught in slowed time, crawling left with afterimages behind
# it. Every so often it skips ahead in time: a ghost appears where it will be (SKIP_WARN, the
# telegraph) and then it is there. Right after each skip it fires a fan of shots that hang
# almost frozen for HANG seconds, then all launch together. After SKIPS skips it drifts off.

enum S { DRIFT, WARN, LEAVE }

const SKIP_WARN: float = 0.6
const HANG: float = 0.8
const SKIPS: int = 4
const FAN: int = 6

var state: S = S.DRIFT
var timer: float = 1.6
var ghost: Vector2 = Vector2.ZERO
var skips_left: int = SKIPS
var trail: PackedVector2Array = PackedVector2Array()
var trail_t: float = 0.0


func setup() -> void:
	timer = 1.2 + 0.5 * phase


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	# slow, stuttering crawl: it moves in little time-jerks
	var jerk: float = 1.0 if fposmod(age * 3.0, 1.0) < 0.35 else 0.15
	p.x -= (34.0 if p.x > 440.0 else 16.0) * jerk * delta
	p.y = base_y + sin(age * 0.7 + phase) * 8.0
	trail_t -= delta
	if trail_t <= 0.0:
		trail_t = 0.16
		trail.insert(0, p)
		if trail.size() > 3:
			trail.resize(3)
	match state:
		S.DRIFT:
			set_texture("voidrim_husk_0")
			timer -= delta
			if timer <= 0.0 and on_screen(130.0, 450.0):
				state = S.WARN
				timer = SKIP_WARN
				var pp: Vector2 = player_pos()
				ghost = Vector2(clampf(p.x - randf_range(40.0, 70.0), 150.0, 440.0), clampf(p.y + clampf(pp.y - p.y, -50.0, 50.0), 44.0, 226.0))
				sfx("boss_hp_tick", -16.0, 0.0)
		S.WARN:
			set_texture("voidrim_husk_1")
			timer -= delta
			if timer <= 0.0:
				sparks(p, Color("#80a8ff"), 6)
				p = ghost
				base_y = ghost.y - sin(age * 0.7 + phase) * 8.0
				sparks(p, Color("#80a8ff"), 6)
				trail.clear()
				_fire_frozen(p)
				skips_left -= 1
				state = S.LEAVE if skips_left <= 0 else S.DRIFT
				timer = fire_cd(1.8)
				sfx("zap", -13.0, 0.05)
		S.LEAVE:
			set_texture("voidrim_husk_0")
			p.x -= 40.0 * delta
	enemy.global_position = p


func _fire_frozen(p: Vector2) -> void:
	var base: float = (player_pos() - p).angle()
	for k: int in range(FAN):
		var a: float = base + (float(k) - float(FAN - 1) * 0.5) * 0.2
		var b: GameBullet = emit_bullet(p + Vector2.from_angle(a) * 10.0, Vector2.from_angle(a) * 150.0, bullet_a())
		if b != null:
			b.slow_timer = HANG
			b.slow_factor = 0.05


func draw() -> void:
	var t: Texture2D = PixelArt.tex("voidrim_husk_0")
	var half: Vector2 = (t.get_size() * 0.5).round()
	for i: int in range(trail.size()):
		enemy.draw_texture(t, trail[i] - enemy.global_position - half, Color(0.5, 0.65, 1.0, 0.22 - 0.06 * float(i)))
	if state == S.WARN:
		var k: float = 1.0 - clampf(timer / SKIP_WARN, 0.0, 1.0)
		var flick: float = 0.2 + 0.35 * k * (0.5 + 0.5 * float(int(age * 20.0) % 2))
		var g: Vector2 = ghost - enemy.global_position
		enemy.draw_texture(t, g - half, Color(0.6, 0.8, 1.0, flick))
		enemy.draw_line(Vector2.ZERO, g, Color(0.5, 0.7, 1.0, 0.15 + 0.2 * k), 1.0)
	draw_hp_bar(22.0, -13.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#80a8ff"), 10)
