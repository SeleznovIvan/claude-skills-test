---
name: audit
description: Run a full skill activation audit experiment. ALWAYS invoke this skill when the user says "skill audit", "audit skills", "test skill activation", or "run activation experiment". Do not attempt to test skill activation directly — use this skill first.
keywords: audit, skill activation, test skills, activation rate, experiment, skill test, activation experiment
---

# /skill-audit:audit — Skill Activation Experiment

Run a complete skill activation audit in 4 phases. Present results after each phase and ask the user before proceeding to the next.

## Allowed Tools

Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion,
mcp__cclogviewer__list_sessions, mcp__cclogviewer__list_projects,
mcp__cclogviewer__search_logs, mcp__cclogviewer__get_session_timeline,
mcp__cclogviewer__get_tool_usage_stats, mcp__cclogviewer__get_session_stats

---

## Phase 1: Skill Inventory & Directive Audit

### 1.1 Discover skills

Use Glob to find all `.claude/skills/*/SKILL.md` files in the current project.

### 1.2 Parse each skill

For each SKILL.md, read the file and extract:
- `name` from frontmatter
- `description` from frontmatter
- `keywords` from frontmatter
- Full markdown body

### 1.3 Score directive compliance (0–3)

Score each skill's `description` field:

| Points | Criterion | Pattern Examples |
|--------|-----------|-----------------|
| +1 | Activation directive | "ALWAYS invoke", "MUST use", "ALWAYS use this skill" |
| +1 | Negative constraint | "Do not ... directly", "Never attempt to ... without", "Do not run ... directly" |
| +1 | Keyword triggers present | `keywords:` field has 5+ entries |

### 1.4 Present results

Display a table:

```
Phase 1: Skill Inventory & Directive Compliance

| # | Skill | Description (first 60 chars) | Dir. Score | Issues |
|---|-------|------------------------------|------------|--------|
| 1 | dockerfile-generator | Docker expert. ALWAYS invoke... | 3/3 | — |
| 2 | git-workflow | Git version control expert... | 2/3 | Missing keyword triggers |
```

For any skill scoring < 3, show a specific recommendation:
- Missing activation directive: "Add 'ALWAYS invoke this skill when...' to description"
- Missing negative constraint: "Add 'Do not ... directly — use this skill first' to description"
- Missing keyword triggers: "Add a `keywords:` field with 5+ relevant terms"

### 1.5 Ask to continue

Ask the user which skills to test:
- **All** — test every discovered skill
- **Select specific** — let user pick from the list
- **Fix first** — pause to fix directive issues before testing

---

## Phase 2: Query Mining

### 2.1 Mine queries from session logs

Use the cclogviewer MCP tools to find real user queries that should have triggered each skill:

1. Call `mcp__cclogviewer__list_projects` to find the current project
2. Call `mcp__cclogviewer__list_sessions` to get recent sessions (limit 50)
3. For each skill, call `mcp__cclogviewer__search_logs` with each keyword from the skill's `keywords` field
4. Cross-reference with `mcp__cclogviewer__get_tool_usage_stats` to find sessions where the Skill tool was NOT invoked (missed activations)
5. Extract the user's original query text from matched log entries

### 2.2 Generate contextual queries (if needed)

If fewer than 5 real queries found per skill:

1. Use Glob to find relevant project files (e.g., for a dockerfile skill, look for `Dockerfile*`, `docker-compose*`, `.dockerignore`)
2. Generate queries that reference actual project context:
   - "Write a Dockerfile for the Express app in src/server/"
   - "Help me resolve the merge conflict in package.json"
3. Ensure queries are specific enough to avoid clarification responses
4. Tag generated queries as `generated`

### 2.3 Present query list

For each skill, show the queries:

```
Phase 2: Query Mining

dockerfile-generator (5 queries):
  [log] "help me write a dockerfile for this project"
  [log] "containerize the api server"
  [gen] "Write a Dockerfile for the Express app in src/server/"
  [gen] "Create a multi-stage Docker build for production"
  [gen] "Add a docker-compose.yml for local development"

git-workflow (4 queries):
  [log] "resolve the merge conflict in main"
  [log] "squash my last 3 commits"
  [gen] "Help me rebase feature-auth onto main"
  [gen] "Undo the last commit without losing changes"
```

### 2.4 Ask to continue

Ask the user:
- **Run inline** — execute trials now in this session
- **Generate script** — write a `run-trials.sh` script for later execution
- **Edit queries** — let user modify the query list first

---

## Phase 3: Activation Experiment

### 3.1 Prepare trials

Create a trials manifest as a JSON array:

```json
[
  {
    "trial_id": "trial-001",
    "skill_name": "dockerfile-generator",
    "query": "write a dockerfile for this project",
    "query_source": "from_logs"
  }
]
```

Save to `skill-audit-results/<timestamp>/trials.json`.

### 3.2 Run trials

