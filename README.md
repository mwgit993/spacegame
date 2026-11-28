# Star Viper: 16-Bit Galactic Roguelite

A horizontal 16-bit style roguelite space shooter built in **Godot 4.7** (`480x270` integer-scaled widescreen pixel art), combining *Gradius*-style modular ship upgrades and *BALL x PIT*-style XP gem leveling with a 46-node *Rogue Legacy*-style Starforge Skill Tree that unlocks 18 new level-up draft cards, **17 unlockable starships** (including bio-cruisers, alien UFOs, cosmic eyeballs, a tongue-lashing frog, a katana ronin, a black-hole orb ship, a sonar-singing space orca, and the **S.S. Meow-zer** firing Flying Space Cats!), 8 themed worlds, animated Mega Man-style boss intros, and a real-time 44.1 kHz multi-instrument synth soundtrack (plus recorded songs for the first stages).

## Controls
- **Move:** `WASD` / `Arrow Keys` / Any Connected Controller Left Stick or D-Pad / Touch Drag
- **Focus Slow-Dodge (shows 3px core hitbox):** Hold `Shift` / Controller `LB`, `RB`, or `LT` / Touch `FOCUS` pad
- **Fire:** Autofire ON by default (`C` or Controller `Y` toggles) / Hold `Space`, `Z`, `J`, `A`, or `X`
- **Speed Up (2x game speed):** Hold `F` / Controller `RT` (switch it to a toggle under **Options → SPEED UP**)
- **FPS:** **Options → FPS** caps the frame rate at 30, 60 (the default) or 120, or UNLOCKED. V-sync stays on unless the cap is above your screen's refresh rate.
- **Soundtrack picker:** **Options → SOUNDTRACK** lists every place music plays (title, each stage, boss fights, the hyperspace jump). Up/down picks a slot, left/right cycles its original track and 5 alternatives (you hear each one as you go), and the choice is saved. Stages 1 and 2 play recorded songs (`assets/music/`) by default; they're listed last, after the synth tracks.
- **Pause (Stats & Installed Upgrades):** `Esc` / `P` / Controller `Start` / Top-right `II` button
- **Level-Up Powerup Draft:** Keys `1` / `2` / `3`, Mouse/Touch tap, or Controller D-Pad + `A` (`R` or `Y` to Reroll when unlocked)
- **Skill Tree & Ship Loadout:** Navigate nodes with `WASD` / Arrows / D-Pad / Stick or Mouse click & drag; `Tab` / `X` switches between **Skill Tree** and **Fleet Ship Loadout**

## Opening in Godot
1. Install **Godot Engine v4.7+** (Standard GDScript build).
2. Open Godot -> **Import** -> select `project.godot` -> press **`F5`** to play.

## Building Standalone `.exe` (PC & Steam Deck)
- **Instant Build (No Export Templates Needed):** Run `build_releases.bat` on Windows to generate `builds/windows/StarViper.exe` + `StarViper.pck`.
  - **Windows PC:** Double-click `builds/windows/StarViper.exe`.
  - **Steam Deck:** Copy the `builds/windows/` folder (`StarViper.exe` and `StarViper.pck` together) to your Steam Deck in Desktop Mode, right-click `StarViper.exe` -> **Add to Steam**, open Properties -> **Compatibility**, check *Force the use of a specific Steam Play compatibility tool* (**Proton Experimental**), and launch in Gaming Mode!
- **Native Single-File Linux / Windows Exports:** In Godot, open `Editor -> Manage Export Templates -> Download and Install`, then use `Project -> Export` (presets for **Windows Desktop** and **Steam Deck (Linux)** are pre-configured in `export_presets.cfg`).
