#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
#  Zyrcon AI v0.1 — One-Command Installer for macOS
#  https://github.com/zyrconai/zyrcon
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/zyrconai/zyrcon/main/install.sh | bash
#
#  What this installs:
#    • llama.cpp (Metal GPU accelerated inference engine)
#    • Zyrcon AI v0.1 server (OpenAI-compatible API on port 8080)
#    • qwen2.5-3b-instruct model (~2GB download)
#    • macOS LaunchAgent (auto-starts on login)
#    • SwiftBar plugin (menu bar control)
# ═══════════════════════════════════════════════════════════════════════════

set -e

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Config ───────────────────────────────────────────────────────────────────
ZYRCON_DIR="$HOME/.zyrcon"
ZYRCON_PORT=8080
LLAMA_DIR="$HOME/llama.cpp"
MODEL_DIR="$ZYRCON_DIR/models"
LOG_DIR="$ZYRCON_DIR/logs"
MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"
MODEL_FILE="$MODEL_DIR/zyrcon-v0.1-3b.gguf"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/ai.zyrcon.server.plist"
SWIFTBAR_DIR="$HOME/SwiftBar"
VERSION="v0.1.0"

# ── Banner ───────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ███████╗██╗   ██╗██████╗  ██████╗ ██████╗ ███╗   ██╗"
echo "     ███╔╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔═══██╗████╗  ██║"
echo "    ███╔╝  ╚████╔╝ ██████╔╝██║     ██║   ██║██╔██╗ ██║"
echo "   ███╔╝    ╚██╔╝  ██╔══██╗██║     ██║   ██║██║╚██╗██║"
echo "  ███████╗   ██║   ██║  ██║╚██████╗╚██████╔╝██║ ╚████║"
echo "  ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "  ${BOLD}Zyrcon AI ${VERSION} — Private Decentralized Inference${NC}"
echo -e "  ${CYAN}Installing on your Mac...${NC}"
echo ""

# ── Helpers ──────────────────────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✓${NC}  $1"; }
info() { echo -e "  ${BLUE}→${NC}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
fail() { echo -e "  ${RED}✗${NC}  $1"; exit 1; }
step() { echo ""; echo -e "  ${BOLD}${CYAN}[$1]${NC} $2"; }

# ── Check macOS ───────────────────────────────────────────────────────────────
step "1/7" "Checking system requirements"

if [[ "$(uname)" != "Darwin" ]]; then
    fail "Zyrcon AI v0.1 requires macOS. Linux/Windows coming soon."
fi

ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    warn "Intel Mac detected. Apple Silicon (M1/M2/M3) recommended for best performance."
fi

MACOS_VER=$(sw_vers -productVersion | cut -d. -f1)
if [[ "$MACOS_VER" -lt 12 ]]; then
    fail "macOS 12 (Monterey) or later required."
fi

RAM_GB=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Memory:" | awk '{print $2}')
ok "macOS $(sw_vers -productVersion) on $ARCH ($RAM_GB RAM)"

# ── Check Homebrew ────────────────────────────────────────────────────────────
step "2/7" "Checking dependencies"

if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
ok "Homebrew ready"

if ! command -v git &>/dev/null; then
    info "Installing git..."
    brew install git
fi
ok "Git ready"

if ! command -v cmake &>/dev/null; then
    info "Installing cmake..."
    brew install cmake
fi
ok "CMake ready"

if ! command -v python3 &>/dev/null; then
    fail "Python 3 required. Install from https://python.org"
fi
ok "Python $(python3 --version | awk '{print $2}') ready"

# ── Install Python deps ───────────────────────────────────────────────────────
step "3/7" "Installing Zyrcon Python dependencies"

python3 -m pip install fastapi uvicorn httpx --break-system-packages -q 2>/dev/null || \
python3 -m pip install fastapi uvicorn httpx -q 2>/dev/null || \
pip3 install fastapi uvicorn httpx --break-system-packages -q
ok "FastAPI + Uvicorn + HTTPX installed"

# ── Build llama.cpp ───────────────────────────────────────────────────────────
step "4/7" "Building llama.cpp inference engine (Metal GPU)"

mkdir -p "$ZYRCON_DIR" "$MODEL_DIR" "$LOG_DIR"

LLAMA_BIN="$LLAMA_DIR/build/bin/llama-server"

if [[ -f "$LLAMA_BIN" ]]; then
    ok "llama-server already built at $LLAMA_BIN"
else
    info "Cloning llama.cpp..."
    if [[ -d "$LLAMA_DIR" ]]; then
        cd "$LLAMA_DIR" && git pull -q
    else
        git clone --depth=1 https://github.com/ggerganov/llama.cpp "$LLAMA_DIR" -q
    fi

    info "Compiling with Metal GPU support (3-5 minutes)..."
    cd "$LLAMA_DIR"
    cmake -B build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release -Wno-dev -DLLAMA_CURL=OFF > /tmp/zyrcon-build.log 2>&1
    cmake --build build --config Release --target llama-server -j$(sysctl -n hw.logicalcpu) >> /tmp/zyrcon-build.log 2>&1

    if [[ ! -f "$LLAMA_BIN" ]]; then
        fail "Build failed. See /tmp/zyrcon-build.log for details."
    fi
    ok "llama-server compiled with Metal GPU"
fi

# ── Download model ────────────────────────────────────────────────────────────
step "5/7" "Downloading Zyrcon AI model (qwen2.5-3b, ~2GB)"

if [[ -f "$MODEL_FILE" ]]; then
    MODEL_SIZE=$(du -sh "$MODEL_FILE" 2>/dev/null | cut -f1)
    ok "Model already downloaded ($MODEL_SIZE)"
else
    info "Downloading from HuggingFace (~2GB, please wait)..."
    curl -L --progress-bar "$MODEL_URL" -o "$MODEL_FILE"
    if [[ ! -f "$MODEL_FILE" ]]; then
        fail "Model download failed. Check your internet connection."
    fi
    MODEL_SIZE=$(du -sh "$MODEL_FILE" | cut -f1)
    ok "Model downloaded ($MODEL_SIZE)"
fi

# ── Write Zyrcon start script ─────────────────────────────────────────────────
step "6/7" "Installing Zyrcon AI server"

# Detect RAM and set safe context size
RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 17179869184)
RAM_GB_NUM=$((RAM_BYTES / 1024 / 1024 / 1024))
if [[ $RAM_GB_NUM -le 8 ]]; then
    CTX=4096
    PARALLEL=1
