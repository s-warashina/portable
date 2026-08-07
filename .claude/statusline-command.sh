#!/bin/bash
# Claude Code ステータスライン表示スクリプト
# 標準入力からJSONを受け取り、整形した1行を標準出力に返す
# 参考: https://docs.anthropic.com/en/docs/claude-code/status-line
#
# 設定ファイル (settings.json) の statusLine.command からこのスクリプトを呼び出すように設定が必要
# jq コマンドも必要 (Windowsなら、winget install jqlang.jq)

if ! command -v jq &>/dev/null; then
  echo "⚠ jq が必要です: (windowsの場合) winget install jqlang.jq"
  exit 0
fi

input=$(cat)

# --- ANSI カラーコード ---
GRN='\033[32m'
YLW='\033[33m'
RED='\033[31m'
MGN='\033[1;35m'   # 太字マゼンタ (ブランチ名用)
CYN='\033[1;38;5;123m'  # 太字+明るいシアン (モデル名用 / 256色)
ORG='\033[1;38;5;208m'  # 太字+明るいオレンジ (Effort用 / 256色)
RST='\033[0m'

# 使用率に応じた色を返す (高いほど危険)
#   0-49%: 緑, 50-79%: 黄, 80%以上: 赤
usage_color() {
  local val=$1
  if [ "$val" -ge 80 ]; then printf '%b' "$RED"
  elif [ "$val" -ge 50 ]; then printf '%b' "$YLW"
  else printf '%b' "$GRN"
  fi
}

# ゲージバーを生成 (10文字幅: █=使用済み, ░=未使用)
# 値は 0-100 にクランプされる
gauge() {
  local val=$1
  (( val < 0 )) && val=0
  (( val > 100 )) && val=100
  local filled=$(( val / 10 ))
  local empty=$(( 10 - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  printf '%s' "$bar"
}

# --- JSONからフィールドを抽出 ---
cwd=$(echo "$input" | jq -r '.cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
# reasoning effort (low/medium/high/xhigh/max)。モデルが非対応の場合はキー自体が存在しない
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Unixタイムスタンプ(秒)からローカル時刻 HH:MM を返す
# 変換失敗時は空文字を返す
format_reset_time() {
  local epoch=$1
  if [ -z "$epoch" ]; then
    printf ''
    return
  fi
  local local_time
  # GNU date (@epoch) を試行し、失敗したらBSD date (-r epoch) を試行
  local_time=$(date -d "@${epoch}" +"%m/%d %H:%M" 2>/dev/null) \
    || local_time=$(date -r "$epoch" +"%m/%d %H:%M" 2>/dev/null) \
    || local_time=""
  printf '%s' "$local_time"
}

# --- 各セクションの組み立て ---

# 作業ディレクトリ + gitブランチ名
branch=""
if [ -n "$cwd" ] && command -v git &>/dev/null; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# printf '%b' はバックスラッシュをエスケープと解釈するため、Windowsパスの \ を \\ に置換しておく
# (特に \c は出力打ち切りを意味し、パスがそこで切れてしまう)
cwd_safe="${cwd//\\/\\\\}"

if [ -n "$branch" ]; then
  path_str="[${cwd_safe:-?}] ${MGN}(${branch})${RST}"
else
  path_str="[${cwd_safe:-?}]"
fi

# モデル名 (太字+シアンで強調) + Effort (太字オレンジ、非対応モデルでは省略)
model_str="${CYN}${model:-?}${RST}"
if [ -n "$effort" ]; then
  model_str="${model_str} ${ORG}[${effort}]${RST}"
fi

# 5時間レートリミット使用率 (色付きゲージ + リセット時刻)
if [ -n "$five_pct" ]; then
  v=$(printf '%.0f' "$five_pct")
  c=$(usage_color "$v")
  five_reset_fmt=$(format_reset_time "$five_resets")
  five_reset_tag=""
  if [ -n "$five_reset_fmt" ]; then
    five_reset_tag=" [resets at ${five_reset_fmt}]"
  fi
  five_str="5h: ${c}$(gauge "$v") ${v}%${RST}${five_reset_tag}"
else
  five_str="5h: (未取得)"
fi

# 7日間レートリミット使用率 (色付きゲージ + リセット時刻)
if [ -n "$week_pct" ]; then
  v=$(printf '%.0f' "$week_pct")
  c=$(usage_color "$v")
  week_reset_fmt=$(format_reset_time "$week_resets")
  week_reset_tag=""
  if [ -n "$week_reset_fmt" ]; then
    week_reset_tag=" [resets at ${week_reset_fmt}]"
  fi
  week_str="7d: ${c}$(gauge "$v") ${v}%${RST}${week_reset_tag}"
else
  week_str="7d: (未取得)"
fi

# コンテキストウィンドウ使用率 (色付きゲージ)
if [ -n "$ctx_used" ]; then
  v=$(printf '%.0f' "$ctx_used")
  c=$(usage_color "$v")
  ctx_str="ctx: ${c}$(gauge "$v") ${v}%${RST}"
else
  ctx_str="ctx: (未取得)"
fi

# --- 出力 ---
# %s: リテラル文字列 (パスのバックスラッシュが解釈されないように)
# %b: ANSIエスケープを解釈 (ゲージの色付き部分)
printf '%b | %b | %b | %b | %b\n' "$path_str" "$model_str" "$five_str" "$week_str" "$ctx_str"
