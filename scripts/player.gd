class_name PlayerShip
extends Area2D

signal hp_changed(current_hp: int, max_hp: int, shield_charges: int, max_shield: int)
signal player_died()
signal touch_state_changed()
signal grazed(xp: int)
signal sub_weapon_changed(id: String)

const MIN_X: float = 18.0
const MAX_X: float = 462.0
const MIN_Y: float = 30.0
const MAX_Y: float = 249.0
const TRAIL_STEP_DIST: float = 2.0
const TRAIL_MAX_POINTS: int = 96
const OPTION_TRAIL_SPACING: int = 12
const MAX_BLADES: int = 5
const FROST_SPEED_MULT: float = 0.55

var bullet_container: Node2D = null
var fx: FxLayer = null

var max_hp: int = 4
var hp: int = 4
var invuln_timer: float = 0.0
var controls_enabled: bool = false
var auto_fire_toggle: bool = true

# Selected Ship Hull & Signature Weapon (SkillTreeData.SHIPS id and weapon_id)
var ship_id: String = "viper"
var signature_weapon: String = "vulcan" # a SHIPS weapon_id, e.g. "vulcan", "rail", "cat", "lance", "katana"
var _ship_tex_0: String = "player_idle"
var _ship_tex_1: String = "player_flame_2"

# In-run Primary Beam Core & Co-Axial Aux Beam (so Exotic Ships NEVER lose their signature weapon!)
var active_beam: String = "vulcan"
var beam_level: int = 0                 # 1..4 for drafted Elemental/Tech Beam
var aux_beam: String = ""               # Used on Exotic Ships when they also draft a Tech Beam!
var weapon_overclock: int = 0           # 0..4 ranks boosting your ship's main blaster!
var has_revive_charge: bool = false

# In-run Physical Ship Addons (visibly mounted on or orbiting the ship!)
var option_count: int = 0               # 0..4 Gradius trailing Option orbs (mirror your active weapon!)
var missile_level: int = 0              # 0..4 Homing missile wing pods
var flank_level: int = 0                # 0..3 Tail & diagonal flank gun turrets
var blade_level: int = 0                # 0..4 Orbiting chakram sawblades
var turret_level: int = 0               # 0..4 360-degree roof smart auto-turret dome
var bomb_level: int = 0                 # 0..3 Underbelly singularity gravity bomb bay
var nova_level: int = 0                 # 0..3 Wing EMP shockwave capacitor fins

# Only ONE sub weapon fires at a time (Matt's call: the ship got silly with every addon on).
# The swap button (swap_weapon in InputPrompts: E / pad B / the touch SWAP button) cycles
# through the ones owned, in this order; drafting one switches to it. "beam" is a drafted Tech
# Beam mounted next to an exotic ship's own gun (aux_beam); on the vulcan ship a beam replaces
# the main gun instead, so it isn't a sub weapon there. The main gun and every passive card
# (CORE / MOD / GUARD / TECH) stay on.
const SUB_WEAPONS: Array[String] = ["option", "blades", "turret", "missile", "flank", "bomb", "nova", "beam"]
var sub_weapon: String = ""             # the active one; "" while none is owned

# In-run Core Ship Systems & Meta Stats
var move_speed: float = 155.0
var fire_rate_bonus: float = 1.0
var damage_bonus: float = 1.0
var crit_chance: float = 0.0
var proj_size_mult: float = 1.0
var aoe_scale_mult: float = 1.0
var spread_level: int = 0               # 0..3 Spread fan matrix
var max_shield: int = 0                 # 0..3 Regenerating Force Shield charges
var rapid_level: int = 0                # 0..5 Fire rate coil ranks
var thruster_level: int = 0             # 0..4 Afterburner speed ranks
var shield_charges: int = 0
var shield_regen_timer: float = 0.0

# In-run perks from DRAFT CARD upgrades (unlocked in the Skill Tree, then drafted on level-up)
var crit_mult: float = 2.0              # Damage multiplier on a critical hit
var homing_level: int = 0               # 0..2 Seeker Rounds: main gun shots curve into enemies
var shrapnel_level: int = 0             # 0..2 Shrapnel Burst: main gun hits split into fragments
var crit_level: int = 0                 # 0..3 Tachyon Optics: +crit chance & crit damage
var berserk_level: int = 0              # 0..2 Berserker Core: +damage per missing hull
var execute_level: int = 0              # 0..2 Execute Protocol: hits kill weakened non-bosses
var ambush_level: int = 0               # 0..2 Ambush Targeting: bonus damage on unhurt enemies
var cryo_level: int = 0                 # 0..2 Cryo Rounds: hits chill (slow) enemies
var napalm_level: int = 0               # 0..2 Napalm Rounds: hits burn enemies over time
var leech_level: int = 0                # 0..3 Vampire Salvage: repair 1 hull every N kills
var reflect_level: int = 0              # 0..2 Mirror Shield: shield breaks fire enemy shots back
var last_stand_level: int = 0           # 0..1 Last Stand: at 1 hull, invincibility + nova (once per stage)
var last_stand_ready: bool = false
var chrono_level: int = 0               # 0..2 Chrono Field: nearby enemy shots slow down
var graze_level: int = 0                # 0..2 Graze Dynamo: near misses give XP
var aura_level: int = 0                 # 0..3 Ion Storm Aura: damage field around the ship
var chain_level: int = 0                # 0..3 Chain Reaction: kills explode
var orbital_level: int = 0              # 0..3 Orbital Strike: sky laser hits the toughest enemy
var mines_level: int = 0                # 0..3 Proximity Mines: drop mines behind the ship
var salvage_level: int = 0              # 0..2 Salvage Claws: +Scrap from kills this run
var _leech_kills: int = 0
var frost_timer: float = 0.0            # Cryo Glacier snow drones' frost: ship flies at FROST_SPEED_MULT
var _aura_timer: float = 0.0
var _orbital_timer: float = 0.0
var _mine_timer: float = 0.0

# Touch & Gamepad state
var touch_detected: bool = false
var touch_focus_held: bool = false
var _touch_drag_idx: int = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_current: Vector2 = Vector2.ZERO
var _mouse_drag_sim: bool = false

# Weapon & Addon timers
var _fire_cooldown: float = 0.0
var _missile_cooldown: float = 0.0
var _flank_cooldown: float = 0.0
var _turret_cooldown: float = 0.0
var _bomb_cooldown: float = 0.0
var _nova_cooldown: float = 0.0
var _blade_dmg_timer: float = 0.0
var _blade_orbit_angle: float = 0.0
var _wave_flip: bool = false
var _volley_count: int = 0
# S.S. MEOW-ZER cat shots cycle through these coats (sprite keys <coat>_0 / <coat>_1).
const CAT_SHOT_COATS: Array[String] = ["bullet_cat", "bullet_cat_snow", "bullet_cat_blue"]
var _cat_coat_idx: int = 0

# --- Signature weapons of the 10 hangar-expansion ships (see _fire_primary / _spawn_mode_shot) ---
# The original 7 ships fire a drafted aux beam every 2nd volley; the newer ones, whose volleys come
# at very different rates (a 0.1 s beam tick, a 0.75 s orb), fire it on a steady timer instead.
const VOLLEY_AUX_WEAPONS: Array[String] = ["vulcan", "biowave", "rail", "flak", "saucer", "ocular", "cat"]
# Weapons the ship itself fires once per volley around its own position (spread changes how,
# not how many); its options throw _option_mode() projectiles instead.
const SELF_AIMED_WEAPONS: Array[String] = ["katana", "tongue", "seed"]
const SENTRY_CAP: int = 4               # STARBLOOM seed sentries alive at once
const COMET_CHARGE_TIME: float = 0.72   # COMET KNIGHT: seconds to a full charge
const COMET_MIN_CHARGE: float = 0.25    # releasing fire below this charge fires nothing
const LANCE_HALF_WIDTH: float = 2.5     # HELIOS LANCER beam: hits enemies this close to its line
const LANCE_FX_TIME: float = 0.11
const SLASH_FX_TIME: float = 0.14
const TONGUE_FX_TIME: float = 0.15
const BEAM_AREA: Rect2 = Rect2(0.0, 22.0, 480.0, 248.0) # beams stop at the screen edge
var _lance_fx: Array[Dictionary] = []
var _slash_fx: Array[Dictionary] = []
var _tongue_fx: Array[Dictionary] = []
var _slash_flip: bool = false
var _sentries: Array[GameBullet] = []
var _comet_charge: float = 0.0
var _comet_power: float = 1.0
var _aux_timer: float = 0.0
var _orbit_pods: Array[Sprite2D] = []
var _orbit_angle: float = 0.0
var _cur_emitter_src: int = -1          # which emitter _spawn_mode_shot is firing for (-1 = ship)
var _turret_aim_dir: Vector2 = Vector2.RIGHT

var _anim_timer: float = 0.0
var _flame_alt: bool = false
var _focus_held: bool = false
var _prev_joy_y_btn: bool = false

var _sprite: Sprite2D
var _trail: Array[Vector2] = []
var _option_sprites: Array[Sprite2D] = []
var _blade_sprites: Array[Sprite2D] = []
var _blade_block_cd: Array[float] = []

# Sub weapon evolutions bought in the skill tree's EVOLVE nodes (SUB_WEAPONS id -> marks 0-3,
# so 1 = MK II ... 3 = MK IV), read at run start. They only change a sub weapon once it's drafted.
var sub_evo: Dictionary = {}
var _option_block_cd: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _blade_throw_t: float = 0.0     # MK IV blades: time into the buzzsaw cycle
var _nova_echo_t: float = -1.0      # MK IV nova: seconds until the echo pulse (< 0: none due)
const BLADE_THROW_PERIOD: float = 3.2
const BLADE_THROW_TIME: float = 0.7


func _ready() -> void:
	collision_layer = 1
	collision_mask = 4
	monitoring = true
	monitorable = true

	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.tex("player_idle")
	add_child(_sprite)

	# Small fair arcade core hurtbox (radius 3px!)
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 3.0
	col.shape = shape
	add_child(col)

	for i: int in range(4):
		var opt: Sprite2D = Sprite2D.new()
		opt.texture = PixelArt.tex("option_orb")
		opt.top_level = true
		opt.visible = false
		add_child(opt)
		_option_sprites.append(opt)

	for i: int in range(MAX_BLADES):
		var bl: Sprite2D = Sprite2D.new()
		bl.texture = PixelArt.tex("addon_sawblade")
		bl.top_level = true
		bl.visible = false
		add_child(bl)
		_blade_sprites.append(bl)
		_blade_block_cd.append(0.0)

	for i: int in range(2):
		var pod: Sprite2D = Sprite2D.new()
		pod.texture = PixelArt.tex("orbit_pod_%d" % i)
		pod.top_level = true
		pod.visible = false
		add_child(pod)
		_orbit_pods.append(pod)

	area_entered.connect(_on_area_entered)


