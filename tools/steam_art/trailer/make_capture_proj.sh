#!/bin/bash
# make_capture_proj.sh <git-ref> <dest>: scratch copy of the game with the capture driver injected.
set -e
REF=$1; DEST=$2; HERE=$(cd "$(dirname "$0")" && pwd); REPO=$(cd "$HERE/../../.." && pwd)
rm -rf "$DEST"; mkdir -p "$DEST"
git -C "$REPO" archive "$REF" | tar -x -C "$DEST"
cp "$HERE/capture_driver.gd" "$DEST/capture_driver.gd"
python3 - "$DEST/project.godot" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'config/name="[^"]*"', 'config/name="Star Viper Capture"', s, count=1)
s = s.replace('window_width_override=1440', 'window_width_override=1920').replace('window_height_override=810', 'window_height_override=1080')
s = s.replace("[autoload]\n", "[autoload]\n", 1)
# append driver as the last autoload
lines = s.split("\n")
i = lines.index("[autoload]")
j = i + 1
while j < len(lines) and not lines[j].startswith("["):
    j += 1
while lines[j - 1].strip() == "":
    j -= 1
lines.insert(j, 'CaptureDriver="*res://capture_driver.gd"')
open(p, "w").write("\n".join(lines))
PY
