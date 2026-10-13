# claude-dotfiles

Claude Code config shared between my host and dev containers.

- `claude/statusline-command.sh` – status line script
- `claude/settings.json` – the only `settings.json` keys that are shared
- `claude/skills/<name>/` – skills shared on purpose (opt-in, one directory each)

`./install.sh` links these into `~/.claude` and merges the shared keys into the
existing `settings.json`. Re-run it after pulling.

This repo is public and its scripts run on the host: nothing is copied from
`~/.claude` automatically, and credentials, history, transcripts, memory,
permissions and hooks stay out of it.
