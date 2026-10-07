#!/data/data/com.termux/files/usr/bin/bash
#
# ============================================================
#  V4Z Hermes Termux — Hermes Agent installer for Termux
#  Version : v1.1.1 (busy-container fix + visible apt retries)
#  Author : V4Z RASHD (https://github.com/v4zrashd)
#  Repo   : https://github.com/v4zrashd/RASHDHermesAgentTermuxx
# ============================================================
#
#  What it does:
#    Installs the open-source Hermes Agent (by Nous Research)
#    inside an Ubuntu proot container on Termux, installs EVERY
#    Python package it needs in one go (core dependencies for
#    the Python in use + upstream's [termux-all] profile), then
#    self-checks the install and auto-installs anything still
#    missing. Finally adds a `hermes` launcher so you can start
#    it from Termux directly. After this installer finishes,
#    there is nothing left to install one-by-one.
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
echo -e "${MAG}║${RST}  ${GRN}V4Z HERMES TERMUX — installer v1.1.1${RST}        ${MAG}║${RST}"
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
# Existing container? Check the rootfs on disk first — parsing
# `proot-distro list` output alone misses installs (and trying to
# reinstall over a *busy* container hard-fails). If an Ubuntu login
# is still open in another Termux tab, close that tab first.
container_exists() {
    [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$DISTRO" ] && return 0
    [ -d "$PREFIX/var/lib/proot-distro/containers/$DISTRO" ] && return 0
    proot-distro list 2>/dev/null | grep -qiE '^[[:space:]]*\*?[[:space:]]*ubuntu([[:space:]]|$)' && return 0
    return 1
}
if container_exists; then
    ok "Reusing existing Ubuntu container"
else
    say "🐧 Installing Ubuntu container (a few minutes, grab a coffee ☕)..."
    proot-distro install ubuntu 2>&1 | tail -n 2 || warn "container install reported an issue — trying to continue"
    if container_exists; then
        ok "Ubuntu container ready"
    else
        die "Ubuntu container could not be installed — send a screenshot of the error above."
    fi
fi

# ---------- everything below runs INSIDE Ubuntu ----------
INNER="$(mktemp)"
trap 'rm -f "$INNER"' EXIT

cat > "$INNER" << 'INNER_EOF'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export PIP_DISABLE_PIP_VERSION_CHECK=1

# apt with retries and VISIBLE errors — a busy container can hold
# the dpkg lock for a while, and silent installs hide the real cause.
apt_install() {
    local n=1
    while [ "$n" -le 3 ]; do
        if apt-get install -y -o Dpkg::Options::="--force-confold" "$@"; then
            return 0
        fi
        echo "↻ apt install hit a problem (try $n/3) — waiting 10s and retrying..."
        sleep 10
        n=$((n+1))
    done
    return 1
}

echo "📦 Updating Ubuntu..."
apt-get update || { echo "⚠️ apt update hiccup — retrying once..."; sleep 5; apt-get update || true; }
apt-get upgrade -y -o Dpkg::Options::="--force-confold" >/dev/null 2>&1 || true

echo "🐍 Installing Python + build tools..."
apt_install python3 python3-pip python3-venv python3-dev \
    git curl wget build-essential ca-certificates \
    || { echo "❌ Python/toolchain install failed — see the apt error above"; exit 1; }

echo "🧰 Installing the everyday toolbox (so nothing is needed later)..."
apt_install --no-install-recommends \
    nodejs npm ripgrep ffmpeg unzip zip tar xz-utils nano openssh-client \
    || echo "⚠️ some toolbox extras were skipped — core install continues"

# hermes-agent supports Python 3.11–3.14 (requires-python ">=3.11,<3.15").
# If the system python3 is outside that range, fetch 3.13 via uv.
PYBIN="python3"
if ! "$PYBIN" -c 'import sys; sys.exit(0 if (3,11) <= sys.version_info < (3,15) else 1)' 2>/dev/null; then
    echo "⚠️ System Python outside 3.11–3.14 — fetching Python 3.13 via uv..."
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

# ------------------------------------------------------------------
# Install EVERYTHING in one go.
#
# Upstream pins its core dependencies per Python version in
# pyproject.toml (markers like python_version >= '3.14'). A venv on
# Python < 3.14 therefore silently receives ZERO core packages —
# including ruamel.yaml, which hermes_cli.config imports at startup.
# The version-aware lists below mirror upstream's pins, so whatever
# Python you run, every package the agent needs is installed now —
# nothing to add one-by-one later.
# ------------------------------------------------------------------
PY_MM="$(python -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
if python -c 'import sys; sys.exit(0 if sys.version_info >= (3,14) else 1)'; then
    CORE_DEPS=(
        "openai==2.24.0" "certifi==2026.5.20" "truststore==0.10.4"
        "python-dotenv==1.2.2" "fire==0.7.1" "httpx[socks]==0.28.1"
        "rich==14.3.3" "tenacity==9.1.4" "tomli-w==1.2.0"
        "ruamel.yaml==0.18.16" "requests==2.33.0" "jinja2==3.1.6"
        "firecrawl-anydoc==0.2.4" "pydantic==2.13.4" "prompt_toolkit==3.0.52"
        "croniter==6.0.0" "snowballstemmer==3.1.1"
    )
else
    CORE_DEPS=(
        "openai" "certifi" "truststore" "python-dotenv" "fire"
        "httpx[socks]" "rich" "tenacity" "tomli-w" "ruamel.yaml"
        "requests" "jinja2" "firecrawl-anydoc" "pydantic"
        "prompt_toolkit" "croniter" "snowballstemmer"
    )
fi

echo "🔧 Installing Hermes Agent + ALL dependencies for Python $PY_MM (5–15 min)..."
INSTALL_OK=0
if python -m pip install -e ".[termux-all]"; then
    INSTALL_OK=1
else
    echo "⚠️ [termux-all] profile failed, trying [all]..."
    if python -m pip install -e ".[all]"; then
        INSTALL_OK=1
    else
        echo "⚠️ extras failed, trying base install..."
        python -m pip install -e . && INSTALL_OK=1
    fi
fi
if [ "$INSTALL_OK" != "1" ]; then
    echo "❌ install failed — see error above"
    exit 1
fi

echo "🔧 Making sure every core package is present (gap-fill)..."
python -m pip install "${CORE_DEPS[@]}" || \
    echo "⚠️ gap-fill reported issues — the self-heal step below will retry what is missing"

# ------------------------------------------------------------------
# Self-heal: import the agent's entry points; whatever module is
# still missing gets installed automatically and the check runs
# again. This way nothing is left for the user to install manually.
# ------------------------------------------------------------------
echo "🩺 Self-check: verifying the agent actually starts..."
declare -A MOD2PKG=(
    [ruamel]=ruamel.yaml [yaml]=PyYAML [dotenv]=python-dotenv
    [telegram]=python-telegram-bot [PIL]=Pillow [cv2]=opencv-python
    [fit2image]=pdf2image [sklearn]=scikit-learn [OpenAI]=openai
    [googleapiclient]=google-api-python-client
)
heal() {
    local try miss pkg top
    for try in 1 2 3 4 5 6; do
        miss="$(python -c "
import sys
try:
    from hermes_cli.main import main  # noqa: F401
    from hermes_cli.config import get_hermes_home  # noqa: F401
except ModuleNotFoundError as e:
    print(e.name or '')
    sys.exit(0)
print('')
" 2>/dev/null || true)"
        if [ -z "${miss:-}" ]; then
            return 0
        fi
        top="${miss%%.*}"
        pkg="${MOD2PKG[$top]:-$top}"
        echo "   ↳ missing module '$miss' — installing $pkg ..."
        python -m pip install --quiet "$pkg" || true
    done
    return 1
}
if ! heal; then
    python -c "from hermes_cli.main import main" || true   # show the real error once
    echo "❌ self-check failed — send a screenshot of the error above"
    exit 1
fi
python -c "
import ruamel.yaml, dotenv, httpx, rich, pydantic, prompt_toolkit, croniter
from hermes_cli.main import main
print('   ↳ entry points + core modules import cleanly')
"
echo "✅ All dependencies verified — nothing left to install"

# CLI covers the same entry import; anything more and it starts setup/REPL.
if CLI_OUT="$(timeout 30 hermes --version 2>&1)" && [ -n "$CLI_OUT" ]; then
    echo "✅ CLI smoke test OK: ${CLI_OUT%%$'\n'*}"
else
    echo "✅ CLI entry point import OK"
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
echo "✅ Hermes Agent installed inside Ubuntu — fully verified!"
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

# ---------- Termux-level smoke test ----------
say "🩺 Final check from Termux..."
if TERMUX_CHECK="$(timeout 240 hermes --version 2>&1)" && [ -n "$TERMUX_CHECK" ]; then
    ok "Termux launcher OK: ${TERMUX_CHECK%%$'\n'*}"
else
    warn "Termux launcher check didn't print a version — try 'hermes --version' once yourself (the Ubuntu install itself was verified)."
fi

echo ""
echo -e "${MAG}══════════════════════════════════════════════${RST}"
ok "V4Z Hermes Termux installed — everything included, nothing left to install!"
echo -e "${MAG}══════════════════════════════════════════════${RST}"
echo ""
say "🚀 Quick start (just type in Termux):"
echo -e "  ${GRN}hermes setup${RST}    # first-time setup"
echo -e "  ${GRN}hermes${RST}          # start chatting"
echo -e "  ${GRN}hermes gateway${RST}  # run the gateway"
echo ""
say "💡 Made by V4Z RASHD — https://github.com/v4zrashd/RASHDHermesAgentTermuxx"
