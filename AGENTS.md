# Star Viper — Agent Context (Antigravity & Claude)

See `CLAUDE.md` and `README.md` for full architecture details.

## Quick Summary
- **Engine:** Godot 4.7+ (`GDScript` with strict static typing; avoid `:=` on `Variant` or untyped `Array` elements).
- **Viewport:** `480x270` (`16:9` pixel art, `3x` window override `1440x810`, nearest-neighbor filtering).
  - Top HUD: `y = 0..19` | Flight Playfield: `y = 28..234` | Stage Floor Deck: `y = 242..250` | Bottom Pictorial Upgrades Dock: `y = 250..270`.
- **Font:** Custom SNES *Final Fantasy VI*-inspired bitmap font (`res://assets/fonts/ff6_font.fnt`), native `font_size = 10`.
- **Autoloads:** `MetaSave`, `StageData`, `PixelArt` (+ `BossPainter`), `RetroSfx`, `GenesisMusic`.
- **Automated Smoke Test:**
  `godot --headless --path . --quit-after 30 -- --smoke-test` (must print `STAR_VIPER_SMOKE_TEST_PASSED` with zero script errors).
- **Standalone Build:** Run `build_releases.bat` (or `--export-pack "Windows" builds/windows/StarViper.pck` + copy Godot binary to `StarViper.exe`).
