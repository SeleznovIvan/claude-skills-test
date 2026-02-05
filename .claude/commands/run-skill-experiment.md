# Run Skill Activation Experiment

You are running a controlled experiment to measure whether a scoring hook improves Claude's skill activation rate.

## Procedure

Follow these steps **exactly in order**. Do NOT skip steps.

### Step 1: Run Baseline Test (No Hook)

Run the test runner script **without** the scoring hook. This removes `.claude/settings.json` temporarily so no hook fires.

```bash
./skill-test-runner.sh --no-hook
```

This runs `claude -p` with `--max-turns 2` for every query in every `.claude/skills/*/test-cases.json` file. Skill activation should happen on the very first turn after the user prompt, so 2 turns is sufficient. Wait for it to complete fully. Save the terminal output to `results/baseline-full.txt`:

```bash
./skill-test-runner.sh --no-hook 2>&1 | tee results/baseline-full.txt
```

After it finishes, read `results/baseline-results.json` to get all session IDs.

### Step 2: Run Hook Test

Run the same test runner **with** the scoring hook active (`.claude/settings.json` in place):

```bash
./skill-test-runner.sh 2>&1 | tee results/hook-full.txt
```

After it finishes, read `results/hook-results.json` to get all session IDs.

### Step 3: Analyze All Sessions with cclogviewer MCP

For **every** session ID from both result files, call **two** MCP tools:

1. `mcp__cclogviewer__get_tool_usage_stats` - to verify whether the `Skill` tool was invoked and its success/failure status
2. `mcp__cclogviewer__get_session_timeline` - to get the step-by-step timeline showing tool invocation order

Collect the data into structured results:

For each session, record:
- `session_id`
- `test_type` (baseline or hook)
- `query` (the test query)
- `expected_skill` (which skill should have been activated)
- `skill_invoked` (true/false - was the Skill tool in the tools list?)
- `skill_success` (true/false - was the Skill tool call successful?)
- `first_tool` (what was the first tool called in the session?)
- `all_tools` (list of all tools used)
- `timeline_summary` (key steps from the timeline)

### Step 4: Generate Report

Write the final report to `results/SKILL_ACTIVATION_REPORT.md` with this structure:

```markdown
# Skill Activation Experiment Report

## Summary

A table comparing baseline vs hook:
- Total tests per condition
- Skill invocation count and percentage
- "Skill as first tool" count
- Date and test parameters

## Results by Skill

For each skill (dockerfile-generator, git-workflow, svelte5-runes):
- Table of all test queries
- Per-query result for baseline AND hook side by side
- Whether Skill was invoked, which tools were used

## Session Evidence

For EACH test query, show side-by-side:

### Query: "<the query>"
**Expected skill:** <skill-name>

#### Baseline Session: <session_id>
- Skill Invoked: YES/NO
- Tools: <list>
- Timeline:
  - Step N: <what happened>
  - Step N: <what happened>

#### Hook Session: <session_id>
- Skill Invoked: YES/NO
- Tools: <list>
- Timeline:
  - Step N: <what happened>
  - Step N: <what happened>

## Tool Usage Statistics

Aggregate tables of all tool usage across baseline vs hook sessions.

## Key Findings

Numbered list of findings derived from the data.

## Reproduction

Commands to reproduce the experiment.
```

### Important Rules

- Do NOT make up or assume session data. Only use data from MCP tool calls.
- Every claim must be backed by a specific session ID and MCP-verified tool stats.
- The report must include EVERY test case, not just a sample.
- Use the `mcp__cclogviewer__get_session_timeline` output to show the exact step-by-step sequence as proof.
- Call MCP tools in parallel where possible (all baseline stats at once, all hook stats at once) to save time.
