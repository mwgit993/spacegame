extends "res://scripts/stages/stage_enemy.gd"

# STEAM CANNON: a hovering brass boiler with a cannon, a pressure gauge on top and a safety
# valve. Its gauge needle climbs from green into the red as the next shot builds (the
# telegraph); in the last moment the valve whistles and spits steam and the muzzle glints. Then
# it fires a heavy fused shell at the player, which bursts into a ring of shrapnel after FUSE
# seconds (a ring closes in on the shell as the fuse burns down). After SHOTS shells it drifts
# off. Shot down, any shell still in flight bursts at once.

enum Phase { ENTER, HOVER, LEAVE }

const NEEDLE_T: float = 1.5      # the needle climbs over the last NEEDLE_T s of the cooldown
const WHISTLE: float = 0.45
const FUSE: float = 0.75
const SHOTS: int = 3
const SHELL_SPEED: float = 92.0
const SHARDS: int = 9
const GAUGE: Vector2 = Vector2(0.5, -8.0)    # gauge centre, local
const VALVE: Vector2 = Vector2(9.0, -12.0)
const MUZZLE: Vector2 = Vector2(-17.0, 1.5)

var state: Phase = Phase.ENTER
var target_x: float = 400.0
var shots_left: int = SHOTS
var recoil: float = 0.0
var shells: Array[GameBullet] = []
var shell_age: PackedFloat32Array = PackedFloat32Array()
var puffs: PackedVector3Array = PackedVector3Array()   # steam puffs: x, y (local), age


func setup() -> void:
	target_x = randf_range(355.0, 425.0)
	fire_timer = 1.6


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		Phase.ENTER:
			p.x = lerpf(p.x, target_x, clampf(2.0 * delta, 0.0, 1.0))
			if p.x < target_x + 8.0:
				state = Phase.HOVER
		Phase.HOVER:
			fire_timer -= delta
			if fire_timer <= 0.0:
				if on_screen(80.0, 455.0):
					_fire(p)
					shots_left -= 1
					fire_timer = fire_cd(2.7)
					if shots_left <= 0:
						state = Phase.LEAVE
				else:
					fire_timer = NEEDLE_T
		Phase.LEAVE:
			p.x -= 58.0 * delta
	p.y = clampf(base_y + sin(age * 1.6 + phase) * 9.0, 40.0, 236.0)
	enemy.global_position = p
	recoil -= delta
	if recoil > 0.0:
		set_texture("clock_boiler_2")
	else:
		set_texture("clock_boiler_%d" % (int(age * 9.0) % 2))
	# Valve steam while whistling.
	if state == Phase.HOVER and fire_timer < WHISTLE and fire_timer > 0.0 and int(age * 30.0) % 3 == 0:
		puffs.append(Vector3(VALVE.x + randf_range(-1.0, 1.0), VALVE.y, 0.0))
	var j: int = 0
	while j < puffs.size():
		var q: Vector3 = puffs[j]
		q.z += delta
		q.y -= 22.0 * delta
		q.x += 10.0 * delta
		if q.z > 0.6:
			puffs.remove_at(j)
			continue
		puffs[j] = q
		j += 1
	# Shells in flight: burst when the fuse runs out.
	var i: int = 0
	while i < shells.size():
		var b: GameBullet = shells[i]
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			shells.remove_at(i)
			shell_age.remove_at(i)
			continue
		shell_age[i] += delta
		if shell_age[i] >= FUSE:
			_burst(b, false)
			shells.remove_at(i)
			shell_age.remove_at(i)
			continue
		i += 1


func _fire(p: Vector2) -> void:
	var origin: Vector2 = p + MUZZLE
	var dir: Vector2 = (player_pos() - origin).normalized()
	var b: GameBullet = emit_bullet(origin, dir * SHELL_SPEED, "clock_shell_0", false, 4.0)
	if b != null:
		b.anim_tex_b = "clock_shell_1"
		shells.append(b)
		shell_age.append(0.0)
	recoil = 0.22
	sparks(origin, Color("#fff0b0"), 4)
	sfx("explode", -15.0, 0.1)


func _burst(b: GameBullet, deferred: bool) -> void:
	var rot: float = randf() * TAU
	for k: int in range(SHARDS):
		emit_bullet(b.global_position, Vector2.from_angle(rot + TAU * float(k) / float(SHARDS)) * 78.0, "clock_shard", deferred, 2.5)
	sparks(b.global_position, Color("#ff9ad8"), 5)
	b.queue_free()


func draw() -> void:
	draw_hp_bar(26.0, -19.0)
	# Gauge needle: green (lower left) round through the top into the red (upper right).
	var k: float = 0.0
	if state == Phase.HOVER:
		k = clampf(1.0 - fire_timer / NEEDLE_T, 0.0, 1.0)
	elif recoil > 0.0:
		k = 1.0
	var whistle: bool = state == Phase.HOVER and fire_timer < WHISTLE
	var ang: float = lerpf(PI * 0.75, PI * 1.75, k)
	if whistle:
		ang += sin(age * 70.0) * 0.12
	var tip: Vector2 = GAUGE + Vector2.from_angle(ang) * 3.0
	enemy.draw_line(GAUGE, tip, Color("#c01810") if k > 0.7 else Color("#1a1210"), 1.0)
	enemy.draw_rect(Rect2(GAUGE.floor(), Vector2.ONE), Color("#1a1210"))
	for q: Vector3 in puffs:
		var u: float = q.z / 0.6
		enemy.draw_circle(Vector2(q.x, q.y), 1.0 + u * 3.0, Color(0.9, 0.92, 0.95, 0.45 * (1.0 - u)))
	if whistle:
		draw_glint(MUZZLE, fire_timer, WHISTLE, Color(1.0, 0.75, 0.3))
	# Fuse rings closing in on each shell in flight.
	for n: int in range(shells.size()):
		var b: GameBullet = shells[n]
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			var u2: float = clampf(shell_age[n] / FUSE, 0.0, 1.0)
			enemy.draw_arc(b.global_position - enemy.global_position, lerpf(12.0, 5.0, u2), 0.0, TAU, 16, Color(1.0, 0.6, 0.85, 0.25 + 0.5 * u2), 1.0)


func on_death() -> void:
	for b: GameBullet in shells:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			_burst(b, true)
	shells.clear()
	sparks(enemy.global_position, Color("#e8c060"), 10)
	sparks(enemy.global_position, Color("#e0e8f0"), 6)
