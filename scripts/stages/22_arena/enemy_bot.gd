extends "res://scripts/stages/stage_enemy.gd"

# COMBAT BOT: arena bots warp in for an announced round. The squad materialises together (a
# holographic outline with a scan line; the leader, variant 1, flashes "ROUND n" above the
# formation, then "FIGHT!"), then every bot fires on the same beat: their visors flash on the
# three beats before each volley, then the whole squad fires at once (an aimed shot, or a 3-way
# spread on alternate volleys). After VOLLEYS volleys the bots break off and rush away.
# The wave director spawns a squad at the same moment, so their clocks stay in step; "phase"
# carries the round number shown by the leader.

const PixFont = preload("pixfont.gd")

const WARP: float = 0.95
const VOLLEYS: int = 4
const FIGHT_SHOW: float = 0.7
const FLASH: float = 0.12

var t: float = 0.0
var cycle: float = 1.7
var volley: int = 0
var next_fire: float = 0.0
var leaving: bool = false
var bob: float = 0.0
var flash_t: float = 0.0


func setup() -> void:
	warn_timer = WARP
	cycle = fire_cd(2.2)
	next_fire = cycle * 0.85
	bob = base_y * 0.07
	fire_timer = 99.0


func on_wake() -> void:
	t = 0.0
	sparks(enemy.global_position, Color("#38e8ff"), 5)
	if variant == 1:
		sfx("shield_hit", -12.0, 0.0)


func _beat() -> float:
	return cycle * 0.17


func tick(delta: float) -> void:
	t += delta
	flash_t -= delta
	var p: Vector2 = enemy.global_position
	if leaving:
		vel = vel.lerp(Vector2(-200.0, sin(bob) * 30.0), clampf(delta * 1.6, 0.0, 1.0))
		p += vel * delta
		set_texture("arena_bot_0")
	else:
		p.x -= 16.0 * delta
		p.y = base_y + sin(age * 2.2 + bob) * 3.0
		var to_fire: float = next_fire - t
		var lit: bool = false
		for b: int in range(1, 4):
			var w0: float = float(b) * _beat()
			if to_fire <= w0 and to_fire > w0 - _beat() * 0.45:
				lit = true
		if flash_t > 0.0:
			set_texture("arena_bot_2")
		else:
			set_texture("arena_bot_1" if lit else "arena_bot_0")
		if t >= next_fire:
			if on_screen(70.0, 462.0):
				_volley(p)
			volley += 1
			next_fire += cycle
			if volley >= VOLLEYS:
				leaving = true
				vel = Vector2(-30.0, 0.0)
	enemy.global_position = p


func _volley(p: Vector2) -> void:
	flash_t = FLASH
	var muzzle: Vector2 = p + Vector2(-10.0, 2.0)
	if volley % 2 == 0:
		shoot_aimed_from(muzzle, 132.0, bullet_a(), -0.07)
		shoot_aimed_from(muzzle, 132.0, bullet_a(), 0.07)
	else:
		shoot_spread_from(muzzle, 3, 0.2, 116.0, bullet_b())
	if variant == 1:
		sfx("laser", -14.0, 0.04)


func draw() -> void:
	draw_hp_bar(14.0, -14.0)
	if not leaving:
		draw_glint(Vector2(-11.0, 2.0), next_fire - t, _beat() * 0.6, Color(1.0, 0.3, 0.8))
	if variant == 1 and t < FIGHT_SHOW:
		var a: float = 1.0 if fposmod(t * 10.0, 1.0) < 0.6 else 0.35
		PixFont.draw_centered(enemy, "FIGHT!", Vector2(0.0, -21.0), 1.0, Color(1.0, 0.82, 0.3, a))


# Warping in: a holographic outline with a scan line sweeping down it.
func draw_warning() -> void:
	var k: float = clampf(1.0 - warn_timer / WARP, 0.0, 1.0)
	var flick: float = 0.75 + 0.25 * sin(age * 40.0)
	var col: Color = Color(0.25, 0.9, 1.0, (0.2 + 0.45 * k) * flick)
	enemy.draw_rect(Rect2(-8.0, -10.0, 17.0, 20.0), col, false, 1.0)
	enemy.draw_rect(Rect2(-6.0, -8.0, 13.0, 6.0), Color(col.r, col.g, col.b, col.a * 0.4))
	var sy: float = lerpf(-10.0, 10.0, fposmod(k * 3.0, 1.0))
	enemy.draw_line(Vector2(-10.0, sy), Vector2(11.0, sy), Color(0.8, 1.0, 1.0, 0.5 * flick), 1.0)
	if variant == 1:
		var blink: float = 1.0 if fposmod(k * 6.0, 1.0) < 0.65 else 0.4
		PixFont.draw_centered(enemy, "ROUND %d" % maxi(1, int(phase)), Vector2(0.0, -21.0), 1.0, Color(1.0, 0.3, 0.82, 0.9 * blink))


func on_death() -> void:
	sparks(enemy.global_position, Color("#ff3cc8"), 6)
