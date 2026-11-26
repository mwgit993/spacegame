extends RefCounted

# Base class of a stage-module enemy behaviour. GameEnemy creates one instance per enemy (from
# the "behaviour" script in the module's get_enemy_defs()) and calls the hooks below, so a
# module adds new enemy types without touching enemy.gd. A behaviour script starts with:
#
#     extends "res://scripts/stages/stage_enemy.gd"
#
# What GameEnemy already does for every module enemy (same as the built-in stage enemies):
#  - base stats, hit shape and starting sprite from the definition; HP scaled by the stage
#  - removal once it leaves the screen (no rewards), kill rewards, the flash on hit
#  - status effects: while chilled, the delta passed to tick() is already slowed
#  - holds fire_timer at 0.5 or more while the enemy is off the right edge, so every first
#    shot is on screen (use fire_timer for your main attack to get this for free)
#  - entrance telegraph: set warn_timer > 0 in setup() and the enemy starts hidden and
#    unhittable (out of the "enemies" group); on_wake() runs when it runs out, and
#    draw_warning() draws the telegraph meanwhile
#
# Regular enemies' bullet speeds and cooldowns are written as stage-1 values: emit_bullet()
# scales speed by the stage's shot_speed, and fire_cd() divides cooldowns by its fire_rate.
#
# Child enemies (splits, drops, copies) go through spawn_child(): they spawn next frame, give
# no Scrap and at most 1 XP. Cap every source of children (see GameEnemy.VIRUS_CAP).

var enemy: GameEnemy
var def: Dictionary = {}

# Sprite keys set_texture() couldn't find (the smoke test fails if this isn't empty).
static var missing_sprites: Dictionary = {}

# Shortcuts to the enemy's shared state.
var fire_timer: float:
	get:
		return enemy._fire_timer
	set(v):
		enemy._fire_timer = v
var warn_timer: float:
	get:
		return enemy._warn_timer
	set(v):
		enemy._warn_timer = v
var vel: Vector2:
	get:
		return enemy._vel
	set(v):
		enemy._vel = v
var base_y: float:
	get:
		return enemy._base_y
	set(v):
		enemy._base_y = v
var age: float:
	get:
		return enemy._age
var phase: float:  # the "phase" the wave director gave this spawn (staggers squads)
	get:
		return enemy._phase_offset
var variant: int:  # the "variant" from the wave director (layout choice, mirrored version...)
	get:
		return enemy.variant
var gen: int:      # 0 = spawned by the wave director, 1+ = a child
	get:
		return enemy.gen


# --- Hooks ---------------------------------------------------------------------------------------

# After the stats are set. fire_timer starts at 1.0-1.6 s (divided by the stage fire rate).
func setup() -> void:
	pass


# Every frame while alive (not called while dormant). Move with enemy.global_position.
func tick(_delta: float) -> void:
	pass


# Telegraphs and HP bars, drawn on top of the sprite in the enemy's local space
# (use enemy.draw_circle(), enemy.draw_rect(), draw_glint(), draw_hp_bar()...).
func draw() -> void:
	pass


# Shot down (not when it leaves the screen). Fire with deferred = true here.
func on_death() -> void:
	pass


# The entrance telegraph (warn_timer) ran out: it's now visible and hittable.
func on_wake() -> void:
	pass


# Drawn instead of draw() while dormant.
func draw_warning() -> void:
	pass


# Lets a behaviour block or amplify damage (a shield, an armoured phase). Return the damage.
func modify_damage(dmg: float) -> float:
	return dmg


# --- Helpers ---------------------------------------------------------------------------------------

func player_pos() -> Vector2:
	return enemy._player_pos()


func on_screen(margin_left: float = 70.0, margin_right: float = 462.0) -> bool:
	return enemy._on_screen(margin_left, margin_right)


func fire_cd(base: float) -> float:
	return enemy._fire_cd(base)


func bullet_a() -> String:
	return enemy._bullet_a


func bullet_b() -> String:
	return enemy._bullet_b


func shoot_aimed(speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	enemy._shoot_aimed(speed, tex_key, angle_offset)


func shoot_aimed_from(origin: Vector2, speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	enemy._shoot_aimed_from(origin, speed, tex_key, angle_offset)


func shoot_spread_from(origin: Vector2, count: int, step_angle: float, speed: float, tex_key: String) -> void:
	enemy._shoot_from_spread(origin, count, step_angle, speed, tex_key)


# One shot; returns it so you can add gravity_pull, homing, life_left... (see GameBullet).
func emit_bullet(pos: Vector2, velocity: Vector2, tex_key: String, deferred: bool = false, hit_radius: float = 2.5) -> GameBullet:
	return enemy._emit_bullet(pos, velocity, tex_key, deferred, hit_radius)


# Unlike PixelArt.tex(), a missing key is reported (once per key, and the smoke test fails on
# it) instead of quietly showing another sprite.
func set_texture(key: String) -> void:
	if not PixelArt._cache.has(key) and not missing_sprites.has(key):
		missing_sprites[key] = true
		push_error("Stage enemy '%s' has no sprite '%s'" % [enemy.module_kind, key])
	enemy._sprite.texture = PixelArt.tex(key)


func sprite() -> Sprite2D:
	return enemy._sprite


# Spawns another enemy of this stage next frame, as a child (gen + 1).
func spawn_child(kind: String, pos: Vector2, velocity: Vector2) -> void:
	enemy._request_child(GameEnemy.Type.MODULE, pos, velocity, enemy.gen + 1, kind)


# Leaves without rewards (flew off, burst on its own).
func leave() -> void:
	enemy._leave()


func sparks(pos: Vector2, col: Color, count: int) -> void:
	if enemy.fx != null:
		enemy.fx.spawn_hit_sparks(pos, col, count)


func sfx(key: String, volume_db: float = -12.0, pitch_jitter: float = 0.05) -> void:
	RetroSfx.play(key, volume_db, pitch_jitter)


# The standard charge glint: grows over the last `window` seconds before timer reaches 0.
func draw_glint(at: Vector2, timer: float, window: float, col: Color = Color(1.0, 0.16, 0.28)) -> void:
	enemy._draw_glint(at, timer, window, col)


func draw_hp_bar(width: float, y: float) -> void:
	enemy._draw_hp_bar(width, y)
