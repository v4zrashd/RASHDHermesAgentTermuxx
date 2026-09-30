#!/data/data/com.termux/files/usr/bin/bash
#
# ============================================================
#  V4Z Hermes Termux — uninstaller
#  Author : V4Z RASHD (https://github.com/v4zrashd)
# ============================================================
#
#  One-line uninstall (in Termux):
#    curl -fsSL https://raw.githubusercontent.com/v4zrashd/RASHDHermesAgentTermuxx/main/uninstall.sh | bash
#
set -euo pipefail

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'; CYN='\033[0;36m'; RST='\033[0m'
export TERM="${TERM:-xterm}"

echo -e "${YLW}🗑️  Uninstalling V4Z Hermes Termux...${RST}"

# 1) Termux-level wrapper
rm -f "$PREFIX/bin/hermes" 2>/dev/null && echo -e "${GRN}✅ removed Termux wrapper${RST}"

# 2) Inside Ubuntu: agent source, venv, launcher, PATH line
proot-distro login ubuntu -- bash -lc '
    rm -rf ~/hermes-agent ~/.local/bin/hermes 2>/dev/null
    sed -i "/\.local\/bin/d" ~/.bashrc 2>/dev/null
    echo "✅ removed agent files inside Ubuntu"
' 2>/dev/null || echo -e "${YLW}⚠️ Ubuntu container not found — skipping inner cleanup${RST}"

# 3) Optionally remove the whole Ubuntu container
echo ""
echo -e "${CYN}Remove the entire Ubuntu container too? (y/N)${RST}"
read -r ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    proot-distro remove ubuntu 2>/dev/null && echo -e "${GRN}✅ Ubuntu container removed${RST}" \
        || echo -e "${YLW}⚠️ could not remove container${RST}"
else
    echo -e "${CYN}kept the Ubuntu container (only Hermes was removed)${RST}"
fi

echo ""
echo -e "${GRN}✅ V4Z Hermes Termux uninstalled. Termux itself was not touched.${RST}"
