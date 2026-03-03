#!/bin/bash
# setup-iterm.sh — macOS iTerm2 환경 설정 자동화
# Claude Code 개발에 최적화된 iTerm2 프로파일, 알림, Shell Integration 설정
#
# 사용법: ./setup-iterm.sh [--skip-font] [--skip-profile] [--skip-notify]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse flags
SKIP_FONT=false
SKIP_PROFILE=false
SKIP_NOTIFY=false

for arg in "$@"; do
    case "$arg" in
        --skip-font) SKIP_FONT=true ;;
        --skip-profile) SKIP_PROFILE=true ;;
        --skip-notify) SKIP_NOTIFY=true ;;
    esac
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  iTerm2 Setup for Claude Code${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ──────────────────────────────────────────────
# 1. macOS 확인
# ──────────────────────────────────────────────
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is macOS only.${NC}"
    exit 1
fi

# ──────────────────────────────────────────────
# 2. Homebrew 확인
# ──────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ──────────────────────────────────────────────
# 3. iTerm2 설치 확인
# ──────────────────────────────────────────────
echo "[1/6] Checking iTerm2..."
if [ -d "/Applications/iTerm.app" ]; then
    echo -e "  ${GREEN}✓${NC} iTerm2 already installed"
else
    echo "  Installing iTerm2..."
    brew install --cask iterm2
    echo -e "  ${GREEN}✓${NC} iTerm2 installed"
fi

# ──────────────────────────────────────────────
# 4. terminal-notifier 설치 (macOS 알림용)
# ──────────────────────────────────────────────
echo "[2/6] Checking terminal-notifier..."
if command -v terminal-notifier &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} terminal-notifier already installed"
else
    echo "  Installing terminal-notifier..."
    brew install terminal-notifier
    echo -e "  ${GREEN}✓${NC} terminal-notifier installed"
fi

# ──────────────────────────────────────────────
# 5. Nerd Font 설치 (cc-chips 상태라인용)
# ──────────────────────────────────────────────
if [ "$SKIP_FONT" = false ]; then
    echo "[3/6] Checking Nerd Font..."

    FONT_DIR="$HOME/Library/Fonts"
    if ls "$FONT_DIR"/MesloLGSNerdFont* &>/dev/null 2>&1 || \
       ls "$FONT_DIR"/JetBrainsMonoNerdFont* &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Nerd Font already installed"
    else
        echo "  Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} JetBrains Mono Nerd Font installed" || \
            echo -e "  ${YELLOW}!${NC} Font install failed. Install manually from nerdfonts.com"
    fi
else
    echo "[3/6] Skipping Nerd Font (--skip-font)"
fi

# ──────────────────────────────────────────────
# 6. iTerm2 Shell Integration 설치
# ──────────────────────────────────────────────
echo "[4/6] Setting up iTerm2 Shell Integration..."

SHELL_INTEGRATION="$HOME/.iterm2_shell_integration.zsh"
if [ -f "$SHELL_INTEGRATION" ]; then
    echo -e "  ${GREEN}✓${NC} Shell Integration already installed"
else
    curl -sL https://iterm2.com/shell_integration/zsh -o "$SHELL_INTEGRATION"
    echo -e "  ${GREEN}✓${NC} Shell Integration downloaded"
fi

# .zshrc에 Shell Integration 소싱 추가
INTEGRATION_LINE="source \"\$HOME/.iterm2_shell_integration.zsh\""
if ! grep -q "iterm2_shell_integration" "$HOME/.zshrc" 2>/dev/null; then
    cat >> "$HOME/.zshrc" << 'EOF'

# iTerm2 Shell Integration
if [ -f "$HOME/.iterm2_shell_integration.zsh" ]; then
    source "$HOME/.iterm2_shell_integration.zsh"
fi
EOF
    echo -e "  ${GREEN}✓${NC} Added Shell Integration to .zshrc"
else
    echo -e "  ${GREEN}✓${NC} Shell Integration already in .zshrc"
fi

