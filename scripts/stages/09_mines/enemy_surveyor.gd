extends "res://scripts/stages/stage_enemy.gd"

# LASER SURVEYOR: settles near the right edge and cuts mining-laser lines through the cavern.
# Its lens charges (glint) while a dashed guide line shows the beam's path; then it streams
# bolts straight ahead while drifting toward the player's height, so the stream bends into a
# moving wall you have to get around. CUTS cuts, then it lifts away. variant 1 starts lower and
# waits a little longer.

enum Phase { ENTER, CHARGE, CUT, REST, LEAVE }

const CHARGE_TIME: float = 0.7
const CUT_TIME: float = 1.0
const BOLT_GAP: float = 0.085
const CUTS: int = 4
const LENS: Vector2 = Vector2(-7.0, 0.0)

var state: Phase = Phase.ENTER
var timer: float = 0.0
var bolt_t: float = 0.0
var cuts_left: int = CUTS
var target_x: float = 410.0


func setup() -> void:
	target_x = randf_range(386.0, 432.0)
	timer = 0.9 if variant == 0 else 1.4


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	var lit: bool = false
	match state:
		Phase.ENTER:
			p.x = lerpf(p.x, target_x, clampf(2.4 * delta, 0.0, 1.0))
			p.y = lerpf(p.y, base_y + sin(age * 1.3) * 10.0, clampf(2.0 * delta, 0.0, 1.0))
			timer -= delta
			if timer <= 0.0 and p.x < 450.0:
				_charge()
		Phase.CHARGE:
			timer -= delta
			lit = int(age * 16.0) % 2 == 0
			if timer <= 0.0:
				state = Phase.CUT
				timer = CUT_TIME
				bolt_t = 0.0
				sfx("laser", -13.0, 0.05)
		Phase.CUT:
			lit = true
			timer -= delta
			bolt_t -= delta
			# Drift toward the player's height while cutting.
			var want: float = clampf(player_pos().y, 44.0, 236.0)
			p.y = move_toward(p.y, want, 48.0 * delta)
			if bolt_t <= 0.0:
				bolt_t = BOLT_GAP
				emit_bullet(p + LENS, Vector2(-178.0, 0.0), "mines_bolt", false, 2.5)
			if timer <= 0.0:
				cuts_left -= 1
				if cuts_left <= 0:
					state = Phase.LEAVE
				else:
					state = Phase.REST
					timer = fire_cd(1.4)
		Phase.REST:
			p.y = lerpf(p.y, p.y + sin(age * 2.0) * 4.0, clampf(delta, 0.0, 1.0))
			timer -= delta
			if timer <= 0.0:
				_charge()
		Phase.LEAVE:
			p += Vector2(36.0, -70.0 if p.y < 135.0 else 70.0) * delta
	set_texture("mines_surveyor_1" if lit else "mines_surveyor_0")
	enemy.global_position = p


func _charge() -> void:
	state = Phase.CHARGE
	timer = CHARGE_TIME
	sfx("boss_hp_tick", -15.0, 0.05)


func draw() -> void:
	if state == Phase.CHARGE:
		var k: float = 1.0 - timer / CHARGE_TIME
		var col: Color = Color(1.0, 0.25, 0.4, 0.2 + 0.4 * k)
		var x: float = LENS.x - 4.0 - fposmod(age * 80.0, 8.0)
		while x > -enemy.global_position.x:
			enemy.draw_line(Vector2(x, 0.0), Vector2(x - 4.0, 0.0), col, 1.0)
			x -= 8.0
		draw_glint(LENS, timer, CHARGE_TIME, Color(1.0, 0.3, 0.45))
	elif state == Phase.CUT:
		enemy.draw_circle(LENS, 3.0 + sin(age * 50.0), Color(1.0, 0.45, 0.6, 0.5))
	draw_hp_bar(16.0, -12.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff5c8a"), 8)
