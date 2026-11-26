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
	"",
	# --- stage 10
	"",
	# --- stage 11
	"",
	# --- stage 12
	"",
	# --- stage 13
	"",
	# --- stage 14
	"",
	# --- stage 15
	"",
	# --- stage 16
	"",
	# --- stage 17
	"",
	# --- stage 18
	"",
	# --- stage 19
	"",
	# --- stage 20
	"",
	# --- stage 21
	"",
	# --- stage 22
	"",
	# --- stage 23
	"",
	# --- stage 24
	"",
	# --- stage 25
	"",
	# --- stage 26
	"",
	# --- stage 27
	"",
	# --- stage 28
	"",
	# --- add more slots below in the same pattern (marker line, then a path line)
]

# The template module. Not playable: the smoke test registers it for the length of its checks.
const EXAMPLE: String = "res://scripts/stages/09_example/stage.gd"
