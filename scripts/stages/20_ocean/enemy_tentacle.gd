extends "res://scripts/stages/stage_enemy.gd"

# KRAKEN ARM: a whirlpool opens on the swell (the entrance telegraph: a turning spiral of foam,
# hidden and unhittable meanwhile), then a huge sucker-lined arm rears out of it and towers over
# the water, swaying, riding the sea scroll. It's a solid column: the whole arm hurts to touch
# and can be shot anywhere above the water. To attack it leans back and curls its tip over (the
# tip's suckers light up, a dotted arc shows the path of the blow and ripples race along the
# water ahead of it), then whips forward and SLAMS the sea: a spray of droplets skims low along
# the water line and a fan of spray arcs up and falls back. Between blows the tip flicks pairs
# of droplets at you (it glints first). After SLAMS slams it sinks away.
# Unlike the desert sandworm (which pops up to your height and spits fans at you), the danger
# here is the sweep of the arm itself and the low spray it throws along the surface.

const Art = preload("art.gd")

enum Phase { RISE, SWAY, CURL, SLAM, RECOVER, SINK }

const WATER_Y: float = 238.0
const SCROLL: float = 34.0
const SEGS: int = 12
const WARN: float = 1.1
const RISE_TIME: float = 0.55
const CURL_TIME: float = 0.62
const SLAM_TIME: float = 0.2
const RECOVER_TIME: float = 0.55
const SLAMS: int = 3
const SPIT_TELL: float = 0.3
const BODY_SHAPES: Array[int] = [3, 6, 9]

var state: Phase = Phase.RISE
var timer: float = 0.0
var base_x: float = 0.0
var full_len: float = 110.0
var ext: float = 0.0          # 0..1 how far the arm is out of the water
var lean: float = -PI * 0.5   # direction of the root segment
var curl: float = 0.0         # total bend spread toward the tip (+ curls back to the right)
var pose_from: Vector2 = Vector2.ZERO   # (lean, curl) at the start of a transition
var pose_to: Vector2 = Vector2.ZERO
var slams_left: int = SLAMS
var sway_ph: float = 0.0
var joints: PackedVector2Array = PackedVector2Array()   # world positions, root (underwater) to tip
var shapes: Array[CollisionShape2D] = []


func setup() -> void:
	base_x = enemy.global_position.x
	enemy.global_position.y = WATER_Y
	warn_timer = WARN
	full_len = randf_range(98.0, 124.0) if variant == 0 else randf_range(112.0, 132.0)
	sway_ph = randf() * TAU
	joints.resize(SEGS + 1)
	for i: int in BODY_SHAPES:
		var cs: CollisionShape2D = CollisionShape2D.new()
		var c: CircleShape2D = CircleShape2D.new()
		c.radius = 4.5
		cs.shape = c
		cs.disabled = true
		enemy.add_child(cs)
		shapes.append(cs)


func on_wake() -> void:
	state = Phase.RISE
	timer = RISE_TIME
	sfx("explode", -14.0, 0.12)
	sparks(Vector2(base_x, WATER_Y), Color("#c8f4ff"), 12)


func _sway_pose() -> Vector2:
	return Vector2(-PI * 0.5 + 0.14 * sin(age * 1.25 + sway_ph), 0.55 * sin(age * 1.8 + sway_ph * 2.0))


