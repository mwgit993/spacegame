class_name GameEnemy
extends Area2D

enum Type {
	SCOUT_SINE, SWOOPER, SNIPER, CRUISER, BOSS,
	# Stage-signature enemies (stats in THEMED). ROCK_CHUNK and SPACE_MINE only appear as
	# children of ASTEROID and MINE_LAYER; VIRUS also spawns copies of itself.
	ASTEROID, ROCK_CHUNK, MINE_LAYER, SPACE_MINE,  # 1 Outer Orbit
	TURRET, SEC_DRONE,                             # 2 Starcruiser
	BLIMP, JET,                                    # 3 Cloud Base
	SPORE_POD, BEETLE,                             # 4 Xeno Forest
	ICE_CRYSTAL, SNOW_DRONE,                       # 5 Cryo Glacier
	LAVA_BLOB, GOLEM,                              # 6 Magma Core
	JELLYFISH, EEL, ANGLER,                        # 7 Abyssal Trench
	VIRUS, GLITCH, FIREWALL,                       # 8 Cyber Nexus
	# Any enemy of a stage module (stages 9+): module_kind names it in the module's
	# get_enemy_defs(), and a behaviour object (scripts/stages/stage_enemy.gd) runs it.
	MODULE,
}

signal destroyed(enemy: GameEnemy, killed_by_player: bool)
signal boss_phase_broken(enemy: GameEnemy, bonus_xp: int)
# Asks main to spawn a child enemy next frame (rock chunks, mines, virus copies). The item has
# the same keys as main's spawn queue, plus "gen" (1 for a child, 2 for a grandchild) and "vel".
signal spawn_requested(item: Dictionary)

static var _flash_shader: Shader = null

# Base stats of the stage-signature enemies, before the stage's HP multiplier
# (StageData.DIFFICULTY). "stage" is the home stage (0-based), "r" the hit radius (or "box"
# a rectangle) and "tex" the sprite.
# Children (gen > 0) give no Scrap and at most 1 XP, and every way of spawning them is capped
# (see MINES_PER_LAYER, ROCK_CHUNKS, VIRUS_MAX_GEN and VIRUS_CAP), so they can't be farmed.
const THEMED: Dictionary = {
	Type.ASTEROID: {"stage": 0, "hp": 6.0, "score": 200, "scrap": 1, "xp": 3, "r": 8.5, "tex": "en_asteroid_0"},
	Type.ROCK_CHUNK: {"stage": 0, "hp": 1.5, "score": 40, "scrap": 0, "xp": 1, "r": 4.5, "tex": "en_rock_chunk"},
	Type.MINE_LAYER: {"stage": 0, "hp": 9.0, "score": 300, "scrap": 2, "xp": 5, "r": 9.0, "tex": "en_mine_layer"},
	Type.SPACE_MINE: {"stage": 0, "hp": 1.0, "score": 25, "scrap": 0, "xp": 0, "r": 5.0, "tex": "en_space_mine_0"},
	Type.TURRET: {"stage": 1, "hp": 8.0, "score": 250, "scrap": 2, "xp": 5, "r": 8.0, "tex": "en_turret"},
	Type.SEC_DRONE: {"stage": 1, "hp": 5.0, "score": 180, "scrap": 1, "xp": 4, "r": 7.0, "tex": "en_sec_drone_0"},
	Type.BLIMP: {"stage": 2, "hp": 24.0, "score": 600, "scrap": 4, "xp": 12, "box": Vector2(42.0, 16.0), "tex": "en_blimp"},
	Type.JET: {"stage": 2, "hp": 3.2, "score": 160, "scrap": 1, "xp": 3, "r": 6.0, "tex": "en_jet"},
	Type.SPORE_POD: {"stage": 3, "hp": 7.0, "score": 280, "scrap": 2, "xp": 6, "r": 8.0, "tex": "en_spore_pod_0"},
	Type.BEETLE: {"stage": 3, "hp": 10.0, "score": 320, "scrap": 2, "xp": 7, "r": 8.5, "tex": "en_beetle_0"},
	Type.ICE_CRYSTAL: {"stage": 4, "hp": 8.0, "score": 300, "scrap": 2, "xp": 6, "r": 8.0, "tex": "en_ice_crystal_0"},
	Type.SNOW_DRONE: {"stage": 4, "hp": 6.0, "score": 240, "scrap": 2, "xp": 5, "r": 7.0, "tex": "en_snow_drone"},
	Type.LAVA_BLOB: {"stage": 5, "hp": 5.0, "score": 220, "scrap": 1, "xp": 5, "r": 6.5, "tex": "en_lava_blob_0"},
	Type.GOLEM: {"stage": 5, "hp": 28.0, "score": 700, "scrap": 5, "xp": 16, "r": 13.0, "tex": "en_golem_0"},
	Type.JELLYFISH: {"stage": 6, "hp": 9.0, "score": 320, "scrap": 2, "xp": 7, "r": 8.0, "tex": "en_jelly_0"},
	Type.EEL: {"stage": 6, "hp": 12.0, "score": 380, "scrap": 3, "xp": 8, "r": 6.0, "tex": "en_eel_head"},
	Type.ANGLER: {"stage": 6, "hp": 26.0, "score": 650, "scrap": 4, "xp": 14, "r": 12.0, "tex": "en_angler_0"},
	Type.VIRUS: {"stage": 7, "hp": 3.5, "score": 150, "scrap": 1, "xp": 3, "r": 6.0, "tex": "en_virus_0"},
	Type.GLITCH: {"stage": 7, "hp": 8.0, "score": 360, "scrap": 3, "xp": 7, "r": 7.5, "tex": "en_glitch_0"},
	Type.FIREWALL: {"stage": 7, "hp": 7.0, "score": 120, "scrap": 1, "xp": 2, "box": Vector2(14.0, 24.0), "tex": "en_firewall"},
}
const ROCK_CHUNKS: int = 3            # an asteroid breaks into this many chunks; chunks don't split
const MINES_PER_LAYER: int = 3        # mines one MINE_LAYER drops in its lifetime
const MINE_FUSE: float = 2.7          # seconds before an unshot mine bursts into a ring
const JELLY_PULSES: int = 4           # rings a jellyfish fires before it swims off
const ANGLER_BITES: int = 4           # bites an anglerfish takes before it sinks away
const VIRUS_REPLICATE_TIME: float = 3.4
const VIRUS_MAX_GEN: int = 2          # one virus becomes at most 4
const VIRUS_CAP: int = 12             # no copying while this many viruses are alive
const EEL_SEGMENTS: int = 6
const EEL_SPACING: float = 8.0
const TURRET_SCROLL: float = 40.0     # turrets and spore pods ride the floor/ceiling at this speed
const FLOOR_MOUNT_Y: float = 251.0
const CEILING_MOUNT_Y: float = 35.0

static var _replica_frame: int = -1
static var _replicas_this_frame: int = 0

var enemy_type: Type = Type.SCOUT_SINE
var stage_idx: int = 0
var max_hp: float = 2.0
var hp: float = 2.0
var score_value: int = 100
var scrap_drop: int = 1
var xp_drop: int = 2
var squad_id: int = -1

var player_ref: Node2D = null
var bullet_container: Node2D = null
var fx: FxLayer = null

var _sprite: Sprite2D
var _mat: ShaderMaterial
var _flash_timer: float = 0.0
var _age: float = 0.0
var _base_y: float = 135.0
var _target_x: float = 360.0
var _phase_offset: float = 0.0
var _fire_timer: float = 1.2

# 3-Phase Boss Resilience, Mega Man Intro & Live Animation System!
const BOSS_HP_PIPS: int = 28
var boss_phase: int = 1                 # 1 (100..66%), 2 (66..33%), 3 (33..0%)
var boss_shield_timer: float = 0.0      # Brief invulnerable phase-shift barrier on phase transition
var boss_intro_active: bool = false     # True while Mega Man teleport arrival -> pose -> HP bar fill runs
var boss_hp_bar_visible: bool = false   # Becomes true once boss strikes pose & begins filling HP gauge
var boss_hp_bar_fill: float = 1.0       # 0.0 -> 1.0 pip-by-pip during Mega Man boss intro!

var _boss_intro_stage: int = 0          # 0 = beam arrival, 1 = landing pose, 2 = HP bar fill, 3 = fight
var _boss_intro_timer: float = 0.0
var _boss_hp_pips_filled: int = 0
var _boss_tex_base: String = "boss_space"
var _boss_attack_anim_timer: float = 0.0
var _boss_recoil_x: float = 0.0
var _boss_spark_timer: float = 0.25
var _boss_dying: bool = false
# Stages 1-8: the boss is an animated rig of parts with a dino pilot (scripts/bosses/), drawn
# under _sprite (which then shows no texture) so the intro squash, recoil and hit flash apply.
const BossRigs = preload("res://scripts/bosses/boss_rigs.gd")
const BossRig = preload("res://scripts/bosses/boss_rig.gd")
var _rig: BossRig = null
# Stage-module bosses keep their painted frames, with a dino pilot in a canopy sitting on top of
# the silhouette (every boss is piloted by an angry space dinosaur).
const DinoPilotScript = preload("res://scripts/bosses/dino_pilot.gd")
var _pilot: DinoPilotScript = null
var _boss_death_timer: float = 0.0
var _boss_death_boom_timer: float = 0.0

var _dps_accumulator: float = 0.0       # Tracks burst damage per second to prevent 2-second instant melts
var _boss_pattern: int = 0
var _boss_substep: int = 0
var _boss_spin: float = 0.0
var _bullet_a: String = "bullet_enemy_pink"
var _bullet_b: String = "bullet_enemy_orange"
var _dead: bool = false

# Stage difficulty (StageData.get_difficulty) and themed-enemy state
var variant: int = 0                    # per-type layout: floor/ceiling mount, from-behind jet, wall links
var gen: int = 0                        # 0 = spawned by the wave director, 1+ = spawned by another enemy
var _raw_stage: int = 0                 # stage index including loops (children inherit it)
var _hp_scale: float = 1.0
var _shot_mult: float = 1.0
var _fire_mult: float = 1.0
var _vel: Vector2 = Vector2.ZERO
var _state: int = 0
var _state_t: float = 0.0
var _aux_timer: float = 0.0
var _burst_left: int = 0
var _burst_t: float = 0.0
var _children_left: int = 0
var _warn_timer: float = 0.0            # > 0: telegraphing its entrance, not yet hittable
var _shot_done: bool = false
var _lock_y: float = 135.0
var _aim_angle: float = PI
var _spin_t: float = 0.0
var _dest: Vector2 = Vector2.ZERO
var _jumps_left: int = 0
var _block_fx_t: float = 0.0
var _trail_pts: Array[Vector2] = []
var _seg_sprites: Array[Sprite2D] = []
var _seg_shapes: Array[CollisionShape2D] = []
var _barrel: Sprite2D = null
var _shield: Sprite2D = null

# Stage modules (stages 9+): set module_kind before setup() for Type.MODULE.
var module_kind: String = ""
var _behaviour: RefCounted = null       # Type.MODULE: scripts/stages/stage_enemy.gd subclass
var _boss_ai: RefCounted = null         # a module stage's boss: scripts/stages/stage_boss.gd subclass
var _module_big: bool = false
var _exit_left: float = -40.0

# Status effects from the player's Cryo Rounds / Napalm Rounds draft perks
var _chill_timer: float = 0.0
var _chill_factor: float = 1.0          # Time scale while chilled (slows movement and firing)
var _burn_timer: float = 0.0
var _burn_dps: float = 0.0
var _burn_tick: float = 0.0
var _status_fx_timer: float = 0.0

# Stage-by-stage exponential Boss HP curve (accounts for Option orbs, Spread, Laser & Rapid upgrades!)
# Built-in stages only: stage modules (9+) give theirs in get_boss_hp().
const STAGE_BOSS_HP: Array[float] = [
	360.0,   # Stage 1: Outer Orbit
	820.0,   # Stage 2: Starcruiser
	1650.0,  # Stage 3: Cloud Base
	3100.0,  # Stage 4: Xeno Forest
	5200.0,  # Stage 5: Cryo Glacier
	8200.0,  # Stage 6: Magma Core
	12200.0, # Stage 7: Abyssal Trench
	17500.0, # Stage 8: Cyber Nexus
]


