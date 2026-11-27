extends "res://scripts/stages/stage_enemy.gd"

# Mine (dropped by hulks, so normally a child: no Scrap). It drifts with the debris, its light
# blinking faster as the fuse burns down; for the last WARN seconds a shrinking ring marks the
# blast. If it isn't shot first it bursts into a ring of RING shots and is gone (no reward).

const FUSE: float = 3.0
const WARN: float = 0.75
const RING: int = 8

var fuse: float = FUSE


func setup() -> void:
	fuse = FUSE + randf() * 0.4


func tick(delta: float) -> void:
	vel = vel.lerp(Vector2(-24.0, 0.0), clampf(1.4 * delta, 0.0, 1.0))
	var p: Vector2 = enemy.global_position + vel * delta
	p.y = clampf(p.y, 36.0, 244.0)
	enemy.global_position = p
	fuse -= delta
	var hz: float = 2.0 + 10.0 * (1.0 - clampf(fuse / FUSE, 0.0, 1.0))
	set_texture("wreck_mine_1" if fposmod(age * hz, 1.0) < 0.5 else "wreck_mine_0")
	sprite().rotation += delta * 1.5
	if fuse <= 0.0 and on_screen(10.0, 470.0):
		var rot: float = randf() * TAU
		for i: int in range(RING):
			emit_bullet(p, Vector2.from_angle(rot + TAU * float(i) / float(RING)) * 82.0, bullet_b())
		sparks(p, Color("#ff6060"), 8)
		sfx("explode", -12.0, 0.1)
		leave()


func draw() -> void:
	if fuse < WARN:
		var k: float = 1.0 - clampf(fuse / WARN, 0.0, 1.0)
		enemy.draw_arc(Vector2.ZERO, lerpf(26.0, 7.0, k), 0.0, TAU, 20, Color(1.0, 0.3, 0.3, 0.25 + 0.4 * k), 1.0)