elif [[ $RAM_GB_NUM -le 16 ]]; then
    CTX=8192
    PARALLEL=2
else
    CTX=32768
    PARALLEL=4
fi
info "RAM: ${RAM_GB_NUM}GB → context: ${CTX} tokens, parallel: ${PARALLEL} slots"

cat > "$ZYRCON_DIR/start.sh" << STARTSCRIPT
#!/bin/bash
# Zyrcon AI v0.1 — start script
# Auto-generated by installer on $(date)
LLAMA_SERVER="$LLAMA_BIN"
MODEL="$MODEL_FILE"
LOG="$LOG_DIR/zyrcon.log"
mkdir -p "$LOG_DIR"
echo "[\$(date)] Starting Zyrcon AI ${VERSION}..." >> "\$LOG"
"\$LLAMA_SERVER" \\
  --model "\$MODEL" \\
  --port $ZYRCON_PORT \\
  --host 127.0.0.1 \\
  --ctx-size $CTX \\
  --n-gpu-layers 99 \\
  --threads 4 \\
  --parallel $PARALLEL \\
  --flash-attn on \\
  --alias zyrcon-ai-v0.1 \\
  >> "\$LOG" 2>&1
STARTSCRIPT
chmod +x "$ZYRCON_DIR/start.sh"
ok "Start script written (~/${ZYRCON_DIR#$HOME}/start.sh)"

# LaunchAgent — auto-start on login
cat > "$LAUNCH_AGENT" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.zyrcon.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$ZYRCON_DIR/start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/zyrcon.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/zyrcon-error.log</string>
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST

launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
launchctl load "$LAUNCH_AGENT"
ok "LaunchAgent installed — Zyrcon starts on login"

# SwiftBar plugin
if [[ -d "$SWIFTBAR_DIR" ]] || command -v swiftbar &>/dev/null; then
    mkdir -p "$SWIFTBAR_DIR"
    cat > "$SWIFTBAR_DIR/zyrcon.5s.sh" << 'SWIFTBAR'
#!/bin/bash
# Zyrcon AI v0.1 — SwiftBar plugin
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

