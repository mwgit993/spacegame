extends "res://scripts/stages/stage_enemy.gd"

# GUNBOAT: a squat armoured patrol boat riding the swell at the water line, bobbing and pitching
# with the waves. It motors in to a firing position and holds there. Each salvo: the deck gun
# raises, its muzzle glints and a dotted arc shows where the mortar will fly (the telegraph);
# then it lobs a flare-orange mortar shell along that arc (it passes through where you were),
# with two flanking shells, and the aft flak gun snaps off a quick aimed burst of three. After a few
# salvos it turns tail and runs off the left edge. variant 1 holds further back and fires its
# first salvo later.

enum Phase { ENTER, HOLD, LEAVE }

const WATER_Y: float = 238.0
const AIM_TIME: float = 0.7
const GRAVITY: float = 150.0
const MUZZLE: Vector2 = Vector2(-14.0, -7.0)
const FLAK: Vector2 = Vector2(14.0, -2.0)
const SALVOS: int = 4

var state: Phase = Phase.ENTER
var target_x: float = 400.0
var salvos_left: int = SALVOS
var aim_v: Vector2 = Vector2.ZERO   # launch velocity of the next shell (stage-1 units)
var aiming: bool = false
var flash_t: float = 0.0
var flak_t: float = -1.0
var bob_ph: float = 0.0


func setup() -> void:
	target_x = _pick_station()
	bob_ph = randf() * TAU
	enemy.global_position.y = WATER_Y
	fire_timer = 1.4 if variant == 0 else 2.1


# A firing station clear of the other gunboats on screen (claims expire after a boat's stay).
static var _stations: PackedVector2Array = PackedVector2Array()   # x, expiry (process frame)


func _pick_station() -> float:
	var now: float = float(Engine.get_process_frames())
	var keep: PackedVector2Array = PackedVector2Array()
	for st: Vector2 in _stations:
		if st.y > now:
			keep.append(st)
	_stations = keep
	var x: float = 0.0
	for attempt: int in range(8):
		x = randf_range(372.0, 420.0) if variant == 0 else randf_range(430.0, 456.0)
		var clear: bool = true
		for st2: Vector2 in _stations:
			if absf(st2.x - x) < 30.0:
				clear = false
				break
		if clear:
			break
	_stations.append(Vector2(x, now + 1000.0))
	return x


func _surface_y(x: float) -> float:
	return WATER_Y - 3.0 + sin(age * 1.7 + bob_ph) * 2.5 + sin(x * 0.045 + age * 2.3) * 1.5


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		Phase.ENTER:
			p.x = move_toward(p.x, target_x, 70.0 * delta)
			if absf(p.x - target_x) < 1.0:
				state = Phase.HOLD
		Phase.HOLD:
			p.x = target_x + sin(age * 0.6 + bob_ph) * 6.0
			if salvos_left <= 0 or age > 18.0:
				state = Phase.LEAVE
		Phase.LEAVE:
			p.x -= 85.0 * delta
	p.y = _surface_y(p.x)
	# Pitch with the swell (a small tilt; bow up on the rising side of a wave).
	sprite().rotation = cos(age * 1.7 + bob_ph) * 0.07
	enemy.global_position = p

	flash_t -= delta
	if state != Phase.LEAVE:
		fire_timer -= delta
		if fire_timer <= AIM_TIME and not aiming and on_screen(80.0, 462.0):
			aiming = true
			aim_v = _solve_lob(p + MUZZLE, player_pos())
			sfx("boss_hp_tick", -16.0, 0.05)
		if aiming:
			# Keep tracking a little during the aim so the preview stays honest.
			aim_v = aim_v.lerp(_solve_lob(p + MUZZLE, player_pos()), clampf(delta * 2.0, 0.0, 1.0))
		if fire_timer <= 0.0:
			if aiming:
				_fire_salvo(p)
				aiming = false
				salvos_left -= 1
				fire_timer = fire_cd(1.9)
			else:
				fire_timer = AIM_TIME + 0.05
	if flak_t >= 0.0:
		flak_t -= delta
		if flak_t < 0.0:
			for k: int in [-1, 0, 1]:
				shoot_aimed_from(p + FLAK, 150.0, bullet_b(), float(k) * 0.09)
	var f: int = 0
	if flash_t > 0.0:
		f = 2
	elif aiming:
		f = 1
	set_texture("ocean_gunboat_%d" % f)


# Launch velocity (stage-1 units) for a lob that passes through `to`, flying for a time that grows
# with the distance. The bullet's real speed is scaled by the stage's shot_speed, so _fire_salvo
# scales gravity by the same factor squared to keep the arc.
func _solve_lob(from: Vector2, to: Vector2) -> Vector2:
	var d: Vector2 = to - from
	var t: float = clampf(absf(d.x) / 170.0, 0.9, 2.1)
	var vx: float = d.x / t
	var vy: float = (d.y - 0.5 * GRAVITY * t * t) / t
	return Vector2(vx, vy)


func _fire_salvo(p: Vector2) -> void:
	var origin: Vector2 = p + MUZZLE
	for k: int in range(3):
		var v: Vector2 = aim_v * (1.0 + float(k - 1) * 0.12)
		if k != 1:
			v.y = aim_v.y * (1.0 - float(k - 1) * 0.06)
		var b: GameBullet = emit_bullet(origin, v, "ocean_shell_0", false, 3.5)
		if b != null:
			var s: float = b.velocity.length() / maxf(1.0, v.length())
			b.gravity_pull = GRAVITY * s * s
			b.anim_tex_b = "ocean_shell_1"
			b.life_left = 4.0
	flash_t = 0.22
	flak_t = 0.35
	sparks(origin, Color("#ffb040"), 5)
	sfx("missile", -12.0, 0.08)


func draw() -> void:
	draw_hp_bar(24.0, -14.0)
	if aiming and fire_timer > 0.0:
		var k: float = clampf(1.0 - fire_timer / AIM_TIME, 0.0, 1.0)
		draw_glint(MUZZLE, fire_timer, AIM_TIME, Color(1.0, 0.6, 0.2))
		# Dotted preview of the shell's arc: dots appear from the muzzle outward as the aim locks.
		var t: float = 0.06
		var shown: int = int(4.0 + k * 22.0)
		var n: int = 0
		while n < shown and t < 3.0:
			var q: Vector2 = MUZZLE + aim_v * t + Vector2(0.0, 0.5 * GRAVITY * t * t)
			if enemy.global_position.y + q.y > 252.0 or enemy.global_position.x + q.x < 0.0:
				break
			if n % 2 == 0:
				enemy.draw_rect(Rect2(q.floor(), Vector2.ONE), Color(1.0, 0.72, 0.35, 0.22 + 0.35 * k))
			t += 0.07
			n += 1
	# Bow wave and wake churning around the hull.
	for i: int in range(4):
		var u: float = fposmod(age * 1.6 + float(i) * 0.25, 1.0)
		var wx: float = -16.0 + u * 36.0
		enemy.draw_rect(Rect2(floorf(wx), 7.0 + floorf(sin(u * 9.0 + float(i)) * 0.8), 2.0, 1.0), Color(0.85, 0.95, 0.95, 0.5 * (1.0 - u)))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ffb040"), 10)
	sparks(enemy.global_position + Vector2(0.0, 6.0), Color("#c8f4ff"), 8)