# ──────────────────────────────────────────────
# 7. iTerm2 Dynamic Profile 생성 (Claude Code 전용)
# ──────────────────────────────────────────────
if [ "$SKIP_PROFILE" = false ]; then
    echo "[5/6] Creating Claude Code iTerm2 profile..."

    DYNAMIC_PROFILES_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    mkdir -p "$DYNAMIC_PROFILES_DIR"

    cat > "$DYNAMIC_PROFILES_DIR/claude-forge.json" << 'PROFILE_JSON'
{
  "Profiles": [
    {
      "Name": "Claude Code",
      "Guid": "claude-forge-profile-001",
      "Dynamic Profile Parent Name": "Default",
      "Badge Text": "Claude \\(session.name)",
      "Use Bold Font": true,
      "Transparency": 0.05,
      "Blend": 0.3,
      "Columns": 140,
      "Rows": 40,
      "Scrollback Lines": 100000,
      "Unlimited Scrollback": true,
      "Normal Font": "JetBrainsMonoNerdFont-Regular 14",
      "Non Ascii Font": "JetBrainsMonoNerdFont-Regular 14",
      "Use Non-ASCII Font": true,
      "Silence Bell": false,
      "BM Growl": true,
      "Send Bell Alert": true,
      "Send Idle Alert": false,
      "Send New Output Alert": false,
      "Send Session Ended Alert": true,
      "Send Terminal Generated Alert": true,
      "Flashing Bell": true,
      "Visual Bell": true,
      "Foreground Color": {
        "Red Component": 0.85,
        "Green Component": 0.85,
        "Blue Component": 0.9,
        "Alpha Component": 1
      },
      "Background Color": {
        "Red Component": 0.08,
        "Green Component": 0.08,
        "Blue Component": 0.12,
        "Alpha Component": 1
      },
      "Cursor Color": {
        "Red Component": 0.82,
        "Green Component": 0.55,
        "Blue Component": 0.28,
        "Alpha Component": 1
      },
      "Badge Color": {
        "Red Component": 0.82,
        "Green Component": 0.55,
        "Blue Component": 0.28,
        "Alpha Component": 0.3
      },
      "Selection Color": {
        "Red Component": 0.2,
        "Green Component": 0.25,
        "Blue Component": 0.35,
        "Alpha Component": 1
      },
      "Ansi 0 Color": {
        "Red Component": 0.15,
        "Green Component": 0.15,
        "Blue Component": 0.2
      },
      "Ansi 1 Color": {
        "Red Component": 0.9,
        "Green Component": 0.35,
        "Blue Component": 0.35
      },
      "Ansi 2 Color": {
        "Red Component": 0.35,
        "Green Component": 0.82,
        "Blue Component": 0.45
      },
      "Ansi 3 Color": {
        "Red Component": 0.92,
        "Green Component": 0.78,
        "Blue Component": 0.35
      },
      "Ansi 4 Color": {
        "Red Component": 0.4,
        "Green Component": 0.55,
        "Blue Component": 0.92
      },
      "Ansi 5 Color": {
        "Red Component": 0.75,
        "Green Component": 0.45,
        "Blue Component": 0.82
      },
      "Ansi 6 Color": {
        "Red Component": 0.35,
        "Green Component": 0.78,
        "Blue Component": 0.82
      },
      "Ansi 7 Color": {
        "Red Component": 0.85,
        "Green Component": 0.85,
        "Blue Component": 0.88
      },
      "Triggers": [
        {
          "partial": false,
          "regex": "\\[task-completed\\].*completed",
          "action": "BounceAction",
          "parameter": ""
        },
        {
          "partial": false,
          "regex": "\\[task-completed\\].*completed",
          "action": "PostNotificationAction",
          "parameter": "Claude: 작업 완료"
        },
        {
          "partial": false,
          "regex": "\\[FORGE\\].*완료|\\[FORGE\\].*complete",
          "action": "PostNotificationAction",
          "parameter": "Claude Forge: 작업 완료"
        },
        {
          "partial": false,
          "regex": "Tests? (passed|failed|error)",
          "action": "PostNotificationAction",
          "parameter": "Claude: 테스트 결과"
        },
        {
          "partial": false,
          "regex": "Build (succeeded|failed)",
          "action": "PostNotificationAction",
          "parameter": "Claude: 빌드 결과"
        }
      ],
      "Smart Selection Rules": [
        {
          "notes": "File path with line number",
          "regex": "([a-zA-Z0-9_/\\-.]+\\.[a-zA-Z]+):(\\d+)",
          "precision": "very_high"
        }
      ]
    }
  ]
}
PROFILE_JSON

    echo -e "  ${GREEN}✓${NC} Dynamic Profile created: Claude Code"
    echo -e "  ${CYAN}  프로파일 위치: $DYNAMIC_PROFILES_DIR/claude-forge.json${NC}"
    echo -e "  ${CYAN}  iTerm2 > Profiles > Claude Code 선택하여 사용${NC}"
else
    echo "[5/6] Skipping profile (--skip-profile)"
fi

# ──────────────────────────────────────────────
# 8. notify.sh 훅 설치 (이미 존재하지 않는 경우)
# ──────────────────────────────────────────────
if [ "$SKIP_NOTIFY" = false ]; then
    echo "[6/6] Setting up notification hook..."

    NOTIFY_HOOK="$REPO_DIR/hooks/notify.sh"
    if [ -f "$NOTIFY_HOOK" ]; then
        chmod +x "$NOTIFY_HOOK"
        echo -e "  ${GREEN}✓${NC} notify.sh hook ready"
    else
        echo -e "  ${YELLOW}!${NC} notify.sh not found (will be created by install)"
    fi

    # macOS 알림 권한 안내
    echo ""
    echo -e "${YELLOW}  ⚠ macOS 알림을 받으려면:${NC}"
    echo -e "    시스템 설정 > 알림 > terminal-notifier > 알림 허용"
    echo -e "    시스템 설정 > 알림 > iTerm2 > 알림 허용"
else
    echo "[6/6] Skipping notification setup (--skip-notify)"
fi

# ──────────────────────────────────────────────
# 완료
# ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  iTerm2 Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  다음 단계:"
echo "    1. iTerm2를 열고 (또는 재시작)"
echo "    2. Profiles > Claude Code 선택"
echo "    3. Set as Default (선택사항)"
echo ""
echo "  알림 트리거:"
echo "    • [task-completed] → macOS 알림 + Dock 바운스"
echo "    • [FORGE] 완료 → macOS 알림"
echo "    • Tests passed/failed → macOS 알림"
echo "    • Build succeeded/failed → macOS 알림"
echo ""
