# 4-Condition Skill Activation Experiment Plan

## Goal

Measure the effect of two independent variables on Claude's Skill tool invocation rate:

1. **Hook** — Whether the UserPromptSubmit scoring hook injects an INSTRUCTION to use the Skill tool
2. **Keywords** — Whether `keywords:` is present in the YAML front matter of each SKILL.md file

This produces a 2x2 matrix of 4 conditions:

| | No Keywords | With Keywords |
|---|---|---|
| **No Hook** | Condition 1 | Condition 2 |
| **With Hook** | Condition 3 | Condition 4 |

Each condition runs all 18 test queries (6 per skill x 3 skills) via `claude -p`.

---

## File Inventory

### Files that get toggled

| File | Toggle | How |
|---|---|---|
| `.claude/skills/dockerfile-generator/SKILL.md` | keywords line added/removed | Edit file |
| `.claude/skills/git-workflow/SKILL.md` | keywords line added/removed | Edit file |
| `.claude/skills/svelte5-runes/SKILL.md` | keywords line added/removed | Edit file |
| `.claude/settings.json` | Moved to `.bak` by `--no-hook` flag | Handled by test runner |

### Current state of SKILL.md files (WITH keywords)

```yaml
# dockerfile-generator/SKILL.md
---
name: dockerfile-generator
description: Docker expert for containerization. Use when creating Dockerfiles, containerizing applications, or configuring Docker images.
keywords: docker, dockerfile, container, containerize, container image, OCI, image, build, deploy, multi-stage, docker compose, docker-compose, microservice, packaging
---
```

```yaml
# git-workflow/SKILL.md
---
name: git-workflow
description: Git expert for version control workflows. Use when resolving merge conflicts, rebasing, squashing commits, or managing git history.
keywords: git, merge, rebase, conflict, squash, commit, branch, history, merge conflict, version control, VCS, undo commit, amend, stash, checkout, pull request, PR, cherry pick, reset, reflog
---
```

```yaml
# svelte5-runes/SKILL.md
---
name: svelte5-runes
description: Svelte 5 runes expert. Use when creating reactive components, migrating from Svelte 4, or working with reactive state management.
keywords: svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component, signal, signals, reactivity, computed value, side effect, reactive state, state management
---
```

### "No keywords" versions (remove the `keywords:` line entirely)

```yaml
# dockerfile-generator/SKILL.md (no keywords)
---
name: dockerfile-generator
description: Docker expert for containerization. Use when creating Dockerfiles, containerizing applications, or configuring Docker images.
---
```

```yaml
# git-workflow/SKILL.md (no keywords)
---
name: git-workflow
description: Git expert for version control workflows. Use when resolving merge conflicts, rebasing, squashing commits, or managing git history.
---
```

```yaml
# svelte5-runes/SKILL.md (no keywords)
---
name: svelte5-runes
description: Svelte 5 runes expert. Use when creating reactive components, migrating from Svelte 4, or working with reactive state management.
---
```

---

## Step-by-Step Procedure

### Step 0: Pre-flight checks

1. Verify `.claude/settings.json` exists (hook is registered)
2. Verify all 3 `test-cases.json` files exist
3. Back up current SKILL.md files (they have keywords):
   ```bash
   for skill in dockerfile-generator git-workflow svelte5-runes; do
     cp .claude/skills/$skill/SKILL.md .claude/skills/$skill/SKILL.md.with-keywords
   done
   ```

### Step 1: Condition 1 — No Hook, No Keywords

1. **Remove keywords** from all 3 SKILL.md files:
   - Edit each file to delete the `keywords:` line from the YAML front matter
   - Verify with: `grep -l "keywords:" .claude/skills/*/SKILL.md` (should return nothing)

2. **Run the test**:
   ```bash
   ./skill-test-runner.sh --no-hook 2>&1 | tee results/c1-no_hook-no_keywords-full.txt
   ```

3. **Rename results**:
   ```bash
   cp results/baseline-results.json results/c1-no_hook-no_keywords-results.json
   ```

4. **Verify**: Confirm settings.json was restored (the `--no-hook` flag moves it temporarily and the trap should restore it, but check).

