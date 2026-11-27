extends "res://scripts/stages/stage_enemy.gd"

# Blob launcher: a pressure tank bolted to the floor (variant 0) or ceiling (variant 1),
# riding the scroll. Its vent cap bulges and glows (the telegraph), then it lobs an ooze blob
# (a child: no Scrap), BLOBS times at most, and never while BLOB_CAP blobs are about.

const Blob = preload("enemy_blob.gd")

const BLOBS: int = 3
const BULGE: float = 0.5
const SCROLL: float = 40.0
const FLOOR_Y: float = 245.0
const CEIL_Y: float = 41.0

var ceiling: bool = false
var blobs_left: int = BLOBS
var launch_t: float = 1.0


func setup() -> void:
	ceiling = variant == 1
	enemy.global_position.y = CEIL_Y if ceiling else FLOOR_Y
	base_y = enemy.global_position.y
	sprite().flip_v = ceiling
	launch_t = 0.9 + randf() * 0.4


func tick(delta: float) -> void:
	var p: Vector2 = enemy.global_position
	p.x -= SCROLL * delta
	enemy.global_position = p
	var on: bool = on_screen(60.0, 450.0)
	if blobs_left > 0 and on:
		launch_t -= delta
		if launch_t <= 0.0:
			if Blob.count(enemy) < Blob.CAP:
				blobs_left -= 1
				var up: float = 1.0 if ceiling else -1.0
				spawn_child("blob", p + Vector2(0.0, 13.0 * up), Vector2(randf_range(-80.0, -40.0), 40.0 if ceiling else -175.0))
				sparks(p + Vector2(0.0, 12.0 * up), Color("#7ad830"), 6)
				sfx("missile", -14.0, 0.1)
			launch_t = fire_cd(2.0)
	set_texture("biolab_launcher_1" if blobs_left > 0 and launch_t < BULGE and on else "biolab_launcher_0")


func draw() -> void:
	if blobs_left > 0 and launch_t < BULGE:
		var k: float = 1.0 - clampf(launch_t / BULGE, 0.0, 1.0)
		var tip: Vector2 = Vector2(0.0, 12.0 if ceiling else -12.0)
		enemy.draw_circle(tip, 3.0 + 4.0 * k, Color(0.5, 1.0, 0.2, 0.15 + 0.3 * k))
	draw_hp_bar(20.0, 16.0 if ceiling else -18.0)


func on_death() -> void:
	sparks(enemy.global_position, Color("#7ad830"), 10)
	sparks(enemy.global_position, Color("#e8c030"), 6)