func reset_for_new_run() -> void:
	global_position = Vector2(56.0, 134.0)
	visible = true
	controls_enabled = true
	auto_fire_toggle = MetaSave.default_autofire
	invuln_timer = 1.0
	touch_focus_held = false
	_touch_drag_idx = -1
	_mouse_drag_sim = false

	var ship_def: Dictionary = MetaSave.get_selected_ship_def()
	ship_id = String(ship_def["id"])
	signature_weapon = String(ship_def["weapon_id"])
	_ship_tex_0 = String(ship_def["sprite_0"])
	_ship_tex_1 = String(ship_def["sprite_1"])
	_sprite.texture = PixelArt.tex(_ship_tex_0)

	var opt_tex_key: String = "option_yarn" if ship_id == "neko" else "option_orb"
	for opt: Sprite2D in _option_sprites:
		opt.texture = PixelArt.tex(opt_tex_key)

	max_hp = MetaSave.get_starting_max_hp()
	hp = max_hp
	move_speed = MetaSave.get_starting_speed()
	fire_rate_bonus = MetaSave.get_base_fire_rate_mult()
	damage_bonus = MetaSave.get_base_damage_mult()
	crit_chance = MetaSave.get_crit_chance()
	proj_size_mult = MetaSave.get_projectile_size_mult()
	aoe_scale_mult = MetaSave.get_aoe_scale_mult()
	has_revive_charge = MetaSave.has_lazarus_revive()

	active_beam = signature_weapon
	aux_beam = ""
	beam_level = 0
	weapon_overclock = 0
	spread_level = 0
	rapid_level = 0
	thruster_level = 0

	# Only ship-hull perks pre-install addons now (Saucer blades, Titan flank gun); the tree adds none.
	var starters: Dictionary = MetaSave.get_starter_addons()
	option_count = 0
	turret_level = 0
	missile_level = 0
	nova_level = 0
	bomb_level = 0
	blade_level = mini(4, int(starters.get("blades", 0)))
	flank_level = mini(3, int(starters.get("flank", 0)))

	max_shield = mini(3, MetaSave.get_starting_shields())
	shield_charges = max_shield
	shield_regen_timer = 0.0

	crit_mult = 2.0
	homing_level = 0
	shrapnel_level = 0
	crit_level = 0
	berserk_level = 0
	execute_level = 0
	ambush_level = 0
	cryo_level = 0
	napalm_level = 0
	leech_level = 0
	reflect_level = 0
	last_stand_level = 0
	last_stand_ready = false
	chrono_level = 0
	graze_level = 0
	aura_level = 0
	chain_level = 0
	orbital_level = 0
	mines_level = 0
	salvage_level = 0
	_leech_kills = 0
	frost_timer = 0.0
	_sprite.self_modulate = Color.WHITE
	_aura_timer = 0.0
	_orbital_timer = 2.0
	_mine_timer = 0.0

	_fire_cooldown = 0.0
	_missile_cooldown = 0.0
	_flank_cooldown = 0.0
	_turret_cooldown = 0.0
	_bomb_cooldown = 0.0
	_nova_cooldown = 2.0
	_volley_count = 0
	_turret_aim_dir = Vector2.RIGHT
	for i: int in range(MAX_BLADES):
		_blade_block_cd[i] = 0.0
	sub_evo.clear()
	for sub_id: String in SUB_WEAPONS:
		sub_evo[sub_id] = MetaSave.get_sub_evolution(sub_id)
	for i: int in range(4):
		_option_block_cd[i] = 0.0
	_blade_throw_t = 0.0
	_nova_echo_t = -1.0

	# Hull perks of the newer ships: a built-in addon or a rank of a DRAFT CARD perk.
	turret_level = mini(4, int(starters.get("turret", 0)))
	missile_level = mini(4, int(starters.get("missile", 0)))
	chrono_level = mini(2, int(starters.get("chrono", 0)))
	graze_level = mini(2, int(starters.get("graze", 0)))
	leech_level = mini(3, int(starters.get("leech", 0)))
	last_stand_level = mini(1, int(starters.get("last_stand", 0)))
	last_stand_ready = last_stand_level > 0
	sub_weapon = ""
	var owned_subs: Array[String] = owned_sub_weapons()
	_select_sub_weapon(owned_subs[0] if not owned_subs.is_empty() else "", false)

	_lance_fx.clear()
	_slash_fx.clear()
	_tongue_fx.clear()
	_sentries.clear()
	_comet_charge = 0.0
	_comet_power = 1.0
	_aux_timer = 0.0
	_orbit_angle = 0.0

	_trail.clear()
	for i: int in range(TRAIL_MAX_POINTS):
		_trail.append(global_position - Vector2(float(i) * 1.5, 0.0))
	_sync_options()
	_sync_blades()
	_sync_orbit_pods()
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func clear_touch_drag() -> void:
	_touch_drag_idx = -1
	_mouse_drag_sim = false
	touch_focus_held = false


func is_touch_dragging() -> bool:
	return _touch_drag_idx != -1 or _mouse_drag_sim


func get_touch_origin() -> Vector2:
	return _touch_origin


func get_touch_current() -> Vector2:
	return _touch_current


func set_options_hidden() -> void:
	for opt: Sprite2D in _option_sprites:
		opt.visible = false
	for bl: Sprite2D in _blade_sprites:
		bl.visible = false
	for pod: Sprite2D in _orbit_pods:
		pod.visible = false


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


func get_committed_tech_beam() -> String:
	if signature_weapon == "vulcan":
		return active_beam if active_beam != "vulcan" else ""
	return aux_beam


func apply_run_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"overclock":
			weapon_overclock = mini(4, weapon_overclock + 1)
			damage_bonus += 0.12
		"laser", "wave", "prism", "tesla", "plasma":
			if signature_weapon == "vulcan":
				if active_beam != upgrade_id:
					active_beam = upgrade_id
					beam_level = maxi(1, beam_level)
				else:
					beam_level = mini(4, beam_level + 1)
			else:
				# Exotic Ships keep their unique signature gun AND mount drafted Tech Beams co-axially!
				if aux_beam != upgrade_id:
					aux_beam = upgrade_id
					beam_level = maxi(1, beam_level)
				else:
					beam_level = mini(4, beam_level + 1)
		"option":
			option_count = mini(4, option_count + 1)
			_sync_options()
		"missile":
			missile_level = mini(4, missile_level + 1)
		"flank":
			flank_level = mini(3, flank_level + 1)
		"blades":
			blade_level = mini(4, blade_level + 1)
			_sync_blades()
		"turret":
			turret_level = mini(4, turret_level + 1)
		"bomb":
			bomb_level = mini(3, bomb_level + 1)
		"nova":
			nova_level = mini(3, nova_level + 1)
			_nova_cooldown = minf(_nova_cooldown, 0.6)
		"spread":
			spread_level = mini(3, spread_level + 1)
		"shield":
			max_shield = mini(3, max_shield + 1)
			shield_charges = max_shield
			shield_regen_timer = 0.0
		"rapid":
			rapid_level = mini(5, rapid_level + 1)
			fire_rate_bonus += 0.22
			damage_bonus += 0.10
		"thruster":
			thruster_level = mini(4, thruster_level + 1)
			move_speed += 25.0
			invuln_timer = maxf(invuln_timer, 0.5)
		"repair":
			max_hp += 1
			hp = mini(max_hp, hp + 2)
			damage_bonus += 0.12
		# --- DRAFT CARD upgrades (caps must match max_rank in main.RUN_UPGRADE_POOL) ---
		"homing":
			homing_level = mini(2, homing_level + 1)
		"shrapnel":
			shrapnel_level = mini(2, shrapnel_level + 1)
		"crit":
			if crit_level < 3:
				crit_level += 1
				crit_chance = minf(0.85, crit_chance + 0.12)
				crit_mult = 2.0 + 0.25 * float(crit_level)
		"berserk":
			berserk_level = mini(2, berserk_level + 1)
		"execute":
			execute_level = mini(2, execute_level + 1)
		"ambush":
			ambush_level = mini(2, ambush_level + 1)
		"cryo":
			cryo_level = mini(2, cryo_level + 1)
		"napalm":
			napalm_level = mini(2, napalm_level + 1)
		"leech":
			leech_level = mini(3, leech_level + 1)
		"reflect":
			if reflect_level < 2:
				reflect_level += 1
				max_shield = mini(3, max_shield + 1)
				shield_charges = max_shield
				shield_regen_timer = 0.0
		"last_stand":
			last_stand_level = 1
			last_stand_ready = true
		"chrono":
			chrono_level = mini(2, chrono_level + 1)
		"graze":
			graze_level = mini(2, graze_level + 1)
		"aura":
			aura_level = mini(3, aura_level + 1)
		"chain":
			chain_level = mini(3, chain_level + 1)
		"orbital":
			orbital_level = mini(3, orbital_level + 1)
			_orbital_timer = minf(_orbital_timer, 1.0)
		"mines":
			mines_level = mini(3, mines_level + 1)
		"salvage":
			salvage_level = mini(2, salvage_level + 1)
	var drafted_sub: String = _sub_weapon_of_card(upgrade_id)
	if drafted_sub != "" and sub_weapon_level(drafted_sub) > 0:
		_select_sub_weapon(drafted_sub, false)
	hp_changed.emit(hp, max_hp, shield_charges, max_shield)


# --- Sub weapon swap ------------------------------------------------------------------------

# The sub weapon a draft card belongs to ("" for the main gun and the passive cards).
func _sub_weapon_of_card(upgrade_id: String) -> String:
	if upgrade_id in ["laser", "wave", "prism", "tesla", "plasma"]:
		return "beam" if aux_beam != "" else ""
	return upgrade_id if SUB_WEAPONS.has(upgrade_id) else ""


# Rank of a sub weapon (0 = not owned).
func sub_weapon_level(id: String) -> int:
	match id:
		"option":
			return option_count
		"blades":
			return blade_level
		"turret":
			return turret_level
		"missile":
			return missile_level
		"flank":
			return flank_level
		"bomb":
			return bomb_level
		"nova":
			return nova_level
		"beam":
			return beam_level if aux_beam != "" else 0
	return 0


func owned_sub_weapons() -> Array[String]:
	var owned: Array[String] = []
	for id: String in SUB_WEAPONS:
		if sub_weapon_level(id) > 0:
			owned.append(id)
	return owned


func is_sub_active(id: String) -> bool:
	return sub_weapon == id and sub_weapon_level(id) > 0


# The swap button: the next owned sub weapon (wraps). Does nothing with fewer than 2.
func swap_sub_weapon() -> void:
	var owned: Array[String] = owned_sub_weapons()
	if owned.size() < 2:
		return
	var i: int = owned.find(sub_weapon)
	_select_sub_weapon(owned[(i + 1) % owned.size()], true)


func _select_sub_weapon(id: String, announce: bool) -> void:
	var changed: bool = id != sub_weapon
	sub_weapon = id
	_sync_options()
	_sync_blades()
	if announce and fx != null:
		fx.spawn_popup(global_position + Vector2(-18.0, -16.0), sub_weapon_name(id), Color("#ffe854"))
		RetroSfx.play("ui", -6.0, 0.03)
	if changed:
		sub_weapon_changed.emit(id)
	queue_redraw()


func sub_weapon_name(id: String) -> String:
	match id:
		"option":
			return "OPTION"
		"blades":
			return "BLADES"
		"turret":
			return "TURRET"
		"missile":
			return "PODS"
		"flank":
			return "FLANK"
		"bomb":
			return "BOMBS"
		"nova":
			return "NOVA"
		"beam":
			return aux_beam.to_upper()
	return ""


# Marks bought for a sub weapon's evolution: 0 (stock) .. 3 (MK IV).
func evo(sub_id: String) -> int:
	return int(sub_evo.get(sub_id, 0))


# Options only fly (and fire) while they're the active sub weapon.
func _live_option_count() -> int:
	return option_count if is_sub_active("option") else 0


func _sync_options() -> void:
	for i: int in range(4):
		var opt: Sprite2D = _option_sprites[i]
		opt.visible = visible and (i < _live_option_count())
		if opt.visible:
			var idx: int = mini(_trail.size() - 1, (i + 1) * OPTION_TRAIL_SPACING)
			opt.global_position = _trail[idx]


func _active_blade_count() -> int:
	return 0 if not is_sub_active("blades") else mini(MAX_BLADES, 1 + blade_level)