func setup(
	t: Type,
	spawn_pos: Vector2,
	hp_scale: float,
	p_ref: Node2D,
	b_container: Node2D,
	fx_ref: FxLayer,
	p_offset: float = 0.0,
	formation_squad: int = -1,
	st_idx: int = 0,
	p_variant: int = 0,
	p_gen: int = 0
) -> void:
	add_to_group("enemies")
	enemy_type = t
	stage_idx = StageData.wrap_stage(st_idx)
	var loop_count: int = StageData.loop_of(st_idx)
	var loop_mult: float = pow(2.2, float(loop_count))
	# A module stage's sprites are normally prefetched; this builds them now if not.
	StageData.prepare_stage(stage_idx)
	_raw_stage = st_idx
	_hp_scale = hp_scale
	variant = p_variant
	gen = p_gen
	var diff: Dictionary = StageData.get_difficulty(st_idx)
	_shot_mult = float(diff["shot_speed"])
	_fire_mult = float(diff["fire_rate"])

	global_position = spawn_pos
	_base_y = spawn_pos.y
	_phase_offset = p_offset
	squad_id = formation_squad
	player_ref = p_ref
	bullet_container = b_container
	fx = fx_ref

	var st: Dictionary = StageData.get_stage(stage_idx)
	_bullet_a = String(st["bullet_a"])
	_bullet_b = String(st["bullet_b"])

	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true

	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = "shader_type canvas_item;\nuniform float flash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 tex = texture(TEXTURE, UV);\n\tCOLOR = vec4(mix(tex.rgb, vec3(1.0), flash), tex.a);\n}\n"

	_mat = ShaderMaterial.new()
	_mat.shader = _flash_shader

	_sprite = Sprite2D.new()
	_sprite.material = _mat
	add_child(_sprite)

	var col: CollisionShape2D = CollisionShape2D.new()

	match enemy_type:
		Type.SCOUT_SINE:
			_sprite.texture = PixelArt.tex(String(st["scout_tex"]))
			max_hp = 2.2 * hp_scale * loop_mult
			score_value = 100
			scrap_drop = 1
			xp_drop = 2
			_fire_timer = randf_range(1.4, 2.4)
			var s1: CircleShape2D = CircleShape2D.new()
			s1.radius = 6.5
			col.shape = s1
		Type.SWOOPER:
			_sprite.texture = PixelArt.tex(String(st["swooper_tex"]))
			max_hp = 3.0 * hp_scale * loop_mult
			score_value = 150
			scrap_drop = 1
			xp_drop = 3
			_fire_timer = randf_range(0.8, 1.5)
			var s2: CircleShape2D = CircleShape2D.new()
			s2.radius = 7.0
			col.shape = s2
		Type.SNIPER:
			_sprite.texture = PixelArt.tex(String(st["sniper_tex"]))
			max_hp = 6.5 * hp_scale * loop_mult
			score_value = 250
			scrap_drop = 2
			xp_drop = 5
			_target_x = randf_range(325.0, 430.0)
			_fire_timer = 0.90
			var s3: CircleShape2D = CircleShape2D.new()
			s3.radius = 7.5
			col.shape = s3
		Type.CRUISER:
			_sprite.texture = PixelArt.tex(String(st["cruiser_tex"]))
			max_hp = 22.0 * hp_scale * loop_mult
			score_value = 600
			scrap_drop = 5
			xp_drop = 14
			_target_x = randf_range(340.0, 425.0)
			_fire_timer = 1.15
			var s4: CircleShape2D = CircleShape2D.new()
			s4.radius = 11.0
			col.shape = s4
		Type.BOSS:
			_boss_tex_base = String(st["boss_tex"])
			_sprite.texture = PixelArt.tex(_boss_tex_base + "_0")
			# Stages 9+ are modules: their boss HP and attack patterns come from the module.
			var boss_module: RefCounted = StageData.get_module(stage_idx)
			var base_hp: float = STAGE_BOSS_HP[stage_idx] if boss_module == null else float(boss_module.call("get_boss_hp"))
			max_hp = base_hp * loop_mult
			score_value = 5000 + stage_idx * 1500
			scrap_drop = 28 + stage_idx * 4
			xp_drop = 48 + stage_idx * 12
			_target_x = 424.0 if stage_idx == 0 else float(st.get("boss_x", 414.0))
			_fire_timer = 1.20
			if boss_module != null:
				_boss_ai = boss_module.call("create_boss")
				_boss_ai.set("boss", self)
				_boss_ai.call("setup")
			elif BossRigs.has_rig(stage_idx):
				_rig = BossRigs.create(stage_idx) as BossRig
				_sprite.add_child(_rig)
				_rig.setup(self)
				_sprite.texture = null
			if _rig == null:
				_add_frame_pilot()

			# Launch Mega Man-style Boss Teleport Arrival -> Signature Pose -> 28-Pip HP Bar Fill!
			boss_intro_active = true
			boss_hp_bar_visible = false
			boss_hp_bar_fill = 0.0
			_boss_intro_stage = 0
			_boss_intro_timer = 0.0
			_boss_hp_pips_filled = 0
			global_position = Vector2(_target_x, -110.0)
			_sprite.scale = Vector2(0.18, 1.95)
			_mat.set_shader_parameter("flash", 1.0)
			RetroSfx.play("boss_beam", -5.0, 0.02)

			var box: RectangleShape2D = RectangleShape2D.new()
			box.size = Vector2(88.0, 176.0) if stage_idx == 0 else Vector2(st.get("boss_box", Vector2(82.0, 146.0)))
			col.shape = box

		_:
			_setup_themed(hp_scale, loop_mult, col)

	hp = max_hp
	add_child(col)
	if enemy_type == Type.EEL:
		_build_eel_body()
	if _warn_timer > 0.0:
		_go_dormant()


func _process(delta: float) -> void:
	if _dead:
		return

	if _burn_timer > 0.0 and not _boss_dying:
		_burn_timer -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.25
			take_damage(_burn_dps * 0.25, true)
			if _dead:
				return
		if _burn_timer <= 0.0:
			_burn_dps = 0.0
	if _chill_timer > 0.0:
		_chill_timer -= delta
		delta *= _chill_factor
		if _chill_timer <= 0.0:
			_chill_factor = 1.0
	if (_burn_timer > 0.0 or _chill_timer > 0.0) and fx != null:
		_status_fx_timer -= delta
		if _status_fx_timer <= 0.0:
			_status_fx_timer = 0.14
			var jitter: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
			fx.spawn_hit_sparks(global_position + jitter, Color("#ff6820") if _burn_timer > 0.0 else Color("#8cf4ff"), 1)

	_age += delta

	if _flash_timer > 0.0 and not boss_intro_active and not _boss_dying:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		_mat.set_shader_parameter("flash", 1.0 if _flash_timer > 0.0 else 0.0)

	if enemy_type == Type.BOSS:
		_process_boss(delta)
		return

	if is_themed():
		_process_themed(delta)
		return

	# Bullet speeds below are the stage-1 values; _shoot_from scales them by the stage's
	# shot_speed and _fire_cd divides cooldowns by its fire_rate (StageData.DIFFICULTY).
	match enemy_type:
		Type.SCOUT_SINE:
			var freq: float = 4.6 if stage_idx == 3 else 3.6
			var spd: float = 96.0 if stage_idx == 7 else 84.0
			global_position.x -= spd * delta
			global_position.y = clampf(_base_y + sin(_age * freq + _phase_offset) * 26.0, 32.0, 232.0)
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x > 90.0 and global_position.x < 455.0:
				_fire_timer = _fire_cd(2.3)
				if randf() < 0.52:
					_shoot_aimed(125.0, _bullet_b)

		Type.SWOOPER:
			var vx: float = -132.0 if (stage_idx == 2 or stage_idx == 4) else -122.0
			var vy: float = sin(_age * 5.0 + _phase_offset) * 75.0
			if _age > 0.55 and _age < 1.85 and player_ref != null and is_instance_valid(player_ref):
				vy = clampf((player_ref.global_position.y - global_position.y) * 2.5, -115.0, 115.0)
			global_position += Vector2(vx, vy) * delta
			global_position.y = clampf(global_position.y, 32.0, 232.0)
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x > 120.0:
				_fire_timer = _fire_cd(1.6)
				_shoot_aimed(144.0, _bullet_a)

		Type.SNIPER:
			if _age < 6.0:
				global_position.x = lerpf(global_position.x, _target_x, 3.2 * delta)
				global_position.y = clampf(_base_y + sin(_age * 2.0 + _phase_offset) * 14.0, 34.0, 230.0)
			else:
				global_position.x -= 95.0 * delta
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x < 465.0 and global_position.x > 80.0:
				_fire_timer = _fire_cd(1.4)
				if stage_idx >= 3:
					_shoot_spread(2, 0.20, 148.0, _bullet_a)
				else:
					_shoot_aimed(155.0, _bullet_a)

		Type.CRUISER:
			if _age < 10.0:
				global_position.x = lerpf(global_position.x, _target_x, 2.2 * delta)
				global_position.y = clampf(_base_y + sin(_age * 1.3 + _phase_offset) * 28.0, 42.0, 224.0)
			else:
				global_position.x -= 55.0 * delta
			_fire_timer -= delta
			if _fire_timer <= 0.0 and global_position.x < 460.0:
				_fire_timer = _fire_cd(1.55)
				_shoot_spread(4 if stage_idx >= 4 else 3, 0.22, 138.0, _bullet_b)
			queue_redraw()

		_:
			pass

	if global_position.x < -36.0:
		_dead = true
		destroyed.emit(self, false)
		queue_free()


# ---------------------------------------------------------------------------------------------
# Stage-signature enemies. Each type has a _tick_* function; telegraphs are drawn in
# _draw_themed. Bullet speeds and cooldowns are stage-1 values scaled like the generic types.
# ---------------------------------------------------------------------------------------------

func is_themed() -> bool:
	return int(enemy_type) >= int(Type.ASTEROID)


# Children get their launch velocity from the parent (rock chunks fly apart, mines drop).
func set_launch_velocity(v: Vector2) -> void:
	_vel = v


