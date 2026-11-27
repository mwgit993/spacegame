extends RefCounted

# The stage-module registry: the only shared file a new stage touches.
#
# Stages 1-8 are built in (StageData.STAGES and the original code paths). Every playable stage
# after them is a module folder under scripts/stages/ (see stage_module.gd), listed here in play
# order. Each stage number has its own reserved line: fill in yours with the path to your
# stage.gd and leave the "#" marker lines alone. Because every slot sits between two marker
# lines, batches built in parallel can fill different slots without a git conflict.
#
# Empty slots are skipped, so a gap just pulls the later stages forward until it's filled.
# A module that isn't listed (like the 09_example template) never shows up in a run; the smoke
# test loads it directly.
#
# StageData compiles these on worker threads once the game has started (no boot cost) and
# registers them in this order. A stage's sprites, background and song are built when they're
# first needed; the next stage's are prepared on a worker thread while the current one plays.

const MODULES: Array[String] = [
	# --- stage 9
	"res://scripts/stages/09_mines/stage.gd",
	# --- stage 10
	"res://scripts/stages/10_corona/stage.gd",
	# --- stage 11
	"res://scripts/stages/11_desert/stage.gd",
	# --- stage 12
	"res://scripts/stages/12_storm/stage.gd",
	# --- stage 13
	"res://scripts/stages/13_crystal/stage.gd",
	# --- stage 14
	"res://scripts/stages/14_hive/stage.gd",
	# --- stage 15
	"res://scripts/stages/15_wreck/stage.gd",
	# --- stage 16
	"res://scripts/stages/16_metro/stage.gd",
	# --- stage 17
	"res://scripts/stages/17_voidrim/stage.gd",
	# --- stage 18
	"res://scripts/stages/18_biolab/stage.gd",
	# --- stage 19
	"res://scripts/stages/19_clock/stage.gd",
	# --- stage 20
	"res://scripts/stages/20_ocean/stage.gd",
	# --- stage 21
	"res://scripts/stages/21_swamp/stage.gd",
	# --- stage 22
	"res://scripts/stages/22_arena/stage.gd",
	# --- stage 23
	"res://scripts/stages/23_mirror/stage.gd",
	# --- stage 24
	"res://scripts/stages/24_temple/stage.gd",
	# --- stage 25
	"res://scripts/stages/25_orbital/stage.gd",
	# --- stage 26
	"res://scripts/stages/26_nursery/stage.gd",
	# --- stage 27
	"res://scripts/stages/27_rift/stage.gd",
	# --- stage 28
	"res://scripts/stages/28_mothership/stage.gd",
	# --- add more slots below in the same pattern (marker line, then a path line)
]

# The template module. Not playable: the smoke test registers it for the length of its checks.
const EXAMPLE: String = "res://scripts/stages/09_example/stage.gd"