func _sync_blades() -> void:
	var count: int = _active_blade_count()
	for i: int in range(MAX_BLADES):
		var bl: Sprite2D = _blade_sprites[i]
		bl.visible = visible and (i < count)
		if bl.visible and count > 0:
			var ang: float = _blade_orbit_angle + TAU * float(i) / float(count)
			bl.global_position = global_position + Vector2(cos(ang), sin(ang)) * _blade_radius()


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.07:
		_anim_timer = 0.0
		_flame_alt = not _flame_alt
		_sprite.texture = PixelArt.tex(_ship_tex_1 if _flame_alt else _ship_tex_0)

	if frost_timer > 0.0:
		frost_timer = maxf(0.0, frost_timer - delta)
		_sprite.self_modulate = Color(0.62, 0.9, 1.0) if frost_timer > 0.0 else Color.WHITE

	if invuln_timer > 0.0:
		invuln_timer = maxf(0.0, invuln_timer - delta)
		_sprite.modulate.a = 0.35 if int(invuln_timer * 24.0) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

	if max_shield > 0 and shield_charges < max_shield and visible and controls_enabled:
		shield_regen_timer += delta
		var regen_needed: float = maxf(4.5, 8.5 - float(max_shield) * 1.2)
		if shield_regen_timer >= regen_needed:
			shield_regen_timer = 0.0
			shield_charges += 1
			RetroSfx.play("powerup", -11.0, 0.03)
			hp_changed.emit(hp, max_hp, shield_charges, max_shield)

	if is_sub_active("blades") and visible:
		_update_orbiting_blades(delta)
	if signature_weapon == "orbit" and visible:
		_update_orbit_pods(delta)
	_age_weapon_fx(delta)

	if not controls_enabled or not visible:
		queue_redraw()
		return

	var move_vec: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		move_vec.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		move_vec.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		move_vec.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		move_vec.y += 1.0

	var joy_focus: bool = false
	var joy_fire: bool = false
	var any_joy_y: bool = false

	# Poll ALL connected joypads so multi-controller PCs work seamlessly!
	for pad_id: int in Input.get_connected_joypads():
		var gx: float = Input.get_joy_axis(pad_id, JOY_AXIS_LEFT_X)
		var gy: float = Input.get_joy_axis(pad_id, JOY_AXIS_LEFT_Y)
		if absf(gx) > 0.18:
			move_vec.x += gx
		if absf(gy) > 0.18:
			move_vec.y += gy
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_LEFT):
			move_vec.x -= 1.0
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_RIGHT):
			move_vec.x += 1.0
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_UP):
			move_vec.y -= 1.0
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_DPAD_DOWN):
			move_vec.y += 1.0

		if (
			Input.is_joy_button_pressed(pad_id, JOY_BUTTON_LEFT_SHOULDER)
			or Input.is_joy_button_pressed(pad_id, JOY_BUTTON_RIGHT_SHOULDER)
			or Input.get_joy_axis(pad_id, JOY_AXIS_TRIGGER_LEFT) > 0.35
		):
			joy_focus = true

		# RT is the speed-up button (main.gd), not fire.
		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_A) or Input.is_joy_button_pressed(pad_id, JOY_BUTTON_X):
			joy_fire = true

		if Input.is_joy_button_pressed(pad_id, JOY_BUTTON_Y):
			any_joy_y = true

	if any_joy_y and not _prev_joy_y_btn:
		_toggle_autofire()
	_prev_joy_y_btn = any_joy_y

	if move_vec.length_squared() > 1.0:
		move_vec = move_vec.normalized()

	_focus_held = Input.is_physical_key_pressed(KEY_SHIFT) or joy_focus or touch_focus_held
	var spd: float = move_speed * (0.52 if _focus_held else 1.0)
	if frost_timer > 0.0:
		spd *= FROST_SPEED_MULT
	global_position += move_vec * spd * delta
	global_position.x = clampf(global_position.x, MIN_X, MAX_X)
	global_position.y = clampf(global_position.y, MIN_Y, MAX_Y)

	var tilt_y: float = move_vec.y
	if is_touch_dragging():
		tilt_y = clampf((_touch_current.y - _touch_origin.y) * 0.05, -1.0, 1.0)
	rotation = lerpf(rotation, tilt_y * 0.09, 14.0 * delta)

	_record_trail_and_options(delta)

	# Primary Weapon & Addons!
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	var fire_pressed: bool = (
		auto_fire_toggle
		or joy_fire
		or is_touch_dragging()
		or Input.is_physical_key_pressed(KEY_SPACE)
		or Input.is_physical_key_pressed(KEY_Z)
		or Input.is_physical_key_pressed(KEY_J)
		or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and MetaSave.touch_mode != 1)
	)
	if active_beam == "comet":
		_update_comet_charge(delta, fire_pressed)
	elif fire_pressed and _fire_cooldown <= 0.0:
		var base_interval: float = _fire_primary()
		_fire_cooldown = base_interval / fire_rate_bonus

	if is_sub_active("beam") and not VOLLEY_AUX_WEAPONS.has(signature_weapon):
		_aux_timer = maxf(0.0, _aux_timer - delta)
		if fire_pressed and _aux_timer <= 0.0:
			_fire_aux_beam()
			_aux_timer = (0.25 if evo("beam") >= 2 else 0.34) / fire_rate_bonus

	if is_sub_active("missile"):
		_missile_cooldown = maxf(0.0, _missile_cooldown - delta)
		if fire_pressed and _missile_cooldown <= 0.0:
			_fire_missiles()
			_missile_cooldown = maxf(0.28, 0.84 - float(missile_level) * 0.13) / (0.55 + 0.45 * fire_rate_bonus) * (0.8 if evo("missile") >= 2 else 1.0)

	if is_sub_active("flank"):
		_flank_cooldown = maxf(0.0, _flank_cooldown - delta)
		if fire_pressed and _flank_cooldown <= 0.0:
			_fire_flank_guns()
			_flank_cooldown = (0.21 if evo("flank") >= 2 else 0.27) / fire_rate_bonus

	if is_sub_active("turret"):
		_turret_cooldown = maxf(0.0, _turret_cooldown - delta)
		_aim_auto_turret(delta)
		if fire_pressed and _turret_cooldown <= 0.0:
			_fire_auto_turret()
			_turret_cooldown = maxf(0.11, 0.30 - float(turret_level) * 0.045) / (0.6 + 0.4 * fire_rate_bonus)

	if is_sub_active("bomb"):
		_bomb_cooldown = maxf(0.0, _bomb_cooldown - delta)
		if fire_pressed and _bomb_cooldown <= 0.0:
			_fire_gravity_bomb()
			_bomb_cooldown = maxf(0.55, 1.35 - float(bomb_level) * 0.22)

	if is_sub_active("nova"):
		_nova_cooldown = maxf(0.0, _nova_cooldown - delta)
		if _nova_cooldown <= 0.0:
			_trigger_nova_pulse(false)
			_nova_cooldown = maxf(3.0, 5.4 - float(nova_level) * 0.75) * (0.8 if evo("nova") >= 1 else 1.0)
		if _nova_echo_t >= 0.0:
			_nova_echo_t -= delta
			if _nova_echo_t < 0.0:
				_trigger_nova_pulse(false, true)

	_update_run_perks(delta, fire_pressed)

	queue_redraw()


# Ticks the timed DRAFT CARD perks (aura, orbital strike, mines) and the enemy-bullet
# perks (chrono field slow, graze XP). Called every frame while the ship is flying.
func _update_run_perks(delta: float, fire_pressed: bool) -> void:
	if aura_level > 0:
		_aura_timer -= delta
		if _aura_timer <= 0.0:
			_aura_timer = 0.35
			_pulse_ion_aura()

	if orbital_level > 0:
		_orbital_timer -= delta
		if _orbital_timer <= 0.0:
			_orbital_timer = 5.8 - 0.8 * float(orbital_level)
			_fire_orbital_strike()

	if mines_level > 0:
		_mine_timer = maxf(0.0, _mine_timer - delta)
		if fire_pressed and _mine_timer <= 0.0:
			_drop_proximity_mine()
			_mine_timer = 2.9 - 0.5 * float(mines_level)

	if (chrono_level > 0 or graze_level > 0) and bullet_container != null:
		var chrono_r: float = 40.0 + 16.0 * float(chrono_level)
		var chrono_r2: float = chrono_r * chrono_r
		var slow: float = 0.55 - 0.15 * float(chrono_level - 1)
		for child: Node in bullet_container.get_children():
			if not (child is GameBullet):
				continue
			var gb: GameBullet = child as GameBullet
			if gb.is_player_bullet:
				continue
			var d2: float = global_position.distance_squared_to(gb.global_position)
			if chrono_level > 0 and d2 <= chrono_r2:
				gb.slow_timer = 0.12
				gb.slow_factor = slow
			if graze_level > 0 and not gb.grazed and d2 <= 256.0 and d2 > 20.0:
				gb.grazed = true
				grazed.emit(graze_level)
				if graze_level >= 2 and shield_charges < max_shield:
					shield_regen_timer += 0.5
				if fx != null:
					fx.spawn_hit_sparks(gb.global_position, Color("#ff9624"), 2)


func _pulse_ion_aura() -> void:
	var radius: float = 30.0 + 8.0 * float(aura_level)
	var r2: float = radius * radius
	var a_dmg: float = (0.8 + 0.55 * float(aura_level)) * damage_bonus
	var zaps: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node) and node.has_method("take_damage"):
			var en: Node2D = node as Node2D
			if global_position.distance_squared_to(en.global_position) <= r2:
				if fx != null and zaps < 4:
					fx.spawn_lightning(global_position, en.global_position, Color("#d44cff"))
				zaps += 1
				en.call("take_damage", a_dmg)
	if zaps > 0:
		RetroSfx.play("zap", -19.0, 0.1)


func _fire_orbital_strike() -> void:
	var target: Node2D = null
	var best_hp: float = -1.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is GameEnemy and is_instance_valid(node):
			var ge: GameEnemy = node as GameEnemy
			if ge.global_position.x < 24.0 or ge.global_position.x > 470.0 or ge.boss_intro_active:
				continue
			if ge.hp > best_hp:
				best_hp = ge.hp
				target = ge
	if target == null:
		_orbital_timer = 0.5
		return
	var o_dmg: float = (8.0 + 5.0 * float(orbital_level)) * damage_bonus
	var hit_pos: Vector2 = target.global_position
	if fx != null:
		fx.spawn_lightning(Vector2(hit_pos.x, 22.0), hit_pos, Color("#ffe854"))
		fx.spawn_lightning(Vector2(hit_pos.x + 3.0, 22.0), hit_pos, Color.WHITE)
		fx.spawn_ring_blast(hit_pos, 22.0, Color("#ffe854"))
		fx.add_shake(1.5)
	RetroSfx.play("boss_beam", -12.0, 0.06)
	target.call("take_damage", o_dmg)


func _drop_proximity_mine() -> void:
	if bullet_container == null:
		return
	var m_dmg: float = (3.0 + 1.5 * float(mines_level)) * damage_bonus
	var b: GameBullet = _spawn_player_bullet(global_position + Vector2(-8.0, 6.0), Vector2(-16.0, 0.0), m_dmg, "bullet_mine", 0, false, 9.0)
	b.aoe_radius = 30.0 + 5.0 * float(mines_level)
	b.aoe_color = Color("#ff4c68")
	b.life_left = 7.0
	b.keep_upright = true
	b.rotation = 0.0


# Called by main when the player destroys an enemy (handles leech healing and chain reactions).
func on_enemy_killed(pos: Vector2, was_boss: bool) -> void:
	if leech_level > 0 and visible and hp > 0:
		_leech_kills += 1
		var needed: int = int([0, 45, 32, 22][leech_level])
		if _leech_kills >= needed:
			_leech_kills = 0
			if hp < max_hp:
				heal(1)
				if fx != null:
					fx.spawn_popup(global_position + Vector2(-16.0, -16.0), "LEECH +1", Color("#3ce878"))
	if chain_level > 0 and not was_boss:
		call_deferred("_chain_blast", pos)


func _chain_blast(pos: Vector2) -> void:
	var radius: float = 22.0 + 8.0 * float(chain_level)
	var r2: float = radius * radius
	var c_dmg: float = (2.5 + 1.5 * float(chain_level)) * damage_bonus
	if fx != null:
		fx.spawn_ring_blast(pos, radius, Color("#ff9624"))
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node) and node.has_method("take_damage"):
			var en: Node2D = node as Node2D
			if pos.distance_squared_to(en.global_position) <= r2:
				en.call("take_damage", c_dmg)


