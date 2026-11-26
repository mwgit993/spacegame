# Steam store assets (preliminary)

First-pass art for the Steam store page and library, all made from the game's own sprites, so it matches the game. Everything here can be regenerated, and none of it is packed into the game (this folder has a `.gdignore`).

## `art/`: store and library images

Sizes follow [Steamworks' graphical asset rules](https://partner.steamgames.com/doc/store/assets).

| File | Size | Used for |
| --- | --- | --- |
| `header_capsule_920x430.png` | 920×430 | **Required.** Top of the store page, and the default library header |
| `small_capsule_462x174.png` | 462×174 | **Required.** Search results, top-sellers lists and other small slots |
| `main_capsule_1232x706.png` | 1232×706 | Front-page featured carousel |
| `vertical_capsule_748x896.png` | 748×896 | Seasonal sale pages |
| `library_capsule_600x900.png` | 600×900 | Steam library grid |
| `library_hero_3840x1240.png` | 3840×1240 | Steam library banner. It has no logo, because Steam draws the library logo on top of it |
| `library_logo_1280.png` | 1280×250 | Transparent logo shown over the library hero |
| `app_icon_184x184.png` / `.jpg` | 184×184 | **Required.** App and community icon |
| `shortcut_icon_256x256.png` | 256×256 | Desktop shortcut icon (Steam converts it to `.ico`) |

To regenerate after changing sprites or the layout in `tools/steam_art/make_steam_art.gd`:

```bash
godot --headless --path . --script res://tools/steam_art/make_steam_art.gd -- steam/art
```

Each image is laid out on a small pixel canvas and scaled up by a whole number, so the pixels stay sharp. The "STAR VIPER" logo letters are drawn by hand in that script (`GLYPHS`), with colours from the game's palette.

## `screenshots/`

1920×1080 gameplay frames (an exact 4× of the game's 480×270), recorded from the real game. Steam asks for at least 5.

## `trailer/`

`star_viper_trailer.mp4`: about 64 s, 1920×1080, 30 fps, H.264 + AAC. It runs: title, Stage 1, a quick tour of the worlds, a level-up draft and a big loadout, the Neon Medusa boss fight, the skill tree and ship bay, and "Coming soon to Steam". The soundtrack is the new Stage 1 theme, with the game's sound effects mixed in.

The game was recorded while playing itself, using Godot's Movie Maker mode. `tools/steam_art/trailer/` has the scripts:

1. `make_capture_proj.sh <git-ref> <dir>` copies the game into a scratch folder. It renames the project, so your real save file isn't touched, and adds `capture_driver.gd` as an extra autoload. The driver is a timed script: it shows the title cards, flies the ship, jumps between stages, opens the draft, fights the boss and visits the menus. It mutes the music (the soundtrack is added afterwards) and makes the ship intangible.
2. Record: `godot --path <dir> --fixed-fps 30 --write-movie <out>/f.png`, with `CAPTURE_LOGO=steam/art/library_logo_1280.png` and `CAPTURE_MARKS=<out>/marks.txt` set. It writes one PNG per frame, a WAV of the sound effects, and the frame numbers of good screenshot moments.
3. `mix.py` mixes a rendered music track with the sound effects.
4. `encode.swift` (macOS) turns the frames and the mix into the MP4. On Windows, ffmpeg does the same thing: `ffmpeg -framerate 30 -i f%08d.png -i mix.wav -c:v libx264 -pix_fmt yuv420p -crf 16 -c:a aac -b:a 192k trailer.mp4`.

Edit the `steps` list in `capture_driver.gd` to change what the trailer shows and when.
