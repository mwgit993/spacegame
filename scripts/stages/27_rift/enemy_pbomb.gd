extends "res://scripts/stages/stage_enemy.gd"

# Probability bomb: drifts in and slows to a stop, then shows three possible futures at once,
# three candidate burst patterns overlaid as faint dotted rays (cyan, amber, violet). One by one
# the candidates flicker and dissolve as the probabilities collapse (every ELIM seconds); the
# survivor brightens to white for LOCK seconds (aimed patterns lock on then), and the bomb bursts
# with exactly that pattern, which ends it (no reward). Shot down before then, it only pops.
# Patterns: RING, CROSS (four arms of three), FAN (aimed), SPIRAL, HALO (slow and fast rings).

enum S { DRIFT, CHOOSE, LOCK }
enum P { RING, CROSS, FAN, SPIRAL, HALO }

const ELIM: float = 0.75
const LOCK_TIME: float = 0.55
const TINTS: Array[Color] = [Color(0.35, 0.9, 1.0), Color(1.0, 0.72, 0.28), Color(0.78, 0.62, 1.0)]

var state: S = S.DRIFT
var timer: float = 0.0
var target_x: float = 340.0
var cands: Array[int] = [0, 1, 2]
var order: Array[int] = [0, 1, 2]    # candidate slots in the order they drop out; the last survives
var dropped: int = 0
var rot: float = 0.0
var aim: float = PI
var spin_t: float = 0.0
var frame: int = 0


func setup() -> void:
	target_x = randf_range(320.0, 390.0) if variant == 0 else randf_range(250.0, 300.0)
	rot = randf() * TAU
	var pool: Array[int] = [P.RING, P.CROSS, P.FAN, P.SPIRAL, P.HALO]
	pool.shuffle()
	for i: int in range(3):
		cands[i] = pool[i]
	order.shuffle()


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		S.DRIFT:
			p.x = lerpf(p.x, target_x, 1.6 * delta) - 8.0 * delta
			p.y = base_y + sin(age * 1.4 + phase) * 6.0
			if absf(p.x - target_x) < 14.0 and on_screen(90.0, 450.0):
				state = S.CHOOSE
				timer = 0.0
				sfx("boss_hp_tick", -14.0, 0.0)
		S.CHOOSE:
			timer += delta
			p.x -= 6.0 * delta
			aim = (player_pos() - p).angle()
			if timer >= ELIM * float(dropped + 1):
				dropped += 1
				sfx("shield_hit", -17.0, 0.15)
				if dropped >= 2:
					state = S.LOCK
					timer = LOCK_TIME
					sfx("missile", -14.0, 0.05)
		S.LOCK:
			timer -= delta
			p.x -= 6.0 * delta
			if timer <= 0.0:
				enemy.global_position = p
				_burst(cands[order[2]], p)
				return
	enemy.global_position = p
	spin_t -= delta * (1.0 if state == S.DRIFT else 2.6)
	if spin_t <= 0.0:
		spin_t = 0.12
		frame = (frame + 1) % 2
	set_texture("rift_pbomb_2" if state == S.LOCK and int(age * 14.0) % 2 == 0 else "rift_pbomb_%d" % frame)


# The candidate's shots as (direction, speed) pairs.
func _shots(pat: int) -> PackedVector3Array:
	var out: PackedVector3Array = PackedVector3Array()
	match pat:
		P.RING:
			for i: int in range(14):
				out.append(Vector3(rot + TAU * float(i) / 14.0, 100.0, 0.0))
		P.CROSS:
			for arm: int in range(4):
				for k: int in range(3):
					out.append(Vector3(rot + PI * 0.5 * float(arm), 78.0 + 32.0 * float(k), 0.0))
		P.FAN:
			for i2: int in range(7):
				out.append(Vector3(aim + (float(i2) - 3.0) * 0.13, 128.0, 0.0))
		P.SPIRAL:
			for i3: int in range(12):
				out.append(Vector3(rot + float(i3) * 0.52, 66.0 + 7.0 * float(i3), 0.0))
		_:
			for i4: int in range(8):
				out.append(Vector3(rot + TAU * float(i4) / 8.0, 70.0, 0.0))
				out.append(Vector3(rot + TAU * (float(i4) + 0.5) / 8.0, 136.0, 0.0))
	return out


func _burst(pat: int, p: Vector2) -> void:
	for s: Vector3 in _shots(pat):
		emit_bullet(p, Vector2.from_angle(s.x) * s.y, "rift_qshot", false, 3.0)
	sparks(p, Color("#e4dcff"), 12)
	sfx("explode", -10.0, 0.1)
	if enemy.fx != null:
		enemy.fx.spawn_ring_blast(p, 26.0, Color("#c8a8ff"))
	leave()


func draw() -> void:
	if state == S.DRIFT:
		draw_hp_bar(22.0, -15.0)
		return
	for slot: int in range(3):
		var rank: int = order.find(slot)
		var a: float = 0.0
		var reach: float = 0.5
		var col: Color = TINTS[slot]
		if rank < dropped:
			# dropped out: a last flicker as it dissolves
			var gone: float = timer - ELIM * float(rank + 1) if state == S.CHOOSE else LOCK_TIME - timer + (0.0 if rank == dropped - 1 else 1.0)
			if gone > 0.25:
				continue
			a = 0.3 * (1.0 - gone / 0.25) * float(int(age * 30.0) % 2)
		elif state == S.LOCK:
			var k: float = 1.0 - clampf(timer / LOCK_TIME, 0.0, 1.0)
			a = 0.4 + 0.35 * k
			reach = 0.5 + 0.3 * k
			col = col.lerp(Color.WHITE, 0.6)
		else:
			a = 0.34 + 0.08 * sin(age * 9.0 + float(slot) * 2.0)
		if a <= 0.0:
			continue
		var segs: PackedVector2Array = PackedVector2Array()
		for s: Vector3 in _shots(cands[slot]):
			var d: Vector2 = Vector2.from_angle(s.x)
			var length: float = s.y * reach
			var dots: int = maxi(2, int(length / 7.0))
			for j: int in range(dots):
				var r0: float = 11.0 + length * float(j) / float(dots)
				var p0: Vector2 = (d * r0).floor() + Vector2(0.5, 0.5)
				segs.append(p0)
				segs.append(p0 + d * 2.0)
		enemy.draw_multiline(segs, Color(col.r, col.g, col.b, a), 1.0)
	var pulse: float = 0.5 + 0.5 * sin(age * 12.0)
	enemy.draw_arc(Vector2.ZERO, 12.0 + 2.0 * pulse, 0.0, TAU, 18, Color(0.85, 0.75, 1.0, 0.25 + 0.2 * pulse), 1.0)
	draw_hp_bar(22.0, -15.0)


func on_death() -> void:
	# collapsed before it could choose: only a harmless pop
	sparks(enemy.global_position, Color("#c8a8ff"), 10)
	sparks(enemy.global_position, Color("#ffffff"), 4)
