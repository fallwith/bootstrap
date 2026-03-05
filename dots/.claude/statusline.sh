#!/usr/bin/env bash

input=$(cat)

sep=" │ "
reset="\033[0m"

# Single jq call, null-delimited to handle spaces in values
{
  IFS= read -r -d '' session_id
  IFS= read -r -d '' model
  IFS= read -r -d '' dir
  IFS= read -r -d '' used_pct
  IFS= read -r -d '' ctx_size
  IFS= read -r -d '' cost
  IFS= read -r -d '' duration_ms
} < <(
  echo "$input" | jq -j '
    (.session_id // ""), "\u0000",
    (.model.display_name // ""), "\u0000",
    (.workspace.current_dir // ""), "\u0000",
    (.context_window.used_percentage // ""), "\u0000",
    (.context_window.context_window_size // ""), "\u0000",
    (.cost.total_cost_usd // ""), "\u0000",
    (.cost.total_duration_ms // ""), "\u0000"
  '
)

session_short="${session_id:0:8}"
dir_name="${dir##*/}"
tide=$("$HOME/bin/tsu" 2>/dev/null)
now=$(date +%H:%M:%S)

# Build context bar (20 chars wide)
if [ -n "$used_pct" ]; then
  pct_int=${used_pct%.*}
  filled=$(( (pct_int + 2) / 5 ))
  [ "$filled" -gt 20 ] && filled=20
  empty_count=$((20 - filled))
  bar=""
  for ((i=0; i<filled; i++)); do bar+="▓"; done
  for ((i=0; i<empty_count; i++)); do bar+="░"; done

  if [ "$pct_int" -ge 90 ]; then
    color="\033[31m"
  elif [ "$pct_int" -ge 70 ]; then
    color="\033[33m"
  else
    color="\033[32m"
  fi

  token_part=""
  if [ -n "$ctx_size" ]; then
    used_k=$(( (pct_int * ctx_size / 100 + 500) / 1000 ))
    max_k=$(( (ctx_size + 500) / 1000 ))
    token_part=" ${used_k}k/${max_k}k"
  fi

  ctx_part="${color}${bar}${reset} ${pct_int}%${token_part}"
else
  ctx_part="░░░░░░░░░░░░░░░░░░░░ --%"
fi

# Format cost
if [ -n "$cost" ]; then
  cost_fmt=$(printf '$%.2f' "$cost")
else
  cost_fmt='$0.00'
fi

# Format duration
if [ -n "$duration_ms" ]; then
  total_s=$((${duration_ms%.*} / 1000))
  dur_fmt="$((total_s / 60))m $((total_s % 60))s"
else
  dur_fmt="0m 0s"
fi

echo -e "🦊 ${tide}${sep}${session_short}${sep}${model}${sep}${ctx_part}${sep}${cost_fmt}${sep}${dur_fmt}${sep}${now}${sep}${dir_name}"