# Called by main at each hyperspace jump.
func on_stage_cleared() -> void:
	if last_stand_level > 0:
		last_stand_ready = true


func get_run_scrap_mult() -> float:
	return 1.0 + 0.4 * float(salvage_level)


# Mirror Shield: turns enemy shots near the ship into player shots aimed at the nearest enemy.
func _reflect_burst() -> void:
	if bullet_container == null:
		return
	var radius: float = 64.0 + 32.0 * float(reflect_level - 1)
	var r2: float = radius * radius
	var r_dmg: float = 1.6 * damage_bonus
	var reflected: int = 0
	for child: Node in bullet_container.get_children():
		if not (child is GameBullet):
			continue
		var gb: GameBullet = child as GameBullet
		if gb.is_player_bullet or gb.is_queued_for_deletion():
			continue
		if global_position.distance_squared_to(gb.global_position) > r2:
			continue
		var from_pos: Vector2 = gb.global_position
		gb.queue_free()
		var target: Node2D = _find_closest_threat()
		var dir: Vector2 = Vector2.RIGHT
		if target != null:
			dir = (target.global_position - from_pos).normalized()
		_spawn_player_bullet(from_pos, dir * 330.0, r_dmg, "bullet_dart", 0, false, 3.5)
		reflected += 1
	if reflected > 0 and fx != null:
		fx.spawn_ring_blast(global_position, radius, Color("#54f4ff"))


# Orbit radius of the blades: wider from MK II, and MK IV flings them out every few seconds.
func _blade_radius() -> float:
	var r: float = 31.0 if evo("blades") >= 1 else 25.0
	if evo("blades") >= 3:
		var phase: float = _blade_throw_t - (BLADE_THROW_PERIOD - BLADE_THROW_TIME)
		if phase > 0.0:
			r += 34.0 * sin(PI * phase / BLADE_THROW_TIME)
	return r


func _update_orbiting_blades(delta: float) -> void:
	var count: int = _active_blade_count()
	_blade_orbit_angle += delta * (4.4 + float(blade_level) * 0.45)
	_blade_dmg_timer = maxf(0.0, _blade_dmg_timer - delta)
	var deal_slice_tick: bool = (_blade_dmg_timer <= 0.0)
	if deal_slice_tick:
		_blade_dmg_timer = 0.13
	if evo("blades") >= 3:
		_blade_throw_t = fmod(_blade_throw_t + delta, BLADE_THROW_PERIOD)
	var orbit_r: float = _blade_radius()

	var slice_dmg: float = (1.35 + 0.45 * float(blade_level)) * damage_bonus * (1.35 if evo("blades") >= 1 else 1.0)

	for i: int in range(MAX_BLADES):
		var bl: Sprite2D = _blade_sprites[i]
		if i >= count:
			bl.visible = false
			continue
		bl.visible = true
		_blade_block_cd[i] = maxf(0.0, _blade_block_cd[i] - delta)
		var ang: float = _blade_orbit_angle + TAU * float(i) / float(count)
		var b_pos: Vector2 = global_position + Vector2(cos(ang), sin(ang)) * orbit_r
		bl.global_position = b_pos
		bl.rotation += delta * 14.0

		if not controls_enabled:
			continue

		if deal_slice_tick:
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				if node is Node2D and is_instance_valid(node) and node.has_method("take_damage"):
					var en: Node2D = node as Node2D
					var hit_r: float = 48.0 if (en is GameEnemy and (en as GameEnemy).enemy_type == GameEnemy.Type.BOSS) else 14.0
					if b_pos.distance_to(en.global_position) <= hit_r:
						en.call("take_damage", slice_dmg)
						if fx != null:
							fx.spawn_hit_sparks(b_pos, Color("#28e8ff"), 3)

		if _blade_block_cd[i] <= 0.0 and bullet_container != null:
			for child: Node in bullet_container.get_children():
				if child is GameBullet:
					var gb: GameBullet = child as GameBullet
					if not gb.is_player_bullet and b_pos.distance_squared_to(gb.global_position) <= 95.0:
						_blade_block_cd[i] = 0.85
						if fx != null:
							fx.spawn_hit_sparks(gb.global_position, Color("#28e8ff"), 5)
						RetroSfx.play("shield_hit", -14.0, 0.08)
						gb.queue_free()
						if evo("blades") >= 2:
							# MK III: the blocked shot flies back at the nearest enemy.
							var tgt: Node2D = _find_closest_threat()
							var back_dir: Vector2 = (tgt.global_position - b_pos).normalized() if tgt != null else Vector2.RIGHT
							_spawn_player_bullet(b_pos, back_dir * 340.0, slice_dmg, "bullet_shard", 0, false, 3.0)
						break


# The trail is a breadcrumb every TRAIL_STEP_DIST px of travel, so options trail by distance
# flown whatever the frame rate. Measure from the last breadcrumb, never drag it along: at
# 120 Hz (or in focus mode) one frame moves the ship less than TRAIL_STEP_DIST, and dragging
# the newest point every frame meant no new point was ever added, so the options froze.
func _record_trail_and_options(delta: float) -> void:
	if _trail.is_empty():
		return
	if global_position.distance_to(_trail[0]) >= TRAIL_STEP_DIST:
		_trail.push_front(global_position)
		if _trail.size() > TRAIL_MAX_POINTS:
			_trail.pop_back()

	for i: int in range(_live_option_count()):
		var opt: Sprite2D = _option_sprites[i]
		opt.visible = true
		var idx: int = mini(_trail.size() - 1, (i + 1) * OPTION_TRAIL_SPACING)
		opt.global_position = opt.global_position.lerp(_trail[idx], clampf(22.0 * delta, 0.0, 1.0))
		var pulse: float = 0.92 + 0.12 * sin(Time.get_ticks_msec() * 0.015 + float(i))
		opt.scale = Vector2(pulse, pulse)
		if evo("option") >= 3:
			_option_guard(i, delta)


# MK IV options: each option swats an enemy shot that touches it, then needs a moment.
func _option_guard(i: int, delta: float) -> void:
	_option_block_cd[i] = maxf(0.0, _option_block_cd[i] - delta)
	if _option_block_cd[i] > 0.0 or bullet_container == null:
		return
	var o_pos: Vector2 = _option_sprites[i].global_position
	for child: Node in bullet_container.get_children():
		if child is GameBullet:
			var gb: GameBullet = child as GameBullet
			if not gb.is_player_bullet and o_pos.distance_squared_to(gb.global_position) <= 80.0:
				_option_block_cd[i] = 0.7
				if fx != null:
					fx.spawn_hit_sparks(gb.global_position, Color("#54f4ff"), 5)
				RetroSfx.play("shield_hit", -15.0, 0.08)
				gb.queue_free()
				return