func _setup_themed(hp_scale: float, loop_mult: float, col: CollisionShape2D) -> void:
	var d: Dictionary = {}
	if enemy_type == Type.MODULE:
		d = StageData.get_enemy_def(stage_idx, module_kind)
		if d.is_empty():
			push_error("GameEnemy: stage %d has no enemy kind '%s'" % [stage_idx + 1, module_kind])
			d = {"hp": 1.0, "score": 0, "scrap": 0, "xp": 0, "r": 6.0, "tex": "scout_space", "behaviour": load("res://scripts/stages/stage_enemy.gd")}
	else:
		d = THEMED[enemy_type]
	_sprite.texture = PixelArt.tex(String(d["tex"]))
	# Telegraphs and HP bars from _draw_themed go on top of the sprite.
	_sprite.show_behind_parent = true
	max_hp = float(d["hp"]) * hp_scale * loop_mult
	score_value = int(d["score"])
	scrap_drop = int(d["scrap"])
	xp_drop = int(d["xp"])
	if d.has("box"):
		var box: RectangleShape2D = RectangleShape2D.new()
		box.size = Vector2(d["box"])
		col.shape = box
	else:
		var circ: CircleShape2D = CircleShape2D.new()
		circ.radius = float(d["r"])
		col.shape = circ
	# Spore pods and jellyfish carry their hittable bulb/bell above (or below) the sprite centre.
	if enemy_type == Type.SPORE_POD:
		col.position = Vector2(0.0, 3.0 if variant == 1 else -3.0)
	elif enemy_type == Type.JELLYFISH:
		col.position = Vector2(0.0, -3.0)
	elif enemy_type == Type.MODULE:
		col.position = Vector2(d.get("col_offset", Vector2.ZERO))
	if gen > 0:
		_apply_child_rewards()
	_fire_timer = randf_range(1.0, 1.6) / _fire_mult

	match enemy_type:
		Type.ASTEROID:
			_vel = Vector2(randf_range(-56.0, -42.0), randf_range(-14.0, 14.0))
			_sprite.texture = PixelArt.tex("en_asteroid_1" if variant == 1 else "en_asteroid_0")
			_spin_t = randf() * 4.0
		Type.ROCK_CHUNK:
			_vel = Vector2(-60.0, 0.0)
			_spin_t = randf() * 4.0
		Type.MINE_LAYER:
			_children_left = MINES_PER_LAYER
			_fire_timer = 0.9
		Type.SPACE_MINE:
			_vel = Vector2(-26.0, 0.0)
		Type.TURRET:
			global_position.y = CEILING_MOUNT_Y if variant == 1 else FLOOR_MOUNT_Y
			_base_y = global_position.y
			_sprite.flip_v = variant == 1
			_aim_angle = PI
			_fire_timer = 1.2
			_barrel = Sprite2D.new()
			_barrel.texture = PixelArt.tex("en_turret_barrel")
			_barrel.material = _mat
			_barrel.show_behind_parent = true
			_barrel.offset = Vector2(6.0, 0.0)  # pivot at the breech
			_barrel.position = Vector2(0.0, 3.0 if variant == 1 else -3.0)
			_barrel.rotation = _aim_angle
			add_child(_barrel)
			move_child(_barrel, 0)  # behind the dome
		Type.SEC_DRONE:
			_target_x = randf_range(330.0, 420.0)
			_spin_t = randf() * 3.0
			_fire_timer = 1.2
		Type.BLIMP:
			_fire_timer = 1.0
			_aux_timer = 2.0
		Type.JET:
			_sprite.flip_h = variant == 1
			_target_x = randf_range(298.0, 318.0)
			if variant == 1:
				_warn_timer = 0.9
				global_position.x = -26.0
				_lock_y = clampf(global_position.y, 40.0, 238.0)
		Type.SPORE_POD:
			global_position.y = CEILING_MOUNT_Y + 2.0 if variant == 1 else FLOOR_MOUNT_Y - 6.0
			_base_y = global_position.y
			_sprite.flip_v = variant == 1
			_state_t = randf_range(0.4, 0.8)
		Type.BEETLE:
			_target_x = randf_range(408.0, 440.0)
		Type.ICE_CRYSTAL:
			_target_x = randf_range(340.0, 430.0)
			_fire_timer = 1.4
		Type.SNOW_DRONE:
			_aux_timer = 0.2
			_fire_timer = 1.5
		Type.LAVA_BLOB:
			_warn_timer = 0.85
			global_position.y = 266.0
		Type.GOLEM:
			_target_x = randf_range(370.0, 420.0)
			_state_t = 2.0
			_shield = Sprite2D.new()
			_shield.texture = PixelArt.tex("en_golem_shield_0")
			_shield.material = _mat
			_shield.show_behind_parent = true
			_shield.position = Vector2(-14.0, 1.0)
			add_child(_shield)
		Type.JELLYFISH:
			_fire_timer = 1.3
			_boss_spin = randf() * TAU
			_children_left = JELLY_PULSES
		Type.ANGLER:
			_target_x = randf_range(385.0, 420.0)
			_fire_timer = 1.8
			_children_left = ANGLER_BITES
		Type.VIRUS:
			_aux_timer = VIRUS_REPLICATE_TIME
			_fire_timer = 1.6
		Type.GLITCH:
			_target_x = randf_range(395.0, 430.0)
			_state_t = 1.0
			_jumps_left = 5
		Type.FIREWALL:
			# The wall fires as a rolling cascade: each slot is a little later than the one above.
			_fire_timer = 1.4 + _phase_offset * 0.2
		Type.MODULE:
			_module_big = bool(d.get("big", false))
			_exit_left = float(d.get("exit_left", -40.0))
			var behaviour_script: Script = d["behaviour"]
			_behaviour = behaviour_script.new() as RefCounted
			_behaviour.set("enemy", self)
			_behaviour.set("def", d)
			_behaviour.call("setup")


# Children (gen > 0) give no Scrap and at most 1 XP.
func _apply_child_rewards() -> void:
	scrap_drop = 0
	xp_drop = mini(xp_drop, 1)
	score_value = mini(score_value, 60)


# Entrance telegraph (lava bubbling on the floor, a jet's warning arrow): hidden and unhittable.
func _go_dormant() -> void:
	collision_layer = 0
	_sprite.visible = false
	remove_from_group("enemies")


func _wake() -> void:
	_warn_timer = 0.0
	collision_layer = 4
	_sprite.visible = true
	add_to_group("enemies")
	match enemy_type:
		Type.LAVA_BLOB:
			_vel = Vector2(randf_range(-75.0, -40.0), -randf_range(270.0, 300.0))
			RetroSfx.play("explode", -14.0, 0.1)
			if fx != null:
				fx.spawn_hit_sparks(Vector2(global_position.x, 256.0), Color("#ffe854"), 8)
		Type.JET:
			_lock_y = clampf(_player_pos().y + _phase_offset * 16.0, 40.0, 238.0)
			RetroSfx.play("laser", -14.0, 0.05)
		Type.MODULE:
			_behaviour.call("on_wake")


func _process_themed(delta: float) -> void:
	if _warn_timer > 0.0:
		_warn_timer -= delta
		if _warn_timer <= 0.0:
			_wake()
		queue_redraw()
		return
	_block_fx_t -= delta
	# Hold fire until on screen, so every first shot still gets its telegraph.
	if global_position.x > 466.0 and enemy_type != Type.FIREWALL:
		_fire_timer = maxf(_fire_timer, 0.5)

	match enemy_type:
		Type.ASTEROID, Type.ROCK_CHUNK:
			_tick_rock(delta)
		Type.MINE_LAYER:
			_tick_mine_layer(delta)
		Type.SPACE_MINE:
			_tick_space_mine(delta)
		Type.TURRET:
			_tick_turret(delta)
		Type.SEC_DRONE:
			_tick_sec_drone(delta)
		Type.BLIMP:
			_tick_blimp(delta)
		Type.JET:
			_tick_jet(delta)
		Type.SPORE_POD:
			_tick_spore_pod(delta)
		Type.BEETLE:
			_tick_beetle(delta)
		Type.ICE_CRYSTAL:
			_tick_ice_crystal(delta)
		Type.SNOW_DRONE:
			_tick_snow_drone(delta)
		Type.LAVA_BLOB:
			_tick_lava_blob(delta)
		Type.GOLEM:
			_tick_golem(delta)
		Type.JELLYFISH:
			_tick_jellyfish(delta)
		Type.EEL:
			_tick_eel(delta)
		Type.ANGLER:
			_tick_angler(delta)
		Type.VIRUS:
			_tick_virus(delta)
		Type.GLITCH:
			_tick_glitch(delta)
		Type.FIREWALL:
			_tick_firewall(delta)
		Type.MODULE:
			_behaviour.call("tick", delta)
	if _dead:
		return
	queue_redraw()
	_check_exit()


func _check_exit() -> void:
	var p: Vector2 = global_position
	var left_edge: float = _exit_left
	if enemy_type == Type.EEL:
		left_edge = -40.0 - float(EEL_SEGMENTS) * EEL_SPACING
	elif enemy_type == Type.BLIMP:
		left_edge = -56.0
	if p.x < left_edge or p.x > 548.0 or p.y > 300.0 or p.y < -60.0:
		_leave()


func _player_pos() -> Vector2:
	if player_ref != null and is_instance_valid(player_ref) and player_ref.visible:
		return player_ref.global_position
	return Vector2(60.0, 135.0)


func _on_screen(margin_left: float = 70.0, margin_right: float = 462.0) -> bool:
	return global_position.x > margin_left and global_position.x < margin_right


func _request_child(t: Type, pos: Vector2, vel: Vector2, child_gen: int, kind: String = "") -> void:
	var item: Dictionary = {
		"type": t,
		"pos": pos,
		"hp_mult": _hp_scale,
		"phase": randf() * TAU,
		"squad": -1,
		"stage": _raw_stage,
		"variant": 0,
		"gen": child_gen,
		"vel": vel,
	}
	if kind != "":
		item["kind"] = kind
	spawn_requested.emit(item)


# --- 1 OUTER ORBIT ---------------------------------------------------------------------------

# Asteroids drift and tumble; shot down they break into ROCK_CHUNKS chunks (see _on_themed_death).
func _tick_rock(delta: float) -> void:
	global_position += _vel * delta
	if global_position.y < 40.0 and _vel.y < 0.0:
		_vel.y = absf(_vel.y)
	elif global_position.y > 240.0 and _vel.y > 0.0:
		_vel.y = -absf(_vel.y)
	if enemy_type == Type.ROCK_CHUNK:
		# The split kick fades and the chunks settle into the leftward drift.
		_vel = _vel.lerp(Vector2(-54.0, _vel.y * 0.5), clampf(delta * 0.7, 0.0, 1.0))
	# Tumble in quarter turns, which keeps the pixel art crisp.
	_spin_t += delta * (5.0 if enemy_type == Type.ROCK_CHUNK else 2.6)
	_sprite.rotation = floorf(_spin_t) * PI * 0.5


# Crosses the screen slowly, dropping a mine every 1.7 s (MINES_PER_LAYER in all).
func _tick_mine_layer(delta: float) -> void:
	global_position.x -= 36.0 * delta
	global_position.y = clampf(_base_y + sin(_age * 1.7 + _phase_offset) * 10.0, 40.0, 238.0)
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _children_left > 0 and _on_screen(70.0, 455.0):
		_fire_timer = _fire_cd(1.7)
		_children_left -= 1
		_request_child(Type.SPACE_MINE, global_position + Vector2(4.0, 7.0), Vector2(-22.0, 18.0), gen + 1)
		RetroSfx.play("bounce", -15.0, 0.05)


# Blinks faster and faster, then bursts into a slow 6-bullet ring unless shot first.
func _tick_space_mine(delta: float) -> void:
	global_position += _vel * delta
	_vel.y = lerpf(_vel.y, 0.0, clampf(delta * 2.2, 0.0, 1.0))
	global_position.y = clampf(global_position.y, 36.0, 244.0)
	var left: float = MINE_FUSE - _age
	var blink_hz: float = 3.0 if left > 1.2 else 9.0
	var lit: bool = int(_age * blink_hz * 2.0) % 2 == 0
	_sprite.texture = PixelArt.tex("en_space_mine_1" if lit else "en_space_mine_0")
	if left <= 0.0:
		var rot: float = randf() * TAU
		for i: int in range(6):
			_emit_bullet(global_position, Vector2.from_angle(rot + TAU * float(i) / 6.0) * 74.0, _bullet_a)
		if fx != null:
			fx.spawn_ring_blast(global_position, 18.0, Color("#ff4c68"))
		RetroSfx.play("explode", -12.0, 0.06)
		_leave()


# --- 2 STARCRUISER ---------------------------------------------------------------------------

# Rides the floor or ceiling; the barrel tracks the player, glints, then fires a 3-round burst.
func _tick_turret(delta: float) -> void:
	global_position.x -= TURRET_SCROLL * delta
	var pivot: Vector2 = global_position + _barrel.position
	var want: float = _mount_aim((_player_pos() - pivot).angle())
	_aim_angle = lerp_angle(_aim_angle, want, clampf(delta * 4.5, 0.0, 1.0))
	_barrel.rotation = _aim_angle
	_fire_timer -= delta
	if _burst_left > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst_t = 0.13
			_burst_left -= 1
			var dir: Vector2 = Vector2.from_angle(_aim_angle)
			_emit_bullet(pivot + dir * 11.0, dir * 150.0, _bullet_a)
	elif _fire_timer <= 0.0 and _on_screen(50.0, 460.0):
		_fire_timer = _fire_cd(2.5)
		_burst_left = 3
		_burst_t = 0.0


# Floor mounts can only aim upward, ceiling mounts only downward.
func _mount_aim(ang: float) -> float:
	if variant == 1:
		if ang < 0.0:
			return 0.15 if ang > -PI * 0.5 else PI - 0.15
		return clampf(ang, 0.15, PI - 0.15)
	if ang > 0.0:
		return -0.15 if ang < PI * 0.5 else -PI + 0.15
	return clampf(ang, -PI + 0.15, -0.15)


