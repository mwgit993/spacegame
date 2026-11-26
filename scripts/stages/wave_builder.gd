extends RefCounted

# Handed to a module's queue_themed_group(): queues one group of spawns for the wave director
# (main._queue_themed_group) and carries the same recipe numbers the built-in stages use.
#
#     func queue_themed_group(w: RefCounted) -> float:
#         match w.recipe:
#             0:
#                 for k: int in range(3 + w.extra):
#                     w.spawn("drone", w.t + float(k) * 0.4, Vector2(504.0, 70.0 + 60.0 * k))
#                 return 3.0
#             ...
#
# Spawn x of about 500-520 enters from the right edge. Times are absolute wave-clock seconds,
# so offset from w.t.

var idx: int = 0        # how many of the stage's own groups this wave queued before this one
var sub_wave: int = 1   # 1-3 (wave 4 is the boss)
var recipe: int = 0     # 0 or 1 in the first wave; 0, 1 or 2 from the second wave on
var extra: int = 0      # 1 in the third wave: add a unit to most recipes
var top: bool = true    # alternates per group, for mirrored layouts
var t: float = 0.0      # the group's start time
var hp_mult: float = 1.0

var _main: Node = null


func _init(main_node: Node, p_idx: int, p_sub_wave: int, p_t: float, p_hp_mult: float) -> void:
	_main = main_node
	idx = p_idx
	sub_wave = p_sub_wave
	t = p_t
	hp_mult = p_hp_mult
	var recipes: int = 3 if sub_wave >= 2 else 2
	recipe = (idx + sub_wave - 1) % recipes
	extra = 1 if sub_wave >= 3 else 0
	top = idx % 2 == 0


# One of the stage's own enemies (a kind from the module's get_enemy_defs()).
func spawn(kind: String, at: float, pos: Vector2, phase: float = 0.0, squad: int = -1, variant: int = 0) -> void:
	_main._queue_enemy(at, GameEnemy.Type.MODULE, pos, hp_mult, phase, squad, variant, kind)


# A generic enemy (GameEnemy.Type.SCOUT_SINE, SWOOPER, SNIPER or CRUISER), in this stage's skin.
func spawn_generic(type: GameEnemy.Type, at: float, pos: Vector2, phase: float = 0.0, squad: int = -1, variant: int = 0) -> void:
	_main._queue_enemy(at, type, pos, hp_mult, phase, squad, variant)


# A squad id for `count` spawns: killing the whole squad pays a bonus.
func new_squad(count: int) -> int:
	return _main._new_squad(count)