func _toggle_autofire() -> void:
	auto_fire_toggle = not auto_fire_toggle
	if fx != null:
		fx.spawn_popup(global_position + Vector2(-18.0, -14.0), "AUTOFIRE ON" if auto_fire_toggle else "AUTOFIRE OFF", Color("#28e8ff"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.physical_keycode == KEY_C and controls_enabled:
			_toggle_autofire()
			return
		if ke.pressed and not ke.echo and ke.physical_keycode == KEY_E and controls_enabled and visible:
			swap_sub_weapon()
			return
	if event is InputEventJoypadButton:
		var jb: InputEventJoypadButton = event as InputEventJoypadButton
		if jb.pressed and jb.button_index == JOY_BUTTON_B and controls_enabled and visible:
			swap_sub_weapon()
			return

	if not controls_enabled or not visible or MetaSave.touch_mode == 2:
		return

	if event is InputEventScreenTouch:
		var te: InputEventScreenTouch = event as InputEventScreenTouch
		if not touch_detected:
			touch_detected = true
			touch_state_changed.emit()
		if te.pressed and _touch_drag_idx == -1 and _is_in_touch_playfield(te.position):
			_touch_drag_idx = te.index
			_touch_origin = te.position
			_touch_current = te.position
		elif not te.pressed and te.index == _touch_drag_idx:
			_touch_drag_idx = -1

	elif event is InputEventScreenDrag:
		var de: InputEventScreenDrag = event as InputEventScreenDrag
		if de.index == _touch_drag_idx:
			_touch_current = de.position
			var mult: float = 0.62 if _focus_held else 1.18
			global_position.x = clampf(global_position.x + de.relative.x * mult, MIN_X, MAX_X)
			global_position.y = clampf(global_position.y + de.relative.y * mult, MIN_Y, MAX_Y)

	elif MetaSave.touch_mode == 1 and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _is_in_touch_playfield(mb.position):
				_mouse_drag_sim = true
				_touch_origin = mb.position
				_touch_current = mb.position
			elif not mb.pressed:
				_mouse_drag_sim = false
	elif MetaSave.touch_mode == 1 and _mouse_drag_sim and event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_touch_current = mm.position
		var mult2: float = 0.62 if _focus_held else 1.18
		global_position.x = clampf(global_position.x + mm.relative.x * mult2, MIN_X, MAX_X)
		global_position.y = clampf(global_position.y + mm.relative.y * mult2, MIN_Y, MAX_Y)


func _is_in_touch_playfield(pos: Vector2) -> bool:
	if pos.y < 23.0 or pos.y > 264.0:
		return false
	if Rect2(410.0, 224.0, 66.0, 38.0).has_point(pos):
		return false
	# The touch SWAP button above FOCUS (main.touch_swap_btn).
	if Rect2(410.0, 192.0, 66.0, 32.0).has_point(pos):
		return false
	return true


func _get_mode_params(mode: String, rank: int) -> Dictionary:
	match mode:
		"laser":
			return {"tex": "bullet_laser", "spd": 435.0, "pierce": rank, "dmg": 1.32 + 0.34 * float(rank - 1), "cd": 0.160, "sfx": "laser"}
		"wave":
			return {"tex": "bullet_wave", "spd": 315.0, "pierce": 1 + rank / 2, "dmg": 1.25 + 0.30 * float(rank - 1), "cd": 0.172, "sfx": "laser"}
		"prism":
			return {"tex": "bullet_prism", "spd": 335.0, "pierce": 1 + rank, "dmg": 1.18 + 0.28 * float(rank - 1), "cd": 0.168, "sfx": "shoot"}
		"tesla":
			return {"tex": "bullet_tesla", "spd": 395.0, "pierce": 0, "dmg": 1.22 + 0.28 * float(rank - 1), "cd": 0.164, "sfx": "zap"}
		"plasma":
			return {"tex": "bullet_plasma", "spd": 278.0, "pierce": 0, "dmg": 1.68 + 0.42 * float(rank - 1), "cd": 0.210, "sfx": "missile"}
		"biowave":
			return {"tex": "bullet_biowave", "spd": 305.0, "pierce": 1 + rank / 2, "dmg": 1.34 + 0.32 * float(rank - 1), "cd": 0.170, "sfx": "laser"}
		"rail":
			return {"tex": "bullet_rail", "spd": 520.0, "pierce": 2 + rank, "dmg": 1.46 + 0.36 * float(rank - 1), "cd": 0.175, "sfx": "laser"}
		"flak":
			return {"tex": "bullet_flak", "spd": 288.0, "pierce": 0, "dmg": 1.60 + 0.38 * float(rank - 1), "cd": 0.205, "sfx": "missile"}
		"saucer":
			return {"tex": "bullet_ufo_ring", "spd": 320.0, "pierce": 1 + rank, "dmg": 1.24 + 0.28 * float(rank - 1), "cd": 0.168, "sfx": "shoot"}
		"ocular":
			return {"tex": "bullet_eyeball", "spd": 310.0, "pierce": 0, "dmg": 1.26 + 0.28 * float(rank - 1), "cd": 0.168, "sfx": "zap"}
		"cat":
			# A little slower than the other blasters so the cats stay readable in flight; the
			# damage is nudged up (was 1.35 + 0.32/rank at 318 px/s) to make up for it.
			return {"tex": "bullet_cat_0", "spd": 272.0, "pierce": 2 + rank / 2, "dmg": 1.42 + 0.34 * float(rank - 1), "cd": 0.172, "sfx": "shoot"}
		# --- Hangar-expansion ships (dmg per beam tick / slash / lash / pellet / petal) ---
		"lance":
			return {"tex": "bullet_lance", "spd": 400.0, "pierce": 0, "dmg": 0.76 + 0.18 * float(rank - 1), "cd": 0.09, "sfx": ""}
		"katana":
			return {"tex": "bullet_slash", "spd": 300.0, "pierce": 0, "dmg": 2.6 + 0.62 * float(rank - 1), "cd": 0.30, "sfx": ""}
		"slashwave":
			return {"tex": "bullet_slash", "spd": 330.0, "pierce": 1, "dmg": 1.5 + 0.36 * float(rank - 1), "cd": 0.30, "sfx": ""}
		"seed":
			return {"tex": "bullet_seedpod_0", "spd": 18.0, "pierce": 0, "dmg": 0.62 + 0.15 * float(rank - 1), "cd": 0.30, "sfx": ""}
		"petal":
			return {"tex": "bullet_petal", "spd": 300.0, "pierce": 0, "dmg": 0.62 + 0.15 * float(rank - 1), "cd": 0.30, "sfx": "shoot"}
		"sonar":
			return {"tex": "bullet_sonar", "spd": 230.0, "pierce": 99, "dmg": 2.2 + 0.52 * float(rank - 1), "cd": 0.30, "sfx": "laser"}
		"scatter":
			return {"tex": "bullet_pellet", "spd": 340.0, "pierce": 0, "dmg": 0.6 + 0.15 * float(rank - 1), "cd": 0.36, "sfx": "missile"}
		"firework":
			return {"tex": "bullet_rocket", "spd": 250.0, "pierce": 0, "dmg": 3.0 + 0.7 * float(rank - 1), "cd": 0.40, "sfx": "missile"}
		"orb":
			return {"tex": "bullet_orb_0", "spd": 120.0, "pierce": 99, "dmg": 1.15 + 0.28 * float(rank - 1), "cd": 0.75, "sfx": "zap"}
		"comet":
			return {"tex": "bullet_comet", "spd": 380.0, "pierce": 3, "dmg": 5.8 + 1.4 * float(rank - 1), "cd": COMET_CHARGE_TIME, "sfx": "laser"}
		"orbit":
			return {"tex": "bullet_twin", "spd": 380.0, "pierce": 0, "dmg": 1.02 + 0.24 * float(rank - 1), "cd": 0.16, "sfx": "shoot"}
		"tongue":
			return {"tex": "bullet_tongue", "spd": 300.0, "pierce": 0, "dmg": 2.3 + 0.55 * float(rank - 1), "cd": 0.26, "sfx": ""}
		"spit":
			return {"tex": "bullet_spit", "spd": 320.0, "pierce": 0, "dmg": 1.1 + 0.26 * float(rank - 1), "cd": 0.26, "sfx": ""}
		_:
			return {"tex": "bullet_vulcan", "spd": 355.0, "pierce": 0, "dmg": 1.0 + 0.24 * float(rank - 1), "cd": 0.148, "sfx": "shoot"}


func _fire_primary() -> float:
	if bullet_container == null:
		return 0.15

	# GEMINI TWINS fire from their two orbiting pods instead of the nose.
	var ship_emitters: Array[Vector2] = [global_position + Vector2(12.0, 0.0)]
	if active_beam == "orbit":
		ship_emitters.clear()
		for pod: Sprite2D in _orbit_pods:
			ship_emitters.append(pod.global_position + Vector2(4.0, 0.0))
	var emitters: Array[Vector2] = ship_emitters.duplicate()
	for i: int in range(_live_option_count()):
		emitters.append(_option_sprites[i].global_position + Vector2(6.0, 0.0))

	_wave_flip = not _wave_flip
	_volley_count += 1
	var eff_rank: int = maxi(1, beam_level if (signature_weapon == "vulcan" and active_beam != "vulcan") else (1 + weapon_overclock))
	if signature_weapon == "vulcan" and active_beam != "vulcan":
		eff_rank = beam_level + weapon_overclock

	var p: Dictionary = _get_mode_params(active_beam, eff_rank)
	var interval: float = float(p["cd"])
	var sfx_key: String = String(p["sfx"])
	var opt_mode: String = _option_mode(active_beam)
	var op: Dictionary = p if opt_mode == active_beam else _get_mode_params(opt_mode, eff_rank)
	var power: float = _comet_power if active_beam == "comet" else 1.0

	for e_idx: int in range(emitters.size()):
		var origin: Vector2 = emitters[e_idx]
		var is_ship: bool = e_idx < ship_emitters.size()
		var mul: float = 1.0 if is_ship else (0.85 if evo("option") >= 1 else 0.65)
		var mode: String = active_beam if is_ship else opt_mode
		var mp: Dictionary = p if is_ship else op
		var tex_key: String = String(mp["tex"])
		var speed: float = float(mp["spd"])
		var pierce: int = int(mp["pierce"]) + (1 if not is_ship and evo("option") >= 2 else 0)
		var dmg: float = float(mp["dmg"]) * damage_bonus * power
		_cur_emitter_src = -1 if is_ship else e_idx - ship_emitters.size()

		if is_ship and SELF_AIMED_WEAPONS.has(mode):
			# Seed sentries are planted every 2nd volley; the pods do the shooting.
			if mode != "seed" or _volley_count % 2 == 0:
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0), dmg, tex_key, pierce, 1.0)
			continue

		if spread_level == 0:
			if mode == "prism" or mode == "cat" or mode == "saucer":
				var diag: float = 0.12 if _wave_flip else -0.12
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(diag), dmg * mul, tex_key, pierce, 1.0)
			elif (mode == "wave" or mode == "biowave") and eff_rank >= 2:
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.68 * mul, tex_key, pierce, 1.0)
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.68 * mul, tex_key, pierce, -1.0)
			else:
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0), dmg * mul, tex_key, pierce, 1.0 if _wave_flip else -1.0)
		elif spread_level == 1:
			var fan1: float = 0.09 if (mode == "prism" or mode == "cat" or mode == "saucer") else 0.0
			_spawn_mode_shot(mode, eff_rank, origin + Vector2(0.0, -3.5), Vector2(speed, 0.0).rotated(-fan1), dmg * 0.78 * mul, tex_key, pierce, 1.0)
			_spawn_mode_shot(mode, eff_rank, origin + Vector2(0.0, 3.5), Vector2(speed, 0.0).rotated(fan1), dmg * 0.78 * mul, tex_key, pierce, -1.0)
		elif spread_level == 2:
			_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.85 * mul, tex_key, pierce, 1.0 if _wave_flip else -1.0)
			_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.18), dmg * 0.68 * mul, tex_key, pierce, 1.0)
			_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(0.18), dmg * 0.68 * mul, tex_key, pierce, -1.0)
		else:
			_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0), dmg * 0.85 * mul, tex_key, pierce, 1.0 if _wave_flip else -1.0)
			if is_ship:
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.15), dmg * 0.62, tex_key, pierce, 1.0)
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(0.15), dmg * 0.62, tex_key, pierce, -1.0)
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.32), dmg * 0.55, tex_key, pierce, 1.0)
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(0.32), dmg * 0.55, tex_key, pierce, -1.0)
			else:
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(-0.17), dmg * 0.55 * mul, tex_key, pierce, 1.0)
				_spawn_mode_shot(mode, eff_rank, origin, Vector2(speed, 0.0).rotated(0.17), dmg * 0.55 * mul, tex_key, pierce, -1.0)
	_cur_emitter_src = -1

	# Co-Axial Aux Tech Beam on the original Exotic Ships: every 2nd volley also fires the drafted
	# Elemental/Tech Beam (the newer ships fire it on a timer, see _process).
	if is_sub_active("beam") and VOLLEY_AUX_WEAPONS.has(signature_weapon) and ((_volley_count % 3 != 0) if evo("beam") >= 2 else (_volley_count % 2 == 0)):
		_fire_aux_beam()

	if active_beam == "cat" and (_volley_count % 5 == 1):
		RetroSfx.play("meow", -14.0, 0.08)
	elif sfx_key != "":
		RetroSfx.play(sfx_key, -15.5 if sfx_key == "zap" else -12.5, 0.05)
	return interval


func _fire_aux_beam() -> void:
	var ap: Dictionary = _get_mode_params(aux_beam, maxi(1, beam_level))
	var dmg: float = float(ap["dmg"]) * damage_bonus * (1.06 if evo("beam") >= 1 else 0.85)
	# MK IV: twin beams, one either side of the nose.
	var offsets: Array[float] = [0.0]
	if evo("beam") >= 3:
		offsets = [-4.0, 4.0]
	for oy: float in offsets:
		_spawn_mode_shot(
			aux_beam,
			maxi(1, beam_level),
			global_position + Vector2(12.0, oy),
			Vector2(float(ap["spd"]), 0.0),
			dmg,
			String(ap["tex"]),
			int(ap["pierce"]),
			1.0 if _wave_flip else -1.0
		)


# What the options fire when the ship's own weapon only works from the hull.
func _option_mode(mode: String) -> String:
	match mode:
		"katana":
			return "slashwave"
		"seed":
			return "petal"
		"tongue":
			return "spit"
	return mode


func _spawn_mode_shot(mode: String, rank: int, pos: Vector2, vel: Vector2, dmg: float, tex_key: String, pierce: int, w_sign: float) -> GameBullet:
	# Weapons that hit without a bullet of their own (they return null), or plant / scatter.
	match mode:
		"lance":
			_fire_lance(pos, vel.normalized(), dmg)
			return null
		"katana":
			_katana_slash(dmg, rank)
			return null
		"tongue":
			_tongue_lash(pos, dmg, rank)
			return null
		"seed":
			return _plant_seed(pos, dmg)
		"scatter":
			return _fire_scatter(pos, vel, dmg, tex_key, rank)

	var hit_r: float = 5.0 if (mode == "wave" or mode == "biowave" or mode == "plasma") else 3.2
	var shot_tex: String = tex_key
	var cat_coat: String = ""
	if mode == "cat":
		# The cats take turns by coat (orange tabby, snow white, blue tabby).
		cat_coat = CAT_SHOT_COATS[_cat_coat_idx]
		_cat_coat_idx = (_cat_coat_idx + 1) % CAT_SHOT_COATS.size()
		shot_tex = cat_coat + "_0"
		hit_r = 6.0
	elif mode == "sonar" or mode == "orb" or mode == "comet":
		hit_r = 5.0
	var is_ocular: bool = (mode == "ocular")
	var b: GameBullet = _spawn_player_bullet(pos, vel, dmg, shot_tex, pierce, is_ocular, hit_r)
	if is_ocular:
		b.homing_turn_rate = 2.8
		b.keep_upright = true
		b.chain_count = 1 + rank / 2

	match mode:
		"wave":
			b.wave_amp = 13.0 + float(rank) * 3.0
			b.wave_freq = 16.5
			b.wave_sign = w_sign
		"biowave":
			b.wave_amp = 11.0 + float(rank) * 2.5
			b.wave_freq = 13.5
			b.wave_sign = w_sign
			if rank >= 3:
				b.aoe_radius = 15.0 * aoe_scale_mult
				b.aoe_color = Color("#3ce878")
		"prism":
			b.spark_color = Color("#ff4cd4")
		"saucer":
			b.spark_color = Color("#6eff8c")
			b.wave_amp = 8.0
			b.wave_freq = 14.0
			b.wave_sign = w_sign
		"tesla":
			b.chain_count = rank
		"plasma":
			b.aoe_radius = (22.0 + float(rank) * 5.0) * aoe_scale_mult
			b.aoe_color = Color("#ff6820")
		"flak":
			b.aoe_radius = (26.0 + float(rank) * 5.0) * aoe_scale_mult
			b.aoe_color = Color("#ff9624")
		"cat":
			b.anim_tex_b = cat_coat + "_1"
			b.keep_upright = true
			b.is_cat_shot = true
			# Just a gentle paddling bob: a big wobble smeared the cat shape at full speed.
			b.wave_amp = 2.0
			b.wave_freq = 9.0
			b.wave_sign = w_sign
		"sonar":
			# Ripples widen as they travel and pass through everything.
			b.grow_rate = 2.0
			b.grow_max = 2.6
			b.spark_color = Color("#54f4ff")
		"firework":
			b.star_burst_time = 0.5
			b.star_burst_count = 7
			b.star_burst_spread = 0.42 + 0.02 * float(rank)
			b.star_burst_dmg = dmg * 0.34
			b.trail_color = Color("#ffe854")
			b.spark_color = Color("#ff4ca8")
		"orb":
			b.aura_radius = (18.0 + 1.5 * float(rank)) * aoe_scale_mult
			b.aura_dmg = dmg * 0.42
			b.eats_shots = true
			b.life_left = 3.0
			b.fade_out = true
			b.anim_tex_b = "bullet_orb_1"
			b.keep_upright = true
			b.rotation = 0.0
			b.spark_color = Color("#d44cff")
		"comet":
			# Size and punch-through grow with the charge (_comet_power).
			b.scale_body(0.55 + 0.75 * _comet_power)
			b.pierce_left = int(round(float(pierce) * _comet_power))
			b.trail_color = Color("#9cf4ff")
			b.spark_color = Color("#28e8ff")
		"orbit":
			b.spark_color = Color("#ff9ce0")
		"slashwave", "spit":
			b.life_left = 0.5
			b.fade_out = true
	_apply_main_gun_mods(b)
	return b