ZYRCON_START="$HOME/.zyrcon/start.sh"
LOG="$HOME/.zyrcon/logs/zyrcon.log"
SELF="$HOME/SwiftBar/zyrcon.5s.sh"

case "$1" in
  start)  nohup bash "$ZYRCON_START" >> "$LOG" 2>&1 & disown; exit 0 ;;
  stop)   pkill -f "llama-server" 2>/dev/null; exit 0 ;;
  logs)   open "$HOME/.zyrcon/logs"; exit 0 ;;
esac

zyrcon_ok=false
pgrep -f "llama-server" > /dev/null 2>&1 && zyrcon_ok=true
JOBS=$(grep -c "POST /v1/chat" "$LOG" 2>/dev/null || echo "0")

if $zyrcon_ok; then
    echo "⚡Z | color=#00C853 font=Menlo-Bold size=12"
    echo "---"
    echo "Zyrcon AI v0.1 | font=Menlo-Bold color=#FFFFFF"
    echo "Online :8080  •  jobs: $JOBS | color=#00C853"
    echo "---"
    echo "Stop Zyrcon | bash='$SELF' param1=stop terminal=false refresh=true color=#FF6B6B"
    echo "View Logs | bash='$SELF' param1=logs terminal=false color=#888888"
else
    echo "◯ Z | color=#FF3B30 font=Menlo-Bold size=12"
    echo "---"
    echo "Zyrcon AI v0.1 | font=Menlo-Bold color=#FFFFFF"
    echo "Offline | color=#FF3B30"
    echo "---"
    echo "Start Zyrcon | bash='$SELF' param1=start terminal=false refresh=true color=#00C853"
fi
echo "---"
echo "Refresh | refresh=true color=#888888"
SWIFTBAR
    chmod +x "$SWIFTBAR_DIR/zyrcon.5s.sh"
    ok "SwiftBar plugin installed"
fi

# ── Start and verify ──────────────────────────────────────────────────────────
step "7/7" "Starting Zyrcon AI and verifying"

pkill -f "llama-server" 2>/dev/null || true
sleep 1
nohup bash "$ZYRCON_DIR/start.sh" >> "$LOG_DIR/zyrcon.log" 2>&1 &
disown

info "Waiting for server to load model..."
for i in {1..30}; do
    sleep 2
    if curl -s http://127.0.0.1:$ZYRCON_PORT/health 2>/dev/null | grep -q "ok"; then
        break
    fi
    if [[ $i -eq 30 ]]; then
        warn "Server taking longer than expected. Check logs: ~/.zyrcon/logs/zyrcon.log"
    fi
done

if curl -s http://127.0.0.1:$ZYRCON_PORT/health 2>/dev/null | grep -q "ok"; then
    RESPONSE=$(curl -s http://127.0.0.1:$ZYRCON_PORT/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{"model":"zyrcon-ai-v0.1","messages":[{"role":"user","content":"Say only: Zyrcon online"}],"max_tokens":10}' \
      2>/dev/null | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['choices'][0]['message']['content'])" 2>/dev/null)
    ok "Server healthy — model responded: $RESPONSE"
else
    warn "Server not yet ready — it will finish loading in the background"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${BOLD}  Zyrcon AI v0.1 installed successfully!${NC}"
echo -e "  ${GREEN}${BOLD}════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}API endpoint:${NC}  http://127.0.0.1:8080"
echo -e "  ${BOLD}Model:${NC}         zyrcon-ai-v0.1 (qwen2.5-3b)"
echo -e "  ${BOLD}Auto-start:${NC}    enabled (starts on login)"
echo -e "  ${BOLD}Logs:${NC}          ~/.zyrcon/logs/zyrcon.log"
echo ""
echo -e "  ${CYAN}Quick test:${NC}"
echo -e "  curl http://127.0.0.1:8080/health"
echo ""
echo -e "  ${CYAN}Connect OpenClaw:${NC}"
echo -e "  Provider URL: http://127.0.0.1:8080"
echo -e "  Model: zyrcon-ai-v0.1"
echo ""
echo -e "  ${CYAN}Uninstall:${NC}"
echo -e "  curl -fsSL https://raw.githubusercontent.com/zyrconai/zyrcon/main/uninstall.sh | bash"
echo ""