# Patrols up and down. When the player crosses its line it locks on (red eye, laser sight)
# and fires a fast 3-shot line straight ahead; out of sight for a while, it takes an aimed shot.
func _tick_sec_drone(delta: float) -> void:
	if _age < 11.0:
		global_position.x = lerpf(global_position.x, _target_x, 2.4 * delta)
	else:
		global_position.x -= 95.0 * delta
	if _state == 0:
		_spin_t += delta
	var tri: float = absf(fposmod(_spin_t * 0.36 + _phase_offset, 2.0) - 1.0) * 2.0 - 1.0
	global_position.y = clampf(_base_y + tri * 56.0, 40.0, 238.0)
	_fire_timer -= delta
	match _state:
		1:
			_state_t -= delta
			if _state_t <= 0.0:
				_state = 2
				_burst_left = 3
				_burst_t = 0.0
		2:
			_burst_t -= delta
			if _burst_t <= 0.0:
				_burst_t = 0.085
				_burst_left -= 1
				_emit_bullet(global_position + Vector2(-9.0, 0.0), Vector2(-185.0, 0.0), _bullet_a)
				if _burst_left <= 0:
					_state = 0
					_fire_timer = _fire_cd(1.6)
		_:
			var pp: Vector2 = _player_pos()
			var in_range: bool = _on_screen(80.0, 462.0)
			if _fire_timer <= 0.0 and in_range and absf(pp.y - global_position.y) < 11.0 and pp.x < global_position.x:
				_state = 1
				_state_t = 0.32
				RetroSfx.play("boss_hp_tick", -12.0, 0.0)
			elif _fire_timer <= -2.6 and in_range:
				_fire_timer = _fire_cd(0.6)
				_shoot_aimed(140.0, _bullet_b)
	_sprite.texture = PixelArt.tex("en_sec_drone_1" if _state != 0 else "en_sec_drone_0")


# --- 3 CLOUD BASE ----------------------------------------------------------------------------

# Slow armoured blimp: drops gravity bombs that burst into a 3-way spray on the ground, plus an
# occasional aimed shot from the gondola.
func _tick_blimp(delta: float) -> void:
	global_position.x -= 24.0 * delta
	global_position.y = _base_y + sin(_age * 0.9 + _phase_offset) * 5.0
	var on_screen: bool = _on_screen(30.0, 468.0)
	_fire_timer -= delta
	if _fire_timer <= 0.0 and on_screen:
		_fire_timer = _fire_cd(1.75)
		var bomb: GameBullet = _emit_bullet(global_position + Vector2(-2.0, 10.0), Vector2(-18.0, 26.0), "bullet_enemy_bomb", false, 3.5)
		if bomb != null:
			bomb.gravity_pull = 120.0
			bomb.floor_burst = 3
			bomb.burst_tex = _bullet_b
			bomb.burst_speed = 88.0 * _shot_mult
		RetroSfx.play("missile", -14.0, 0.05)
	_aux_timer -= delta
	if _aux_timer <= 0.0 and on_screen:
		_aux_timer = _fire_cd(3.1)
		_shoot_aimed_from(global_position + Vector2(-10.0, 5.0), 135.0, _bullet_b)


# Formation fighters: cruise in, then each one breaks toward where the player is with one
# aimed shot. variant 1 comes in from behind after a warning arrow on the left edge.
func _tick_jet(delta: float) -> void:
	if variant == 1:
		global_position.x += 190.0 * delta
		global_position.y = lerpf(global_position.y, _lock_y, clampf(delta * 1.1, 0.0, 1.0))
		if not _shot_done and global_position.x > _player_pos().x + 60.0:
			_shot_done = true
			_shoot_aimed(140.0, _bullet_a)
		return
	if _state == 0:
		var spd: float = lerpf(215.0, 125.0, clampf(_age / 0.9, 0.0, 1.0))
		global_position.x -= spd * delta
		global_position.y = lerpf(global_position.y, _base_y, clampf(delta * 3.0, 0.0, 1.0))
		if global_position.x < _target_x:
			_state = 1
			_vel = Vector2(-125.0, 0.0)
			_lock_y = clampf(_player_pos().y + _phase_offset * 12.0, 40.0, 238.0)
			_shoot_aimed(150.0, _bullet_a, -0.06)
			_shoot_aimed(150.0, _bullet_a, 0.06)
	else:
		_vel.x = move_toward(_vel.x, -255.0, 260.0 * delta)
		_vel.y = clampf((_lock_y - global_position.y) * 2.6, -150.0, 150.0)
		global_position += _vel * delta


# --- 4 XENO FOREST ---------------------------------------------------------------------------

# Grows on the floor or ceiling. Swells for 1.8 s (the telegraph), then bursts into 7 slow
# homing spores (they wither after 5 s), and regrows. Killed before it bursts, it pops harmlessly.
func _tick_spore_pod(delta: float) -> void:
	global_position.x -= TURRET_SCROLL * delta
	var swell_time: float = 1.8
	match _state:
		0:
			if global_position.x < 440.0:
				_state_t -= delta
				if _state_t <= 0.0:
					_state = 1
					_state_t = swell_time
		1:
			_state_t -= delta
			var k: float = clampf(1.0 - _state_t / swell_time, 0.0, 1.0)
			var wobble: float = sin(_age * 26.0) * 0.07 * k
			_sprite.scale = Vector2(1.0 + 0.2 * k + wobble, 1.0 + 0.2 * k - wobble)
			_sprite.texture = PixelArt.tex("en_spore_pod_1" if k > 0.45 else "en_spore_pod_0")
			if _state_t <= 0.0:
				_burst_spores()
				_state = 2
				_state_t = _fire_cd(2.8)
		_:
			_sprite.scale = Vector2.ONE
			_sprite.texture = PixelArt.tex("en_spore_pod_2")
			_state_t -= delta
			if _state_t <= 0.0 and global_position.x > 60.0:
				_state = 1
				_state_t = swell_time


func _burst_spores() -> void:
	var base_ang: float = PI * 0.5 if variant == 1 else -PI * 0.5
	var origin: Vector2 = global_position + Vector2(0.0, 5.0 if variant == 1 else -5.0)
	for i: int in range(7):
		var a: float = base_ang + (float(i) - 3.0) * 0.36
		var b: GameBullet = _emit_bullet(origin, Vector2.from_angle(a) * 66.0, "bullet_enemy_spore", false, 3.0)
		if b != null:
			b.home_target = player_ref
			b.home_time = 2.4
			b.home_rate = 1.6
			b.life_left = 5.0
	if fx != null:
		fx.spawn_hit_sparks(origin, Color("#5eff6e"), 10)
	RetroSfx.play("explode", -15.0, 0.12)


# Settles at the right edge tracking the player's height, rears up (shake, red lane line)
# for 0.6 s, then spits a 3-way spread from its horn and charges straight across the screen.
func _tick_beetle(delta: float) -> void:
	match _state:
		0:
			global_position.x = lerpf(global_position.x, _target_x, 2.6 * delta)
			var want_y: float = _player_pos().y
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				if node != self and node is GameEnemy and (node as GameEnemy).enemy_type == Type.BEETLE:
					var dy: float = global_position.y - (node as Node2D).global_position.y
					if absf(dy) < 22.0:
						want_y += 40.0 if dy >= 0.0 else -40.0
			global_position.y = lerpf(global_position.y, clampf(want_y, 40.0, 238.0), clampf(1.8 * delta, 0.0, 1.0))
			if _age > 1.3 and absf(global_position.x - _target_x) < 14.0:
				_state = 1
				_state_t = 0.62
				RetroSfx.play("boss_siren", -22.0, 0.04)
		1:
			_state_t -= delta
			_sprite.position = Vector2(float(randi_range(-1, 1)), float(randi_range(-1, 1)))
			if _state_t <= 0.0:
				_state = 2
				_sprite.position = Vector2.ZERO
				for k: int in [-1, 0, 1]:
					_shoot_aimed_from(global_position + Vector2(-10.0, -5.0), 150.0, _bullet_a, float(k) * 0.2)
				RetroSfx.play("missile", -10.0, 0.05)
		_:
			global_position.x -= 300.0 * _shot_mult * delta
			_aux_timer -= delta
			if _aux_timer <= 0.0 and fx != null:
				_aux_timer = 0.05
				fx.spawn_hit_sparks(global_position + Vector2(10.0, randf_range(-4.0, 4.0)), Color("#5eff94"), 1)
	var legs: bool = int(_age * (14.0 if _state == 2 else 6.0)) % 2 == 0
	_sprite.texture = PixelArt.tex("en_beetle_1" if legs else "en_beetle_0")


# --- 5 CRYO GLACIER --------------------------------------------------------------------------

# Hovers and fires paired ice shards; cracks below half HP and shatters into 8 shards when
# destroyed, so it's safest to kill from a distance.
func _tick_ice_crystal(delta: float) -> void:
	if _age < 8.0:
		global_position.x = lerpf(global_position.x, _target_x, 1.6 * delta)
	else:
		global_position.x -= 42.0 * delta
	global_position.y = clampf(_base_y + sin(_age * 1.3 + _phase_offset) * 12.0, 40.0, 238.0)
	_sprite.texture = PixelArt.tex("en_ice_crystal_1" if hp < max_hp * 0.5 else "en_ice_crystal_0")
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _on_screen(80.0, 462.0):
		_fire_timer = _fire_cd(2.6)
		_shoot_aimed(140.0, "bullet_enemy_shard", -0.12)
		_shoot_aimed(140.0, "bullet_enemy_shard", 0.12)


# Weaves across leaving a trail of frost puffs (they slow the ship instead of hurting it)
# and fires an aimed pair now and then.
func _tick_snow_drone(delta: float) -> void:
	global_position.x -= 62.0 * delta
	global_position.y = clampf(_base_y + sin(_age * 1.7 + _phase_offset) * 48.0, 40.0, 238.0)
	_aux_timer -= delta
	if _aux_timer <= 0.0 and _on_screen(20.0, 470.0):
		_aux_timer = 0.34
		var puff: GameBullet = _emit_bullet(global_position + Vector2(9.0, 1.0 + randf_range(-2.0, 2.0)), Vector2(-14.0, randf_range(-7.0, 7.0)), "bullet_frost_0", false, 5.0)
		if puff != null:
			puff.make_frost(1.5, 2.6, "bullet_frost_1")
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _on_screen(90.0, 460.0):
		_fire_timer = _fire_cd(2.5)
		_shoot_aimed(150.0, _bullet_a, -0.07)
		_shoot_aimed(150.0, _bullet_a, 0.07)


# --- 6 MAGMA CORE ----------------------------------------------------------------------------

# Bubbles on the floor for 0.85 s (dormant), then leaps up in an arc and sprays 4 falling
# droplets at the top of its jump. Falls back into the lava if not shot.
func _tick_lava_blob(delta: float) -> void:
	_vel.y += 230.0 * delta
	global_position += _vel * delta
	_sprite.texture = PixelArt.tex("en_lava_blob_0" if _vel.y < 0.0 else "en_lava_blob_1")
	if not _shot_done and _vel.y >= 0.0:
		_shot_done = true
		for i: int in range(4):
			var a: float = PI * 0.5 + (float(i) - 1.5) * 0.55
			var drop: GameBullet = _emit_bullet(global_position, Vector2.from_angle(a) * 62.0 + Vector2(-16.0, -46.0), _bullet_a)
			if drop != null:
				drop.gravity_pull = 105.0
		RetroSfx.play("bounce", -14.0, 0.1)
	_aux_timer -= delta
	if _aux_timer <= 0.0 and fx != null:
		_aux_timer = 0.06
		fx.spawn_hit_sparks(global_position + Vector2(randf_range(-3.0, 3.0), 5.0 if _vel.y < 0.0 else -5.0), Color("#ff7828"), 1)


# Holds a rock shield (80% damage reduction) for 2.4 s, cracks glow, then opens for 1.3 s:
# fires a 5-way fan and an aimed burst, and takes 150% damage while open.
func _tick_golem(delta: float) -> void:
	if _age < 15.0:
		global_position.x = lerpf(global_position.x, _target_x, 1.8 * delta)
		global_position.y = clampf(_base_y + sin(_age * 1.1 + _phase_offset) * 22.0, 46.0, 226.0)
	else:
		global_position.x -= 50.0 * delta
	_state_t -= delta
	if _state == 0:
		if _state_t <= 0.0 and _on_screen(40.0, 455.0):
			_state = 1
			_state_t = 1.3
			_shot_done = false
			_shoot_from_spread(global_position + Vector2(-12.0, 0.0), 5, 0.22, 148.0, _bullet_a)
			RetroSfx.play("explode", -12.0, 0.05)
	else:
		if not _shot_done and _state_t < 0.7:
			_shot_done = true
			for k: int in [-1, 0, 1]:
				_shoot_aimed_from(global_position + Vector2(-12.0, 0.0), 165.0, _bullet_b, float(k) * 0.1)
		if _state_t <= 0.0:
			_state = 0
			_state_t = _fire_cd(2.4)
	_sprite.texture = PixelArt.tex("en_golem_1" if _state == 1 else "en_golem_0")
	_shield.visible = _state == 0
	_shield.texture = PixelArt.tex("en_golem_shield_1" if _state_t < 0.45 else "en_golem_shield_0")