func tick(delta: float) -> void:
	base_x -= SCROLL * delta
	timer -= delta
	match state:
		Phase.RISE:
			ext = 1.0 - pow(clampf(timer / RISE_TIME, 0.0, 1.0), 2.0)
			var sp: Vector2 = _sway_pose()
			lean = sp.x
			curl = sp.y + 1.2 * (1.0 - ext)
			if timer <= 0.0:
				ext = 1.0
				state = Phase.SWAY
				timer = randf_range(0.7, 1.1)
		Phase.SWAY:
			var sp2: Vector2 = _sway_pose()
			lean = sp2.x
			curl = sp2.y
			# Between blows the tip flicks spray at you (the tip glints first).
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(60.0, 462.0):
				fire_timer = fire_cd(1.0)
				for k: int in [-1, 1]:
					shoot_aimed_from(enemy.global_position, 135.0, "ocean_drop", float(k) * 0.12)
			if timer <= 0.0:
				if slams_left > 0 and base_x > 150.0:
					state = Phase.CURL
					timer = CURL_TIME
					pose_from = Vector2(lean, curl)
					pose_to = Vector2(-PI * 0.5 + 0.38, 1.7)
					sfx("boss_hp_tick", -14.0, 0.1)
				else:
					state = Phase.SINK
					timer = 0.8
		Phase.CURL:
			var u: float = 1.0 - clampf(timer / CURL_TIME, 0.0, 1.0)
			var e: float = 1.0 - pow(1.0 - u, 3.0)
			lean = lerpf(pose_from.x, pose_to.x, e) + sin(age * 40.0) * 0.012 * u
			curl = lerpf(pose_from.y, pose_to.y, e)
			if timer <= 0.0:
				state = Phase.SLAM
				timer = SLAM_TIME
				pose_from = Vector2(lean, curl)
				pose_to = _slam_pose()
				sfx("missile", -11.0, 0.05)
		Phase.SLAM:
			var u2: float = 1.0 - clampf(timer / SLAM_TIME, 0.0, 1.0)
			var e2: float = u2 * u2
			lean = lerpf(pose_from.x, pose_to.x, e2)
			curl = lerpf(pose_from.y, pose_to.y, e2)
			if timer <= 0.0:
				_build_joints()
				_impact()
				slams_left -= 1
				state = Phase.RECOVER
				timer = RECOVER_TIME
				pose_from = Vector2(lean, curl)
		Phase.RECOVER:
			var u3: float = 1.0 - clampf(timer / RECOVER_TIME, 0.0, 1.0)
			var e3: float = u3 * u3 * (3.0 - 2.0 * u3)
			var sp3: Vector2 = _sway_pose()
			lean = lerpf(pose_from.x, sp3.x, e3)
			curl = lerpf(pose_from.y, sp3.y, e3)
			if timer <= 0.0:
				state = Phase.SWAY
				timer = randf_range(0.6, 0.9)
		Phase.SINK:
			ext = clampf(timer / 0.8, 0.0, 1.0)
			var sp4: Vector2 = _sway_pose()
			lean = sp4.x
			curl = sp4.y + 1.0 * (1.0 - ext)
			if timer <= 0.0:
				leave()
				return
	_build_joints()
	set_texture("ocean_tip_1" if state == Phase.CURL else "ocean_tip_0")


# The pose the blow ends in: leaning far forward with the tip curled down onto the water.
func _slam_pose() -> Vector2:
	return Vector2(-PI * 0.5 - 1.05, -1.25)


# Lays the arm out from the root (just under the water) to the tip, then puts the enemy (and its
# hit shape) on the tip and the body shapes on their joints.
func _build_joints() -> void:
	var seg: float = full_len * ext / float(SEGS)
	var p: Vector2 = Vector2(base_x, WATER_Y + 8.0)
	var a: float = lean
	joints[0] = p
	for i: int in range(1, SEGS + 1):
		var w: float = pow(float(i) / float(SEGS), 1.6)
		var wave: float = sin(age * 2.6 - float(i) * 0.5 + sway_ph) * 0.05 * ext
		a = lean + curl * w + wave * float(i) * 0.4
		p += Vector2.from_angle(a) * seg
		joints[i] = p
	var tip_dir: Vector2 = Vector2.from_angle(a)
	enemy.global_position = p + tip_dir * 8.0
	var s: Sprite2D = sprite()
	s.rotation = a + PI * 0.5
	s.offset = Vector2(0.0, -1.0)
	s.visible = enemy.global_position.y < WATER_Y + 4.0
	for k: int in range(shapes.size()):
		var j: Vector2 = joints[BODY_SHAPES[k]]
		shapes[k].position = j - enemy.global_position
		shapes[k].disabled = j.y > WATER_Y - 2.0 or ext < 0.3