# Seeker Rounds and Shrapnel Burst, for every main-gun shot.
func _apply_main_gun_mods(b: GameBullet) -> void:
	if homing_level > 0 and not b.is_homing:
		b.is_homing = true
		b.homing_trail = false
		b.homing_turn_rate = 1.6 + 1.6 * float(homing_level - 1)
		# Curving shots could otherwise circle the screen indefinitely.
		b.life_left = 2.2 if b.life_left <= 0.0 else minf(b.life_left, 2.2)
	if shrapnel_level > 0:
		b.split_count = 1 + shrapnel_level


# --- Hangar-expansion signature weapons that hit without bullets ------------------------------

# Damage dealt straight to an enemy (beam, katana, tongue), with the same crit, berserk and
# DRAFT CARD on-hit effects a main-gun bullet gets.
func _direct_hit(en: Node2D, base_dmg: float) -> void:
	var crit: bool = crit_chance > 0.0 and randf() < crit_chance
	var dmg: float = _shot_damage(base_dmg, crit)
	if en is GameEnemy:
		var ge: GameEnemy = en as GameEnemy
		if ambush_level > 0 and ge.hp >= ge.max_hp:
			dmg *= 1.0 + 0.75 * float(ambush_level)
		if cryo_level > 0:
			ge.apply_chill(0.6 + 0.6 * float(cryo_level), 0.6 - 0.15 * float(cryo_level - 1))
		if napalm_level > 0:
			ge.apply_burn((1.6 + 1.2 * float(napalm_level - 1)) * damage_bonus, 2.0)
		var exec_frac: float = 0.08 + 0.12 * float(execute_level)
		if execute_level > 0 and ge.enemy_type != GameEnemy.Type.BOSS and ge.hp - dmg > 0.0 and ge.hp - dmg <= ge.max_hp * exec_frac:
			dmg = ge.hp + 1.0
	en.call("take_damage", dmg)
	if crit and fx != null:
		fx.spawn_hit_sparks(en.global_position, Color(1.0, 0.96, 0.65), 4)


# Distance along the ray from o in direction d (unit) to where it first touches box, or -1 if it
# misses within max_t. 0 if o is already inside.
static func _ray_box_t(o: Vector2, d: Vector2, box: Rect2, max_t: float) -> float:
	var t0: float = 0.0
	var t1: float = max_t
	for axis: int in range(2):
		var oa: float = o.x if axis == 0 else o.y
		var da: float = d.x if axis == 0 else d.y
		var lo: float = box.position.x if axis == 0 else box.position.y
		var hi: float = box.end.x if axis == 0 else box.end.y
		if absf(da) < 0.00001:
			if oa < lo or oa > hi:
				return -1.0
			continue
		var ta: float = (lo - oa) / da
		var tb: float = (hi - oa) / da
		if ta > tb:
			var sw: float = ta
			ta = tb
			tb = sw
		t0 = maxf(t0, ta)
		t1 = minf(t1, tb)
		if t0 > t1:
			return -1.0
	return t0


# Distance from o (inside BEAM_AREA) along d to the screen edge.
static func _beam_reach(o: Vector2, d: Vector2) -> float:
	var reach: float = 9999.0
	if d.x > 0.00001:
		reach = minf(reach, (BEAM_AREA.end.x - o.x) / d.x)
	elif d.x < -0.00001:
		reach = minf(reach, (BEAM_AREA.position.x - o.x) / d.x)
	if d.y > 0.00001:
		reach = minf(reach, (BEAM_AREA.end.y - o.y) / d.y)
	elif d.y < -0.00001:
		reach = minf(reach, (BEAM_AREA.position.y - o.y) / d.y)
	return maxf(0.0, reach)


# HELIOS LANCER: a solar beam to the first enemy in its line, or to the screen edge. Fired every
# 0.1 s; each tick hurts that one enemy and refreshes the drawn beam.
func _fire_lance(origin: Vector2, dir: Vector2, dmg: float) -> void:
	var reach: float = _beam_reach(origin, dir)
	var best: Node2D = null
	var best_t: float = reach
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not (node is Node2D) or not is_instance_valid(node) or not node.has_method("take_damage"):
			continue
		var en: Node2D = node as Node2D
		var t: float = _ray_box_t(origin, dir, GameBullet.enemy_hit_box(en).grow(LANCE_HALF_WIDTH), best_t)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = en
	if best != null:
		_direct_hit(best, dmg)
		if fx != null and randf() < 0.5:
			fx.spawn_hit_sparks(origin + dir * best_t, Color("#ffe854"), 2)
	_lance_fx.append({"src": _cur_emitter_src, "dir": dir, "len": best_t, "hit": best != null, "t": LANCE_FX_TIME})


# RONIN-7: a photon-katana slash around the nose. Hurts every enemy in the arc and cuts enemy
# shots out of the air. Spread draws a wider, longer cut that hits harder (still one hit each).
func _katana_slash(dmg: float, rank: int) -> void:
	var radius: float = 44.0 + 3.0 * float(rank) + 7.0 * float(spread_level)
	var half_arc: float = 1.1 + 0.12 * float(spread_level)
	var spread_mult: float = 1.0 + 0.18 * float(spread_level)
	var center: Vector2 = global_position + Vector2(2.0, 0.0)
	var hits: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not (node is Node2D) or not is_instance_valid(node) or not node.has_method("take_damage"):
			continue
		var en: Node2D = node as Node2D
		var box: Rect2 = GameBullet.enemy_hit_box(en)
		var near: Vector2 = Vector2(clampf(center.x, box.position.x, box.end.x), clampf(center.y, box.position.y, box.end.y))
		var off: Vector2 = near - center
		if off.length() > radius or (off.length() > 6.0 and absf(off.angle()) > half_arc):
			continue
		_direct_hit(en, dmg * spread_mult)
		hits += 1
		if fx != null:
			fx.spawn_hit_sparks(near, Color("#ff4ca8"), 3)
	if bullet_container != null:
		for child: Node in bullet_container.get_children():
			if child is GameBullet:
				var gb: GameBullet = child as GameBullet
				if gb.is_player_bullet or gb.is_queued_for_deletion():
					continue
				var b_off: Vector2 = gb.global_position - center
				if b_off.length() <= radius and absf(b_off.angle()) <= half_arc:
					if fx != null:
						fx.spawn_hit_sparks(gb.global_position, Color.WHITE, 2)
					gb.queue_free()
	_slash_flip = not _slash_flip
	_slash_fx.append({"t": SLASH_FX_TIME, "r": radius, "arc": half_arc, "flip": _slash_flip})
	RetroSfx.play("laser" if hits == 0 else "hit", -13.0, 0.12)


# LEAPFROG: the tongue snaps at the nearest enemy ahead within reach (spread adds more targets,
# each further one at 70%). With nothing in reach it just flicks out.
func _tongue_lash(origin: Vector2, dmg: float, rank: int) -> void:
	var reach: float = 140.0 + 8.0 * float(rank)
	var found: Array[Dictionary] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not (node is Node2D) or not is_instance_valid(node) or not node.has_method("take_damage"):
			continue
		var en: Node2D = node as Node2D
		var box: Rect2 = GameBullet.enemy_hit_box(en)
		if box.end.x < origin.x - 4.0:
			continue
		var near: Vector2 = Vector2(clampf(origin.x, box.position.x, box.end.x), clampf(origin.y, box.position.y, box.end.y))
		var d: float = near.distance_to(origin)
		if d <= reach:
			found.append({"en": en, "d": d, "at": near})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	var count: int = mini(found.size(), 1 + spread_level)
	for i: int in range(count):
		var tgt: Dictionary = found[i]
		_direct_hit(tgt["en"] as Node2D, dmg * (1.0 if i == 0 else 0.7))
		_tongue_fx.append({"to": Vector2(tgt["at"]), "t": TONGUE_FX_TIME})
		if fx != null:
			fx.spawn_hit_sparks(Vector2(tgt["at"]), Color("#ff6fa8"), 3)
	if count == 0:
		_tongue_fx.append({"to": origin + Vector2(reach * 0.45, 0.0), "t": TONGUE_FX_TIME})
	RetroSfx.play("bounce", -15.0 if count > 0 else -19.0, 0.15)


# STARBLOOM: plants a seed sentry that hovers ahead of the ship and fires petals (fire_sentry).
# At most SENTRY_CAP live at once; planting another wilts the oldest.
func _plant_seed(origin: Vector2, dmg: float) -> GameBullet:
	var alive: Array[GameBullet] = []
	for pod: GameBullet in _sentries:
		if is_instance_valid(pod) and not pod.is_queued_for_deletion():
			alive.append(pod)
	_sentries = alive
	while _sentries.size() >= SENTRY_CAP:
		var oldest: GameBullet = _sentries.pop_front()
		if fx != null:
			fx.spawn_hit_sparks(oldest.global_position, Color("#3ce878"), 3)
		oldest.queue_free()
	var pod: GameBullet = _spawn_player_bullet(origin + Vector2(2.0, 0.0), Vector2(18.0, 0.0), 0.0, "bullet_seedpod_0", 0, false, 4.0, false)
	pod.collision_mask = 0
	pod.anim_tex_b = "bullet_seedpod_1"
	pod.keep_upright = true
	pod.rotation = 0.0
	pod.life_left = 2.8
	pod.fade_out = true
	pod.sentry_owner = self
	pod.sentry_interval = 0.30
	pod.sentry_timer = 0.08
	pod.sentry_dmg = dmg
	_sentries.append(pod)
	RetroSfx.play("powerup", -20.0, 0.1)
	return pod