# --- 7 ABYSSAL TRENCH ------------------------------------------------------------------------

# Drifts and pulses: the bell contracts (telegraph), then releases a slow 8-bullet ring and
# swims up or down. Each ring is rotated from the last; after JELLY_PULSES it drifts away.
func _tick_jellyfish(delta: float) -> void:
	global_position.x -= (34.0 if _children_left > 0 else 70.0) * delta
	_vel.y = lerpf(_vel.y, 10.0, clampf(delta * 1.4, 0.0, 1.0))
	global_position.y = clampf(global_position.y + _vel.y * delta, 42.0, 232.0)
	_fire_timer -= delta
	var contracting: bool = _fire_timer < 0.45 and _children_left > 0
	_sprite.texture = PixelArt.tex("en_jelly_1" if contracting else "en_jelly_0")
	if _fire_timer <= 0.0 and _children_left > 0 and _on_screen(60.0, 462.0):
		_fire_timer = _fire_cd(2.6)
		_children_left -= 1
		for i: int in range(8):
			_emit_bullet(global_position + Vector2(0.0, -1.0), Vector2.from_angle(_boss_spin + TAU * float(i) / 8.0) * 80.0, _bullet_a)
		_boss_spin += 0.39
		_vel.y = -58.0 if global_position.y > 100.0 else 34.0
		RetroSfx.play("bounce", -13.0, 0.08)


# A fast eel weaving through the screen. Its body segments follow the head's path and are
# solid: touching any of them hurts, and shooting any of them damages the eel.
func _tick_eel(delta: float) -> void:
	global_position.x -= 102.0 * delta
	global_position.y = clampf(_base_y + sin(_age * 2.5 + _phase_offset) * 44.0, 40.0, 238.0)
	_trail_pts.insert(0, global_position)
	if _trail_pts.size() > 160:
		_trail_pts.resize(160)
	_update_eel_body()
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _on_screen(90.0, 455.0):
		_fire_timer = _fire_cd(2.8)
		_shoot_aimed(150.0, _bullet_a)


func _build_eel_body() -> void:
	for i: int in range(EEL_SEGMENTS):
		var s: Sprite2D = Sprite2D.new()
		s.texture = PixelArt.tex("en_eel_tail" if i == EEL_SEGMENTS - 1 else "en_eel_body")
		s.material = _mat
		s.show_behind_parent = true
		add_child(s)
		move_child(s, 0)  # each segment draws under the one in front of it
		_seg_sprites.append(s)
		var cs: CollisionShape2D = CollisionShape2D.new()
		var c: CircleShape2D = CircleShape2D.new()
		c.radius = 3.5 if i == EEL_SEGMENTS - 1 else 4.5
		cs.shape = c
		add_child(cs)
		_seg_shapes.append(cs)
	# Seed the path with a straight line trailing off to the right, behind the head.
	_trail_pts.clear()
	var steps: int = int(float(EEL_SEGMENTS + 1) * EEL_SPACING / 2.0)
	for i: int in range(steps + 1):
		_trail_pts.append(global_position + Vector2(float(i) * 2.0, 0.0))
	_update_eel_body()


func _update_eel_body() -> void:
	var placed: int = 0
	var acc: float = 0.0
	var prev: Vector2 = global_position
	for i: int in range(1, _trail_pts.size()):
		var p: Vector2 = _trail_pts[i]
		acc += prev.distance_to(p)
		prev = p
		while placed < EEL_SEGMENTS and acc >= EEL_SPACING * float(placed + 1):
			_seg_sprites[placed].position = p - global_position
			_seg_shapes[placed].position = p - global_position
			placed += 1
		if placed >= EEL_SEGMENTS:
			break
	while placed < EEL_SEGMENTS:
		var tail: Vector2 = prev + Vector2(EEL_SPACING * float(placed + 1) - acc, 0.0)
		_seg_sprites[placed].position = tail - global_position
		_seg_shapes[placed].position = tail - global_position
		placed += 1


# Lurks at the right edge. Its lure flashes (telegraph), then it lunges and bites out a
# 5-bullet cone aimed at the player. After ANGLER_BITES bites it sinks away.
func _tick_angler(delta: float) -> void:
	_state_t = maxf(0.0, _state_t - delta)
	var lunge: float = 0.0
	if _state_t > 0.0:
		lunge = sin((1.0 - _state_t / 0.9) * PI) * 34.0
	if _age < 14.0 and (_children_left > 0 or _state_t > 0.0):
		global_position.x = lerpf(global_position.x, _target_x - lunge, 3.0 * delta)
		global_position.y = clampf(_base_y + sin(_age * 0.8 + _phase_offset) * 18.0, 48.0, 222.0)
	else:
		global_position.x -= 55.0 * delta
	_fire_timer -= delta
	_sprite.texture = PixelArt.tex("en_angler_1" if _state_t > 0.5 else "en_angler_0")
	if _fire_timer <= 0.0 and _children_left > 0 and _on_screen(40.0, 455.0):
		_fire_timer = _fire_cd(2.9)
		_children_left -= 1
		_state_t = 0.9
		for k: int in range(-2, 3):
			_shoot_aimed_from(global_position + Vector2(-16.0, 5.0), 148.0, _bullet_a, float(k) * 0.13)
		RetroSfx.play("explode", -11.0, 0.05)


# --- 8 CYBER NEXUS ---------------------------------------------------------------------------

# Copies itself every VIRUS_REPLICATE_TIME seconds it stays alive (flashing for the last
# second first), up to VIRUS_MAX_GEN generations and VIRUS_CAP viruses on screen.
func _tick_virus(delta: float) -> void:
	global_position.x -= 44.0 * delta
	global_position.y = clampf(_base_y + sin(_age * 3.0 + _phase_offset) * 20.0, 40.0, 238.0)
	_aux_timer -= delta
	var urgent: bool = _aux_timer < 1.0 and gen < VIRUS_MAX_GEN
	var lit: bool = urgent and int(_age * 12.0) % 2 == 0
	_sprite.texture = PixelArt.tex("en_virus_1" if lit else "en_virus_0")
	var pulse: float = sin(_age * 30.0) * 0.08 if urgent else 0.0
	_sprite.scale = Vector2(1.0 + pulse, 1.0 - pulse)
	if _aux_timer <= 0.0:
		_aux_timer = VIRUS_REPLICATE_TIME
		_try_replicate()
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _on_screen(80.0, 455.0):
		_fire_timer = _fire_cd(2.4)
		_shoot_aimed(135.0, _bullet_a)


func _try_replicate() -> bool:
	if gen >= VIRUS_MAX_GEN or global_position.x < 40.0:
		return false
	if _virus_population() >= VIRUS_CAP:
		return false
	var frame: int = Engine.get_process_frames()
	if _replica_frame != frame:
		_replica_frame = frame
		_replicas_this_frame = 0
	_replicas_this_frame += 1
	gen += 1
	_apply_child_rewards()
	var off_y: float = 18.0 if global_position.y < 135.0 else -18.0
	_request_child(Type.VIRUS, global_position + Vector2(6.0, off_y), Vector2.ZERO, gen)
	if fx != null:
		fx.spawn_hit_sparks(global_position, Color("#ff38d4"), 6)
	RetroSfx.play("zap", -13.0, 0.08)
	return true


# Live viruses plus copies requested this frame that main hasn't spawned yet.
func _virus_population() -> int:
	var n: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is GameEnemy:
			var ge: GameEnemy = node as GameEnemy
			if ge.enemy_type == Type.VIRUS and not ge._dead and not ge.is_queued_for_deletion():
				n += 1
	if _replica_frame == Engine.get_process_frames():
		n += _replicas_this_frame
	return n


# Teleports around the right side: a flickering ghost marks the destination for 0.5 s, it
# blinks there and fires a 3-way spread. After 5 jumps it flees.
func _tick_glitch(delta: float) -> void:
	match _state:
		0:
			global_position.x = lerpf(global_position.x, _target_x, 3.0 * delta)
			global_position.y = lerpf(global_position.y, _base_y, 3.0 * delta)
			_state_t -= delta
			if _state_t <= 0.0 and global_position.x < 450.0:
				if _jumps_left <= 0:
					_state = 3
				else:
					_dest = _pick_glitch_dest()
					_state = 1
					_state_t = 0.5
					RetroSfx.play("boss_hp_tick", -14.0, 0.2)
		1:
			_state_t -= delta
			if _state_t <= 0.0:
				if fx != null:
					fx.spawn_hit_sparks(global_position, Color("#ff38d4"), 8)
					fx.spawn_hit_sparks(_dest, Color("#28f8ff"), 8)
				global_position = _dest
				_target_x = _dest.x
				_base_y = _dest.y
				_jumps_left -= 1
				_state = 2
				_state_t = 0.18
				RetroSfx.play("zap", -12.0, 0.08)
		2:
			_state_t -= delta
			if _state_t <= 0.0:
				for k: int in [-1, 0, 1]:
					_shoot_aimed(160.0, _bullet_a, float(k) * 0.16)
				_state = 0
				_state_t = _fire_cd(1.0)
		_:
			global_position.x -= 170.0 * delta
	_sprite.texture = PixelArt.tex("en_glitch_1" if (_state == 1 or randf() < 0.12) else "en_glitch_0")


func _pick_glitch_dest() -> Vector2:
	var pp: Vector2 = _player_pos()
	var cand: Vector2 = Vector2(randf_range(260.0, 435.0), randf_range(48.0, 230.0))
	for i: int in range(8):
		cand = Vector2(randf_range(260.0, 435.0), randf_range(48.0, 230.0))
		if cand.distance_to(pp) >= 110.0 and cand.distance_to(global_position) >= 50.0:
			break
	return cand


# One block of a wall the wave director lays out as a column with a 2-block gap. Blocks fire
# straight ahead in a rolling cascade; variant bits 1/2 draw the laser link up/down.
func _tick_firewall(delta: float) -> void:
	global_position.x -= 34.0 * delta
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _on_screen(70.0, 465.0):
		_fire_timer = _fire_cd(2.0)
		_emit_bullet(global_position + Vector2(-8.0, 0.0), Vector2(-130.0, 0.0), _bullet_b)


# Death effects of the themed enemies (called from _die, so only for kills).
func _on_themed_death() -> void:
	match enemy_type:
		Type.ASTEROID:
			var base_ang: float = randf() * TAU
			for i: int in range(ROCK_CHUNKS):
				var a: float = base_ang + TAU * float(i) / float(ROCK_CHUNKS)
				_request_child(Type.ROCK_CHUNK, global_position + Vector2.from_angle(a) * 4.0, Vector2.from_angle(a) * 64.0 + Vector2(-24.0, 0.0), gen + 1)
		Type.ICE_CRYSTAL:
			var rot: float = randf() * TAU
			for i: int in range(8):
				_emit_bullet(global_position, Vector2.from_angle(rot + TAU * float(i) / 8.0) * 96.0, "bullet_enemy_shard", true)
			if fx != null:
				fx.spawn_ring_blast(global_position, 20.0, Color("#a8f8ff"))
			RetroSfx.play("shield_hit", -9.0, 0.1)
		Type.SPORE_POD:
			if fx != null:
				fx.spawn_hit_sparks(global_position, Color("#5eff6e"), 8)
		Type.VIRUS, Type.GLITCH, Type.FIREWALL:
			if fx != null:
				fx.spawn_hit_sparks(global_position, Color("#ff38d4"), 6)
		Type.MODULE:
			_behaviour.call("on_death")


