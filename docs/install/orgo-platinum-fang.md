---
title: "Platinum Fang on Orgo"
description: "Run your Platinum Fang (OhWhale515/openclaw) on Orgo with the same secure baseline as Docker"
summary: "Clone your fork, apply Platinum Fang baseline config (no Docker), start gateway, pair Discord"
read_when:
  - You run Platinum Fang from https://github.com/OhWhale515/openclaw on an Orgo computer
  - You want the same Discord/safe-mode policy as the Docker runbook without Docker
---

# Platinum Fang on Orgo

This runbook maps the **Platinum Fang** setup from your repo ([OhWhale515/openclaw](https://github.com/OhWhale515/openclaw)) to a **native (no Docker)** run on an [Orgo](https://www.orgo.ai) computer. You get the same secure baseline (Discord pairing, guild allowlist, mention gating, tools profile, model chain) as in [DISCORD_SETUP_WALKTHROUGH](https://github.com/OhWhale515/openclaw/blob/main/DISCORD_SETUP_WALKTHROUGH.md) and [platinumfang-setup.sh](https://github.com/openclaw/openclaw/blob/main/scripts/platinumfang-setup.sh), but using `node openclaw.mjs` instead of Docker.

## What this gives you

- **Gateway:** `gateway.mode=local`, `gateway.bind=loopback` (or `lan` on Orgo so the Control UI is reachable on the same desktop).
- **Discord:** Enabled, `dmPolicy=pairing`, `groupPolicy=allowlist`, one guild with `requireMention: true` and your user ID.
- **Tools:** `tools.profile=messaging`, deny list for gateway/cron/sessions/risk groups, `tools.fs.workspaceOnly=true`, elevated disabled.
- **Session:** `session.dmScope=per-channel-peer`.
- **Models:** Primary = OpenRouter `arcee-ai/trinity-large-preview:free`; fallback = `openrouter/openrouter/free`. Override with env vars (see [OpenRouter / Arcee Trinity](#openrouter--arcee-trinity-as-primary-model)).

## Prerequisites

- Orgo computer (Ubuntu) with root or sudo.
- Your Discord server ID and user ID (see [DISCORD_SETUP_WALKTHROUGH](https://github.com/OhWhale515/openclaw/blob/main/DISCORD_SETUP_WALKTHROUGH.md)).
- Discord bot token (from Discord Developer Portal).
- **OpenRouter API key** when using the default model (Arcee Trinity). Get one at [openrouter.ai/keys](https://openrouter.ai/keys). Set `OPENROUTER_API_KEY` in the environment before starting the gateway.
- **Gemini API key** (for web search). Get one at [Google AI Studio](https://aistudio.google.com/apikey). Set `GEMINI_API_KEY` in the environment (or use the [env file](#safest-key-storage-env-file) below).

## 1) Install git and Node on Orgo

On the Orgo computer:

```bash
apt-get update && apt-get install -y git curl
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
apt-get install -y nodejs
node -v
sudo npm install -g pnpm
```

## 2) Clone your fork and build

```bash
cd ~
git clone https://github.com/OhWhale515/openclaw.git openclaw
cd openclaw
pnpm install
pnpm ui:build
pnpm build
```

To **update** later:

```bash
cd ~/openclaw
git pull origin main
pnpm install
pnpm ui:build
pnpm build
```

## 3) Apply Platinum Fang baseline config

From repo root. Optionally set your Discord server/user IDs and token:

```bash
cd ~/openclaw

# Optional: override defaults (defaults match your fork's walkthrough)
export DISCORD_SERVER_ID="1478877509285318656"
export DISCORD_USER_ID="1143280146435027108"

# Set bot token and write it into config (recommended only on first run; then unset env)
export SET_TOKEN=1
export DISCORD_BOT_TOKEN="YOUR_DISCORD_BOT_TOKEN"

chmod +x scripts/platinumfang-orgo-baseline.sh
./scripts/platinumfang-orgo-baseline.sh

# Clear token from shell after run
unset DISCORD_BOT_TOKEN SET_TOKEN
```

If you prefer to set the token later (or keep it out of the script):

```bash
export SET_TOKEN=0
./scripts/platinumfang-orgo-baseline.sh
# Then:
node openclaw.mjs config set channels.discord.token '"YOUR_DISCORD_BOT_TOKEN"' --json
```

Config is written to `~/.openclaw/openclaw.json` (or `$OPENCLAW_HOME/openclaw.json`).

**CLI on Orgo:** The `openclaw` command is not installed globally. From the repo root run:

```bash
cd ~/openclaw
node openclaw.mjs config get tools.profile
node openclaw.mjs config set tools.profile messaging
```

## 4) Start the gateway

Set the OpenRouter API key (for Arcee Trinity) and, for web search, `GEMINI_API_KEY`. Then start the gateway. See [Safest key storage (env file)](#safest-key-storage-env-file) and [Gemini as web search](#gemini-as-web-search) for details.

**Foreground (with env file):**

```bash
cd ~/openclaw
set -a && source ~/.openclaw/.env && set +a
node openclaw.mjs gateway --port 18789 --bind lan
```

Or set env vars in the shell: `export OPENROUTER_API_KEY="..."` and `export GEMINI_API_KEY="..."`.

On Orgo you can bind to `lan` so the Control UI is reachable at `http://<orgo-ip>:18789` from the same Orgo desktop browser. For strict loopback-only, use `loopback` instead of `lan`.

**Background (optional; source env file or set vars in the same shell):**

```bash
cd ~/openclaw
set -a && source ~/.openclaw/.env && set +a
nohup node openclaw.mjs gateway --port 18789 --bind lan > /tmp/openclaw-gateway.log 2>&1 &
```

## OpenRouter / Arcee Trinity as primary model

The baseline script sets the primary model to **OpenRouter** `arcee-ai/trinity-large-preview:free` and fallbacks to `openrouter/openrouter/free`. No Ollama or local model is required.

- **Set OpenRouter API key** before starting the gateway (required for OpenRouter models):

  ```bash
  export OPENROUTER_API_KEY="your-openrouter-api-key"
  ```

  Get a key at [openrouter.ai/keys](https://openrouter.ai/keys).

- **Override primary or fallbacks** when running the baseline script:

  ```bash
  export PRIMARY_MODEL="openrouter/arcee-ai/trinity-large-preview:free"
  export FALLBACKS_JSON='["openrouter/openrouter/free"]'
  ./scripts/platinumfang-orgo-baseline.sh
  ```

  Or set after the fact:

  ```bash
  node openclaw.mjs config set agents.defaults.model.primary '"openrouter/arcee-ai/trinity-large-preview:free"' --json
  node openclaw.mjs config set agents.defaults.model.fallbacks '["openrouter/openrouter/free"]' --strict-json
  ```

  Restart the gateway after changing the model.

- **Verify:** `node openclaw.mjs config get agents.defaults.model.primary` should print `openrouter/arcee-ai/trinity-large-preview:free`.

## Gemini as web search

Use **Arcee Trinity** as the brain (primary model) and **Gemini** for the `web_search` tool (Google Search grounding). The baseline script sets the web search provider to `gemini`; you only need to supply `GEMINI_API_KEY`.

- **Set provider** (if not already set by baseline):

  ```bash
  node openclaw.mjs config set tools.web.search.provider '"gemini"' --json
  ```

- **Set `GEMINI_API_KEY`** in the environment before starting the gateway (or in `~/.openclaw/.env`; see [Safest key storage (env file)](#safest-key-storage-env-file)).
- Restart the gateway after setting the key.
- **Verify:** `node openclaw.mjs config get tools.web.search.provider` should print `gemini`.

## Safest key storage (env file)

Store API keys in a restricted env file instead of the config file or shell history:

1. Copy the example file to your OpenClaw home:  
   From repo root: `cp docs/install/orgo-env.example ~/.openclaw/.env` (see [orgo-env.example](orgo-env.example)).
2. Edit `~/.openclaw/.env` and set:
   - `OPENROUTER_API_KEY=...`
   - `GEMINI_API_KEY=...`
3. Restrict permissions: `chmod 600 ~/.openclaw/.env`
4. Load before starting the gateway:  
   `set -a && source ~/.openclaw/.env && set +a`  
   then run the gateway command in the same shell.

Never commit the real `.env` file; never paste keys in chat or docs.

## 5) Pair Discord

1. In Discord, DM your bot (e.g. send `hi`).
2. Bot replies with a pairing code.
3. On the Orgo computer:

```bash
cd ~/openclaw
node openclaw.mjs pairing list discord
node openclaw.mjs pairing approve discord <CODE>
```

## 6) Verify

```bash
cd ~/openclaw
node openclaw.mjs config get channels.discord.enabled
node openclaw.mjs config get channels.discord.guilds
node openclaw.mjs config get tools.profile
node openclaw.mjs security audit --deep
```

## 7) Daily use (no Docker)

- **Start:** `cd ~/openclaw && node openclaw.mjs gateway --port 18789 --bind lan` (or run in background as above).
- **Status:** `node openclaw.mjs config get gateway.mode` and `node openclaw.mjs config get tools.profile`.
- **Safe mode:** Already applied by baseline script. To re-apply: `./scripts/platinumfang-orgo-baseline.sh` (with `SET_TOKEN=0` if you don’t want to overwrite token).
- **Power mode (more permissive):** Adjust tools and model chain manually or add a small wrapper; the Docker-only `scripts/platinumfang-mode.sh` uses Docker, so on Orgo you change config with `node openclaw.mjs config set ...` as needed.

## What to do next (Orgo already running)

If you already have: repo built, baseline applied, gateway running, Discord connected. Below are only the **incremental** steps, in order. No re-run of clone, build, baseline, or pairing is required.

### 1. Env file for API keys (recommended)

So you don't type keys in the shell each time and they're not in history:

- **On Orgo:** Copy the example, edit, lock down:
  - `cp ~/openclaw/docs/install/orgo-env.example ~/.openclaw/.env`
  - Edit `~/.openclaw/.env`: set `OPENROUTER_API_KEY=` and `GEMINI_API_KEY=` (no quotes)
  - `chmod 600 ~/.openclaw/.env`
- **Next time you start the gateway:** In the same shell, run `set -a && source ~/.openclaw/.env && set +a` then your usual gateway command (foreground or nohup). No need to restart the current run just for this; use it from the next start.

### 2. Gemini as web search

If you want Arcee as brain and Gemini for web search:

- **Set provider** (if baseline didn't already): `node openclaw.mjs config set tools.web.search.provider '"gemini"' --json`
- **Ensure `GEMINI_API_KEY` is set** when the gateway starts (env file above or `export`).
- **Restart the gateway** so it picks up the provider and key (stop current process, then start again with env sourced).
- **Verify:** `node openclaw.mjs config get tools.web.search.provider` should print `gemini`.

### 3. Optional: lock down

Only if you want stricter Control UI and gateway access. See [Lock down (tighten security)](#lock-down-tighten-security): set `gateway.controlUi.allowedOrigins`, set `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback` to `false`, optionally set a gateway auth token, and run `node openclaw.mjs security audit --deep`.

### 4. Optional: orchestrator and workers

Only if you want separate agents (e.g. main, content, trading) and the Discord bridge. See [Run the orchestrator and workers (main + content + trading)](#run-the-orchestrator-and-workers-main--content--trading): start orchestrator, then workers, then the Discord bridge; use the env file in the same shell when starting those processes.

### Quick verification (after 1 and 2)

```bash
node openclaw.mjs config get agents.defaults.model.primary
node openclaw.mjs config get tools.web.search.provider
```

Then in Discord, mention the bot and ask something that needs web search to confirm Gemini is used.

## Differences from Docker runbook

| Aspect | Docker (WSL/local) | Orgo (this runbook) |
| ------ | ------------------ | ------------------- |
| Repo | Your fork, any path | Clone OhWhale515/openclaw into ~/openclaw |
| Config | `docker compose run --rm openclaw-cli config set ...` | `node openclaw.mjs config set ...` + baseline script |
| Start | `scripts/platinumfang-mode.sh safe` | `node openclaw.mjs gateway --port 18789 --bind lan` |
| Pairing | `docker compose run --rm openclaw-cli pairing ...` | `node openclaw.mjs pairing ...` |
| State | Docker volumes | `~/.openclaw` on Orgo (persists while computer exists) |

## Main + content + trading (three agent profiles)

The **main / content / trading** layout lives in the repo under **Platinum Fang OS** (`apps/pfos`). It is a separate layer from the single OpenClaw gateway:

- **What you have now:** One OpenClaw gateway (port 18789) and one Discord bot. All Discord messages go to a single agent (Platinum Fang). That is your “main” bot and is fully usable.
- **What the repo describes:** A **pfos orchestrator** (port 18791) plus **workers** (main, YouTube/content, trading). One Discord bot can route by command:
  - `!agent main <message>` or `@pf-main` → main (daily/work)
  - `!agent content <message>` or `@pf-content` → content (YouTube, scripts)
  - `!agent trading <message>` or `@pf-trading` → trading (forex/crypto, paper or live with guardrails)

Full details (task prefixes, worker profiles, Discord bridge, single-worker mode, TradingView/YouTube/MT5 integrations) are in the repo: [apps/pfos/README.md](https://github.com/openclaw/openclaw/blob/main/apps/pfos/README.md) (Orgo Main + Worker Setup, 3-Agent Layout, Direct Discord Gateway Bridge). Your fork [OhWhale515/openclaw](https://github.com/OhWhale515/openclaw) has the same structure. To run the full 3-agent flow on Orgo you would, in addition to (or instead of) the single gateway, run from `apps/pfos`: `orchestrator:main`, one or more `orchestrator:worker` (with profiles main/content/trading), and `orchestrator:discord` so Discord messages are dispatched to the orchestrator.

## Security checklist (are you fully secure?)

The baseline you applied (pairing, guild allowlist, mention gating, `tools.profile=messaging`, deny list, `gateway.mode=local`) matches the Platinum Fang secure posture for a single-bot setup. You are not missing core security for that setup.

Recommended next steps:

1. **Run a security audit:** `node openclaw.mjs security audit` (or `--deep`). Fix any findings.
2. **Rotate secrets if they were exposed:** If your OpenRouter or Discord token was ever pasted in chat or committed, create new keys and update config/env, then revoke the old ones (OpenRouter: [openrouter.ai/keys](https://openrouter.ai/keys); Discord: Developer Portal → Bot → Reset Token).
3. **Apply doctor fixes if suggested:** `node openclaw.mjs doctor --fix`.
4. **Keep Control UI access tight:** You enabled `gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback` for Orgo. Use it only on a trusted network; for production, prefer `gateway.controlUi.allowedOrigins` with explicit URLs.
5. **When adding the pfos orchestrator:** Use `PF_API_TOKEN` and optional `DISCORD_ALLOWED_GUILD_ID` / `DISCORD_ALLOWED_CHANNEL_IDS`; keep trading guardrails (e.g. `PF_TRADE_LIVE_ENABLED=0`) until you intend to go live.

See [Platinum Fang whitepaper Q&A](https://github.com/openclaw/openclaw/blob/main/PLATINUMCLAW_WHITEPAPER_QA.md) (control principles, safe/power/off, security audit).

## Lock down (tighten security)

After rotating secrets, tighten the gateway so Control UI and API are not relying on the Host-header fallback and (optionally) require a token for API access.

**Order of operations:** (1) Set explicit Control UI allowed origins (and add your Orgo URL if you use it). (2) Turn off Host-header origin fallback. (3) (Recommended when binding to lan) Set gateway auth token and store it safely. (4) Re-run security audit.

**1. Set explicit Control UI allowed origins** (replace with your actual Orgo URL if you use it to open the dashboard):

```bash
cd ~/openclaw
node openclaw.mjs config set gateway.controlUi.allowedOrigins '["http://127.0.0.1:18789","http://localhost:18789"]' --strict-json
```

If you open the Control UI from the Orgo desktop at a specific hostname or IP, add it, e.g. `["http://127.0.0.1:18789","http://localhost:18789","http://orgo-desktop:18789"]`.

**2. Turn off Host-header origin fallback:**

```bash
node openclaw.mjs config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback false --json
```

**3. (Recommended when binding to lan) Set gateway auth token** so only clients with the token can use the gateway API:

```bash
# Generate a token (or use your own secret string)
export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
node openclaw.mjs config set gateway.auth.mode '"token"' --json
node openclaw.mjs config set gateway.auth.token "\"$OPENCLAW_GATEWAY_TOKEN\"" --json
# Store OPENCLAW_GATEWAY_TOKEN somewhere safe; you'll need it for CLI and Control UI
```

Then restart the gateway. When opening the Control UI, use the token in the auth prompt. For CLI from the same machine, set `export OPENCLAW_GATEWAY_TOKEN=<that-token>` so `openclaw` commands authenticate.

**4. Re-run security audit:**

```bash
node openclaw.mjs security audit --deep
```

## Run the orchestrator and workers (main + content + trading)

To use the **three agent profiles** (main, content, trading) from one Discord bot, run the **pfos orchestrator** plus **workers** and the **Discord bridge**. All of this runs in addition to (or instead of) the single OpenClaw gateway for Discord-sourced tasks; see [apps/pfos/README.md](https://github.com/openclaw/openclaw/blob/main/apps/pfos/README.md).

**Order of operations:** (1) Install + build + apply baseline (steps 1–3). (2) Set env: use `~/.openclaw/.env` with `OPENROUTER_API_KEY` and `GEMINI_API_KEY`; source it when starting the gateway (and when running orchestrator/workers if they need the same keys). (3) Start the OpenClaw gateway (port 18789). (4) Optional (3-agent layout): Start orchestrator (18791), then workers (main, content, trading), then optional Discord bridge (Option A, B, or C below).

**Prereqs on Orgo:** You already have `~/openclaw` cloned and built. The orchestrator and workers are Node scripts under `apps/pfos/orgo/`; run them from `apps/pfos` so the data directory (`.pf-data`) is correct. Create a shared API token and have your Discord bot token ready.

**Option A – Separate terminals (easiest to watch logs)**

Use five terminals (or five tmux/screen windows). On the Orgo machine:

| Terminal | Command | Purpose |
| -------- | ------- | ------- |
| 1 | `cd ~/openclaw && set -a && source ~/.openclaw/.env && set +a && node openclaw.mjs gateway --port 18789 --bind lan` | OpenClaw gateway |
| 2 | `cd ~/openclaw/apps/pfos && PF_API_TOKEN=<shared-token> npm run orchestrator:main` | Orchestrator (API on 18791) |
| 3 | `cd ~/openclaw/apps/pfos && PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=<token> PF_WORKER_PROFILE=main npm run orchestrator:worker` | Worker: main |
| 4 | `cd ~/openclaw/apps/pfos && PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=<token> PF_WORKER_PROFILE=youtube npm run orchestrator:worker` | Worker: content |
| 5 | `cd ~/openclaw/apps/pfos && PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=<token> PF_WORKER_PROFILE=trading npm run orchestrator:worker` | Worker: trading |
| 6 (optional) | `cd ~/openclaw/apps/pfos && DISCORD_BOT_TOKEN=<token> PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=<token> PF_DISCORD_STRICT_ROUTING=1 npm run orchestrator:discord` | Discord bridge (sends Discord to orchestrator) |

**Discord: one bot, one connection.** You cannot use the same Discord bot token for both the OpenClaw gateway and the pfos Discord bridge at the same time. Choose one: (a) **Gateway only** – Discord stays on the gateway (single agent, as you have now); or (b) **Orchestrator + bridge** – disable the Discord channel on the OpenClaw gateway and run the bridge so Discord messages go to the orchestrator (main/content/trading). Alternatively use a **second** Discord bot token for the bridge and keep the first on the gateway.

**Option B – Background with nohup**

Same commands as above, but run in the background and log to files. Source the env file before starting the gateway so `OPENROUTER_API_KEY` and `GEMINI_API_KEY` are set:

```bash
cd ~/openclaw
set -a && source ~/.openclaw/.env && set +a
nohup node openclaw.mjs gateway --port 18789 --bind lan > /tmp/openclaw-gateway.log 2>&1 &
cd ~/openclaw/apps/pfos
export PF_API_TOKEN="your-shared-token"

nohup npm run orchestrator:main > /tmp/pf-main.log 2>&1 &
nohup env PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=$PF_API_TOKEN PF_WORKER_PROFILE=main npm run orchestrator:worker > /tmp/pf-worker-main.log 2>&1 &
nohup env PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=$PF_API_TOKEN PF_WORKER_PROFILE=youtube npm run orchestrator:worker > /tmp/pf-worker-yt.log 2>&1 &
nohup env PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=$PF_API_TOKEN PF_WORKER_PROFILE=trading npm run orchestrator:worker > /tmp/pf-worker-trading.log 2>&1 &
nohup env DISCORD_BOT_TOKEN=your-discord-token PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=$PF_API_TOKEN PF_DISCORD_STRICT_ROUTING=1 npm run orchestrator:discord > /tmp/pf-discord.log 2>&1 &
```

Check logs: `tail -f /tmp/pf-main.log`, `tail -f /tmp/pf-worker-main.log`, etc.

**Option C – Single worker (all profiles on one process)**

If you want one worker to handle main, content, and trading until you scale out:

```bash
cd ~/openclaw/apps/pfos
PF_API_TOKEN=<token> PF_SINGLE_WORKER_ID=pf-main-operator npm run orchestrator:main
```

In another terminal, one worker with all capabilities:

```bash
cd ~/openclaw/apps/pfos
PF_MAIN_URL=http://127.0.0.1:18791 PF_API_TOKEN=<token> PF_WORKER_PROFILE=main PF_WORKER_ID=pf-main-operator PF_WORKER_CAPS=daily,ops,research,admin,youtube,content,trading,forex,crypto npm run orchestrator:worker
```

Then run the Discord bridge as in option A or B. Discord commands: `!agent main ...`, `!agent content ...`, `!agent trading ...`.

**Lockdown for the orchestrator:** Use `PF_API_TOKEN` for all calls to the main API (port 18791). Restrict Discord to one server: `DISCORD_ALLOWED_GUILD_ID=<your-server-id>`. Keep trading guardrails: `PF_TRADE_LIVE_ENABLED=0` unless you intend live trading.

## Links

- [Orgo install (generic)](/install/orgo)
- [Platinum Fang whitepaper Q&A](https://github.com/openclaw/openclaw/blob/main/PLATINUMCLAW_WHITEPAPER_QA.md) (upstream)
- [Your fork](https://github.com/OhWhale515/openclaw) · [Discord walkthrough](https://github.com/OhWhale515/openclaw/blob/main/DISCORD_SETUP_WALKTHROUGH.md) · [Next steps runbook](https://github.com/OhWhale515/openclaw/blob/main/NEXT_STEPS_RUNBOOK.md)
- [Gateway configuration](/gateway/configuration)