# A seed sentry's petal volley (called by the pod). Spread fans the petals like a main gun.
func fire_sentry(pod: GameBullet) -> void:
	if bullet_container == null or not visible:
		return
	var p: Dictionary = _get_mode_params("petal", 1)
	var spd: float = float(p["spd"])
	var at: Vector2 = pod.global_position + Vector2(5.0, 0.0)
	var fan: Array[Vector3] = [Vector3(0.0, 0.0, 1.0)]
	if spread_level == 1:
		fan = [Vector3(-3.5, 0.0, 0.78), Vector3(3.5, 0.0, 0.78)]
	elif spread_level == 2:
		fan = [Vector3(0.0, 0.0, 0.85), Vector3(0.0, -0.18, 0.68), Vector3(0.0, 0.18, 0.68)]
	elif spread_level >= 3:
		fan = [Vector3(0.0, 0.0, 0.85), Vector3(0.0, -0.15, 0.62), Vector3(0.0, 0.15, 0.62), Vector3(0.0, -0.32, 0.55), Vector3(0.0, 0.32, 0.55)]
	for f: Vector3 in fan:
		_spawn_mode_shot("petal", 1, at + Vector2(0.0, f.x), Vector2(spd, 0.0).rotated(f.y), pod.sentry_dmg * f.z, String(p["tex"]), 0, 1.0)


# WARHOG: a shotgun blast of pellets that spread out and fade after a short range.
func _fire_scatter(origin: Vector2, vel: Vector2, dmg: float, tex_key: String, rank: int) -> GameBullet:
	var first: GameBullet = null
	for i: int in range(6):
		var ang: float = 0.0 if i == 0 else randf_range(-0.22, 0.22)
		var v: Vector2 = vel.rotated(ang) * (1.0 if i == 0 else randf_range(0.82, 1.12))
		var b: GameBullet = _spawn_player_bullet(origin, v, dmg, tex_key, 0, false, 3.0)
		b.life_left = 0.40 + 0.02 * float(rank)
		b.fade_out = true
		b.fade_time = 0.1
		b.spark_color = Color("#ffb070")
		_apply_main_gun_mods(b)
		if first == null:
			first = b
	if fx != null:
		fx.spawn_hit_sparks(origin + Vector2(3.0, 0.0), Color("#ffe854"), 3) # muzzle flash
	return first


# COMET KNIGHT: holding fire charges the cannon (autofire holds it for you); a full charge fires
# by itself, and letting go early fires a smaller comet.
func _update_comet_charge(delta: float, fire_pressed: bool) -> void:
	if fire_pressed:
		_comet_charge = minf(1.0, _comet_charge + delta * fire_rate_bonus / COMET_CHARGE_TIME)
		if _comet_charge >= 1.0:
			_release_comet(1.0)
	elif _comet_charge >= COMET_MIN_CHARGE:
		_release_comet(_comet_charge)
	else:
		_comet_charge = 0.0


func _release_comet(power: float) -> void:
	_comet_power = power
	_fire_primary()
	_comet_power = 1.0
	_comet_charge = 0.0


# GEMINI TWINS: two gun pods circling the ship (they are the ship's emitters in _fire_primary).
func _update_orbit_pods(delta: float) -> void:
	_orbit_angle = fposmod(_orbit_angle + delta * 4.2, TAU)
	for i: int in range(_orbit_pods.size()):
		var a: float = _orbit_angle + PI * float(i)
		_orbit_pods[i].global_position = global_position + Vector2(cos(a) * 15.0, sin(a) * 17.0)


func _sync_orbit_pods() -> void:
	for pod: Sprite2D in _orbit_pods:
		pod.visible = visible and signature_weapon == "orbit"
	if signature_weapon == "orbit":
		_update_orbit_pods(0.0)


func _age_weapon_fx(delta: float) -> void:
	_age_fx_list(_lance_fx, delta)
	_age_fx_list(_slash_fx, delta)
	_age_fx_list(_tongue_fx, delta)


static func _age_fx_list(fx_list: Array[Dictionary], delta: float) -> void:
	var i: int = fx_list.size() - 1
	while i >= 0:
		var e: Dictionary = fx_list[i]
		e["t"] = float(e["t"]) - delta
		if float(e["t"]) <= 0.0:
			fx_list.remove_at(i)
		i -= 1


func _fire_missiles() -> void:
	if bullet_container == null:
		return
	var m_dmg: float = (1.85 + 0.55 * float(missile_level)) * damage_bonus
	var salvo: Array[GameBullet] = []
	salvo.append(_spawn_player_bullet(global_position + Vector2(2.0, 7.0), Vector2(145.0, 65.0), m_dmg, "bullet_missile", 0, true, 4.0))
	if missile_level >= 2:
		salvo.append(_spawn_player_bullet(global_position + Vector2(2.0, -7.0), Vector2(145.0, -65.0), m_dmg, "bullet_missile", 0, true, 4.0))
	if missile_level >= 3:
		salvo.append(_spawn_player_bullet(global_position + Vector2(-2.0, 10.0), Vector2(125.0, 105.0), m_dmg * 0.85, "bullet_missile", 0, true, 4.0))
	if missile_level >= 4:
		salvo.append(_spawn_player_bullet(global_position + Vector2(-2.0, -10.0), Vector2(125.0, -105.0), m_dmg * 0.85, "bullet_missile", 0, true, 4.0))
	if evo("missile") >= 2:
		salvo.append(_spawn_player_bullet(global_position + Vector2(6.0, 0.0), Vector2(175.0, 0.0), m_dmg, "bullet_missile", 0, true, 4.0))
	for m: GameBullet in salvo:
		if evo("missile") >= 1:
			m.aoe_radius = 20.0 * aoe_scale_mult
			m.aoe_color = Color("#ff9624")
		if evo("missile") >= 3:
			# Cluster warheads: 4 sparks on impact (or after a while in flight).
			m.star_burst_count = 4
			m.star_burst_time = 2.4
			m.star_burst_spread = 0.9
			m.star_burst_dmg = m_dmg * 0.35
	RetroSfx.play("missile", -11.5, 0.06)


func _fire_flank_guns() -> void:
	if bullet_container == null:
		return
	var f_dmg: float = (0.95 + 0.30 * float(flank_level)) * damage_bonus
	var f_pierce: int = (1 if flank_level >= 3 else 0) + (1 if evo("flank") >= 1 else 0)
	var angles: Array[float] = [PI, 2.35, -2.35]
	if flank_level >= 2:
		angles = [PI, 2.15, -2.15, 1.35, -1.35]
	if flank_level >= 3:
		angles = [PI, 2.35, -2.35, PI * 0.5, -PI * 0.5]
	for ang: float in angles:
		var dir: Vector2 = Vector2.from_angle(ang)
		var fb: GameBullet = _spawn_player_bullet(global_position + dir * 8.0, dir * 310.0, f_dmg, "bullet_flank", f_pierce, false, 3.0)
		if evo("flank") >= 3:
			fb.split_count = 2


func _find_closest_threat() -> Node2D:
	var best: Node2D = null
	var best_d2: float = 999999.0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node):
			var en: Node2D = node as Node2D
			if en.global_position.x > 6.0 and en.global_position.x < 476.0:
				var d2: float = global_position.distance_squared_to(en.global_position)
				if d2 < best_d2:
					best_d2 = d2
					best = en
	return best


func _aim_auto_turret(delta: float) -> void:
	var target: Node2D = _find_closest_threat()
	var desired: Vector2 = Vector2.RIGHT
	if target != null:
		desired = (target.global_position - (global_position + Vector2(-1.0, -6.0))).normalized()
	_turret_aim_dir = _turret_aim_dir.lerp(desired, clampf(16.0 * delta, 0.0, 1.0)).normalized()


func _fire_auto_turret() -> void:
	if bullet_container == null:
		return
	var t_dmg: float = (0.92 + 0.28 * float(turret_level)) * damage_bonus
	var muzzle: Vector2 = global_position + Vector2(-1.0, -6.0) + _turret_aim_dir * 6.0
	var t_pierce: int = (1 if turret_level >= 4 else 0) + (1 if evo("turret") >= 1 else 0)
	# MK III: a double tap (two darts a hair apart, 80% damage each).
	var dirs: Array[Vector2] = [_turret_aim_dir]
	if evo("turret") >= 2:
		dirs = [_turret_aim_dir.rotated(-0.05), _turret_aim_dir.rotated(0.05)]
		t_dmg *= 0.8
	for d: Vector2 in dirs:
		var tb: GameBullet = _spawn_player_bullet(muzzle, d * 425.0, t_dmg, "bullet_dart", t_pierce, false, 3.0)
		if evo("turret") >= 3:
			tb.split_count = 2


func _fire_gravity_bomb() -> void:
	if bullet_container == null:
		return
	var b_dmg: float = (2.8 + 0.9 * float(bomb_level)) * damage_bonus
	_drop_bomb(global_position + Vector2(0.0, 8.0), Vector2(185.0, -28.0), b_dmg)
	if evo("bomb") >= 3:
		# MK IV: a second bomb lobbed higher, so the two land apart.
		_drop_bomb(global_position + Vector2(0.0, -6.0), Vector2(150.0, -105.0), b_dmg)
	RetroSfx.play("missile", -12.0, 0.06)


func _drop_bomb(pos: Vector2, vel: Vector2, b_dmg: float) -> void:
	var b: GameBullet = _spawn_player_bullet(pos, vel, b_dmg, "bullet_bomb", 0, false, 4.5)
	b.gravity_pull = 245.0
	b.aoe_radius = (36.0 + float(bomb_level) * 9.0) * aoe_scale_mult * (1.3 if evo("bomb") >= 1 else 1.0)
	b.aoe_color = Color("#b84cff")
	b.aoe_clears_shots = evo("bomb") >= 2
	b.explode_on_floor = true


# echo: MK IV's follow-up pulse (70% damage, a little wider, never echoes again).
func _trigger_nova_pulse(reactive_burst: bool, echo: bool = false) -> void:
	var radius: float = (74.0 + float(nova_level) * 14.0) * aoe_scale_mult * (1.18 if reactive_burst else 1.0)
	var n_dmg: float = (3.2 + 1.4 * float(nova_level)) * damage_bonus
	if evo("nova") >= 1:
		radius *= 1.12
	if echo:
		radius *= 1.15
		n_dmg *= 0.7
	elif evo("nova") >= 3:
		_nova_echo_t = 0.45
	if fx != null:
		var ring_col: Color = Color("#28e8ff") if reactive_burst else Color("#ffe854")
		fx.spawn_ring_blast(global_position, radius, Color("#ff9cf0") if echo else ring_col)
		fx.add_shake(1.5 if echo else 2.5)
	RetroSfx.play("zap", -12.0 if echo else -9.0, 0.04)

	var r2: float = radius * radius
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node) and node.has_method("take_damage"):
			var en: Node2D = node as Node2D
			if global_position.distance_squared_to(en.global_position) <= r2:
				en.call("take_damage", n_dmg)
				# MK III: the pulse chills what it hits.
				if evo("nova") >= 2 and is_instance_valid(en) and en.has_method("apply_chill"):
					en.call("apply_chill", 1.5, 0.55)

	var clear_r2: float = (radius * 0.78) * (radius * 0.78)
	if bullet_container != null:
		for child: Node in bullet_container.get_children():
			if child is GameBullet:
				var gb: GameBullet = child as GameBullet
				if not gb.is_player_bullet and global_position.distance_squared_to(gb.global_position) <= clear_r2:
					if fx != null:
						fx.spawn_hit_sparks(gb.global_position, Color("#ffe854"), 3)
					gb.queue_free()


# Crit and Berserker Core applied to a hit's base damage.
func _shot_damage(dmg: float, crit: bool) -> float:
	var final_dmg: float = dmg * (crit_mult if crit else 1.0)
	if berserk_level > 0:
		var missing: int = maxi(0, max_hp - hp)
		final_dmg *= 1.0 + minf(1.0, float(missing) * (0.15 + 0.10 * float(berserk_level - 1)))
	return final_dmg