func _process_boss(delta: float) -> void:
	# 1) Dramatic Boss Chain-Explosion Meltdown on Defeat!
	if _boss_dying:
		_boss_death_timer -= delta
		_boss_death_boom_timer -= delta
		_boss_frame("_2")
		_sprite.position = Vector2(randf_range(-4.5, 4.5), randf_range(-4.5, 4.5))
		_mat.set_shader_parameter("flash", 1.0 if (int(_age * 26.0) % 2 == 0) else 0.0)
		if _boss_death_boom_timer <= 0.0:
			_boss_death_boom_timer = 0.13
			if fx != null:
				fx.spawn_explosion(global_position + Vector2(randf_range(-38.0, 24.0), randf_range(-58.0, 58.0)), true)
				fx.add_shake(5.0)
			RetroSfx.play("explode", -6.0, 0.09)
		if _boss_death_timer <= 0.0:
			_finish_boss_death()
			return
		queue_redraw()
		return

	# 2) Mega Man-Style 3-Stage Boss Intro Sequence!
	if boss_intro_active:
		_update_boss_intro(delta)
		queue_redraw()
		return

	# 3) Active Boss Combat & Multi-Frame Procedural Animation!
	var max_dps_allowed: float = max_hp * 0.062
	_dps_accumulator = maxf(0.0, _dps_accumulator - max_dps_allowed * delta)
	if boss_shield_timer > 0.0:
		boss_shield_timer = maxf(0.0, boss_shield_timer - delta)

	var bob_amp: float = 10.0 if stage_idx == 0 else (22.0 + float(boss_phase) * 4.0)
	var bob_spd: float = (0.9 if stage_idx == 0 else 1.2) + float(boss_phase - 1) * 0.25
	var sway_x: float = 0.0 if stage_idx == 0 else (-sin(_age * bob_spd * 2.0) * float(boss_phase) * 3.2)
	global_position.x = lerpf(global_position.x, _target_x + sway_x, 3.5 * delta)
	global_position.y = 134.0 + sin(_age * bob_spd) * bob_amp

	# Decay weapon recoil & attack squash/stretch smoothly
	_boss_recoil_x = lerpf(_boss_recoil_x, 0.0, clampf(delta * 14.0, 0.0, 1.0))
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, clampf(delta * 12.0, 0.0, 1.0))
	if _boss_attack_anim_timer > 0.0:
		_boss_attack_anim_timer = maxf(0.0, _boss_attack_anim_timer - delta)

	# Select animated boss sprite frame (_0, _1, or _2 for roar/attack/phase-burst)
	if _boss_attack_anim_timer > 0.0 or boss_shield_timer > 0.0:
		_boss_frame("_2")
	else:
		var anim_fps: float = 3.2 + float(boss_phase) * 1.5
		var idle_idx: int = int(_age * anim_fps) % 2
		_boss_frame("_1" if idle_idx == 1 else "_0")

	if boss_shield_timer > 0.0:
		_sprite.position = Vector2(_boss_recoil_x + randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	else:
		_sprite.position = Vector2(_boss_recoil_x, 0.0)
	_sprite.rotation = 0.0 if stage_idx == 0 else sin(_age * (1.8 + float(boss_phase) * 0.45)) * 0.036

	# Phase 3 Berserk damage sparks venting from hull
	if boss_phase >= 3:
		_boss_spark_timer -= delta
		if _boss_spark_timer <= 0.0:
			_boss_spark_timer = 0.26
			if fx != null:
				fx.spawn_hit_sparks(global_position + Vector2(randf_range(-32.0, 20.0), randf_range(-50.0, 50.0)), Color("#ff6828"), 4)

	_fire_timer -= delta
	if _fire_timer <= 0.0 and global_position.x < 465.0:
		_boss_attack()
		if _rig != null:
			_rig.on_attack(_boss_pattern)
		if _pilot != null:
			_pilot.roar(0.3)
		_boss_attack_anim_timer = 0.28
		_boss_recoil_x = 5.5
		_sprite.scale = Vector2(1.06, 0.95)

	queue_redraw()


func _update_boss_intro(delta: float) -> void:
	_boss_intro_timer += delta

	if _boss_intro_stage == 0:
		# Stage 0: Vertical Mega Man Teleport Beam streak-in to arena perch!
		var t0: float = clampf(_boss_intro_timer / 0.46, 0.0, 1.0)
		global_position.x = _target_x
		global_position.y = lerpf(-110.0, 134.0, 1.0 - pow(1.0 - t0, 2.2))
		_sprite.scale = Vector2(lerpf(0.16, 0.36, t0), lerpf(1.95, 1.42, t0))
		_mat.set_shader_parameter("flash", 1.0)

		if _boss_intro_timer >= 0.46:
			_boss_intro_stage = 1
			_boss_intro_timer = 0.0
			global_position = Vector2(_target_x, 134.0)
			_sprite.scale = Vector2(1.24, 0.80)
			_boss_frame("_2")
			if _rig != null:
				_rig.on_pose()
			RetroSfx.play("boss_pose", -4.5, 0.01)
			if fx != null:
				fx.add_shake(6.5)
				fx.spawn_hit_sparks(global_position + Vector2(-20.0, 0.0), Color("#28e8ff"), 18)

	elif _boss_intro_stage == 1:
		# Stage 1: Materialization Flash & Signature 2-Beat Boss Taunt / Power Pose!
		var t1: float = clampf(_boss_intro_timer / 0.68, 0.0, 1.0)
		_sprite.scale = _sprite.scale.lerp(Vector2.ONE, clampf(delta * 12.0, 0.0, 1.0))
		_mat.set_shader_parameter("flash", maxf(0.0, 1.0 - t1 * 2.8))
		var pose_suf: String = "_1" if (t1 > 0.28 and t1 < 0.52) else "_2"
		_boss_frame(pose_suf)
		_sprite.position = Vector2(-6.0 * sin(t1 * PI), 0.0)

		if _boss_intro_timer >= 0.68:
			_boss_intro_stage = 2
			_boss_intro_timer = 0.0
			_sprite.scale = Vector2.ONE
			_sprite.position = Vector2.ZERO
			_mat.set_shader_parameter("flash", 0.0)
			boss_hp_bar_visible = true
			_boss_hp_pips_filled = 0
			boss_hp_bar_fill = 0.0

	else:
		# Stage 2: Classic Mega Man Tick-by-Tick Boss HP Bar Fill (28 pips)!
		while _boss_intro_timer >= 0.038 and _boss_hp_pips_filled < BOSS_HP_PIPS:
			_boss_intro_timer -= 0.038
			_boss_hp_pips_filled += 1
			boss_hp_bar_fill = float(_boss_hp_pips_filled) / float(BOSS_HP_PIPS)
			RetroSfx.play("boss_hp_tick", -9.0, 0.0)

		var fill_suf: String = "_2" if _boss_hp_pips_filled >= BOSS_HP_PIPS - 4 else (
			"_1" if (_boss_hp_pips_filled / 3) % 2 == 1 else "_0"
		)
		_boss_frame(fill_suf)

		if _boss_hp_pips_filled >= BOSS_HP_PIPS:
			boss_hp_bar_fill = 1.0
			boss_intro_active = false
			_boss_intro_stage = 3
			boss_shield_timer = 0.0
			_age = 0.0
			_fire_timer = 0.35
			_boss_attack_anim_timer = 0.22
			RetroSfx.play("shield_hit", -6.0, 0.02)


func _boss_attack() -> void:
	# Faster cooldowns & higher bullet velocity in Phase 2 (<=66% HP) and Phase 3 (<=33% HP)!
	var rate_mult: float = 1.0 if boss_phase == 1 else (0.78 if boss_phase == 2 else 0.62)
	# +5 per stage through stage 8, then +2 per stage, so stage 28 bosses aren't absurdly fast.
	var spd_bonus: float = float(boss_phase - 1) * 18.0 + float(mini(stage_idx, 7)) * 5.0 + float(maxi(0, stage_idx - 7)) * 2.0

	_boss_substep += 1
	if _boss_substep >= 4:
		_boss_substep = 0
		_boss_pattern = (_boss_pattern + 1) % 3
		# In Phase 2 & 3 on Stages 2+, summon a pair of escort fighters to keep pressure high!
		if boss_phase >= 2 and stage_idx >= 1 and get_parent() != null:
			_spawn_boss_escort()

	# Stages 9+: the module's boss AI picks the attack (scripts/stages/stage_boss.gd).
	if _boss_ai != null:
		_boss_ai.call("attack", rate_mult, spd_bonus)
		return

	match stage_idx:
		0: # STAGE 1: NEMESIS DREADNOUGHT WALL
			if _boss_pattern == 0:
				var gap_idx: int = 2 + ((_boss_substep * 2 + int(_age)) % 5)
				for slot: int in range(9):
					if slot == gap_idx or slot == gap_idx + 1:
						continue
					var wy: float = 36.0 + float(slot) * 24.0
					_shoot_from(Vector2(global_position.x - 42.0, wy), Vector2(-(134.0 + spd_bonus), 0.0), _bullet_b)
				_fire_timer = 1.00 * rate_mult
			elif _boss_pattern == 1:
				var ang_off: float = sin(float(_boss_substep) * 0.9) * 0.24
				var b_spd: float = 150.0 + spd_bonus
				var top_gun: Vector2 = _bm("cannon_top", Vector2(-50.0, -50.0))
				var bot_gun: Vector2 = _bm("cannon_bot", Vector2(-50.0, 50.0))
				_shoot_from(top_gun, Vector2(-b_spd, 38.0).rotated(ang_off), _bullet_b)
				_shoot_from(top_gun, Vector2(-b_spd, 0.0).rotated(ang_off), _bullet_b)
				_shoot_from(bot_gun, Vector2(-b_spd, -38.0).rotated(-ang_off), _bullet_b)
				_shoot_from(bot_gun, Vector2(-b_spd, 0.0).rotated(-ang_off), _bullet_b)
				if boss_phase >= 3:
					_shoot_aimed_from(_bm("core", Vector2(-36.0, 0.0)), b_spd + 15.0, _bullet_a, 0.0)
				_fire_timer = 0.66 * rate_mult
			else:
				_shoot_ring(7 + boss_phase * 2, 136.0 + spd_bonus, _bullet_a, _boss_spin)
				_boss_spin += 0.28
				_fire_timer = 0.82 * rate_mult

		1: # STAGE 2: MECHA SCORPION
			if _boss_pattern == 0:
				var stinger_pos: Vector2 = _bm("stinger", Vector2(-38.0, -52.0))
				for k: int in range(4 + boss_phase):
					var vel: Vector2 = Vector2(-(158.0 + spd_bonus), 18.0 + float(k) * 20.0)
					_shoot_from(stinger_pos, vel, _bullet_a)
				_fire_timer = 0.88 * rate_mult
			elif _boss_pattern == 1:
				_shoot_from_spread(_bm("claw_top", Vector2(-46.0, -16.0)), 2 + boss_phase, 0.19, 148.0 + spd_bonus, _bullet_b)
				_shoot_from_spread(_bm("claw_bot", Vector2(-46.0, 38.0)), 2 + boss_phase, 0.19, 148.0 + spd_bonus, _bullet_b)
				_fire_timer = 0.92 * rate_mult
			else:
				var sting: Vector2 = _bm("stinger", Vector2(-38.0, -52.0))
				_shoot_aimed_from(sting, 178.0 + spd_bonus, _bullet_a, -0.10)
				_shoot_aimed_from(sting, 182.0 + spd_bonus, _bullet_a, 0.0)
				_shoot_aimed_from(sting, 178.0 + spd_bonus, _bullet_a, 0.10)
				_fire_timer = 0.72 * rate_mult

		2: # STAGE 3: SKY WYVERN
			if _boss_pattern == 0:
				_shoot_spread(4 + boss_phase * 2, 0.16, 158.0 + spd_bonus, _bullet_a)
				_fire_timer = 0.84 * rate_mult
			elif _boss_pattern == 1:
				var maw: Vector2 = _bm("maw", Vector2(-38.0, -4.0))
				for k: int in range(-boss_phase, boss_phase + 1):
					_shoot_aimed_from(maw, 174.0 + spd_bonus, _bullet_b, float(k) * 0.11)
				_fire_timer = 0.80 * rate_mult
			else:
				_shoot_ring(8 + boss_phase * 2, 146.0 + spd_bonus, _bullet_a, _boss_spin)
				_boss_spin += 0.25
				_fire_timer = 0.78 * rate_mult

		3: # STAGE 4: EMPEROR STAG-MANTIS BUG
			if _boss_pattern == 0:
				var s_off: float = sin(_age * 4.5) * 42.0
				_shoot_from(global_position + Vector2(-34.0, s_off), Vector2(-(150.0 + spd_bonus), 20.0), _bullet_a)
				_shoot_from(global_position + Vector2(-34.0, -s_off), Vector2(-(150.0 + spd_bonus), -20.0), _bullet_b)
				if boss_phase >= 2:
					_shoot_from(_bm("mouth", Vector2(-34.0, 0.0)), Vector2(-(160.0 + spd_bonus), sin(_age * 6.0) * 35.0), _bullet_a)
				_fire_timer = 0.42 * rate_mult
			else:
				_shoot_from_spread(_bm("scythe_top", Vector2(-42.0, -34.0)), 3 + boss_phase, 0.17, 156.0 + spd_bonus, _bullet_a)
				_shoot_from_spread(_bm("scythe_bot", Vector2(-42.0, 34.0)), 3 + boss_phase, 0.17, 156.0 + spd_bonus, _bullet_b)
				_fire_timer = 0.86 * rate_mult

		4: # STAGE 5: FROST SERAPH TITAN
			_shoot_ring(8 + boss_phase * 2, 142.0 + spd_bonus, _bullet_a if _boss_substep % 2 == 0 else _bullet_b, _boss_spin)
			if boss_phase >= 2 and _boss_substep % 2 == 0:
				_shoot_aimed(176.0 + spd_bonus, _bullet_b, 0.0)
			_boss_spin += 0.21
			_fire_timer = 0.76 * rate_mult

		5: # STAGE 6: INFERNO SKULL BALROG
			if _boss_pattern == 0:
				_shoot_from_spread(_bm("mouth", Vector2(-32.0, 14.0)), 5 + boss_phase * 2, 0.18, 155.0 + spd_bonus, _bullet_a)
				_fire_timer = 0.86 * rate_mult
			else:
				for k: int in range(-boss_phase, boss_phase + 1):
					_shoot_aimed_from(_bm("eye", Vector2(-20.0, -16.0)), 178.0 + spd_bonus, _bullet_b, float(k) * 0.09)
				_fire_timer = 0.74 * rate_mult

		6: # STAGE 7: ABYSSAL KRAKEN
			for arm: int in range(4 + boss_phase):
				var ang: float = PI + sin(_age * 3.0 + float(arm) * 0.5) * 0.58 + float(arm - 2) * 0.19
				_shoot_from(_bm("arm%d" % (arm % 6), Vector2(-40.0, float(arm - 2) * 20.0)), Vector2.from_angle(ang) * (146.0 + spd_bonus), _bullet_a)
			_fire_timer = 0.68 * rate_mult

		_: # STAGE 8: NEON MEDUSA OVERMIND
			if _boss_pattern == 0:
				var safe_lane: int = (_boss_substep * 2 + 1) % 6
				for lane: int in range(8):
					if lane == safe_lane or lane == safe_lane + 1:
						continue
					var ly: float = 36.0 + float(lane) * 26.0
					_shoot_from(Vector2(global_position.x - 36.0, ly), Vector2(-(172.0 + spd_bonus), 0.0), _bullet_a)
				_fire_timer = 0.80 * rate_mult
			else:
				_shoot_ring(10 + boss_phase * 2, 154.0 + spd_bonus, _bullet_b, _boss_spin)
				_boss_spin -= 0.25
				_fire_timer = 0.72 * rate_mult


# A dino pilot for a boss drawn from painted frames: its canopy straddles the top edge of the
# silhouette a little ahead of centre, and the species comes from the stage, so each boss keeps its
# own pilot.
func _add_frame_pilot() -> void:
	var tex: Texture2D = _sprite.texture
	if tex == null:
		return
	var img: Image = tex.get_image()
	var used: Rect2i = img.get_used_rect()
	if used.size.x < 24 or used.size.y < 24:
		return
	var cx: int = used.position.x + int(float(used.size.x) * 0.42)
	# The first row where the body is solid across the canopy's middle (skips thin antennae,
	# branches and rings).
	var top: int = used.position.y
	for y: int in range(used.position.y, used.end.y):
		var solid: int = 0
		for x: int in range(maxi(0, cx - 7), mini(img.get_width(), cx + 8)):
			if img.get_pixel(x, y).a > 0.5:
				solid += 1
		if solid >= 11:
			top = y
			break
	var species: Array = (DinoPilotScript.SPECIES as Dictionary).keys()
	var st_id: String = String(StageData.get_stage(stage_idx).get("id", str(stage_idx)))
	_pilot = DinoPilotScript.new()
	_pilot.position = Vector2(float(cx), float(top + 12)) - Vector2(img.get_size()) * 0.5
	_pilot.use_parent_material = true
	_sprite.add_child(_pilot)
	_pilot.setup(String(species[absi(st_id.hash()) % species.size()]), Vector2i(34, 28))


# Shows one of BossPainter's frames (_0/_1 idle, _2 attack); rigged bosses animate themselves.
func _boss_frame(suffix: String) -> void:
	if _rig == null:
		_sprite.texture = PixelArt.tex(_boss_tex_base + suffix)


# Where a boss shot leaves from: the rig's named muzzle (it moves with the part), or a fixed offset.
func _bm(muzzle_name: String, fallback: Vector2) -> Vector2:
	if _rig != null and _rig.has_muzzle(muzzle_name):
		return _rig.muzzle(muzzle_name)
	return global_position + fallback


# The pattern the next attack will use (patterns advance every 4 attacks; see _boss_attack).
func next_boss_pattern() -> int:
	return (_boss_pattern + 1) % 3 if _boss_substep + 1 >= 4 else _boss_pattern


func _spawn_boss_escort() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= 5:
		return
	for offset_y: float in [-62.0, 62.0]:
		var esc: GameEnemy = GameEnemy.new()
		get_parent().add_child(esc)
		var esc_hp_scale: float = StageData.stage_hp_growth(stage_idx, 1.32)
		esc.setup(
			Type.SWOOPER,
			Vector2(492.0, clampf(global_position.y + offset_y, 38.0, 226.0)),
			esc_hp_scale,
			player_ref,
			bullet_container,
			fx,
			offset_y,
			-1,
			stage_idx
		)


func _shoot_ring(count: int, speed: float, tex_key: String, rot_offset: float) -> void:
	for i: int in range(count):
		var ang: float = rot_offset + (TAU * float(i) / float(count))
		var vel: Vector2 = Vector2.from_angle(ang) * speed
		if vel.x < 35.0:
			_shoot_from(_bm("ring", Vector2(-24.0, 0.0)), vel, tex_key)


func _shoot_aimed(speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	_shoot_aimed_from(_bm("aimed", Vector2(-8.0, 0.0)), speed, tex_key, angle_offset)


func _shoot_aimed_from(origin: Vector2, speed: float, tex_key: String, angle_offset: float = 0.0) -> void:
	if bullet_container == null:
		return
	var dir: Vector2 = Vector2.LEFT
	if player_ref != null and is_instance_valid(player_ref) and player_ref.visible:
		dir = (player_ref.global_position - origin).normalized()
	dir = dir.rotated(angle_offset)
	_shoot_from(origin, dir * speed, tex_key)


func _shoot_spread(count: int, step_angle: float, speed: float, tex_key: String) -> void:
	_shoot_from_spread(_bm("spread", Vector2(-10.0, 0.0)), count, step_angle, speed, tex_key)


func _shoot_from_spread(origin: Vector2, count: int, step_angle: float, speed: float, tex_key: String) -> void:
	var half: float = float(count - 1) * 0.5
	for i: int in range(count):
		var ang: float = (float(i) - half) * step_angle
		var vel: Vector2 = Vector2(-speed, 0.0).rotated(ang)
		_shoot_from(origin, vel, tex_key)


func _shoot_from(pos: Vector2, vel: Vector2, tex_key: String) -> void:
	_emit_bullet(pos, vel, tex_key)


# Fires one enemy shot and returns it so callers can add gravity, homing and so on. Regular
# enemies' shots are scaled by the stage's shot_speed; boss patterns set their own speeds.
# deferred = true is for shots fired while dying, which can happen inside a physics callback.
func _emit_bullet(pos: Vector2, vel: Vector2, tex_key: String, deferred: bool = false, hit_radius: float = 2.5) -> GameBullet:
	if bullet_container == null:
		return null
	var v: Vector2 = vel if enemy_type == Type.BOSS else vel * _shot_mult
	var b: GameBullet = GameBullet.new()
	if deferred:
		b.setup(pos, v, 1.0, false, tex_key, 0, false, hit_radius, fx)
		bullet_container.call_deferred("add_child", b)
	else:
		bullet_container.add_child(b)
		b.setup(pos, v, 1.0, false, tex_key, 0, false, hit_radius, fx)
	return b


func _fire_cd(base: float) -> float:
	return base / _fire_mult


func take_contact_damage(dmg: float) -> void:
	if enemy_type != Type.BOSS:
		take_damage(dmg)


func apply_chill(duration: float, factor: float) -> void:
	if _dead or _boss_dying or boss_intro_active:
		return
	# Bosses shrug off most of the slow so fights don't stall.
	var f: float = lerpf(1.0, factor, 0.35) if enemy_type == Type.BOSS else factor
	_chill_timer = maxf(_chill_timer, duration)
	_chill_factor = minf(_chill_factor, f)


func apply_burn(dps: float, duration: float) -> void:
	if _dead or _boss_dying or boss_intro_active:
		return
	if _burn_timer <= 0.0:
		_burn_tick = 0.25
	_burn_dps = maxf(_burn_dps, dps)
	_burn_timer = maxf(_burn_timer, duration)


func take_damage(dmg: float, silent: bool = false) -> void:
	if _dead or _boss_dying or _warn_timer > 0.0:
		return

	if enemy_type == Type.GOLEM:
		# Rock shield: shots barely chip it while closed; the open core takes extra damage.
		if _state == 0:
			dmg *= 0.2
			if fx != null and _block_fx_t <= 0.0:
				_block_fx_t = 0.08
				fx.spawn_hit_sparks(global_position + Vector2(-13.0, randf_range(-10.0, 10.0)), Color("#c8b8a8"), 2)
		else:
			dmg *= 1.5
	elif enemy_type == Type.MODULE:
		dmg = float(_behaviour.call("modify_damage", dmg))

	if enemy_type == Type.BOSS:
		if boss_intro_active or boss_shield_timer > 0.0:
			return
		# Smooth Adaptive Boss Plating: caps ultra-high stacked multi-ray burst so bosses never melt in 2 seconds!
		var cap_window: float = max_hp * 0.095
		var effective_dmg: float = dmg
		if _dps_accumulator > cap_window:
			effective_dmg = dmg * 0.18
		elif _dps_accumulator > cap_window * 0.6:
			effective_dmg = dmg * 0.45
		_dps_accumulator += effective_dmg
		hp = maxf(0.0, hp - effective_dmg)
		if _rig != null:
			_rig.on_hurt()
		if _pilot != null:
			_pilot.hurt()

		# Check 3-Phase Thresholds (66% -> Phase 2, 33% -> Phase 3)!
		var ratio: float = hp / max_hp
		if boss_phase == 1 and ratio <= 0.66 and hp > 0.0:
			_enter_next_boss_phase(2)
			return
		elif boss_phase == 2 and ratio <= 0.33 and hp > 0.0:
			_enter_next_boss_phase(3)
			return
	else:
		hp -= dmg

	_flash_timer = 0.055
	_mat.set_shader_parameter("flash", 1.0)
	if hp <= 0.0:
		if enemy_type == Type.BOSS:
			_start_boss_death_sequence()
		else:
			_die()
	elif not silent:
		RetroSfx.play("hit", -14.0, 0.08)


func _enter_next_boss_phase(new_phase: int) -> void:
	boss_phase = new_phase
	if _rig != null:
		_rig.on_phase(new_phase)
	if _pilot != null:
		_pilot.roar(0.95)
		_pilot.low_hp = new_phase >= 3
	boss_shield_timer = 0.95 # Brief phase-transition energy shield!
	_dps_accumulator = 0.0
	_fire_timer = 0.45
	_boss_attack_anim_timer = 0.95
	_sprite.scale = Vector2(1.14, 0.88)
	RetroSfx.play("explode", -5.0, 0.04)
	if fx != null:
		fx.spawn_explosion(global_position + Vector2(-20.0, 0.0), true)
		fx.add_shake(6.5)
		fx.spawn_popup(
			global_position + Vector2(-58.0, -40.0),
			"PHASE 2: OVERDRIVE!" if new_phase == 2 else "PHASE 3: BERSERK!",
			Color("#ffe854") if new_phase == 2 else Color("#ff4c68")
		)
	boss_phase_broken.emit(self, 18 + stage_idx * 4)


func _start_boss_death_sequence() -> void:
	_boss_dying = true
	if _rig != null:
		_rig.on_die()
	if _pilot != null:
		_pilot.low_hp = true
	_boss_death_timer = 1.15
	_boss_death_boom_timer = 0.02
	hp = 0.0
	collision_layer = 0
	monitorable = false
	_sprite.rotation = 0.0
	_sprite.scale = Vector2(1.08, 1.08)
	# Cancel all active enemy bullets on screen as an immediate boss-kill reward!
	if bullet_container != null:
		for child: Node in bullet_container.get_children():
			if child is GameBullet:
				var gb: GameBullet = child as GameBullet
				if not gb.is_player_bullet:
					if fx != null:
						fx.spawn_hit_sparks(gb.global_position, Color("#ff4c68"), 3)
					gb.queue_free()


func _finish_boss_death() -> void:
	_dead = true
	if fx != null:
		fx.spawn_explosion(global_position, true)
		for k: int in range(7):
			fx.spawn_explosion(global_position + Vector2(randf_range(-36.0, 26.0), randf_range(-58.0, 58.0)), true)
		fx.add_shake(13.0)
	RetroSfx.play("big_explode", -3.5, 0.05)
	if _rig != null and fx != null:
		_rig.eject(fx, fx)
	if _pilot != null and fx != null:
		_pilot.eject(fx, fx)
	destroyed.emit(self, true)
	queue_free()


func _die() -> void:
	_dead = true
	var is_big: bool = (enemy_type == Type.CRUISER or enemy_type == Type.BOSS or enemy_type == Type.BLIMP or enemy_type == Type.GOLEM or enemy_type == Type.ANGLER or _module_big)
	if fx != null:
		fx.spawn_explosion(global_position, is_big)
		if is_big:
			fx.add_shake(4.0)
	RetroSfx.play("big_explode" if is_big else "explode", -4.0 if is_big else -8.5, 0.07)
	_on_themed_death()
	destroyed.emit(self, true)
	queue_free()


# Leaving the screen (or a mine bursting on its own) is not a kill: no score, Scrap or XP.
func _leave() -> void:
	if _dead:
		return
	_dead = true
	destroyed.emit(self, false)
	queue_free()


func _draw() -> void:
	if is_themed():
		_draw_themed()
		return
	if enemy_type == Type.CRUISER and hp < max_hp:
		var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-12.0, -14.0, 24.0, 3.0), Color("#14182e"))
		draw_rect(Rect2(-12.0, -14.0, 24.0 * ratio, 3.0), Color("#ff4c5e"))
	elif enemy_type == Type.BOSS:
		if boss_intro_active:
			if _boss_intro_stage == 0:
				# Mega Man vertical cyan-white teleport arrival beam!
				draw_rect(Rect2(-12.0, -220.0, 24.0, 300.0), Color(0.16, 0.91, 1.0, 0.38))
				draw_rect(Rect2(-4.0, -220.0, 8.0, 300.0), Color(1.0, 1.0, 1.0, 0.92))
			elif _boss_intro_stage == 1:
				# Expanding signature pose shockwave ring!
				var pt: float = clampf(_boss_intro_timer / 0.68, 0.0, 1.0)
				draw_arc(Vector2(-10.0, 0.0), lerpf(16.0, 76.0, pt), 0.0, TAU, 32, Color(1.0, 0.91, 0.33, 1.0 - pt), 2.0)
		elif boss_shield_timer > 0.0:
			# Glowing cyan phase-shift energy barrier around the boss!
			draw_arc(Vector2(-8.0, 0.0), 58.0, 0.0, TAU, 32, Color(0.16, 0.91, 1.0, 0.65), 2.0)
		elif _rig == null and not _boss_dying and _fire_timer > 0.0 and _fire_timer < 0.22:
			# Pre-attack weapon charge glint right before firing a volley!
			var ct: float = 1.0 - (_fire_timer / 0.22)
			var r_glint: float = lerpf(3.0, 8.5, ct)
			draw_circle(Vector2(-36.0, 0.0), r_glint, Color(1.0, 0.16, 0.28, 0.55))
			draw_circle(Vector2(-36.0, 0.0), r_glint * 0.48, Color(1.0, 0.95, 0.75, 0.92))
		if _boss_ai != null and not boss_intro_active and not _boss_dying:
			_boss_ai.call("draw")


