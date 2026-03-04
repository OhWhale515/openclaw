# Platinum Fang Whitepaper Q&A

Version: 1.0  
Audience: Operator/Owner  
Scope: Local-first, high-security OpenClaw deployment profile branded as **Platinum Fang**

---

## 1) What is Platinum Fang?

**Q:** What is Platinum Fang?  
**A:** Platinum Fang is a hardened operating profile and runbook for OpenClaw focused on:
- local-first runtime
- Discord-first collaboration
- strict security boundaries
- on-demand usage (only when you are working)

Platinum Fang is not a separate codebase. It is a security-first deployment pattern on top of OpenClaw.

---

## 2) Why Platinum Fang uses strict defaults

**Q:** Why is everything locked down by default?  
**A:** Because AI assistants handle untrusted input by default. The secure baseline is:
- explicit identity controls first
- tool restrictions second
- model intelligence third

If your bot is reachable by many users and has broad tools, prompt injection risk grows quickly.

---

## 3) Trust model in plain language

**Q:** Is this multi-tenant secure for adversarial users?  
**A:** No. OpenClaw is designed as a personal-assistant trust model. Platinum Fang enforces a one-owner boundary unless you explicitly add trusted users.

**Q:** What does that mean operationally?  
**A:** Treat one gateway as one trust boundary. Do not share broad tool authority with untrusted users.

---

## 4) Core architecture

**Q:** What architecture does Platinum Fang use?  
**A:** 
1. Dockerized gateway
2. Loopback bind only
3. Discord channel integration
4. Local model primary (Ollama)
5. Cloud fallback optional (OpenRouter free-first chain)
6. Sandboxing and strict tool policy

**Q:** Why loopback only?  
**A:** It prevents accidental internet exposure. Remote access should use secure tunneling/tailnet patterns.

---

## 5) Your configured Discord identity policy

**Q:** Why do I have 1 user instead of unlimited?  
**A:** Because guild policy is set to one approved user ID:
- Server ID: `1478877509285318656`
- Allowed user ID list includes only: `1143280146435027108`

That is intentional maximum safety.

**Q:** How do I add more users safely?  
**A:** Add specific IDs to the `users` array. Do not open wildcard access unless you accept higher risk.

---

## 6) Mode system (safe/power/off)

**Q:** What does `safe` mode do?  
**A:** 
- strict tools profile
- deny high-risk control-plane/runtime groups
- elevated execution disabled
- Discord mention required in guild
- per-peer DM session isolation
- local-first model chain

**Q:** What does `power` mode do?  
**A:** 
- less restrictive tool profile for trusted focused work
- still keeps key dangerous control-plane paths denied
- mention requirement can be relaxed
- cloud-first fallback possible

**Q:** What does `off` mode do?  
**A:** Stops containers so assistant is inactive when you are not working.

---

## 7) Command reference: how and why

### `scripts/platinumfang-mode.sh safe`
- Sets hardened daily posture.
- Use at start of work.

### `scripts/platinumfang-mode.sh power`
- Enables a more permissive posture.
- Use only when you intentionally need it.

### `scripts/platinumfang-mode.sh status`
- Shows container status and key policy/model settings.
- Use to verify current operational state.

### `scripts/platinumfang-mode.sh off`
- Stops services.
- Use at end of day.

### `scripts/platinumfang-mode.sh mention-on` / `mention-off`
- Controls guild response gating.
- `mention-on` is safer and recommended.

### `scripts/platinumfang-mode.sh discord-on` / `discord-off`
- Enables or disables Discord integration.
- `discord-off` is a quick containment switch.

### `scripts/platinumfang-mode.sh local-only`
- Restricts primary/fallback chain to local model behavior.

### `scripts/platinumfang-mode.sh cloud-only`
- Uses cloud route chain when local model is unavailable or insufficient.

---

## 8) Model strategy

**Q:** Why local-first?  
**A:** Better privacy and cost control.

**Q:** Why keep cloud fallback?  
**A:** Reliability and quality when local hardware/model limits are hit.

**Recommended order**
1. Local primary (Ollama tool-capable model)
2. OpenRouter free GLM path
3. OpenRouter free router path
4. Optional premium GLM fallback

---

## 9) Token and credential security

**Q:** What if a token is exposed?  
**A:** Immediate incident response:
1. Rotate token at provider (Discord Developer Portal -> Bot -> Reset Token)
2. Update local configuration with new token
3. Unset shell env variable
4. Re-run security verification commands

**Q:** Should tokens be committed to files?  
**A:** No. Keep secrets out of versioned docs/scripts. Inject at runtime via environment or secret references.

---

## 10) Daily operator runbook

### Start work
```bash
cd "/mnt/e/Sterling Storage/openclaw"
scripts/platinumfang-mode.sh safe
```

### Verify
```bash
scripts/platinumfang-mode.sh status
docker compose run --rm openclaw-cli security audit --deep
```

### End work
```bash
cd "/mnt/e/Sterling Storage/openclaw"
scripts/platinumfang-mode.sh off
```

---

## 11) Discord onboarding checklist

1. Create app and bot in Discord Developer Portal
2. Enable Message Content Intent and Server Members Intent
3. Invite bot with required scopes/permissions
4. Set bot token in OpenClaw config
5. Configure DM pairing + guild allowlist + mention gating
6. DM bot, retrieve pairing code, approve pairing
7. Validate with status and security audit

---

## 12) Troubleshooting Q&A

**Q:** Why did `VAR=value` fail in terminal?  
**A:** That syntax is Bash, not PowerShell. Use WSL/bash for Linux-style commands.

**Q:** Why did `unset` fail?  
**A:** `unset` is Bash-only. In PowerShell use `$env:VAR=$null`; in Bash use `unset VAR`.

**Q:** Why is `docker` not recognized?  
**A:** Docker is not available in that shell context. Use WSL terminal where Docker CLI is configured.

**Q:** Why are responses getting clipped?  
**A:** Terminal UI paging/scroll constraints. Use markdown runbook files and `Get-Content <file> | more`.

---

## 13) Expansion policy (how to scale safely)

**Q:** How to add more users safely?  
**A:** Add user IDs one-by-one in guild allowlist and keep mention gating on.

**Q:** How to open access broadly?  
**A:** Not recommended. If required, do it temporarily and with stricter tool lockdown.

**Q:** How to support multiple trust groups?  
**A:** Separate gateways/hosts per trust boundary.

---

## 14) Platinum Fang control principles

1. Default deny
2. Explicit allowlists
3. Minimal tool exposure
4. Local-first model routing
5. Rotate secrets immediately after exposure
6. Keep runtime off when not in use
7. Verify posture continuously (`security audit --deep`)

---

## 15) Quick command card

```bash
# Start secure
scripts/platinumfang-mode.sh safe

# Current posture
scripts/platinumfang-mode.sh status

# Toggle Discord
scripts/platinumfang-mode.sh discord-off
scripts/platinumfang-mode.sh discord-on

# Mention gating
scripts/platinumfang-mode.sh mention-on
scripts/platinumfang-mode.sh mention-off

# Model routing
scripts/platinumfang-mode.sh local-only
scripts/platinumfang-mode.sh cloud-only

# Stop all
scripts/platinumfang-mode.sh off
```

---

## 16) Final note

Platinum Fang is strongest when used as:
- one owner
- one trust boundary
- strict policies by default
- intentional, auditable temporary expansions

Treat every permission increase as a deliberate change, not a convenience default.