func _impact() -> void:
	var hit: Vector2 = Vector2(enemy.global_position.x, WATER_Y - 4.0)
	# Low spray skimming along the water line toward the player...
	for k: int in range(7):
		var v: Vector2 = Vector2(-(112.0 + float(k) * 15.0), -(28.0 + float(k % 3) * 14.0))
		var b: GameBullet = emit_bullet(hit + Vector2(float(k) * -3.0, 0.0), v, "ocean_drop", false, 2.5)
		if b != null:
			var s: float = b.velocity.length() / maxf(1.0, v.length())
			b.gravity_pull = 70.0 * s * s
			b.life_left = 3.5
	# ...and a fan of spray thrown up that falls back.
	for k2: int in range(6):
		var ang: float = -PI * 0.5 - 0.2 - float(k2) * 0.2
		var v2: Vector2 = Vector2.from_angle(ang) * (150.0 + float(k2) * 6.0)
		var b2: GameBullet = emit_bullet(hit + Vector2(0.0, -4.0), v2, bullet_b(), false, 2.5)
		if b2 != null:
			var s2: float = b2.velocity.length() / maxf(1.0, v2.length())
			b2.gravity_pull = 120.0 * s2 * s2
			b2.life_left = 3.5
	sparks(hit, Color("#c8f4ff"), 14)
	sfx("explode", -11.0, 0.1)
	if enemy.fx != null:
		enemy.fx.add_shake(2.5)


func draw() -> void:
	var o: Vector2 = enemy.global_position
	var water_l: float = WATER_Y - o.y
	if joints.size() == SEGS + 1 and ext > 0.0:
		# Foam collar where the arm leaves the water.
		var cross_x: float = joints[1].x - o.x
		enemy.draw_set_transform(Vector2(floorf(cross_x), water_l + 1.0), 0.0, Vector2(1.0, 0.3))
		enemy.draw_circle(Vector2.ZERO, 10.0 + sin(age * 6.0) * 1.0, Color(0.75, 0.92, 0.95, 0.35))
		enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# The body, root to tip: dark outline, plum flesh, a lit band, the pale underside with a
		# row of suckers along it (they glow during the curl), and a few cyan storm-light spots.
		var pts: PackedVector2Array = PackedVector2Array()
		var rad: PackedFloat32Array = PackedFloat32Array()
		var nrm: PackedVector2Array = PackedVector2Array()
		for i: int in range(SEGS):
			var d: Vector2 = (joints[i + 1] - joints[i]).normalized()
			for h: int in range(3):
				var t: float = float(h) / 3.0
				var q: Vector2 = joints[i].lerp(joints[i + 1], t) - o
				if q.y > water_l + 1.0:
					continue
				pts.append(q.floor())
				rad.append(lerpf(8.5, 3.6, (float(i) + t) / float(SEGS)))
				nrm.append(Vector2(d.y, -d.x))
		var n_pts: int = pts.size()
		for k: int in range(n_pts):
			enemy.draw_circle(pts[k], rad[k] + 1.0, Art.FLESH[0])
		for k2: int in range(n_pts):
			enemy.draw_circle(pts[k2], rad[k2], Art.FLESH[1])
		for k3: int in range(n_pts):
			enemy.draw_circle((pts[k3] + nrm[k3] * rad[k3] * 0.15 + Vector2(0.0, -rad[k3] * 0.1)).floor(), rad[k3] * 0.62, Art.FLESH[2])
		for k4: int in range(n_pts):
			var band: Vector2 = (pts[k4] + nrm[k4] * (rad[k4] - 1.6)).floor()
			enemy.draw_rect(Rect2(band, Vector2(2.0, 2.0)), Art.FLESH[3])
		for k7: int in range(0, n_pts, 3):
			var ridge: Vector2 = (pts[k7] - nrm[k7] * rad[k7] * 0.45 + Vector2(0.0, -1.0)).floor()
			enemy.draw_rect(Rect2(ridge, Vector2.ONE), Art.FLESH[3])
		var lit: bool = state == Phase.CURL
		for k5: int in range(1, n_pts, 2):
			var c: Vector2 = (pts[k5] + nrm[k5] * (rad[k5] - 1.8)).floor()
			var sc: Color = Art.SUCKER
			if lit and int(age * 16.0 + float(k5)) % 3 != 0:
				sc = Color("#ffe27a")
			if rad[k5] > 5.0:
				enemy.draw_rect(Rect2(c, Vector2(2.0, 2.0)), sc)
				enemy.draw_rect(Rect2(c + Vector2(1.0, 1.0), Vector2.ONE), Art.SUCKER_D)
			else:
				enemy.draw_rect(Rect2(c, Vector2.ONE), sc)
		for k6: int in range(4, n_pts - 2, 7):
			var c2: Vector2 = (pts[k6] - nrm[k6] * rad[k6] * 0.35).floor()
			enemy.draw_rect(Rect2(c2, Vector2.ONE), Art.GLOW)
	if state == Phase.SWAY:
		draw_glint(Vector2.ZERO, fire_timer, SPIT_TELL, Color(0.6, 0.95, 1.0))
	if state == Phase.CURL:
		var u: float = 1.0 - clampf(timer / CURL_TIME, 0.0, 1.0)
		draw_glint(Vector2.ZERO, timer, CURL_TIME, Color(1.0, 0.85, 0.35))
		# Dotted arc: where the tip will sweep (around the root, out to the slam point).
		var root: Vector2 = joints[0] - o
		var reach: float = full_len * 0.92
		var a0: float = lean
		var a1: float = _slam_pose().x - 0.35
		var steps: int = 14
		for s: int in range(steps + 1):
			var aa: float = lerpf(a0, a1, float(s) / float(steps))
			var q2: Vector2 = root + Vector2.from_angle(aa) * reach
			if q2.y < water_l:
				enemy.draw_rect(Rect2(q2.floor(), Vector2.ONE), Color(1.0, 0.75, 0.45, 0.2 + 0.4 * u))
		# Ripples racing along the water ahead of the blow.
		for r: int in range(5):
			var rx: float = root.x - fposmod(age * 120.0 + float(r) * 24.0, 120.0) - 20.0
			enemy.draw_rect(Rect2(floorf(rx), water_l - 1.0, 5.0, 1.0), Color(0.8, 0.95, 1.0, 0.25 + 0.35 * u))
	draw_hp_bar(18.0, -14.0)