# Telegraphs (charge glints, warning markers, lock-on lines) and HP bars of themed enemies.
# The sprites are set to show_behind_parent, so all of this draws on top of them.
func _draw_themed() -> void:
	if _warn_timer > 0.0:
		_draw_entrance_warning()
		return
	match enemy_type:
		Type.MINE_LAYER:
			if _children_left > 0:
				_draw_glint(Vector2(4.0, 6.0), _fire_timer, 0.35)
		Type.TURRET:
			if _burst_left == 0:
				_draw_glint(_barrel.position + Vector2.from_angle(_aim_angle) * 11.0, _fire_timer, 0.45)
		Type.SEC_DRONE:
			if _state == 1:
				var a: float = 0.3 + 0.3 * sin(_age * 40.0)
				draw_line(Vector2(-9.0, 0.0), Vector2(-global_position.x, 0.0), Color(1.0, 0.2, 0.3, a), 1.0)
				draw_rect(Rect2(-1.0, -18.0, 2.0, 5.0), Color("#ffe854"))
				draw_rect(Rect2(-1.0, -12.0, 2.0, 2.0), Color("#ffe854"))
		Type.BLIMP:
			_draw_glint(Vector2(-2.0, 9.0), _fire_timer, 0.35, Color(1.0, 0.6, 0.1))
			_draw_hp_bar(36.0, -14.0)
		Type.BEETLE:
			if _state == 1:
				var a: float = 0.22 + 0.22 * sin(_age * 36.0)
				draw_rect(Rect2(-global_position.x, -1.0, global_position.x - 10.0, 2.0), Color(1.0, 0.25, 0.3, a))
				draw_circle(Vector2(-7.5, 1.0), 1.5, Color(1.0, 0.2, 0.2, 0.9))
		Type.ICE_CRYSTAL:
			_draw_glint(Vector2(-8.0, 0.0), _fire_timer, 0.35, Color(0.5, 0.95, 1.0))
		Type.SNOW_DRONE:
			_draw_glint(Vector2(-8.0, 1.0), _fire_timer, 0.3, Color(0.5, 0.95, 1.0))
		Type.GOLEM:
			if _state == 1:
				var pulse: float = 0.5 + 0.5 * sin(_age * 24.0)
				draw_circle(Vector2(-1.0, 1.5), 5.5 + pulse, Color(1.0, 0.55, 0.1, 0.35))
			_draw_hp_bar(28.0, -19.0)
		Type.JELLYFISH:
			if _fire_timer > 0.0 and _fire_timer < 0.45 and _children_left > 0:
				var k: float = 1.0 - _fire_timer / 0.45
				draw_circle(Vector2(0.0, -3.0), 6.0 + 4.0 * k, Color(1.0, 0.45, 0.75, 0.18 + 0.2 * k))
		Type.EEL:
			_draw_glint(Vector2(-7.0, 0.0), _fire_timer, 0.3)
		Type.ANGLER:
			_draw_angler_lure()
			_draw_hp_bar(30.0, -18.0)
		Type.VIRUS:
			_draw_glint(Vector2(-6.0, 0.0), _fire_timer, 0.3)
		Type.GLITCH:
			if _state == 1:
				var off: Vector2 = _dest - global_position
				var tex: Texture2D = PixelArt.tex("en_glitch_1")
				var a: float = 0.3 + 0.35 * float(int(_age * 20.0) % 2)
				draw_texture(tex, (off - tex.get_size() * 0.5).round(), Color(0.6, 1.0, 1.0, a))
				draw_rect(Rect2(off - Vector2(11.0, 9.0), Vector2(22.0, 18.0)), Color(0.16, 0.97, 1.0, a), false, 1.0)
			elif _state == 2:
				_draw_glint(Vector2(-8.0, 0.0), _state_t, 0.18)
		Type.FIREWALL:
			var flick: float = 0.55 + 0.35 * sin(_age * 18.0 + _phase_offset)
			var link: Color = Color(1.0, 0.3, 0.85, flick)
			if variant & 1:
				draw_rect(Rect2(-2.0, -12.5, 4.0, 3.5), link)
			if variant & 2:
				draw_rect(Rect2(-2.0, 9.0, 4.0, 3.5), link)
			_draw_glint(Vector2(-8.0, 0.0), _fire_timer, 0.3, Color(1.0, 0.3, 0.85))
		Type.MODULE:
			_behaviour.call("draw")


