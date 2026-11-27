extends "res://scripts/stages/stage_enemy.gd"

# Dust wraith: the nebula's dust gathers into a hooded shape at a spot near the ship's lane
# (GATHER: motes spiral inward and the silhouette condenses; nothing to hit yet), then its
# gold eyes open and it takes aim (AIM: a lock line shows where it will go), and it lunges
# down that line, shedding a wake of dust motes that hang where they fell for a moment, then
# drift apart and fade; at the end of each lunge it spits an aimed pair. It recovers, aims
# again, and after LUNGES lunges drifts off left.
# Variant 0 gathers above the ship's lane, variant 1 below.

enum S { AIM, LUNGE, RECOVER, LEAVE }

const GATHER: float = 1.0
const AIM_T: float = 0.5
const LUNGE_T: float = 0.7
const LUNGE_V: float = 270.0
const DROP_EVERY: float = 0.1
const RECOVER_T: float = 0.5
const LUNGES: int = 2
const MOTE_HANG: float = 0.7
const MOTE_LIFE: float = 2.4
const MAX_TURN: float = 1.05  # the lunge stays within this many radians of straight left

var state: S = S.AIM
var timer: float = 0.0
var dir: Vector2 = Vector2.LEFT
var lunges_left: int = LUNGES
var drop_t: float = 0.0


func setup() -> void:
	var pp: Vector2 = player_pos()
	var side: float = -1.0 if variant == 0 else 1.0
	var at: Vector2 = Vector2(randf_range(320.0, 430.0), clampf(pp.y + side * randf_range(40.0, 70.0), 44.0, 226.0))
	enemy.global_position = at
	base_y = at.y
	warn_timer = GATHER


func on_wake() -> void:
	state = S.AIM
	timer = AIM_T
	_aim()
	sparks(enemy.global_position, Color("#c8a8ff"), 8)
	sfx("boss_hp_tick", -16.0, 0.05)


func _aim() -> void:
	var to: Vector2 = player_pos() - enemy.global_position
	var a: float = angle_difference(PI, to.angle())
	a = clampf(a, -MAX_TURN, MAX_TURN)
	dir = Vector2.from_angle(PI + a)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var s: Sprite2D = sprite()
	match state:
		S.AIM:
			timer -= delta
			if timer > AIM_T * 0.4:
				_aim()
			p.y += sin(age * 6.0) * 6.0 * delta
			s.rotation = lerp_angle(s.rotation, dir.angle() - PI, clampf(delta * 10.0, 0.0, 1.0))
			set_texture("nursery_wraith_0")
			if timer <= 0.0:
				state = S.LUNGE
				timer = LUNGE_T
				drop_t = 0.0
				sfx("missile", -14.0, 0.08)
		S.LUNGE:
			timer -= delta
			var k: float = 1.0 - clampf(timer / LUNGE_T, 0.0, 1.0)
			p += dir * LUNGE_V * (1.0 - k * 0.55) * delta
			s.rotation = dir.angle() - PI
			set_texture("nursery_wraith_1")
			drop_t -= delta
			if drop_t <= 0.0:
				drop_t = DROP_EVERY
				_drop(p)
			if p.y < 38.0 or p.y > 242.0:
				dir.y = -dir.y
				p.y = clampf(p.y, 38.0, 242.0)
			if timer <= 0.0:
				for s2: int in range(2):
					shoot_aimed_from(p, 150.0, bullet_a(), (float(s2) - 0.5) * 0.18)
				lunges_left -= 1
				state = S.RECOVER if lunges_left > 0 else S.LEAVE
				timer = RECOVER_T
		S.RECOVER:
			timer -= delta
			p += dir * 30.0 * delta
			s.rotation = lerp_angle(s.rotation, 0.0, clampf(delta * 6.0, 0.0, 1.0))
			set_texture("nursery_wraith_0")
			if timer <= 0.0:
				state = S.AIM
				timer = AIM_T
				_aim()
				sfx("boss_hp_tick", -17.0, 0.05)
		S.LEAVE:
			p.x -= 70.0 * delta
			p.y += sin(age * 2.0) * 10.0 * delta
			s.rotation = lerp_angle(s.rotation, 0.0, clampf(delta * 4.0, 0.0, 1.0))
			set_texture("nursery_wraith_0")
	enemy.global_position = p


# A dust mote shed from the wake: hangs still for MOTE_HANG, then drifts out sideways.
func _drop(p: Vector2) -> void:
	var side: Vector2 = dir.orthogonal() * (1.0 if randf() < 0.5 else -1.0)
	var b: GameBullet = emit_bullet(p - dir * 6.0, side * randf_range(14.0, 24.0) + Vector2(-10.0, 0.0), "nursery_dust", false, 2.2)
	if b != null:
		b.slow_timer = MOTE_HANG
		b.slow_factor = 0.0
		b.life_left = MOTE_LIFE


func draw_warning() -> void:
	var k: float = 1.0 - clampf(warn_timer / GATHER, 0.0, 1.0)
	for i: int in range(16):
		var a: float = float(i) * TAU / 16.0 + age * 3.0 + float(i % 3)
		var r: float = lerpf(40.0, 3.0, k) + sin(float(i) * 1.7) * 5.0 * (1.0 - k)
		enemy.draw_rect(Rect2(Vector2.from_angle(a) * r - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(0.78, 0.65, 1.0, 0.2 + 0.5 * k))
	var t: Texture2D = PixelArt.tex("nursery_wraith_0")
	enemy.draw_texture(t, -(t.get_size() * 0.5).round(), Color(0.7, 0.6, 1.0, 0.45 * k * k))


func draw() -> void:
	match state:
		S.AIM:
			var k: float = 1.0 - clampf(timer / AIM_T, 0.0, 1.0)
			var flick: float = 0.5 + 0.5 * float(int(age * 20.0) % 2)
			enemy.draw_line(dir * 10.0, dir * (60.0 + 200.0 * k), Color(1.0, 0.85, 0.4, (0.18 + 0.35 * k) * flick), 1.0)
			enemy.draw_circle(Vector2(-6.0, 0.0), 2.0 + 2.0 * k, Color(1.0, 0.85, 0.4, 0.3 + 0.3 * k))
		S.RECOVER:
			draw_glint(Vector2(-6.0, 0.0), timer, RECOVER_T, Color(1.0, 0.85, 0.4))
	draw_hp_bar(20.0, -13.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#c8a8ff"), 12)
