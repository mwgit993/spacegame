extends RefCounted

# The animated boss rig for each built-in stage (index 0 = stage 1). GameEnemy uses the rig in
# place of BossPainter's frames when its stage has one here.

const RIGS: Dictionary = {
	0: preload("res://scripts/bosses/rig_dreadnought.gd"),
	1: preload("res://scripts/bosses/rig_scorpion.gd"),
	2: preload("res://scripts/bosses/rig_wyvern.gd"),
	3: preload("res://scripts/bosses/rig_mantis.gd"),
	4: preload("res://scripts/bosses/rig_seraph.gd"),
	5: preload("res://scripts/bosses/rig_skull.gd"),
	6: preload("res://scripts/bosses/rig_kraken.gd"),
	7: preload("res://scripts/bosses/rig_medusa.gd"),
}


static func has_rig(stage_idx: int) -> bool:
	return RIGS.has(stage_idx)


static func create(stage_idx: int) -> Node2D:
	var script: GDScript = RIGS[stage_idx]
	return script.new()
