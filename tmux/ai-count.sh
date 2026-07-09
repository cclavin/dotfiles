#!/usr/bin/env bash
# Counts claude/codex/gemini processes running inside tmux panes only.
# A plain system-wide `ps | grep` also catches unrelated matches (e.g. a
# VS Code extension host process), so this walks descendants of each pane's
# root pid instead of matching every process on the machine.
set -euo pipefail

command -v tmux >/dev/null 2>&1 || { echo 0; exit 0; }

pane_pids=$(tmux list-panes -a -F '#{pane_pid}' 2>/dev/null || true)
[ -z "$pane_pids" ] && { echo 0; exit 0; }

ps -eo pid=,ppid=,comm= 2>/dev/null | awk -v seeds="$pane_pids" '
  BEGIN {
    n = split(seeds, s, "\n")
    for (i = 1; i <= n; i++) if (s[i] != "") live[s[i]] = 1
  }
  {
    pid = $1; ppid = $2
    comm = $3
    for (k = 4; k <= NF; k++) comm = comm " " $k
    p_pid[NR] = pid; p_ppid[NR] = ppid; p_comm[NR] = comm
  }
  END {
    changed = 1
    while (changed) {
      changed = 0
      for (i = 1; i <= NR; i++) {
        if (!(p_pid[i] in live) && (p_ppid[i] in live)) {
          live[p_pid[i]] = 1
          changed = 1
        }
      }
    }
    count = 0
    for (i = 1; i <= NR; i++) {
      if ((p_pid[i] in live) && p_comm[i] ~ /claude|codex|gemini/) count++
    }
    print count
  }
'
