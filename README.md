# Star Viper: 16-Bit Galactic Roguelite

A horizontal 16-bit style roguelite space shooter built in **Godot 4.7** (`480x270` integer-scaled widescreen pixel art), combining *Gradius*-style modular ship upgrades (trailing Option orbs, spread vulcan, piercing lasers, homing missiles, regenerating shields) with between-run permanent Hangar progression, 8 themed worlds, giant multi-phase bosses, and a real-time 44.1 kHz multi-instrument synth soundtrack.

## Controls
- **Move:** `WASD` / `Arrow Keys` / Controller Left Stick or D-Pad / Touch Drag
- **Focus Slow-Dodge (shows 3px core hitbox):** Hold `Shift` / Controller `LB`, `RB`, or `LT` / Touch `FOCUS` pad
- **Fire:** Autofire ON by default (`C` or Controller `Y` toggles) / Hold `Space`, `Z`, `J`, `A`, `X`, or `RT`
- **Pause:** `Esc` / `P` / Controller `Start` / Top-right `II` button
- **Draft Upgrades:** Keys `1` / `2` / `3`, Mouse/Touch tap, or Controller D-Pad + `A`

## Opening in Godot
1. Install **Godot Engine v4.7+** (Standard GDScript build).
2. Open Godot -> **Import** -> select `project.godot` -> press **`F5`** to play.

## Building Standalone `.exe` (PC & Steam Deck)
- **Instant Build (No Export Templates Needed):** Run `build_releases.bat` on Windows to generate `builds/windows/StarViper.exe` + `StarViper.pck`.
  - **Windows PC:** Double-click `builds/windows/StarViper.exe`.
  - **Steam Deck:** Copy the `builds/windows/` folder (`StarViper.exe` and `StarViper.pck` together) to your Steam Deck in Desktop Mode, right-click `StarViper.exe` -> **Add to Steam**, open Properties -> **Compatibility**, check *Force the use of a specific Steam Play compatibility tool* (**Proton Experimental**), and launch in Gaming Mode!
- **Native Single-File Linux / Windows Exports:** In Godot, open `Editor -> Manage Export Templates -> Download and Install`, then use `Project -> Export` (presets for **Windows Desktop** and **Steam Deck (Linux)** are pre-configured in `export_presets.cfg`).
