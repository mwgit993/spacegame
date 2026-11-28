extends RefCounted

# Recorded music: MP3 files in assets/music/ that play in place of the synth for a soundtrack
# slot. A recording is that slot's default track (GenesisMusic.get_pick() falls back to it) and
# its last choice in Options > Soundtrack, after the original and the 5 synth alternatives, so
# the synth tracks can still be picked. When a slot first gets a recording, MetaSave drops the
# pick saved for it, once, so players who chose a synth track there before get the new song.
#
# Loop points are sample positions at 44.1 kHz, measured on Godot's own MP3 decoder. A song
# plays from the top once (intro included), then repeats loop_start..loop_end forever. Both
# points sit a few ms before a downbeat and a whole number of bars apart, so the jump keeps the
# beat; Godot crossfades the 256 samples after loop_end over the start of the loop. "bpm" is the
# song's tempo; GenesisMusic uses it to express loop_end to Godot (AudioStreamMP3 ends a loop
# after beat_count beats at its bpm). To add a song: drop the MP3 in assets/music/, run
# --import, find two downbeats that repeat (same music before both), and add an entry here.
const TRACKS: Dictionary = {
	# 120 BPM. The 4-bar intro plays once, then 8.05 s -> 98.05 s (45 bars) repeats. The jump
	# back comes at the end of the near-silent stop bar before the last section (a reprise of
	# the main part), and lands on the first beat after the intro, where the main part begins.
	"stage_1": {
		"name": "LEVEL 1", "info": "RECORDED MP3  120 BPM", "file": "res://assets/music/level 1.mp3",
		"bpm": 120.0, "loop_start": 354914, "loop_end": 4323914,
	},
	# 126 BPM. The intro and the first 2 bars of the verse play once, then 19.13 s -> 110.56 s
	# (48 bars) repeats. The last section restarts the verse (its first 2 bars match the verse's
	# first 2 almost sample for sample), so the jump goes from there to the verse's third bar.
	"stage_2": {
		"name": "LEVEL 2", "info": "RECORDED MP3  126 BPM", "file": "res://assets/music/level 2.mp3",
		"bpm": 126.0, "loop_start": 843635, "loop_end": 4875635,
	},
}
