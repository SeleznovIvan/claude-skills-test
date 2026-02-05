# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Skill Activation Testing Framework** that measures whether a UserPromptSubmit hook (scoring algorithm) improves Claude's rate of invoking the correct Skill tool for a given query. It includes a scoring engine, test harness, hook integration, and session analysis tooling.

## Architecture

```
User Prompt → Claude CLI → UserPromptSubmit Hook (skill-scoring-hook.sh)
  → score.sh evaluates prompt against all .claude/skills/*/SKILL.md
  → If score ≥ threshold: injects INSTRUCTION to use Skill tool
  → Claude receives modified prompt and invokes Skill tool
```

**Key components:**

- **`score.sh`** — Multi-factor weighted scoring algorithm. Scores a query against skill metadata (name, keywords, description, "use when" triggers, stem matches). Weights are tunable via environment variables (`WEIGHT_EXACT_NAME=10`, `WEIGHT_KEYWORD_MATCH=10`, `WEIGHT_USE_WHEN=3`, `WEIGHT_STEM=3`, `WEIGHT_DESCRIPTION=1`, `MIN_THRESHOLD=5`).
- **`skill-scoring-hook.sh`** — UserPromptSubmit hook that reads the prompt from stdin JSON, runs `score.sh`, and outputs an INSTRUCTION string if a skill scores above threshold.
- **`skill-test-runner.sh`** — A/B test harness. Runs `claude -p` for each test case with `--allowedTools "Skill"`. Supports `--no-hook` (baseline, temporarily moves settings.json) and `--max-cases N`.
- **`test-runner.sh`** — Standalone scoring test runner with 4 modes: embedded tests, external test suite, weight comparison (8 configs), and single query debug (`--query`).
- **`.claude/settings.json`** — Registers the hook on `UserPromptSubmit`.
- **`.claude/skills/*/SKILL.md`** — Skill definitions with `name:`, `description:`, `keywords:` metadata fields, plus markdown content.
- **`.claude/skills/*/test-cases.json`** — Per-skill test queries (`query` + `why` fields). 6 cases per skill, 18 total.

## Commands

```bash
# Run the full A/B experiment
./skill-test-runner.sh --no-hook 2>&1 | tee results/baseline-full.txt   # Baseline (no hook)
./skill-test-runner.sh 2>&1 | tee results/hook-full.txt                 # With hook

# Score a single query (debug mode)
./score.sh "write a dockerfile" .claude/skills/ --verbose

# Run scoring tests against sample skills
./test-runner.sh ./sample-skills/
./test-runner.sh ./sample-skills/ --compare-weights   # Compare 8 weight configs
./test-runner.sh ./sample-skills/ --query "resolve git merge conflict"  # Single query debug

# Tune weights via environment variables
WEIGHT_KEYWORD_MATCH=15 WEIGHT_EXACT_NAME=15 ./test-runner.sh ./sample-skills/

# Analyze a session after experiment (using cclogviewer MCP)
# mcp__cclogviewer__get_tool_usage_stats(session_id=<id>)
# mcp__cclogviewer__get_session_timeline(session_id=<id>)
```

## Skills

Three test skills in `.claude/skills/`:

| Skill | Domain | Key Keywords |
|-------|--------|-------------|
| `dockerfile-generator` | Docker/containerization | docker, dockerfile, container, multi-stage, OCI |
| `git-workflow` | Git version control | git, merge, rebase, squash, cherry pick, conflict |
| `svelte5-runes` | Svelte 5 reactivity | svelte, runes, $state, $derived, $effect, $props |

Each `SKILL.md` follows the format: `name:`, `description:`, `keywords:` header fields followed by markdown content with capabilities, "Use When" triggers, and examples.

## Results

Experiment outputs go to `results/`:
- `baseline-results.json` / `hook-results.json` — Per-test JSON with session IDs
- `baseline-full.txt` / `hook-full.txt` — Full terminal output
- `SKILL_ACTIVATION_REPORT.md` / `SKILL_ACTIVATION_REPORT_FULL.md` — Analysis reports

## Scoring Algorithm

`score.sh` uses 5 scoring factors (additive):
1. **Exact name** (+10) — skill name appears in query
2. **Keyword match** (+10 each) — keywords from `keywords:` field
3. **Use-when triggers** (+3 each) — phrases from "Use when" sections
4. **Stem match** (+3) — stemmed query words match stemmed description words
5. **Description words** (+1 each) — query words (4+ chars) found in description

Activation threshold: total score ≥ 5 (configurable via `MIN_THRESHOLD`).
