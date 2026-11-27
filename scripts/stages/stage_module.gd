extends RefCounted

# Base class of a stage module: one stage after the 8 built-in ones, self-contained in its own
# folder (scripts/stages/<NN>_<id>/). A module's stage.gd extends this file:
#
#     extends "res://scripts/stages/stage_module.gd"
#
# and overrides the functions below. Nothing in a module edits shared code: GameEnemy, the wave
# director, StarfieldBg and GenesisMusic call into the module through these hooks. To make a
# module playable, put the path of its stage.gd in its slot in scripts/stages/registry.gd.
# scripts/stages/09_example/ is a complete, commented template; copy it to start a new stage.
#
# Timing and threads:
#  - The module object is created once, when StageData registers it (shortly after startup,
#    once its scripts have compiled on a worker thread), so _init() and the getters must stay
#    cheap. The getters are called again by the smoke test and by validate_module().
#  - build_art() and paint_background() run on a worker thread while the previous stage plays
#    (or synchronously the first time something needs them). They must be pure: build Images
#    only, no nodes, no PixelArt/StageData calls, no shared state.
#  - Everything else runs on the main thread during play.

# Set by StageData when the module is registered: the 0-based stage index (8 = stage 9).
var stage_index: int = -1


# --- Stage table -----------------------------------------------------------------------------

# The stage's StageData entry. Same keys as the built-in StageData.STAGES rows ("num" is filled
# in from the stage's position):
#   "id"             unique lowercase id; also the background theme key and the art key prefix
#   "name", "subtitle", "boss_name"   banner and HUD text (upper case; the bitmap font has no
#                    lower case). Keep "name" short: the HUD fits about 16 characters.
#   "sky_top", "sky_mid", "sky_bot"   Colors, used before the background textures exist
#   "deck_fill", "deck_line", "accent" Colors of the floor/ceiling decks and the stage banner
#   "has_ceiling"    true draws a ceiling deck at y 22-28 (enclosed stages)
#   "scout_tex", "swooper_tex", "sniper_tex", "cruiser_tex"   sprites of the four generic
#                    enemies on this stage (existing keys such as "scout_cyber", or your own)
#   "boss_tex"       base key of the boss frames: build_art() must make <boss_tex>_0, _1, _2
#   "bullet_a", "bullet_b"   the two enemy shot textures (e.g. "bullet_enemy_pink")
# Optional:
#   "boss_box"       Vector2 size of the boss hit box (default Vector2(82, 146))
#   "boss_x"         x the boss settles at (default 414)
#   "clear_banner"   first line of the banner when the stage's boss is beaten and the hyperspace
#                    jump starts (default "HYPERSPACE JUMP!"; the final stage marks the win here)
func get_stage_def() -> Dictionary:
	return {}


# The stage's StageData.DIFFICULTY row: "hp", "shot_speed", "fire_rate", "groups", "pace",
# "themed" (see stage_data.gd). The smoke test checks the table only ever gets harder, so start
# from the previous stage's row. "hp" documents the HP curve (enemy HP is 1.34^stage_index);
# keep it at that value.
func get_difficulty_row() -> Dictionary:
	return {}


# The boss's HP before the loop multiplier (GameEnemy.STAGE_BOSS_HP has the built-in values;
# stage 8 is 17500).
func get_boss_hp() -> float:
	return 0.0


# --- Art (worker thread) -----------------------------------------------------------------------

# Every sprite the stage needs, as key -> Image: the stage's enemies, special shots, the boss
# frames (<boss_tex>_0, _1, _2) and any generic re-skins. Prefix keys with the stage id so stages
# never collide. StageData turns them into textures in PixelArt's cache. Remember that
# PixelArt.tex() quietly falls back to another sprite on a missing key; the smoke test checks
# every key the stage refers to.
func build_art() -> Dictionary:
	return {}


# --- Enemies -----------------------------------------------------------------------------------

# The stage's own enemies, as kind (String) -> definition:
#   "hp", "score", "scrap", "xp"   base stats (HP is multiplied by the stage's HP scale)
#   "r" (hit radius) or "box" (Vector2 hit rectangle)
#   "tex"            starting sprite key
#   "behaviour"      the behaviour script (extends scripts/stages/stage_enemy.gd); one instance
#                    is created per enemy
# Optional:
#   "col_offset"     Vector2 offset of the hit shape
#   "big"            true for a big explosion and screen shake on death
#   "exit_left"      how far past the left edge it may go before it counts as gone (default -40)
func get_enemy_defs() -> Dictionary:
	return {}


# One group of the stage's own enemies for the wave director (StageData.DIFFICULTY "themed"
# share of a wave). Queue spawns through the WaveBuilder (scripts/stages/wave_builder.gd) and
# return the time until the next group, like main._queue_themed_group does for stages 1-8.
func queue_themed_group(_w: RefCounted) -> float:
	return 3.0


# --- Boss --------------------------------------------------------------------------------------

# A new boss AI (extends scripts/stages/stage_boss.gd) for each boss fight.
func create_boss() -> RefCounted:
	return null


# --- Background --------------------------------------------------------------------------------

# Paints the stage's still parallax layers (worker thread): layer name -> Image, plus any
# metadata (positions of lights, vents...) as other values. Use the primitives in
# scripts/stage_bg_painter.gd. Keep bright detail out of the y 30-249 playfield.
func paint_background() -> Dictionary:
	return {}


# A new background animator (extends scripts/stages/stage_background.gd) each time the stage's
# background becomes active. It draws the painted layers and the animated parts every frame.
func create_background() -> RefCounted:
	return null


# --- Music -------------------------------------------------------------------------------------

# The stage's song, a GenesisMusic song dictionary in the same form as the alternative tracks in
# scripts/music_candidates.gd: "style" (groove 0-17), "root", "bpm", "scale", "prog_a",
# "prog_b", optional voices ("bass", "pad", "arp", "lead"), "kit", and a "seed" for
# GenesisMusic.compose_melody (or spelled-out "mel_a" / "mel_b"). Shared settings come from
# music_candidates.gd BASE.
func get_song() -> Dictionary:
	return {}


# Optional alternatives for Options > SOUNDTRACK, in the same form plus "name" and "info".
# The stage's slot ("stage_<N>") lists the song above as ORIGINAL, then these.
func get_song_alternatives() -> Array:
	return []


# --- Helpers -------------------------------------------------------------------------------------

func get_id() -> String:
	return String(get_stage_def().get("id", ""))


# Enemy kinds in a stable order (the smoke test spawns every one).
func get_enemy_kinds() -> Array[String]:
	var kinds: Array[String] = []
	for k: Variant in get_enemy_defs().keys():
		kinds.append(String(k))
	kinds.sort()
	return kinds
