#!/bin/bash
# Zyrcon AI v0.1 — Uninstaller

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}Zyrcon AI v0.1 — Uninstaller${NC}"
echo ""

read -p "  Remove Zyrcon AI? This keeps your models. (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "  Cancelled."
    exit 0
fi

# Stop server
pkill -f "llama-server" 2>/dev/null && echo -e "  ${GREEN}✓${NC}  Server stopped"

# Remove LaunchAgent
launchctl unload ~/Library/LaunchAgents/ai.zyrcon.server.plist 2>/dev/null
rm -f ~/Library/LaunchAgents/ai.zyrcon.server.plist
echo -e "  ${GREEN}✓${NC}  LaunchAgent removed"

# Remove SwiftBar plugin
rm -f ~/SwiftBar/zyrcon.5s.sh
echo -e "  ${GREEN}✓${NC}  SwiftBar plugin removed"

# Remove start script
rm -f ~/.zyrcon/start.sh
echo -e "  ${GREEN}✓${NC}  Start script removed"

read -p "  Also remove model file (~2GB)? (y/N): " remove_model
if [[ "$remove_model" == "y" || "$remove_model" == "Y" ]]; then
    rm -f ~/.zyrcon/models/zyrcon-v0.1-3b.gguf
    echo -e "  ${GREEN}✓${NC}  Model removed"
fi

echo ""
echo -e "  ${GREEN}Zyrcon AI uninstalled.${NC}"
echo "  llama.cpp kept at ~/llama.cpp"
echo ""
