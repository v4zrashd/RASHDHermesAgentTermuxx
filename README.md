<div align="center">

![V4Z Hermes Termux](https://i.ibb.co/m5pPzNX7/V4-Z-Hermes-Termux-banner.jpg)

# ⚡ V4Z Hermes Termux — Hermes Agent for Android (Termux)

### Run a self-evolving AI assistant on your phone

[![License: MIT](https://img.shields.io/badge/license-MIT-9146ff?style=for-the-badge)](LICENSE)
[![Termux](https://img.shields.io/badge/Termux-Android-6f42c1?style=for-the-badge)](https://termux.com)
[![Version](https://img.shields.io/badge/version-v1.1.1-00ff88?style=for-the-badge)](https://github.com/v4zrashd/RASHDHermesAgentTermuxx)
[![Made by](https://img.shields.io/badge/made%20by-V4Z%20RASHD-ff00aa?style=for-the-badge)](https://github.com/v4zrashd)

[![Typing SVG](https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=22&pause=1000&color=00FF88&center=true&vCenter=true&width=650&lines=Your+pocket+AI+assistant+is+here;Self-learning.+Always+with+you.;One+command.+Zero+servers.;Built+by+V4Z+RASHD)](https://git.io/typing-svg)

**Transform your Android device into a powerful, learning AI assistant — no server, no fees.**

</div>

---

## ✨ What is Hermes Agent?

**Hermes Agent** is an open-source, self-evolving AI framework created by **Nous Research**.
Think of it as *Jarvis in your pocket* — an AI that learns, adapts, and gets smarter
with every conversation.

**V4Z Hermes Termux** is my installer that sets all of it up on your phone automatically:
Ubuntu container, Python environment, the agent itself, and a one-word `hermes` launcher.

| 🧠 Self-learning | 🔄 Cross-platform | 💾 Persistent memory | 🛠️ 70+ tools |
|---|---|---|---|
| Gets smarter over time | Runs on 16+ apps | Remembers your preferences | Executes complex tasks |

---

## ⏱️ Installation takes ~5–15 minutes — grab a coffee! ☕

```mermaid
graph LR
    A[📱 Open Termux] --> B[📋 Copy Command]
    B --> C[⚡ Paste & Run]
    C --> D[🔄 Auto-Install]
    D --> E[✅ Ready to Use!]
```

---

## 🚀 One-line installation

Copy and paste this in **Termux**:

```bash
curl -fsSL https://raw.githubusercontent.com/v4zrashd/RASHDHermesAgentTermuxx/main/install.sh | bash
```

That's it. The script does everything: updates Termux, sets up Ubuntu, installs Python,
clones the agent, and creates your `hermes` command.

---

## 🛠️ Manual installation

Prefer doing it yourself? Step by step:

```bash
pkg install git
```

```bash
# 1. Clone this repository
git clone https://github.com/v4zrashd/RASHDHermesAgentTermuxx.git
cd RASHDHermesAgentTermuxx

# 2. Make the script executable
chmod +x install.sh

# 3. Run the installer
./install.sh
```

---

## 📱 Full Termux step-by-step guide

Everything at command level — from a fresh Termux install to a working agent.
Run these **one by one** in Termux.

### 1️⃣ Set up Termux (first time)

```bash
# Allow storage access (grant the popup on your phone)
termux-setup-storage
```

### 2️⃣ Update all packages

```bash
pkg update -y
pkg upgrade -y
```

### 3️⃣ Core packages

```bash
pkg install -y proot-distro git curl
```

### 4️⃣ Install Ubuntu container

```bash
proot-distro install ubuntu
proot-distro login ubuntu
```

### 5️⃣ Inside Ubuntu — Python toolchain

```bash
apt update && apt install -y python3 python3-pip python3-venv git curl build-essential
```

### 6️⃣ Clone & install the agent

```bash
git clone --depth 1 https://github.com/NousResearch/hermes-agent.git ~/hermes-agent
cd ~/hermes-agent
python3 -m venv venv && source venv/bin/activate
pip install -e ".[all]"
```

### 7️⃣ Run it

```bash
hermes setup   # first-time setup
hermes         # start chatting
```

> 💡 **Or skip all of the above** — the one-line installer does steps 1–7 for you automatically.

---

## 🔁 What the installer sets up

| Purpose | Details |
|---|---|
| Base update | `pkg update && pkg upgrade` |
| Storage access | `termux-setup-storage` |
| Container | Ubuntu via `proot-distro` (reuses yours if it exists) |
| Python | 3.11–3.13 (auto-fetches 3.13 via `uv` if Ubuntu ships 3.14+) |
| Agent | Cloned from `NousResearch/hermes-agent`, installed in a venv |
| Launcher | `hermes` command works directly from Termux |

---

## 🤖 Start the agent

After installing, from Termux:

```bash
hermes setup     # first-time setup — choose your model provider
hermes           # start chatting
hermes gateway   # run the gateway mode
```

### Manual path (if the wrapper is missing)

```bash
proot-distro login ubuntu
cd hermes-agent && source venv/bin/activate
hermes
```

---

## 🆕 What's new in v1.1.1

- **Busy-container fix** — an already-installed Ubuntu is now detected from its rootfs on disk, so the installer never tries to reinstall over a running ("busy") container.
- **Visible, retrying apt** — Ubuntu package installs now show real errors and retry automatically (e.g. while another session holds the dpkg lock) instead of failing silently.
- Everything else from v1.1.0 below still applies.

## 🆕 What's new in v1.1.0

- **Everything in one go** — the installer now pulls the complete dependency set for your Python version plus Hermes Agent's official `[termux-all]` profile. No more `ModuleNotFoundError` (e.g. `ruamel`) after install, and nothing to install one-by-one later.
- **Everyday toolbox included** — Node.js, npm, ripgrep, ffmpeg, unzip/zip, tar and nano are installed up front for the agent's tools.
- **Self-check + self-heal** — before declaring success, the installer imports the agent's entry points; if anything is somehow still missing, it installs it automatically and checks again, then runs `hermes --version` as a final smoke test.
- Re-running the installer safely repairs or updates an existing install.

## 🗑️ Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/v4zrashd/RASHDHermesAgentTermuxx/main/uninstall.sh | bash
```

Removes the agent, launchers, and optionally the Ubuntu container (it asks first).
Termux itself is never touched.

---

## ⚙️ System requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Android version | 11 | 13 / 14 / 15 |
| Storage | 3 GB | 5 GB+ |
| RAM | 2 GB | 4 GB+ |
| Internet | Required | Fast connection |
| Termux | Latest from F-Droid | Latest from F-Droid |

---

## 🌍 Why run Hermes on Android?

| Benefit | Description |
|---|---|
| 📱 Portable AI | Your assistant goes everywhere with you |
| 🔒 Privacy | Runs on your own device |
| 💰 Cost-effective | No server hosting fees |
| ⚡ Low latency | Direct on-device execution |
| 🔄 Always available | Works offline with local models |

---

## 🎛️ AI model freedom

Works with 200+ models: **OpenAI** (GPT-4), **Anthropic** (Claude), **Google** (Gemini),
**DeepSeek**, **Qwen** — or fully local models via Ollama:

```bash
pkg install ollama
ollama serve
ollama run gemma3:4b
```

---

## 🙏 Credits

- **Nous Research** — creators of the open-source Hermes Agent framework
- **Termux team** — for making Android development possible
- **Open-source community** — for the countless tools this is built on
- **V4Z RASHD** — installer scripts, branding & docs in this repo
- **W8SOJIB** — public Termux guide ideas this installer was benchmarked against (the implementation here is original)

---

<div align="center">

## ⭐ If this helped you, give it a star! ⭐

Made with ⚡ by [V4Z RASHD](https://github.com/v4zrashd)

</div>
