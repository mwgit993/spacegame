extends "res://scripts/stages/stage_enemy.gd"

# BINARY DRONES: two heat-shielded drones orbiting a shared centre as the pair crosses the screen
# (a squad of two spawned together, variant 0 and 1, half an orbit apart, joined by a faint
# magnetic tether). Each one spins up (a charge glint grows on its eye: the telegraph), then
# streams a slow rotating spiral of plasma, so the pair paints a double spiral. If its partner is
# shot down it enrages: a red-hot flash, it breaks orbit, tracks the player's height and fires
# fast aimed triples (each with a glint first). A lone drone (no squad) enrages on its own after
# SOLO_RAGE seconds.

enum Phase { SPIN_UP, STREAM, REST }

const ORBIT_R: float = 22.0
const SPIN: float = 2.1
const SPIN_UP: float = 0.8
const STREAM_TIME: float = 2.2
const SPIRAL_GAP: float = 0.8
const RAGE_GAP: float = 1.2
const RAGE_WARN: float = 0.3
const SOLO_RAGE: float = 2.0

var state: Phase = Phase.SPIN_UP
var center: Vector2 = Vector2.ZERO
var spiral_ang: float = 0.0
var stream_t: float = 0.0
var shot_t: float = 0.0
var enraged: bool = false
var rage_flash: float = 0.0
var check_t: float = 0.0
var had_partner: bool = false


func setup() -> void:
	center = enemy.global_position
	spiral_ang = float(variant) * PI
	fire_timer = 1.3
	_orbit(0.0)


func _orbit(_delta: float) -> void:
	var a: float = age * SPIN + float(variant) * PI
	enemy.global_position = center + Vector2(cos(a), sin(a) * 0.8) * ORBIT_R


func tick(delta: float) -> void:
	check_t -= delta
	if check_t <= 0.0 and not enraged:
		check_t = 0.2
		_check_partner()
	rage_flash = maxf(0.0, rage_flash - delta)
	if enraged:
		_tick_rage(delta)
		return
	center.x -= 38.0 * delta
	center.y = clampf(base_y + sin(age * 0.8 + phase) * 16.0, 50.0, 222.0)
	_orbit(delta)
	set_texture("corona_binary_0")
	match state:
		Phase.SPIN_UP:
			fire_timer -= delta
			if fire_timer <= 0.0 and on_screen(60.0, 460.0):
				state = Phase.STREAM
				stream_t = STREAM_TIME
				shot_t = 0.0
		Phase.STREAM:
			stream_t -= delta
			shot_t -= delta
			if shot_t <= 0.0:
				shot_t = fire_cd(SPIRAL_GAP)
				var d: Vector2 = Vector2.from_angle(spiral_ang)
				emit_bullet(enemy.global_position + d * 6.0, d * 80.0, bullet_b())
				spiral_ang += 0.62
			if stream_t <= 0.0:
				state = Phase.REST
				fire_timer = fire_cd(1.3) + SPIN_UP
		Phase.REST:
			fire_timer -= delta
			if fire_timer <= SPIN_UP:
				state = Phase.SPIN_UP


func _check_partner() -> void:
	if enemy.squad_id < 0:
		if age > SOLO_RAGE:
			_enrage()
		return
	var found: bool = false
	for n: Node in enemy.get_tree().get_nodes_in_group("enemies"):
		var ge: GameEnemy = n as GameEnemy
		if ge != null and ge != enemy and not ge._dead and ge.squad_id == enemy.squad_id and ge.module_kind == enemy.module_kind:
			found = true
			break
	if found:
		had_partner = true
	elif had_partner:
		_enrage()


func _enrage() -> void:
	enraged = true
	rage_flash = 0.5
	fire_timer = 0.6
	set_texture("corona_binary_1")
	sfx("boss_hp_tick", -11.0, 0.0)
	sparks(enemy.global_position, Color("#ff7a20"), 8)


func _tick_rage(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= 52.0 * delta
	p.y = move_toward(p.y, clampf(player_pos().y, 44.0, 234.0), 62.0 * delta)
	enemy.global_position = p
	set_texture("corona_binary_1")
	fire_timer -= delta
	if fire_timer <= 0.0 and on_screen(70.0, 460.0):
		fire_timer = fire_cd(RAGE_GAP)
		for k: int in [-1, 0, 1]:
			shoot_aimed(165.0, bullet_a(), float(k) * 0.16)
		sfx("laser", -14.0, 0.05)


func draw() -> void:
	if enraged:
		draw_glint(Vector2(-6.0, 0.0), fire_timer, RAGE_WARN, Color(1.0, 0.45, 0.15))
		if rage_flash > 0.0:
			var k: float = 1.0 - rage_flash / 0.5
			enemy.draw_arc(Vector2.ZERO, 6.0 + k * 16.0, 0.0, TAU, 20, Color(1.0, 0.6, 0.2, 1.0 - k), 2.0)
		return
	# Faint tether to the partner across the shared centre.
	if had_partner:
		var other: Vector2 = (center - enemy.global_position) * 2.0
		var fl: float = 0.12 + 0.08 * sin(age * 17.0 + float(variant))
		enemy.draw_line(Vector2.ZERO, other, Color(0.55, 0.65, 1.0, fl), 1.0)
	if state == Phase.SPIN_UP:
		draw_glint(Vector2(-5.0, 0.0), fire_timer, SPIN_UP, Color(0.5, 0.65, 1.0))
	elif state == Phase.STREAM:
		enemy.draw_circle(Vector2(-5.0, 0.0), 2.0 + sin(age * 30.0), Color(0.7, 0.8, 1.0, 0.6))


func on_death() -> void:
	sparks(enemy.global_position, Color("#8ab0ff"), 8)