func _draw_entrance_warning() -> void:
	if enemy_type == Type.MODULE:
		_behaviour.call("draw_warning")
	elif enemy_type == Type.LAVA_BLOB:
		# Bubbling, brightening glow on the lava where it will leap out.
		var k: float = clampf(1.0 - _warn_timer / 0.85, 0.0, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_age * 30.0)
		var fy: float = 255.0 - global_position.y
		draw_set_transform(Vector2(0.0, fy), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, lerpf(5.0, 12.0, k), Color(1.0, 0.42, 0.08, 0.35 + 0.3 * pulse))
		draw_circle(Vector2.ZERO, lerpf(2.0, 6.0, k), Color(1.0, 0.92, 0.45, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i: int in range(3):
			var by: float = fy - fposmod(_age * 40.0 + float(i) * 7.0, 18.0) * k
			draw_rect(Rect2(float(i - 1) * 4.0, by, 2.0, 2.0), Color(1.0, 0.7, 0.2, 0.8))
	elif enemy_type == Type.JET:
		# Blinking arrow on the left edge: a fighter is coming in from behind.
		if int(_warn_timer * 10.0) % 2 == 0:
			var lx: float = 6.0 - global_position.x
			var col: Color = Color("#ff4c68")
			draw_colored_polygon(PackedVector2Array([Vector2(lx, -6.0), Vector2(lx + 7.0, 0.0), Vector2(lx, 6.0)]), col)
			draw_colored_polygon(PackedVector2Array([Vector2(lx + 6.0, -6.0), Vector2(lx + 13.0, 0.0), Vector2(lx + 6.0, 6.0)]), Color(1.0, 0.85, 0.35))


func _draw_angler_lure() -> void:
	var lure: Vector2 = Vector2(-14.5, -10.5)
	var pulse: float = 0.5 + 0.5 * sin(_age * 6.0)
	var tele: bool = _fire_timer > 0.0 and _fire_timer < 0.6 and _children_left > 0
	var r: float = 2.5 + pulse
	var core: Color = Color(0.55, 1.0, 0.85, 0.75)
	if tele:
		r = 4.0 + 2.0 * float(int(_age * 16.0) % 2)
		core = Color(1.0, 1.0, 1.0, 0.9)
	draw_circle(lure, r + 5.0, Color(0.3, 1.0, 0.85, 0.10 + 0.08 * pulse))
	draw_circle(lure, r, core)
	draw_circle(lure, 1.2, Color.WHITE)


func _draw_glint(at: Vector2, timer: float, window: float, col: Color = Color(1.0, 0.16, 0.28)) -> void:
	if timer <= 0.0 or timer >= window:
		return
	var ct: float = 1.0 - timer / window
	var r: float = lerpf(1.5, 4.5, ct)
	draw_circle(at, r, Color(col.r, col.g, col.b, 0.6))
	draw_circle(at, r * 0.48, Color(1.0, 0.95, 0.75, 0.95))


func _draw_hp_bar(width: float, y: float) -> void:
	if hp >= max_hp:
		return
	var ratio: float = clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5, y, width, 3.0), Color("#14182e"))
	draw_rect(Rect2(-width * 0.5, y, width * ratio, 3.0), Color("#ff4c5e"))