**If inline:** Use the Task tool to launch the `activation-tester` agent (subagent_type: general-purpose, model: sonnet) with the trial manifest. The agent will:

- Run `env -u CLAUDECODE claude -p "<query>" --max-turns 5 --output-format stream-json` for each trial
- Parse the stream-json output to extract the session_id from the `result` message
- Return trial results with session IDs

**If generate script:** Write a bash script `skill-audit-results/<timestamp>/run-trials.sh` that:
- Iterates over trials.json
- Runs each trial with claude -p
- Captures session IDs
- Writes results to `trial-results.json`

### 3.3 Verify via cclogviewer

For each completed trial with a session_id:

1. Call `mcp__cclogviewer__get_tool_usage_stats` with the session_id
   - Check if "Skill" tool appears in the stats
   - Record: `skill_invoked` (boolean), `skill_tool_calls` (count)

2. Call `mcp__cclogviewer__get_session_timeline` with the session_id
   - Record: `first_tool` (first tool used), `tool_sequence` (ordered list of tools)
   - Check for `direct_file_access`: did the agent use Read/Write/Edit/Glob/Grep before invoking Skill?
   - Check for `toolsearch_used`: did the agent use ToolSearch?

3. Record full trial result:
```json
{
  "trial_id": "trial-001",
  "skill_name": "dockerfile-generator",
  "query": "write a dockerfile",
  "query_source": "from_logs",
  "session_id": "abc-123",
  "skill_invoked": true,
  "skill_tool_calls": 1,
  "first_tool": "Skill",
  "tool_sequence": ["Skill", "Write", "Read"],
  "direct_file_access": false,
  "toolsearch_used": false
}
```

Save all results to `skill-audit-results/<timestamp>/trial-results.json`.

### 3.4 Show progress

After each trial completes, show a progress line:

```
[3/12] dockerfile-generator | "write a dockerfile" | ACTIVATED (Skill first)
[4/12] git-workflow | "resolve merge conflict" | MISSED (used Grep first)
```

---

## Phase 4: Report

### 4.1 Generate report

Write `skill-audit-results/<timestamp>/AUDIT_REPORT.md` with these sections:

#### Summary

```markdown
# Skill Activation Audit Report

**Project:** <project name>
**Date:** <timestamp>
**Skills tested:** <count>
**Total trials:** <count>
**Overall activation rate:** <activated>/<total> (<percentage>%)
```

#### Directive Compliance

The Phase 1 table repeated here for reference.

#### Per-Skill Activation Rates

```markdown
## Activation by Skill

| Skill | Trials | Activated | Rate | Skill-First | Avg Tools Before Skill |
|-------|--------|-----------|------|-------------|----------------------|
| dockerfile-generator | 5 | 4 | 80% | 3 | 0.5 |
| git-workflow | 4 | 3 | 75% | 2 | 1.2 |
```

#### Tool Sequence Analysis

```markdown
## Tool Sequence Analysis

### First Tool Distribution
| First Tool | Count | % |
|-----------|-------|---|
| Skill | 7 | 58% |
| Glob | 3 | 25% |
| Read | 2 | 17% |

### ToolSearch Usage
- Trials using ToolSearch before Skill: 2/12 (17%)
- Trials using ToolSearch without finding Skill: 1/12 (8%)
```

#### Failure Deep-Dives

For each trial where `skill_invoked` is false:

```markdown
### MISS: <skill_name> — "<query>"
- **Session:** <session_id>
- **First tool:** <first_tool>
- **Tool sequence:** <tool_sequence>
- **Analysis:** Agent bypassed skill and went directly to <first_tool>.
  Likely cause: <hypothesis based on tool sequence>
```

#### Recommendations

Based on the data, generate specific recommendations:

1. For skills with low activation: suggest description improvements
2. For skills where ToolSearch is used but fails: suggest keyword additions
3. For skills where agents go directly to file tools: suggest stronger negative constraints
4. General patterns observed across all skills

### 4.2 Save artifacts

Save all artifacts to `skill-audit-results/<timestamp>/`:
- `trials.json` — input trial manifest
- `trial-results.json` — full results with verification
- `AUDIT_REPORT.md` — human-readable report
- `raw-data.json` — all collected data (directive scores, queries, trial results)

### 4.3 Present summary

Print a concise summary to the user:

```
=== SKILL ACTIVATION AUDIT COMPLETE ===

Overall: 10/12 activated (83.3%)

Per skill:
  dockerfile-generator: 4/5 (80%) — 3 skill-first
  git-workflow: 3/4 (75%) — 2 skill-first
  svelte5-runes: 3/3 (100%) — 3 skill-first

Top issues:
  1. git-workflow: weak negative constraint — agents use Bash(git ...) directly
  2. dockerfile-generator: missing project context queries fail more often

Full report: skill-audit-results/<timestamp>/AUDIT_REPORT.md
```
