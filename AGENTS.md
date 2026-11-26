# Star Viper — Agent Context (Antigravity & Claude)

See `PROJECT_CONTEXT.md`, `CLAUDE.md`, and `README.md` for full architecture details.

## Quick Summary
- **Engine:** Godot 4.7+ (`GDScript` with strict static typing; avoid `:=` on `Variant` or untyped `Array` elements).
- **Viewport:** `480x270` (`16:9` pixel art, `3x` window override `1440x810`, nearest-neighbor filtering).
  - Top HUD: `y = 0..19` | Full-Width XP Bar: `y = 19..23` | Flight Playfield: `y = 30..249` | Stage Floor Deck: `y = 258..270`.
  - Split-Screen Pause Menu (`Esc` / `Start`): Left column has compact Pause Options + Ship card; Right panel inspects live Ship Stats & Installed Weapons/Upgrades.
- **Font:** Custom SNES *Final Fantasy VI*-inspired bitmap font (`res://assets/fonts/ff6_font.fnt`), native `font_size = 10`.
- **Autoloads & Core Data:** `MetaSave`, `StageData`, `PixelArt` (+ `BossPainter`), `RetroSfx`, `GenesisMusic`, plus `SkillTreeData` (`scripts/skill_tree_data.gd` — 36-node *Rogue Legacy* Skill Tree & 7 Playable Ships).
- **Automated Smoke Test:**
  `godot --headless --path . --quit-after 30 -- --smoke-test` (must print `STAR_VIPER_SMOKE_TEST_PASSED` with zero script errors).
- **Standalone Build:** Run `build_releases.bat` (auto-detects Home/Work Godot paths and packages `builds/windows/StarViper.exe` + `StarViper.pck`).
