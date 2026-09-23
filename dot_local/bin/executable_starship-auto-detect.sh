#!/bin/bash
# starship-auto-detect.sh - Auto-detects whether the battery module is available
# and toggles its config section accordingly.
# Only updates the config if the state has changed since last run.
set -e

CONFIG_FILE="$HOME/.config/starship.toml"
CACHE_FILE="$HOME/.cache/starship_battery_detected"

# Detect if battery module is available
# Note: starship module battery returns exit 0 even when the module doesn't exist,
# so we must check stderr for the error message.
if starship module battery 2>/dev/null | grep -q "^\["; then
    DETECTED=true
else
    DETECTED=false
fi

# Read previous state from cache
if [ -f "$CACHE_FILE" ]; then
    PREVIOUS=$(cat "$CACHE_FILE")
else
    PREVIOUS=""
fi

# Only update config if state changed
if [ "$DETECTED" = "$PREVIOUS" ]; then
    exit 0
fi

# Save new state
mkdir -p "$(dirname "$CACHE_FILE")"
echo "$DETECTED" > "$CACHE_FILE"

# Toggle the battery section using Python for reliable text manipulation
export STARSHIP_BATTERY_DETECTED="$DETECTED"
python3 << 'PYEOF'
import os

path = os.path.expanduser("~/.config/starship.toml")
enable = os.environ.get("STARSHIP_BATTERY_DETECTED", "false") == "true"

with open(path, 'r') as f:
    lines = f.readlines()

START_MARKER = "# STARSHIP-BATTERY-AUTO-DETECT-START"
END_MARKER = "# STARSHIP-BATTERY-AUTO-DETECT-END"

in_section = False
new_lines = []

for line in lines:
    stripped = line.strip()

    if stripped == START_MARKER:
        in_section = True
        new_lines.append(line)
        continue

    if stripped == END_MARKER:
        in_section = False
        new_lines.append(line)
        continue

    if in_section:
        if enable:
            # Uncomment this line (remove first '# ' only)
            if stripped.startswith("# "):
                new_lines.append(line.replace("# ", "", 1))
            else:
                new_lines.append(line)
        else:
            # Comment this line (add '# ' prefix if not already commented)
            if not stripped.startswith("#"):
                new_lines.append("# " + line)
            else:
                new_lines.append(line)
    else:
        new_lines.append(line)

content = "".join(new_lines)

# Update right_format
if enable:
    content = content.replace('right_format = "$time"', 'right_format = "$time$battery"')
    if 'right_format = ""' in content:
        content = content.replace('right_format = ""', 'right_format = "$time$battery"')
else:
    content = content.replace('right_format = "$time$battery"', 'right_format = "$time"')

with open(path, 'w') as f:
    f.write(content)

status = "enabled" if enable else "disabled"
print(f"Battery module {status} in config")
PYEOF
