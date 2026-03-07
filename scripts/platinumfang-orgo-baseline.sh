#!/usr/bin/env bash
# Platinum Fang baseline config for native (non-Docker) runs, e.g. on Orgo.
# Run from repo root after: git clone https://github.com/OhWhale515/openclaw.git && cd openclaw && pnpm install && pnpm build
# Uses node openclaw.mjs config set ... so no Docker required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required." >&2
  exit 1
fi

CLI="node openclaw.mjs"

DISCORD_SERVER_ID="${DISCORD_SERVER_ID:-1478877509285318656}"
DISCORD_USER_ID="${DISCORD_USER_ID:-1143280146435027108}"
SET_TOKEN="${SET_TOKEN:-0}"
DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"

# Model chain: default primary = OpenRouter Arcee Trinity (free). Override with PRIMARY_MODEL / FALLBACKS_JSON.
PRIMARY_MODEL="${PRIMARY_MODEL:-openrouter/arcee-ai/trinity-large-preview:free}"
FALLBACKS_JSON="${FALLBACKS_JSON:-[\"openrouter/openrouter/free\"]}"

run_cli() {
  $CLI "$@"
}

print_step() {
  printf "\n[Platinum Fang Orgo] %s\n" "$1"
}

# Ensure config dir exists
mkdir -p "${OPENCLAW_HOME:-$HOME/.openclaw}"
export OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

print_step "Applying gateway baseline"
run_cli config set gateway.mode '"local"' --json
run_cli config set gateway.bind '"loopback"' --json

print_step "Applying Discord channel baseline"
run_cli config set channels.discord.enabled true --json
run_cli config set channels.discord.dmPolicy pairing
run_cli config set channels.discord.groupPolicy allowlist
run_cli config set channels.discord.guilds "{\"$DISCORD_SERVER_ID\":{\"requireMention\":true,\"users\":[\"$DISCORD_USER_ID\"]}}" --strict-json

if [[ "$SET_TOKEN" == "1" ]]; then
  if [[ -z "$DISCORD_BOT_TOKEN" ]]; then
    echo "SET_TOKEN=1 requires DISCORD_BOT_TOKEN." >&2
    exit 1
  fi
  print_step "Setting Discord bot token"
  run_cli config set channels.discord.token "\"$DISCORD_BOT_TOKEN\"" --json
else
  print_step "Skipping token update (SET_TOKEN=0). Set later: openclaw config set channels.discord.token \"<token>\" --json"
fi

print_step "Applying secure runtime policy"
run_cli config set session.dmScope per-channel-peer
run_cli config set tools.profile messaging
run_cli config set tools.deny '["gateway","cron","sessions_spawn","sessions_send","group:runtime","group:fs","group:automation"]' --strict-json
run_cli config set tools.elevated.enabled false --json
run_cli config set tools.fs.workspaceOnly true --json
run_cli config set tools.exec.applyPatch.workspaceOnly true --json

print_step "Applying safe-mode model chain (primary + fallbacks)"
run_cli config set agents.defaults.model.primary "\"$PRIMARY_MODEL\"" --json
run_cli config set agents.defaults.model.fallbacks "$FALLBACKS_JSON" --strict-json

print_step "Setting web search provider to Gemini"
run_cli config set tools.web.search.provider '"gemini"' --json

print_step "Running security audit"
run_cli security audit --deep || true

print_step "Done"
echo "Config: ${OPENCLAW_HOME:-$HOME/.openclaw}/openclaw.json"
echo "Primary model: $PRIMARY_MODEL (set OPENROUTER_API_KEY for OpenRouter models)"
echo "Start gateway: node openclaw.mjs gateway --port 18789 --bind loopback"
echo "Or on Orgo (same-machine UI): node openclaw.mjs gateway --port 18789 --bind lan"
echo "Then pair Discord: node openclaw.mjs pairing list discord && node openclaw.mjs pairing approve discord <CODE>"
