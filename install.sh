#!/data/data/com.termux/files/usr/bin/bash
#
# ============================================================
#  V4Z Hermes Termux — Hermes Agent installer for Termux
#  Author : V4Z RASHD (https://github.com/v4zrashd)
#  Repo   : https://github.com/v4zrashd/RASHDHermesAgentTermuxx
# ============================================================
#
#  What it does:
#    Installs the open-source Hermes Agent (by Nous Research)
#    inside an Ubuntu proot container on Termux, then adds a
#    `hermes` launcher so you can start it from Termux directly.
#
#  One-line install (in Termux):
#    curl -fsSL https://raw.githubusercontent.com/v4zrashd/RASHDHermesAgentTermuxx/main/install.sh | bash
#
set -euo pipefail

# ---------- pretty output ----------
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
CYN='\033[0;36m'; MAG='\033[0;35m'; RST='\033[0m'
export TERM="${TERM:-xterm}"
export DEBIAN_FRONTEND=noninteractive

say()  { echo -e "${CYN}$*${RST}"; }
ok()   { echo -e "${GRN}✅ $*${RST}"; }
warn() { echo -e "${YLW}⚠️ $*${RST}"; }
die()  { echo -e "${RED}❌ $*${RST}"; exit 1; }

clear 2>/dev/null || true
echo -e "${MAG}╔══════════════════════════════════════════════╗${RST}"
echo -e "${MAG}║${RST}  ${GRN}V4Z HERMES TERMUX — installer${RST}              ${MAG}║${RST}"
echo -e "${MAG}║${RST}  ${CYN}by V4Z RASHD${RST}                               ${MAG}║${RST}"
echo -e "${MAG}╚══════════════════════════════════════════════╝${RST}"
echo ""

# ---------- Termux level ----------
termux-wake-lock 2>/dev/null || true   # keep Android from killing Termux mid-install

say "📦 Updating Termux packages..."
pkg update -y 2>&1 | tail -n 1 || warn "pkg update had issues, continuing..."
pkg upgrade -y 2>&1 | tail -n 1 || true

say "📦 Installing base tools (proot-distro, git, curl)..."
pkg install -y proot-distro git curl 2>&1 | tail -n 1

# ---------- Ubuntu container ----------
DISTRO="ubuntu"
if proot-distro list 2>/dev/null | grep -qiE '^[[:space:]]*\*?[[:space:]]*ubuntu([[:space:]]|$)'; then
    ok "Reusing existing Ubuntu container"
else
    say "🐧 Installing Ubuntu container (a few minutes, grab a coffee ☕)..."
    proot-distro install ubuntu 2>&1 | tail -n 2 || warn "container install reported an issue — trying to continue"
    ok "Ubuntu container ready"
fi

# ---------- everything below runs INSIDE Ubuntu ----------
INNER="$(mktemp)"
trap 'rm -f "$INNER"' EXIT

cat > "$INNER" << 'INNER_EOF'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "📦 Updating Ubuntu..."
apt-get update -qq
apt-get upgrade -y -o Dpkg::Options::="--force-confold" >/dev/null 2>&1 || true

echo "🐍 Installing Python + build tools..."
apt-get install -y -o Dpkg::Options::="--force-confold" \
    python3 python3-pip python3-venv python3-dev \
    git curl wget build-essential ca-certificates >/dev/null 2>&1

# hermes-agent needs Python >=3.11 and <3.14.
# Newer Ubuntu ships 3.14+, so fall back to 3.13 via uv when needed.
PYBIN="python3"
if ! "$PYBIN" -c 'import sys; sys.exit(0 if (3,11) <= sys.version_info < (3,14) else 1)' 2>/dev/null; then
    echo "⚠️ Default Python too new for hermes-agent — fetching Python 3.13 via uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || true
    export PATH="$HOME/.local/bin:$PATH"
    uv python install 3.13 >/dev/null 2>&1 || true
    PYBIN="$(uv python find 3.13 2>/dev/null || echo python3)"
fi
echo "✅ Using: $("$PYBIN" --version 2>&1)"

AGENT_DIR="$HOME/hermes-agent"
if [ -d "$AGENT_DIR/.git" ]; then
    echo "🔄 Updating existing hermes-agent..."
    git -C "$AGENT_DIR" pull --ff-only 2>/dev/null || true
else
    echo "📥 Cloning Hermes Agent (open-source, by Nous Research)..."
    rm -rf "$AGENT_DIR"
    git clone --depth 1 https://github.com/NousResearch/hermes-agent.git "$AGENT_DIR"
fi

cd "$AGENT_DIR"
echo "🐍 Creating virtual environment..."
rm -rf venv
"$PYBIN" -m venv venv
# shellcheck disable=SC1091
source venv/bin/activate

echo "⬆️ Upgrading pip..."
python -m pip install --quiet --upgrade pip setuptools wheel

echo "🔧 Installing Hermes Agent (5–10 min on first run)..."
if ! python -m pip install -e ".[all]"; then
    echo "⚠️ full extras failed, trying base install..."
    python -m pip install -e . || { echo "❌ install failed — see error above"; exit 1; }
fi

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/hermes" << 'EOF'
#!/bin/bash
# V4Z Hermes Termux — in-container launcher
cd "$HOME/hermes-agent" || exit 1
source venv/bin/activate
exec hermes "$@"
EOF
chmod +x "$HOME/.local/bin/hermes"
grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

echo ""
echo "✅ Hermes Agent installed inside Ubuntu!"
INNER_EOF

say "🚀 Installing inside Ubuntu (5–15 min depending on connection)..."
proot-distro login "$DISTRO" -- bash "$INNER" || die "installation inside Ubuntu failed"

# ---------- Termux-level wrapper ----------
WRAPPER="$PREFIX/bin/hermes"
cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# V4Z Hermes Termux — run hermes straight from Termux
exec proot-distro login ubuntu -- bash -lc 'source ~/hermes-agent/venv/bin/activate && exec hermes "$@"' hermes "$@"
WRAPPER_EOF
chmod +x "$WRAPPER"

echo ""
echo -e "${MAG}══════════════════════════════════════════════${RST}"
ok "V4Z Hermes Termux installed!"
echo -e "${MAG}══════════════════════════════════════════════${RST}"
echo ""
say "🚀 Quick start (just type in Termux):"
echo -e "  ${GRN}hermes setup${RST}    # first-time setup"
echo -e "  ${GRN}hermes${RST}          # start chatting"
echo -e "  ${GRN}hermes gateway${RST}  # run the gateway"
echo ""
say "💡 Made by V4Z RASHD — https://github.com/v4zrashd/RASHDHermesAgentTermuxx"