# A whirlpool opening on the swell: a turning foam spiral around a dark eye, with spray.
func draw_warning() -> void:
	var k: float = clampf(1.0 - warn_timer / WARN, 0.0, 1.0)
	var wy: float = WATER_Y - enemy.global_position.y
	enemy.draw_set_transform(Vector2(0.0, wy), 0.0, Vector2(1.0, 0.3))
	enemy.draw_circle(Vector2.ZERO, lerpf(3.0, 13.0, k), Color(0.02, 0.05, 0.07, 0.75))
	for arm: int in range(3):
		var pts: PackedVector2Array = PackedVector2Array()
		for s: int in range(10):
			var r: float = 4.0 + float(s) * 1.9 * (0.6 + 0.6 * k)
			var a: float = -age * 7.0 + float(arm) * TAU / 3.0 + float(s) * 0.42
			pts.append(Vector2.from_angle(a) * r)
		enemy.draw_polyline(pts, Color(0.75, 0.93, 0.97, 0.3 + 0.4 * k), 1.0)
	enemy.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for j: int in range(4):
		var t: float = fposmod(age * 2.8 + float(j) * 0.25, 1.0)
		var sx: float = (float(j) - 1.5) * 6.0
		enemy.draw_rect(Rect2(sx, wy - (t * 14.0 - t * t * 10.0) * (0.3 + k), 1.0, 1.0), Color(0.85, 0.97, 1.0, 0.85 * (1.0 - t)))


func on_death() -> void:
	sparks(enemy.global_position, Color("#d8849c"), 10)
	for i: int in range(0, SEGS, 3):
		if joints.size() > i and joints[i].y < WATER_Y:
			sparks(joints[i], Color("#7a2c50"), 4)
