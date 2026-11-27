extends "res://scripts/stages/stage_enemy.gd"

# SCARAB: small gold-and-lapis drones that weave in from the right, each clutching an energy orb.
# It slows to a hover, lifts its wing cases and the orb flares (telegraph), then hurls the orb at
# the player. The orb blinks in flight and bursts into a ring of glyph shards after ORB_FUSE
# seconds. A new orb grows in its claws for a second throw, then it flies off. Shooting a scarab
# down makes any orb it still has in flight fizzle out harmlessly.

enum Phase { FLY, WINDUP, COOL, LEAVE }

const WINDUP: float = 0.45
const ORB_FUSE: float = 0.85
const SHARDS: int = 7
const THROWS: int = 2
const ORB_OFF: Vector2 = Vector2(-3.0, 7.0)

var state: Phase = Phase.FLY
var timer: float = 0.0
var throws_left: int = THROWS
var orb: GameBullet = null
var orb_t: float = 0.0
var target_x: float = 360.0
var regrow: float = 1.0


func setup() -> void:
	target_x = randf_range(310.0, 410.0) - float(variant) * 30.0


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	match state:
		Phase.FLY:
			p.x -= 80.0 * delta
			p.y = clampf(base_y + sin(age * 2.6 + phase) * 16.0, 40.0, 236.0)
			if p.x <= target_x and on_screen(60.0, 450.0):
				_windup()
		Phase.WINDUP:
			p.y += sin(age * 9.0) * 8.0 * delta
			timer -= delta
			if timer <= 0.0:
				_throw(p)
		Phase.COOL:
			p.x -= 10.0 * delta
			p.y = lerpf(p.y, base_y + sin(age * 1.8 + phase) * 20.0, clampf(delta * 1.5, 0.0, 1.0))
			regrow = minf(1.0, regrow + delta)
			timer -= delta
			if timer <= 0.0:
				if throws_left > 0 and on_screen(60.0, 450.0):
					_windup()
				elif throws_left <= 0:
					state = Phase.LEAVE
		Phase.LEAVE:
			p += Vector2(-130.0, -36.0 if p.y > 135.0 else 36.0) * delta
	enemy.global_position = p
	var wings: bool = state == Phase.WINDUP or (int(age * 12.0) % 4 == 0)
	set_texture("desert_scarab_1" if wings else "desert_scarab_0")
	_update_orb(delta)


func _windup() -> void:
	state = Phase.WINDUP
	timer = WINDUP
	sfx("boss_hp_tick", -16.0, 0.15)


func _throw(p: Vector2) -> void:
	var dir: Vector2 = (player_pos() - (p + ORB_OFF)).normalized()
	orb = emit_bullet(p + ORB_OFF, dir * 105.0, "desert_orb_0", false, 4.0)
	if orb != null:
		orb.anim_tex_b = "desert_orb_1"
	orb_t = ORB_FUSE
	throws_left -= 1
	regrow = 0.0
	state = Phase.COOL
	timer = fire_cd(1.5)
	sfx("laser", -15.0, 0.1)


# The thrown orb is a plain bullet; the scarab bursts it into shards when its fuse runs out.
func _update_orb(delta: float) -> void:
	if orb == null:
		return
	if not is_instance_valid(orb) or orb.is_queued_for_deletion():
		orb = null
		return
	orb_t -= delta
	if orb_t <= 0.0:
		var at: Vector2 = orb.global_position
		var rot: float = randf() * TAU
		for i: int in range(SHARDS):
			emit_bullet(at, Vector2.from_angle(rot + TAU * float(i) / float(SHARDS)) * 84.0, bullet_b())
		sparks(at, Color("#e070ff"), 6)
		orb.queue_free()
		orb = null


func draw() -> void:
	# The orb it is carrying (growing back after a throw).
	if throws_left > 0 and state != Phase.LEAVE:
		var tex: Texture2D = PixelArt.tex("desert_orb_1" if state == Phase.WINDUP and int(age * 16.0) % 2 == 0 else "desert_orb_0")
		var sz: float = floorf(lerpf(3.0, 11.0, regrow))
		enemy.draw_texture_rect(tex, Rect2(ORB_OFF - Vector2(sz, sz) * 0.5, Vector2(sz, sz)).abs(), false)
	if state == Phase.WINDUP:
		var k: float = 1.0 - timer / WINDUP
		enemy.draw_circle(ORB_OFF, 5.0 + 3.0 * k, Color(0.9, 0.45, 1.0, 0.15 + 0.25 * k))
		draw_glint(ORB_OFF, timer, WINDUP, Color(0.85, 0.4, 1.0))


func on_death() -> void:
	if orb != null and is_instance_valid(orb) and not orb.is_queued_for_deletion():
		orb.life_left = 0.25
	orb = null
	sparks(enemy.global_position, Color("#e0b040"), 7)
