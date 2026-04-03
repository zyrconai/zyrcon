# Zyrcon AI v0.1

**Private decentralized AI inference for macOS.**

Run powerful AI models locally. Your prompts never leave your machine unencrypted. No subscriptions. No OpenAI. No data collection.

---

## Install in one command

```bash
curl -fsSL https://raw.githubusercontent.com/zyrconai/zyrcon/main/install.sh | bash
```

That's it. The installer handles everything:
- Compiles llama.cpp with Apple Metal GPU acceleration
- Downloads the Zyrcon AI v0.1 model (~2GB)
- Sets up auto-start on login
- Installs SwiftBar menu bar control (if SwiftBar is installed)

**Requirements:** macOS 12+, Apple Silicon recommended, 8GB RAM minimum

---

## What you get

| Feature | Detail |
|---|---|
| **API endpoint** | `http://127.0.0.1:8080` |
| **OpenAI-compatible** | Drop-in replacement for OpenAI API |
| **Model** | qwen2.5-3b-instruct (Q4_K_M) |
| **GPU acceleration** | Apple Metal on M1/M2/M3 |
| **Auto-start** | Starts on login via LaunchAgent |
| **Menu bar** | SwiftBar plugin included |

---

## Connect to OpenClaw

1. Open OpenClaw settings
2. Add provider: `http://127.0.0.1:8080`
3. Select model: `zyrcon-ai-v0.1`

---

## Quick test

```bash
# Health check
curl http://127.0.0.1:8080/health

# Ask a question
curl http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "zyrcon-ai-v0.1",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 100
  }'
```

---

## Manual controls

```bash
# Start
bash ~/.zyrcon/start.sh &

# Stop
pkill -f llama-server

# View logs
tail -f ~/.zyrcon/logs/zyrcon.log

# Health check
curl http://127.0.0.1:8080/health
```

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/zyrconai/zyrcon/main/uninstall.sh | bash
```

---

## Roadmap

- [x] Local inference engine (llama.cpp + Metal)
- [x] OpenAI-compatible API
- [x] macOS auto-start
- [x] SwiftBar menu bar control
- [ ] Encrypted packet layer (AES-256)
- [ ] Two-node network routing
- [ ] Node earnings (Stripe)
- [ ] Mobile client
- [ ] Windows installer

---

## About

Zyrcon is building private decentralized AI infrastructure. The network is owned by the people who run nodes — not by any company.

**Website:** zyrcon.ai  
**Version:** v0.1.0  
**License:** MIT
