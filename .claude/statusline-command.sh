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
CYN='\033[1;36m'  # 太字+シアン (モデル名用)
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
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# --- 各セクションの組み立て ---

# 作業ディレクトリ
path_str="[${cwd:-?}]"

# モデル名 (太字+シアンで強調)
model_str="${CYN}${model:-?}${RST}"

# 5時間レートリミット使用率 (色付きゲージ)
if [ -n "$five_pct" ]; then
  v=$(printf '%.0f' "$five_pct")
  c=$(usage_color "$v")
  five_str="5h: ${c}$(gauge "$v") ${v}%${RST}"
else
  five_str="5h: -"
fi

# 7日間レートリミット使用率 (色付きゲージ)
if [ -n "$week_pct" ]; then
  v=$(printf '%.0f' "$week_pct")
  c=$(usage_color "$v")
  week_str="7d: ${c}$(gauge "$v") ${v}%${RST}"
else
  week_str="7d: -"
fi

# コンテキストウィンドウ使用率 (色付きゲージ)
if [ -n "$ctx_used" ]; then
  v=$(printf '%.0f' "$ctx_used")
  c=$(usage_color "$v")
  ctx_str="ctx: ${c}$(gauge "$v") ${v}%${RST}"
else
  ctx_str="ctx: -"
fi

# --- 出力 ---
# %s: リテラル文字列 (パスのバックスラッシュが解釈されないように)
# %b: ANSIエスケープを解釈 (ゲージの色付き部分)
printf '%s | %b | %b | %b | %b\n' "$path_str" "$model_str" "$five_str" "$week_str" "$ctx_str"
