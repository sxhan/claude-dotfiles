#!/bin/sh
# Installs the shared Claude Code config from this repo into the Claude config dir.
# Idempotent; runs on the host and inside dev containers.
set -eu

repo=$(cd "$(dirname "$0")" && pwd)
dest=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

command -v jq >/dev/null || { echo "install.sh: jq is required" >&2; exit 1; }
mkdir -p "$dest"

# Symlink $1 to $2, refusing to replace anything that is not already a symlink.
link() {
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    echo "install.sh: $2 exists and is not a symlink, skipping" >&2
    return
  fi
  ln -sfn "$1" "$2"
}

link "$repo/claude/statusline-command.sh" "$dest/statusline-command.sh"

# Skills are opt-in: only directories placed in claude/skills/ are linked.
for skill in "$repo"/claude/skills/*/; do
  [ -d "$skill" ] || continue
  mkdir -p "$dest/skills"
  link "${skill%/}" "$dest/skills/$(basename "$skill")"
done

# Merge the shared keys over the existing settings; all other keys are kept.
settings="$dest/settings.json"
[ -s "$settings" ] || echo '{}' > "$settings"
tmp=$(mktemp)
jq -s '.[0] * .[1]' "$settings" "$repo/claude/settings.json" > "$tmp"
cat "$tmp" > "$settings"
rm -f "$tmp"
