# skill-audit Plugin

Portable skill activation experiment plugin for Claude Code. Audits and tests whether Claude correctly invokes project skills when given relevant queries.

## Overview

This plugin provides two skills:
- `/skill-audit:setup` — Initialize the audit environment (check cclogviewer, discover project skills)
- `/skill-audit:audit` — Run the full 4-phase activation experiment

## Dependencies

- **cclogviewer MCP** — Required for session log analysis. Install with `go install github.com/anthropics/cclogviewer@latest`

## How It Works

1. **Phase 1** scans `.claude/skills/*/SKILL.md` and scores directive compliance
2. **Phase 2** mines real queries from session logs via cclogviewer and generates contextual queries
3. **Phase 3** runs `claude -p` trials and verifies activation via cclogviewer
4. **Phase 4** generates an audit report with activation rates, tool sequences, and recommendations

## Key Conventions

- Always use `env -u CLAUDECODE` when running `claude -p` from within Claude Code to bypass nested session check
- Use `--output-format stream-json` (not `--output-format json`) — the latter sends output to stderr
- Parse stream-json line by line; the session_id is in the final `result` type message
- Wait 2 seconds between trials to avoid rate limiting
- Results are saved to `skill-audit-results/<timestamp>/`

## Directive Scoring

Skills are scored 0–3 on their `description` field:
- +1 for activation directive ("ALWAYS invoke", "MUST use")
- +1 for negative constraint ("Do not ... directly")
- +1 for keyword triggers (5+ entries in `keywords:` field)

## Agents

- `activation-tester.md` — Sonnet-based agent that runs batches of `claude -p` trials and returns session IDs
