extends RefCounted

# The giant dinosaur robots guarding the checkpoints (every 4th level, Matthew's request): a fixed
# lineup, the same every run, each one tougher than the last and adding new attacks on top of the
# previous one's, ending with the MEGA T-REX at the last checkpoint. The boss pilot flies all of
# them. A robot is rig_dino_mech.gd (how it looks and moves) plus mech_boss.gd (its attacks);
# GameEnemy builds both when checkpoint_tier is set (see StageData's checkpoint notes).

const RigScript = preload("res://scripts/bosses/rig_dino_mech.gd")
const AiScript = preload("res://scripts/bosses/mech_boss.gd")

const HP_MULT: float = 1.6        # vs. a normal boss at the same level
const TARGET_X: float = 396.0
## Checkpoint 1, 2, ... in order. More checkpoints than entries (more stages) cycle the list.
const LINEUP: Array[Dictionary] = [
	{"species": "raptor", "name": "RAPTOR-BOT RX-1", "body": "#7d8aa8", "trim": "#ff9624"},
	{"species": "trike", "name": "TRICERATANK T-3", "body": "#6f8f7a", "trim": "#ffe854"},
	{"species": "ptero", "name": "PTERO-JET SKY KING", "body": "#8a7fa8", "trim": "#28e8ff"},
	{"species": "stego", "name": "STEGO-FORTRESS", "body": "#8f7a64", "trim": "#3ce878"},
	{"species": "spino", "name": "SPINO-DREADSAIL", "body": "#8a5f5f", "trim": "#d44cff"},
	{"species": "ankylo", "name": "ANKYLO-CRUSHER", "body": "#6a6f80", "trim": "#ff4ca8"},
]
## The last checkpoint.
const FINAL: Dictionary = {"species": "rex", "name": "MEGA T-REX OMEGA", "body": "#56607a", "trim": "#ffd23c"}


static func is_final(tier: int) -> bool:
	return tier >= StageData.checkpoint_count() - 1


static func spec(tier: int) -> Dictionary:
	return FINAL if is_final(tier) else LINEUP[posmod(tier, LINEUP.size())]


static func boss_name(tier: int) -> String:
	return String(spec(tier)["name"])


static func create_rig(tier: int) -> Node2D:
	var rig: Node2D = RigScript.new()
	rig.set("tier", tier)
	rig.set("spec", spec(tier))
	rig.set("final_boss", is_final(tier))
	return rig


static func create_ai(tier: int) -> RefCounted:
	var ai: RefCounted = AiScript.new()
	ai.set("tier", tier)
	ai.set("final_boss", is_final(tier))
	return ai


## The robot's hit box.
static func box(tier: int) -> Vector2:
	return Vector2(104.0, 120.0) * (RigScript.FINAL_SCALE if is_final(tier) else 1.0)