### Step 2: Condition 2 — No Hook, With Keywords

1. **Restore keywords** to all 3 SKILL.md files:
   - Copy back from `.with-keywords` backups, or re-add the `keywords:` lines

2. **Verify** keywords are present:
   ```bash
   grep "keywords:" .claude/skills/*/SKILL.md
   ```

3. **Run the test**:
   ```bash
   ./skill-test-runner.sh --no-hook 2>&1 | tee results/c2-no_hook-keywords-full.txt
   ```

4. **Rename results**:
   ```bash
   cp results/baseline-results.json results/c2-no_hook-keywords-results.json
   ```

5. **Verify**: Confirm settings.json was restored.

### Step 3: Condition 3 — Hook, No Keywords

1. **Remove keywords** from all 3 SKILL.md files again (same as Step 1.1)

2. **Verify** settings.json exists (hook is active):
   ```bash
   cat .claude/settings.json
   ```

3. **Run the test**:
   ```bash
   ./skill-test-runner.sh 2>&1 | tee results/c3-hook-no_keywords-full.txt
   ```

4. **Rename results**:
   ```bash
   cp results/hook-results.json results/c3-hook-no_keywords-results.json
   ```

### Step 4: Condition 4 — Hook, With Keywords

1. **Restore keywords** to all 3 SKILL.md files

2. **Verify** keywords are present and settings.json exists

3. **Run the test**:
   ```bash
   ./skill-test-runner.sh 2>&1 | tee results/c4-hook-keywords-full.txt
   ```

4. **Rename results**:
   ```bash
   cp results/hook-results.json results/c4-hook-keywords-results.json
   ```

### Step 5: Restore original files

1. Restore SKILL.md files to their original state (with keywords):
   ```bash
   for skill in dockerfile-generator git-workflow svelte5-runes; do
     cp .claude/skills/$skill/SKILL.md.with-keywords .claude/skills/$skill/SKILL.md
   done
   ```
2. Clean up backup files:
   ```bash
   rm .claude/skills/*/SKILL.md.with-keywords
   ```

### Step 6: Analyze all sessions

For every session ID across all 4 result files, call two MCP tools:

1. `mcp__cclogviewer__get_tool_usage_stats(session_id=<id>)` — verify Skill tool invocation and success/failure
2. `mcp__cclogviewer__get_session_timeline(session_id=<id>)` — get step-by-step tool invocation order

Collect per-session:
- `session_id`
- `condition` (c1/c2/c3/c4)
- `query`
- `expected_skill`
- `skill_invoked` (true/false)
- `skill_success` (true/false)
- `first_tool`
- `all_tools`
- `timeline_summary`

### Step 7: Generate report

Write to `results/REPORT_4_CONDITIONS.md` with:

1. **Summary table** — 2x2 matrix showing Skill invocation rates for each condition
2. **Results by skill** — Per-skill breakdown across all 4 conditions
3. **Session evidence** — For each of the 18 queries, show all 4 conditions side-by-side
4. **Tool usage statistics** — Aggregate tool counts per condition
5. **Key findings** — What effect do keywords have? What effect does the hook have? Is there an interaction effect?
6. **Reproduction commands**

---

## Expected Output Files

```
results/
├── c1-no_hook-no_keywords-results.json
├── c1-no_hook-no_keywords-full.txt
├── c2-no_hook-keywords-results.json
├── c2-no_hook-keywords-full.txt
├── c3-hook-no_keywords-results.json
├── c3-hook-no_keywords-full.txt
├── c4-hook-keywords-results.json
├── c4-hook-keywords-full.txt
└── REPORT_4_CONDITIONS.md
```

---

## Key Questions the Report Should Answer

1. Does adding `keywords:` to SKILL.md improve Skill activation rate?
2. Does the scoring hook improve Skill activation rate?
3. Is there an interaction effect (do keywords + hook together perform differently than expected)?
4. Which condition achieves the highest Skill activation rate?
5. Are there specific queries that only activate under certain conditions?
6. Does the hook's adversarial effect (seen in Test 2) persist when keywords are present?
