---
title: Orgo
description: Run OpenClaw on Orgo cloud computers
summary: "Run the OpenClaw Gateway (and optional Platinum Fang OS) on Orgo.ai computers for AI agents"
read_when:
  - You want to run OpenClaw on Orgo (orgo.ai) cloud desktops
  - You use Orgo for computer-use agents and want the gateway there too
---

# Orgo Setup

[Orgo](https://www.orgo.ai) provides cloud desktop environments (Ubuntu 24) that you create and control via API or dashboard. You can run the OpenClaw Gateway on an Orgo computer so your agent has access to the full OpenClaw stack (channels, skills, models) from the same environment.

## What you need

- [Orgo account](https://www.orgo.ai/start) and [API key](https://www.orgo.ai/workspaces) (`ORGO_API_KEY`)
- Model and channel credentials (same as any OpenClaw install)

**Platinum Fang (OhWhale515/openclaw):** If you run the [Platinum Fang](https://github.com/OhWhale515/openclaw) fork with Discord and the same secure baseline as the Docker runbook, use the dedicated runbook: [Platinum Fang on Orgo](/install/orgo-platinum-fang). It uses your repo, a native baseline script (no Docker), and the same config as your Discord walkthrough.

## How it works

- You **create an Orgo computer** (RAM/CPU of your choice). Orgo gives you a Linux desktop you control via `computer.bash()`, `computer.prompt()`, or the Orgo dashboard.
- On that computer you **install Node 22**, clone OpenClaw, build, and run the gateway (and optionally the [Platinum Fang OS](/install/orgo#platinum-fang-os-pfos-on-orgo) orchestrator).
- **Persistence:** Orgo preserves disk state when the computer is *stopped* (e.g. auto-stop on inactivity). If you *destroy* the computer, state is lost; re-run setup on a new computer.

## 1) Create an Orgo computer

From your own machine (with Node or Python), use the Orgo SDK to create a computer.

**Node (recommended for this repo):**

```bash
npm install orgo dotenv
```

Create a script (e.g. `create-orgo.mjs`):

```javascript
import { Computer } from 'orgo';
import 'dotenv/config';

const computer = await Computer.create({
  workspace: 'openclaw',
  name: 'openclaw-gateway',
  ram: 8,
  cpu: 4,
  os: 'linux',
});
console.log('Computer ID:', computer.id);
console.log('View desktop:', computer.url);
```

Run with `ORGO_API_KEY=sk_live_...` in `.env` or your environment, then run the script. Note the **computer ID** and **URL** so you can run bash commands and open the desktop in the browser.

**Python:**

```bash
pip install orgo python-dotenv
```

```python
from orgo import Computer
from dotenv import load_dotenv
load_dotenv()

computer = Computer(workspace="openclaw", name="openclaw-gateway", ram=8, cpu=4, os="linux")
print("Computer ID:", computer.id)
print("View desktop:", computer.url)
```

Default specs (4 GB RAM, 2 CPU) can run the gateway; 8 GB RAM / 4 CPU is more comfortable. See [Orgo computer specs](https://docs.orgo.ai/quickstart#computer-specs).

## 2) Install OpenClaw on the Orgo computer

Use the Orgo API to run bash on the computer. With the Node SDK:

```javascript
const output = await computer.bash('...');
```

Run these steps in order (each `computer.bash(...)` is one command or a small script).

**2a) Install Node 22**

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs
node -v   # should be v22.x
```

**2b) Install pnpm and clone OpenClaw**

```bash
sudo npm install -g pnpm
cd ~
git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build
pnpm build
```

**2c) Create config and set env (optional but recommended)**

```bash
mkdir -p ~/.openclaw
export OPENCLAW_STATE_DIR=$HOME/.openclaw
export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
# Store OPENCLAW_GATEWAY_TOKEN somewhere safe for remote access
```

Create `~/.openclaw/openclaw.json` (minimal) or run the onboarding wizard later via the Orgo desktop terminal:

```bash
pnpm openclaw onboard
```

**2d) Start the gateway**

```bash
cd ~/openclaw
node openclaw.mjs gateway --port 18789 --bind lan --allow-unconfigured
```

Use `--bind lan` so the gateway is reachable on the Orgo computer’s network. If you only need access from the same machine (e.g. browser on the Orgo desktop), you can use `--bind loopback` and open the Control UI at `http://127.0.0.1:18789` from that desktop.

**Keeping the gateway running:** Orgo computers auto-stop after inactivity. To keep the gateway up, either keep the computer active (e.g. use the dashboard, or send periodic `computer.bash('date')` or similar) or run the gateway under a process manager and rely on Orgo’s “restart when you send commands” behavior when you need it.

## 3) Access the gateway

- **From the Orgo desktop:** Open the Orgo computer URL in your browser (Orgo dashboard), then open a terminal or browser on that desktop and go to `http://127.0.0.1:18789` for the Control UI.
- **From your laptop:** If the gateway is bound to `lan`, you’d need the Orgo computer’s internal IP (if Orgo exposes it) or a tunnel. Orgo’s docs don’t expose arbitrary ports by default; for remote access from your machine, consider [Fly](/install/fly), [Railway](/install/railway), or another VPS and use Orgo for agent workloads only (see [Platinum Fang OS](#platinum-fang-os-pfos-on-orgo) below).

## 4) Optional – run from the Orgo dashboard terminal

If you use the [Orgo dashboard](https://www.orgo.ai) (playground) and open a terminal on the computer, you can run the same steps by hand:

```bash
# Install Node 22, pnpm, clone, build (as above)
cd ~/openclaw
export OPENCLAW_STATE_DIR=$HOME/.openclaw
node openclaw.mjs gateway --port 18789 --bind loopback --allow-unconfigured
```

Then open the Control UI in a browser tab on that same Orgo desktop.

## Platinum Fang OS (pfos) on Orgo

The [Platinum Fang OS](/start/openclaw) orchestrator (main + workers) can run on one or more Orgo computers. Use one Orgo computer as **Main** and optionally others as **workers**.

- **Main:** On the first Orgo computer (after cloning openclaw and building), from `apps/pfos` run:
  - `PF_API_TOKEN=<token> npm run orchestrator:main`
- **Workers:** On the same or other Orgo computers, set `PF_MAIN_URL` to the Main computer’s reachable URL (e.g. `http://<main-ip>:18791`) and run:
  - `PF_MAIN_URL=http://<MAIN_IP>:18791 PF_API_TOKEN=<token> PF_WORKER_ID=pf-worker-001 npm run orchestrator:worker`

Networking between Orgo computers (Main URL reachable by workers) depends on Orgo’s networking; if they don’t share a private network, you may need to run Main on a small VPS and workers on Orgo, or run a single-worker setup on one Orgo computer.

Full orchestrator options, profiles, and systemd-style autostart (for Linux VMs, not Orgo API): [Platinum Fang OS README](https://github.com/openclaw/openclaw/blob/main/apps/pfos/README.md) (`apps/pfos/README.md`).

## Summary

| Step | Action |
|------|--------|
| 1 | Sign up at [orgo.ai](https://www.orgo.ai/start), get [API key](https://www.orgo.ai/workspaces) |
| 2 | Create an Orgo computer (SDK or API), note ID and URL |
| 3 | Run bash on the computer: install Node 22, clone openclaw, `pnpm install && pnpm build` |
| 4 | Set `OPENCLAW_STATE_DIR`, optionally `OPENCLAW_GATEWAY_TOKEN`, create config |
| 5 | Start gateway: `node openclaw.mjs gateway --port 18789 --bind lan \| loopback` |
| 6 | Open Control UI from the Orgo desktop or (if applicable) your tunnel/VPS |

## Links

- [Orgo docs](https://docs.orgo.ai/)
- [Orgo quickstart](https://docs.orgo.ai/quickstart)
- [VPS hosting hub](/vps) (other cloud options)
- [Gateway configuration](/gateway/configuration)