func _spawn_player_bullet(pos: Vector2, vel: Vector2, dmg: float, tex_key: String, pierce: int, homing: bool, hit_r: float = 3.0, can_crit: bool = true) -> GameBullet:
	var crit: bool = can_crit and crit_chance > 0.0 and randf() < crit_chance
	var final_dmg: float = _shot_damage(dmg, crit)
	var b: GameBullet = GameBullet.new()
	bullet_container.add_child(b)
	b.setup(pos, vel, final_dmg, true, tex_key, pierce, homing, hit_r, fx)
	b.apply_size_and_crit(proj_size_mult, crit)
	if execute_level > 0:
		b.execute_frac = 0.08 + 0.12 * float(execute_level)
	if ambush_level > 0:
		b.ambush_mult = 0.75 * float(ambush_level)
	if cryo_level > 0:
		b.chill_time = 0.6 + 0.6 * float(cryo_level)
		b.chill_factor = 0.6 - 0.15 * float(cryo_level - 1)
	if napalm_level > 0:
		b.burn_dps = (1.6 + 1.2 * float(napalm_level - 1)) * damage_bonus
	return b


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_contact_damage"):
			area.call("take_contact_damage", 4.0)
		take_player_hit()


# Frost puffs from Cryo Glacier snow drones: no damage, the ship flies slower for a moment.
func apply_frost(duration: float) -> void:
	if not visible or not controls_enabled:
		return
	if frost_timer <= 0.0 and fx != null:
		fx.spawn_hit_sparks(global_position, Color("#c8f4ff"), 4)
	frost_timer = maxf(frost_timer, duration)
	_sprite.self_modulate = Color(0.62, 0.9, 1.0)


func take_player_hit() -> void:
	if invuln_timer > 0.0 or not visible or not controls_enabled:
		return

	if is_sub_active("nova"):
		_trigger_nova_pulse(true)

	if shield_charges > 0:
		shield_charges -= 1
		shield_regen_timer = 0.0
		invuln_timer = 0.9
		RetroSfx.play("shield_hit", -6.0, 0.04)
		if fx != null:
			fx.add_shake(3.0)
			fx.spawn_hit_sparks(global_position, Color("#28e8ff"), 14)
			fx.spawn_popup(global_position + Vector2(-14.0, -14.0), "SHIELD!", Color("#28e8ff"))
		if reflect_level > 0:
			# Deferred: this runs inside a physics callback, where new Area2Ds can't be added.
			call_deferred("_reflect_burst")
		hp_changed.emit(hp, max_hp, shield_charges, max_shield)
		return

	hp = maxi(0, hp - 1)
	invuln_timer = 1.35
	shield_regen_timer = 0.0
	RetroSfx.play("player_hit", -4.0, 0.03)
	if fx != null:
		fx.add_shake(5.5)
		fx.spawn_explosion(global_position, false)

	# Lazarus Blackbox Skill Tree Keystone: Once-per-run Supernova Revive!
	if hp <= 0 and has_revive_charge:
		has_revive_charge = false
		hp = maxi(2, (max_hp + 1) / 2)
		invuln_timer = 2.4
		RetroSfx.play("unlock_ship", -4.0, 0.01)
		if fx != null:
			fx.spawn_ring_blast(global_position, 150.0, Color("#ffe854"))
			fx.add_shake(8.0)
			fx.spawn_popup(global_position + Vector2(-34.0, -18.0), "LAZARUS REVIVE!", Color("#ffe854"))
		if bullet_container != null:
			for child: Node in bullet_container.get_children():
				if child is GameBullet and not (child as GameBullet).is_player_bullet:
					child.queue_free()
		hp_changed.emit(hp, max_hp, shield_charges, max_shield)
		return

	# Last Stand draft perk: dropping to 1 hull triggers a nova, 3s invincibility and full shields.
	if hp == 1 and last_stand_level > 0 and last_stand_ready:
		last_stand_ready = false
		invuln_timer = 3.0
		shield_charges = max_shield
		shield_regen_timer = 0.0
		_trigger_nova_pulse(true)
		if fx != null:
			fx.spawn_popup(global_position + Vector2(-26.0, -18.0), "LAST STAND!", Color("#ffe854"))

	hp_changed.emit(hp, max_hp, shield_charges, max_shield)

	if hp <= 0:
		visible = false
		controls_enabled = false
		clear_touch_drag()
		set_options_hidden()
		if fx != null:
			fx.add_shake(9.0)
			fx.spawn_explosion(global_position, true)
		RetroSfx.play("big_explode", -2.0, 0.02)
		player_died.emit()


func _get_beam_nose_color() -> Color:
	var check_b: String = aux_beam if aux_beam != "" else active_beam
	match check_b:
		"laser", "rail":
			return Color("#28e8ff")
		"wave", "biowave", "saucer":
			return Color("#3ce878")
		"prism", "cat", "katana", "tongue", "seed":
			return Color("#ff4cd4")
		"tesla", "ocular", "orb":
			return Color("#b86bff")
		"plasma", "flak", "scatter", "firework":
			return Color("#ff6820")
		"sonar", "comet", "orbit":
			return Color("#54f4ff")
		_:
			return Color("#ffe854")


func _draw() -> void:
	if not visible:
		return

	# --- DRAFT CARD perk fields (drawn under the hull) ---
	if aura_level > 0:
		var a_r: float = 30.0 + 8.0 * float(aura_level)
		var a_pulse: float = 0.18 + 0.10 * sin(Time.get_ticks_msec() * 0.01)
		draw_arc(Vector2.ZERO, a_r, 0.0, TAU, 40, Color(0.83, 0.30, 1.0, a_pulse), 1.0)
	if chrono_level > 0:
		var c_r: float = 40.0 + 16.0 * float(chrono_level)
		var c_rot: float = Time.get_ticks_msec() * 0.0015
		for seg: int in range(6):
			var a0: float = c_rot + TAU * float(seg) / 6.0
			draw_arc(Vector2.ZERO, c_r, a0, a0 + 0.5, 6, Color(0.16, 0.91, 1.0, 0.22), 1.0)

	# --- Visibly Mounted Hull Addons & Active Beam Nose Barrel! ---
	if active_beam != "vulcan" or is_sub_active("beam"):
		var nose_col: Color = _get_beam_nose_color()
		draw_rect(Rect2(11.0, -2.0, 4.0, 4.0), nose_col)
		draw_rect(Rect2(12.0, -1.0, 3.0, 2.0), Color.WHITE)

	if is_sub_active("missile"):
		draw_rect(Rect2(-1.0, -9.0, 6.0, 3.0), Color("#f03c4e"))
		draw_rect(Rect2(-1.0, 6.0, 6.0, 3.0), Color("#f03c4e"))

	if is_sub_active("flank"):
		draw_rect(Rect2(-13.0, -2.0, 5.0, 4.0), Color("#8ca6d8"))
		draw_rect(Rect2(-5.0, -10.0, 4.0, 3.0), Color("#ffe854"))
		draw_rect(Rect2(-5.0, 7.0, 4.0, 3.0), Color("#ffe854"))

	if is_sub_active("bomb"):
		draw_rect(Rect2(-4.0, 6.0, 6.0, 4.0), Color("#681d94"))
		draw_circle(Vector2(-1.0, 8.0), 1.5, Color("#ff4cd4"))

	if is_sub_active("nova"):
		draw_line(Vector2(-6.0, -8.0), Vector2(-10.0, -12.0), Color("#ffe854"), 1.5)
		draw_line(Vector2(-6.0, 8.0), Vector2(-10.0, 12.0), Color("#ffe854"), 1.5)

	if is_sub_active("turret"):
		var dome_pos: Vector2 = Vector2(-1.0, -6.0)
		var local_aim: Vector2 = _turret_aim_dir.rotated(-rotation)
		draw_circle(dome_pos, 3.2, Color("#197a44"))
		draw_circle(dome_pos, 2.0, Color("#3ce878"))
		draw_line(dome_pos, dome_pos + local_aim * 6.5, Color("#dce8ff"), 1.5)

	if shield_charges > 0:
		var pulse: float = 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
		var col: Color = Color(0.16, 0.91, 1.0, pulse)
		draw_arc(Vector2(1.0, 0.0), 15.0, 0.0, TAU, 24, col, 1.0)
		if shield_charges >= 2:
			draw_arc(Vector2(1.0, 0.0), 17.5, -1.1, 1.1, 12, Color(0.55, 0.98, 1.0, pulse), 1.0)

	if _focus_held:
		draw_circle(Vector2.ZERO, 3.5, Color(0.16, 0.91, 1.0, 0.85))
		draw_circle(Vector2.ZERO, 1.8, Color.WHITE)

	_draw_signature_fx()


# Beams, katana cuts, tongue lashes and the comet charge glow of the hangar-expansion ships.
# Drawn in the ship's local space, from wherever each emitter is now, so they stay attached.
func _draw_signature_fx() -> void:
	var flick: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.06)
	for e: Dictionary in _lance_fx:
		var src: int = int(e["src"])
		var from_g: Vector2 = global_position + Vector2(12.0, 0.0)
		if src >= 0 and src < _option_sprites.size():
			from_g = _option_sprites[src].global_position + Vector2(6.0, 0.0)
		var to_g: Vector2 = from_g + Vector2(e["dir"]) * float(e["len"])
		var a: Vector2 = to_local(from_g)
		var b: Vector2 = to_local(to_g)
		var w: float = 1.0 if src >= 0 else 1.6
		draw_line(a, b, Color(1.0, 0.62, 0.15, 0.35), (4.0 + flick) * w)
		draw_line(a, b, Color("#ffe854"), 2.0 * w)
		draw_line(a, b, Color.WHITE, 1.0)
		draw_circle(a, 2.5 * w, Color("#fff4b0"))
		if bool(e["hit"]):
			draw_circle(b, (2.5 + 1.5 * flick) * w, Color(1.0, 0.9, 0.4, 0.85))
			draw_circle(b, 1.5 * w, Color.WHITE)
	for e: Dictionary in _slash_fx:
		var k: float = 1.0 - float(e["t"]) / SLASH_FX_TIME # 0 -> 1 over the cut
		var r: float = float(e["r"])
		var arc: float = float(e["arc"])
		var sweep: float = clampf(k * 1.6, 0.0, 1.0)
		var a0: float = -arc if not bool(e["flip"]) else arc
		var a1: float = lerpf(a0, -a0, sweep)
		var alpha: float = clampf(1.4 - k, 0.0, 1.0)
		var c: Vector2 = Vector2(2.0, 0.0)
		draw_arc(c, r, minf(a0, a1), maxf(a0, a1), 18, Color(1.0, 0.3, 0.66, 0.45 * alpha), 6.0)
		draw_arc(c, r - 2.0, minf(a0, a1), maxf(a0, a1), 18, Color(1.0, 0.75, 0.9, alpha), 3.0)
		draw_arc(c, r - 3.0, minf(a0, a1), maxf(a0, a1), 18, Color(1.0, 1.0, 1.0, alpha), 1.0)
	for e: Dictionary in _tongue_fx:
		var k2: float = 1.0 - float(e["t"]) / TONGUE_FX_TIME
		var reach: float = sin(PI * clampf(k2 * 1.15, 0.0, 1.0))
		var mouth: Vector2 = Vector2(12.0, 2.0)
		var tip: Vector2 = mouth.lerp(to_local(Vector2(e["to"])), reach)
		draw_line(mouth, tip, Color("#b0204e"), 3.0)
		draw_line(mouth, tip, Color("#ff6fa8"), 2.0)
		draw_circle(tip, 2.6, Color("#ff6fa8"))
		draw_circle(tip + Vector2(-0.6, -0.8), 1.0, Color("#ffd0e4"))
	if active_beam == "comet" and _comet_charge > 0.02:
		var cr: float = 1.5 + 4.5 * _comet_charge
		draw_circle(Vector2(16.0, 0.0), cr + 1.5 * flick, Color(0.3, 0.9, 1.0, 0.35))
		draw_circle(Vector2(16.0, 0.0), cr, Color("#9cf4ff"))
		draw_circle(Vector2(16.0, 0.0), cr * 0.5, Color.WHITE)
