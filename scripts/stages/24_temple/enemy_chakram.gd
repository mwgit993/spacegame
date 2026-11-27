extends "res://scripts/stages/stage_enemy.gd"

# Sun chakram: a spinning golden disc. It glides in and spins up while a faint dotted arc shows
# the boomerang path it's about to fly (AIM_TIME, the telegraph): out past the ship's row and
# back. The release flings a fast aimed fan. Thrown, it whirls along the arc and sheds a shot every DROP_GAP that hangs in the air
# for HANG seconds, then launches at where the ship was when it was shed, so the trail peels
# off in a ripple. It catches itself at the far end and throws again (THROWS in all), then
# leaves. Variant 1 throws a tighter arc (its tip closer to the ship).

enum S { ENTER, AIM, THROW, LEAVE }

const AIM_TIME: float = 0.7
const THROW_TIME: float = 2.0
const DROP_GAP: float = 0.23
const HANG: float = 0.55
const SHOT_SPEED: float = 105.0
const FLING_SPEED: float = 140.0
const THROWS: int = 2
const HOME_X: float = 444.0

var state: S = S.ENTER
var timer: float = 0.0
var throws_left: int = THROWS
var p0: Vector2 = Vector2.ZERO
var p1: Vector2 = Vector2.ZERO
var p2: Vector2 = Vector2.ZERO
var p3: Vector2 = Vector2.ZERO
var drop_t: float = 0.0
var spin_v: float = 4.0


func setup() -> void:
	fire_timer = 1.0


func _bez(t: float) -> Vector2:
	var u: float = 1.0 - t
	return p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t)


# A loop from here out to just ahead of the ship's row and back, its tip on the ship's height.
func _plan(from: Vector2) -> void:
	var pp: Vector2 = player_pos()
	var tip_x: float = clampf(pp.x + (32.0 if variant == 1 else 58.0), 90.0, 230.0)
	var y1: float = clampf(2.0 * pp.y - from.y, 42.0, 228.0)
	if absf(y1 - from.y) < 60.0:
		y1 = clampf(from.y + (70.0 if from.y < 135.0 else -70.0), 42.0, 228.0)
	p0 = from
	p3 = Vector2(HOME_X + 8.0, y1)
	var cx: float = (8.0 * tip_x - p0.x - p3.x) / 6.0
	p1 = Vector2(cx, p0.y)
	p2 = Vector2(cx, y1)


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		S.ENTER:
			p.x = move_toward(p.x, HOME_X, 170.0 * delta)
			p.y = base_y + sin(age * 2.0) * 4.0
			if p.x <= HOME_X + 0.5:
				state = S.AIM
				timer = AIM_TIME
				_plan(p)
				sfx("boss_hp_tick", -17.0, 0.15)
		S.AIM:
			timer -= delta
			spin_v = lerpf(spin_v, 16.0, 3.0 * delta)
			if timer <= 0.0:
				state = S.THROW
				timer = 0.0
				drop_t = DROP_GAP * 0.5
				# the release flings a fast aimed fan
				for k: int in range(-1, 2):
					shoot_aimed_from(p, FLING_SPEED, bullet_a(), float(k) * 0.16)
				set_texture("temple_chakram_1")
				sfx("missile", -13.0, 0.1)
		S.THROW:
			timer += delta / THROW_TIME
			var t: float = clampf(timer, 0.0, 1.0)
			# eases out of the throw and back into the catch
			var e: float = t * t * (3.0 - 2.0 * t) * 0.5 + t * 0.5
			p = _bez(e)
			drop_t -= delta
			if drop_t <= 0.0 and p.x < 456.0:
				drop_t = DROP_GAP
				var b: GameBullet = emit_bullet(p, (player_pos() - p).normalized() * SHOT_SPEED, bullet_b())
				if b != null:
					b.slow_timer = HANG
					b.slow_factor = 0.02
			if timer >= 1.0:
				throws_left -= 1
				set_texture("temple_chakram_0")
				spin_v = 6.0
				if throws_left <= 0:
					state = S.LEAVE
				else:
					state = S.AIM
					timer = AIM_TIME
					_plan(p)
		S.LEAVE:
			p.x += 150.0 * delta
	enemy.global_position = p
	sprite().rotation = wrapf(sprite().rotation - spin_v * delta, -PI, PI)


func draw() -> void:
	if state == S.AIM:
		var k: float = 1.0 - clampf(timer / AIM_TIME, 0.0, 1.0)
		var me: Vector2 = enemy.global_position
		var n: int = 26
		for i: int in range(1, n):
			if float(i) / float(n) > 0.35 + k:
				break
			var q: Vector2 = _bez(float(i) / float(n)) - me
			enemy.draw_rect(Rect2(q.floor(), Vector2(2.0, 1.0)), Color(1.0, 0.8, 0.3, 0.14 + 0.3 * k))
		enemy.draw_arc(Vector2.ZERO, 11.0 + 2.0 * sin(age * 20.0), 0.0, TAU, 16, Color(1.0, 0.78, 0.25, 0.25 + 0.3 * k), 1.0)
	draw_hp_bar(18.0, -14.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#e0b040"), 10)
