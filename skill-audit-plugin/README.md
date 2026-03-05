# skill-audit Plugin

A portable Claude Code plugin that audits skill activation rates in any project. Replicates the methodology from skill activation experiments (exp04-06) in a self-contained, reusable package.

## What It Does

Tests whether Claude Code correctly invokes your project's skills when given relevant user queries. Produces an activation report with per-skill rates, tool sequence analysis, and specific recommendations for improving skill descriptions.

## Quick Start

```bash
# Install the plugin
cd skill-audit-plugin
claude plugin install

# In your project directory:
claude
> /skill-audit:setup    # Initialize (checks cclogviewer, discovers skills)
> /skill-audit:audit    # Run the full experiment
```

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI
- [cclogviewer](https://github.com/anthropics/cclogviewer) MCP server for session log analysis
- At least one skill defined in `.claude/skills/*/SKILL.md`

## Install cclogviewer

```bash
go install github.com/anthropics/cclogviewer@latest
```

## The 4-Phase Audit

### Phase 1: Skill Inventory & Directive Audit
Scans `.claude/skills/*/SKILL.md`, parses frontmatter, and scores directive compliance (0-3) based on activation directives, negative constraints, and keyword triggers.

### Phase 2: Query Mining
Searches session logs via cclogviewer for real user queries matching skill keywords. Generates contextual queries from project files if insufficient real queries found.

### Phase 3: Activation Experiment
Runs `claude -p` trials for each skill/query pair. Verifies activation by checking session logs for Skill tool invocations.

### Phase 4: Report
Generates `AUDIT_REPORT.md` with:
- Directive compliance table
- Per-skill activation rates
- Tool sequence analysis (first tool, ToolSearch usage)
- Failure deep-dives for missed activations
- Specific recommendations for description improvements

## Output

Results are saved to `skill-audit-results/<timestamp>/`:
- `trials.json` — Trial manifest
- `trial-results.json` — Full results with cclogviewer verification
- `AUDIT_REPORT.md` — Human-readable report
- `raw-data.json` — All collected data

## Directive Scoring

Skills are scored 0–3 on their description field quality:

| Points | Criterion | Example |
|--------|-----------|---------|
| +1 | Activation directive | "ALWAYS invoke this skill when..." |
| +1 | Negative constraint | "Do not write Dockerfiles directly — use this skill first" |
| +1 | Keyword triggers | `keywords:` field with 5+ entries |

## License

MIT
