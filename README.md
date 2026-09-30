<div align="center">

# ⚡ V4Z Hermes Termux

### Run a self-evolving AI assistant on your Android phone

![Termux](https://img.shields.io/badge/Termux-Android-6f42c1?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-9146ff?style=for-the-badge)
![Made by](https://img.shields.io/badge/made%20by-V4Z%20RASHD-00ff88?style=for-the-badge)

**Transform your Android device into a portable AI assistant — no server, no fees.**

</div>

---

## ✨ What is this?

**V4Z Hermes Termux** is a one-command installer that sets up the open-source **Hermes Agent**
(an AI framework by Nous Research) inside an Ubuntu container on Termux, and gives you a
simple `hermes` command to talk to it — straight from your phone.

| 🧠 Self-learning | 📱 Portable | 🔒 Private | 🛠️ Extensible |
|---|---|---|---|
| Gets smarter over time | Your assistant, everywhere | Runs on your device | 70+ tools |

---

## 🚀 One-line install

Paste this in **Termux**:

```bash
curl -fsSL https://raw.githubusercontent.com/v4zrashd/RASHDHermesAgentTermuxx/main/install.sh | bash
```

Takes ~5–15 minutes depending on your connection. Grab a coffee ☕

### Manual install

```bash
pkg install git
git clone https://github.com/v4zrashd/RASHDHermesAgentTermuxx.git
cd RASHDHermesAgentTermuxx
chmod +x install.sh
./install.sh
```

---

## 🤖 Usage

After installing, just type in Termux:

```bash
hermes setup     # first-time setup (pick your model provider)
hermes           # start chatting
hermes gateway   # run the gateway
```

### Manual path (if the wrapper is missing)

```bash
proot-distro login ubuntu
cd hermes-agent && source venv/bin/activate
hermes
```

---

## 🗑️ Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/v4zrashd/RASHDHermesAgentTermuxx/main/uninstall.sh | bash
```

Removes the agent, the launchers, and (optionally) the Ubuntu container. Termux itself is never touched.

---

## ⚙️ Requirements

| | Minimum | Recommended |
|---|---|---|
| Android | 11 | 13 / 14 / 15 |
| Storage | 3 GB | 5 GB+ |
| RAM | 2 GB | 4 GB+ |
| Termux | Latest (F-Droid) | Latest (F-Droid) |

---

## 🎛️ Model freedom

Works with 200+ models — OpenAI, Anthropic Claude, Google Gemini, DeepSeek, Qwen —
or fully local models via Ollama:

```bash
pkg install ollama
ollama serve
ollama run gemma3:4b
```

---

## 🙏 Credits

- **Nous Research** — creators of the open-source Hermes Agent framework
- **Termux team** — for making Android development possible
- **V4Z RASHD** — installer, scripts & docs in this repo

---

<div align="center">

**⭐ Star this repo if it helped you!**

Made with ⚡ by [V4Z RASHD](https://github.com/v4zrashd)

</div>
