#!/usr/bin/env zsh
# Claude Code status line, 1 line: [model·effort] 📁 dir 🌿 branch(⑂ worktree) │ ▓▓░ ctx% │ 💰 cost │ ✎ diff

emulate -L zsh
input=$(cat)

C_MODEL=$'\033[36m' C_EFF=$'\033[2;36m' C_BR=$'\033[32m' C_WT=$'\033[33m' C_DIR=$'\033[35m'
C_ADD=$'\033[32m' C_DEL=$'\033[31m' C_COST=$'\033[33m' C_DIM=$'\033[2m' R=$'\033[0m'
sep=" ${C_DIM}│${R} "

IFS=$'\t' read -r model cwd cost effort tpath < <(jq -r '[
  (.model.display_name // "?"),
  (.workspace.current_dir // .cwd // "."),
  (.cost.total_cost_usd // 0),
  (.effort.level // "default"),
  (.transcript_path // "")
] | @tsv' <<<"$input")

# context window still comes from settings
settings=~/.claude/settings.json
win=200000; [[ "$(jq -r '.model // ""' "$settings" 2>/dev/null)" == *"[1m]"* ]] && win=1000000

human() { local n=$1; if (( n >= 1000000 )); then printf '%.1fM' "$((n/100000))e-1"; elif (( n >= 1000 )); then printf '%dk' "$((n/1000))"; else printf '%d' "$n"; fi }

parts=("${C_DIM}[${R}${C_MODEL}${model}${R}${C_EFF}·${effort}${R}${C_DIM}]${R} 📁 ${C_DIR}${cwd:t}${R}")

if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  br=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  wt=""; [[ "$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)" == *"/worktrees/"* ]] && wt=" ${C_WT}⑂${R}"
  parts[-1]+=" 🌿 ${C_BR}${br}${R}${wt}"
fi

# context bar from last assistant usage in transcript
if [[ -f "$tpath" ]]; then
  used=$(grep '"usage"' "$tpath" | tail -1 | jq -r '(.message.usage) | ((.input_tokens//0)+(.cache_read_input_tokens//0)+(.cache_creation_input_tokens//0))' 2>/dev/null)
  if [[ -n "$used" && "$used" != null ]]; then
    pct=$(( used * 100 / win )); (( pct > 100 )) && pct=100
    filled=$(( (pct + 9) / 10 )); empty=$(( 10 - filled ))
    bc=$C_ADD; (( pct >= 60 )) && bc=$C_COST; (( pct >= 85 )) && bc=$C_DEL
    bar="${bc}${(l:filled::▓:):-}${C_DIM}${(l:empty::░:):-}${R}"
    parts+=("${bar} ${bc}${pct}%${R} ${C_DIM}$(human $used)${R}")
  fi
fi

# cost
c=$(printf '%.2f' "$cost" 2>/dev/null)
[[ "$c" != "0.00" && -n "$c" ]] && parts+=("💰 ${C_COST}\$${c}${R}")

# working-tree diff vs HEAD
stat=$(git -C "$cwd" diff --shortstat HEAD 2>/dev/null)
if [[ -n "$stat" ]]; then
  num() { local n=$(grep -oE "[0-9]+ $1" <<<"$stat" | grep -oE '^[0-9]+'); print -- "${n:-0}"; }
  parts+=("✎ ${C_ADD}+$(num insertion)${R}/${C_DEL}-$(num deletion)${R}")
fi

print -rn -- "${(j: │ :)parts}"
