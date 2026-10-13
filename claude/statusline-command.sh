#!/bin/sh
# Status line approximating the Powerlevel10k rainbow prompt: context, dir, vcs, time.
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)

sep=$(printf '\357\202\260')   # U+E0B0 powerline separator
branch_icon=$(printf '\356\202\240')   # U+E0A0

# user@host block: bold white on red
out=$(printf '\033[1;38;5;255;48;5;1m %s@%s ' "$(whoami)" "$(hostname -s)")

# dir block: blue background (p10k rainbow), ~ abbreviation
case "$cwd" in
  "$HOME") d="~" ;;
  "$HOME"/*) d="~${cwd#"$HOME"}" ;;
  *) d="$cwd" ;;
esac
out="$out$(printf '\033[38;5;1;48;5;4m%s\033[38;5;254m %s ' "$sep" "$d")"

# vcs block: green clean, yellow modified/untracked
last_bg=4
if branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
  st=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  if [ -n "$st" ]; then bg=3; mark=" *"; else bg=2; mark=""; fi
  out="$out$(printf '\033[38;5;4;48;5;%sm%s\033[38;5;0m %s %s%s ' "$bg" "$sep" "$branch_icon" "$branch" "$mark")"
  last_bg=$bg
fi

# closing separator
out="$out$(printf '\033[0m\033[38;5;%sm%s\033[0m' "$last_bg" "$sep")"

# plain-text segments after the blocks, divided by a dim bar
div=$(printf ' \033[38;5;240m│\033[0m ')

# meter: dim label, 5-cell bar and bold percentage, coloured by level
meter() {  # $1 = label, $2 = percentage (integer)
  if [ "$2" -ge 80 ]; then c=1; elif [ "$2" -ge 50 ]; then c=3; else c=2; fi
  fill=$(( ($2 * 5 + 50) / 100 )); [ "$fill" -gt 5 ] && fill=5
  cells=''; i=0
  while [ "$i" -lt 5 ]; do
    if [ "$i" -lt "$fill" ]; then col=$c; else col=240; fi
    cells="$cells$(printf '\033[38;5;%sm━' "$col")"
    i=$((i + 1))
  done
  out="$out$div$(printf '\033[38;5;250m%s %s \033[1;38;5;%sm%s%%\033[0m' "$1" "$cells" "$c" "$2")"
}

# model name
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
[ -n "$model" ] && out="$out$(printf ' \033[1;38;5;5m%s\033[0m' "$model")"

# context usage
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty | floor')
[ -n "$ctx" ] && meter ctx "$ctx"

# usage limits: 5-hour session and weekly, each with its reset time
limit() {  # $1 = label, $2 = rate_limits key, $3 = date format for the reset time
  pct=$(echo "$input" | jq -r --arg k "$2" '.rate_limits[$k].used_percentage // empty | floor')
  [ -z "$pct" ] && return
  meter "$1" "$pct"
  reset=$(echo "$input" | jq -r --arg k "$2" '.rate_limits[$k].resets_at // empty')
  case "$reset" in
    '') return ;;
    *[!0-9]*) when=$(date -d "$reset" +"$3" 2>/dev/null) ;;   # ISO timestamp
    *) when=$(date -d "@$reset" +"$3" 2>/dev/null) ;;          # epoch seconds
  esac
  [ -n "$when" ] && out="$out$(printf ' \033[38;5;244m↻ %s\033[0m' "$when")"
}
limit 5h five_hour '%H:%M'
limit 7d seven_day '%a %H:%M'

# time (24h) on the end, grey
printf '%s%s\033[38;5;66m%s\033[0m' "$out" "$div" "$(date +%H:%M:%S)"
