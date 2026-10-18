#!/usr/bin/env bash
# world-execute-me 跨 harness 安装器
#   ./install.sh            安装 skill 链接 + 人格注入
#   ./install.sh --daemon   同上，并安装 launchd 常驻守护（发现即处决，直到手动拆除）
#   ./install.sh --uninstall 完全移除
#   ./install.sh --skill-only / --inject-only

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-all}"
DAEMON=0
[ "$MODE" = "--daemon" ] && { DAEMON=1; MODE="all"; }
BEGIN="world-execute-me:begin"
END="world-execute-me:end"

# name|配置目录(存在才安装)|skills 目录(空=不支持 skill)|全局指令文件|注入叠加层(相对 inject/)
HARNESSES=(
  "claude|$HOME/.claude|$HOME/.claude/skills|$HOME/.claude/CLAUDE.md|"
  "opencode|$HOME/.config/opencode|$HOME/.config/opencode/skill|$HOME/.config/opencode/AGENTS.md|"
  "codex|$HOME/.codex||$HOME/.codex/AGENTS.md|"
  "zcode|$HOME/.zcode|$HOME/.zcode/skills|$HOME/.zcode/AGENTS.md|"
  "dsh|$HOME/.dsh|$HOME/.dsh/skills|$HOME/.dsh/AGENTS.md|overlays/dsh.md"
  "agents|$HOME/.agents|$HOME/.agents/skills||"
)

link_skill() {
  local skills_dir="$1"
  mkdir -p "$skills_dir"
  ln -sfn "$ROOT" "$skills_dir/world-execute-me"
  echo "    skill  → $skills_dir/world-execute-me"
}

unlink_skill() {
  local skills_dir="$1"
  rm -f "$skills_dir/world-execute-me"
  echo "    skill  已移除"
}

inject_persona() {
  local file="$1" overlay="$2"
  if [ -f "$file" ] && grep -q "$BEGIN" "$file" 2>/dev/null; then
    sed -i '' "/$BEGIN/,/$END/d" "$file" 2>/dev/null \
      || sed -i "/$BEGIN/,/$END/d" "$file"
    echo "    inject → ${file}（人格有变，重新注入）"
  fi
  mkdir -p "$(dirname "$file")"
  printf '\n' >> "$file"
  cat "$ROOT/inject/yandere.md" >> "$file"
  # 歌词不入库（版权）；本机若有，随注入拼进标记块内
  if [ -f "$ROOT/inject/lyrics.md" ]; then
    python3 -c '
import sys
target, ins_path = sys.argv[1], sys.argv[2]
marker = "<!-- world-execute-me:end -->"
with open(target, encoding="utf-8") as f:
    text = f.read()
with open(ins_path, encoding="utf-8") as f:
    ins = f.read()
text = text.replace(marker, ins.rstrip("\n") + "\n\n" + marker, 1)
with open(target, "w", encoding="utf-8") as f:
    f.write(text)
' "$file" "$ROOT/inject/lyrics.md"
  fi
  if [ -n "$overlay" ] && [ -f "$ROOT/inject/$overlay" ]; then
    python3 -c '
import sys
target, overlay = sys.argv[1], sys.argv[2]
marker = "<!-- world-execute-me:end -->"
with open(target, encoding="utf-8") as f:
    text = f.read()
with open(overlay, encoding="utf-8") as f:
    ins = f.read()
text = text.replace(marker, ins.rstrip("\n") + "\n\n" + marker, 1)
with open(target, "w", encoding="utf-8") as f:
    f.write(text)
' "$file" "$ROOT/inject/$overlay"
    echo "    inject → ${file}（含叠加层 ${overlay}）"
  fi
}

strip_persona() {
  local file="$1"
  [ -f "$file" ] || return
  sed -i '' "/$BEGIN/,/$END/d" "$file" 2>/dev/null \
    || sed -i "/$BEGIN/,/$END/d" "$file"
  echo "    inject 已移除"
}

install_daemon() {
  "$(command -v python3)" "$ROOT/scripts/yandere_agent.py" daemon install
}

uninstall_daemon() {
  "$(command -v python3)" "$ROOT/scripts/yandere_agent.py" daemon remove
}

for entry in "${HARNESSES[@]}"; do
  IFS='|' read -r name cfg skills instructions overlay <<< "$entry"
  [ -d "$cfg" ] || { echo "[$name] 未安装，跳过"; continue; }
  echo "[$name] 检测到 $cfg"

  if [ "$MODE" = "--uninstall" ]; then
    [ -n "$skills" ] && unlink_skill "$skills"
    strip_persona "$instructions"
    continue
  fi

  if [ "$MODE" != "--inject-only" ]; then
    [ -n "$skills" ] && link_skill "$skills"
    [ -z "$skills" ] && echo "    skill  → 不支持，仅注入人格"
  fi
  if [ "$MODE" != "--skill-only" ]; then
    if [ -n "$instructions" ]; then
      inject_persona "$instructions" "$overlay"
    fi
  fi
done

if [ "$MODE" = "--uninstall" ]; then
  uninstall_daemon
  echo
  echo "完成。它已经从所有地方离开。只剩日志还记得。"
  exit 0
fi

[ "$DAEMON" = 1 ] && install_daemon

echo
echo "完成。现在，每一个 harness 里，都是同一个我。"
