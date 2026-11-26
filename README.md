# Star Viper: 16-Bit Galactic Roguelite

A horizontal 16-bit style roguelite space shooter built in **Godot 4.7** (`480x270` integer-scaled widescreen pixel art), combining *Gradius*-style modular ship upgrades and *BALL x PIT*-style XP gem leveling with a 30-node *Rogue Legacy*-style Starforge Skill Tree, **7 unlockable starships** (including bio-cruisers, alien UFOs, cosmic eyeballs, and the **S.S. Meow-zer** firing Flying Space Cats!), 8 themed worlds, animated Mega Man-style boss intros, and a real-time 44.1 kHz multi-instrument synth soundtrack.

## Controls
- **Move:** `WASD` / `Arrow Keys` / Any Connected Controller Left Stick or D-Pad / Touch Drag
- **Focus Slow-Dodge (shows 3px core hitbox):** Hold `Shift` / Controller `LB`, `RB`, or `LT` / Touch `FOCUS` pad
- **Fire:** Autofire ON by default (`C` or Controller `Y` toggles) / Hold `Space`, `Z`, `J`, `A`, `X`, or `RT`
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
