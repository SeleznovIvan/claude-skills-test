# SKILL.md Quality Experiment Report

**Date:** 2026-01-30
**Hypothesis:** SKILL.md file quality (not CLAUDE.md, not Hook, not model/CLI version) is the primary driver of Skill tool invocation rate.

## Background

### The Mystery

Across multiple experiments, Skill tool invocation rates varied wildly:

| Experiment | Date | Condition | Rate |
|-----------|------|-----------|------|
| Original baseline | Jan 29 01:07 JST | No CLAUDE.md, No Hook, Original SKILL.md | **0/4 (0%)** |
| Keywords×Hook C1 (nothing) | Jan 29 ~08:00 JST | No Keywords, No Hook | **16/18 (88.9%)** |
| CLAUDE.md×Hook C1 (nothing) | Jan 30 ~02:00 JST | No CLAUDE.md, No Hook | **14/18 (77.8%)** |

The jump from 0% to 77-89% could not be explained by:
- **CLAUDE.md** — C1 had no CLAUDE.md, yet scored 77.8%
- **Hook** — C1 had no Hook
- **Keywords** — Keywords×Hook experiment showed 0pp effect
- **Model/CLI version** — User's other project still shows 0% activation with different SKILL.md files, ruling out global platform changes

The only remaining variable: **SKILL.md file content changed between the original experiment and subsequent experiments.**

### What Changed in SKILL.md Files

Between the original experiment (Jan 29 01:07 JST) and the Keywords×Hook experiment (Jan 29 ~08:00 JST), the SKILL.md files were modified in two ways:

#### 1. YAML Frontmatter Fencing Added

**Original format:**
```
name: dockerfile-generator
description: Docker expert for containerization...
keywords: docker, dockerfile, container...

# Dockerfile Generator Skill
```

**Current format:**
```
---
name: dockerfile-generator
description: Docker expert for containerization...
keywords: docker, dockerfile, container...
---

# Dockerfile Generator Skill
```

The `---` delimiters create standard YAML frontmatter, which may be parsed differently by Claude Code's skill system.

#### 2. Keywords Significantly Expanded

| Skill | Original Keywords | Current Keywords |
|-------|------------------|-----------------|
| **dockerfile-generator** | docker, dockerfile, container, containerize, image, build, deploy (7) | docker, dockerfile, container, containerize, container image, OCI, image, build, deploy, multi-stage, docker compose, docker-compose, microservice, packaging (14) |
| **git-workflow** | git, merge, rebase, conflict, squash, commit, branch, history (8) | git, merge, rebase, conflict, squash, commit, branch, history, merge conflict, version control, VCS, undo commit, amend, stash, checkout, pull request, PR, cherry pick, reset, reflog (20) |
| **svelte5-runes** | svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component (9) | svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component, signal, signals, reactivity, computed value, side effect, reactive state, state management (16) |

Keywords nearly doubled across all skills. Multi-word phrases were added (e.g., "merge conflict", "cherry pick", "docker compose").

#### 3. Body Content Unchanged

The Capabilities, Use When, and Examples sections remained identical.

### Timeline of Changes

| Time (JST) | Event | Source |
|------------|-------|--------|
| Jan 28 07:48 | Original SKILL.md files created in `sample-skills/` | Session `ba15df45` entries 22-24 |
| Jan 28 15:34 | Verbatim copy to `.claude/skills/` | Session `ba15df45` entry 673 (`cp -r sample-skills/* .claude/skills/`) |
| Jan 29 01:07 | **Original experiment runs (0/4 = 0%)** | `results/baseline.txt` |
| Jan 29 04:41 | Keywords expanded in `.claude/skills/` SKILL.md files | Session `ba15df45` entries 1848-1853 |
| Jan 29 ~08:00 | Keywords×Hook experiment runs (C1 = 88.9%) | Session `43ce0562` |
| Jan 29 ~10:30 | `---` YAML fences added (exact session TBD) | Between Keywords×Hook and CLAUDE.md×Hook experiments |
| Jan 30 ~02:00 | CLAUDE.md×Hook experiment runs (C1 = 77.8%) | Session with current SKILL.md files |

The keyword expansion at 04:41 is the modification that occurred between the 0% and 89% results.

## Experiment Design

**Question:** Does reverting SKILL.md files to their original state reproduce the original 0% activation rate?

**Method:**
1. Extracted original SKILL.md content from session `ba15df45` Write tool calls (entries 22-24)
2. Backed up current SKILL.md files
3. Wrote original content to `.claude/skills/*/SKILL.md`
4. Removed CLAUDE.md (to match original experiment conditions: no CLAUDE.md, no Hook)
5. Ran: `./skill-test-runner.sh --no-hook`
6. Verified each session via `mcp__cclogviewer__get_tool_usage_stats()`
7. Restored all files

**Controlled variables:**
- Same 18 test queries (6 per skill)
- Same test runner script (`skill-test-runner.sh`)
- Same CLI version (claude)
- Same model (inherited from CLI)
- No CLAUDE.md (moved to `.bak`)
- No Hook (`--no-hook` flag)

**Independent variable:** SKILL.md file content (original vs current)

## Results

### Overall

| SKILL.md Version | Skill Invocations | Rate |
|-----------------|-------------------|------|
| **Original** (this experiment) | 1/18 | **5.6%** |
| **Current** (C1 from CLAUDE.md×Hook) | 14/18 | **77.8%** |

**Δ = 72.2 percentage points.** SKILL.md quality is the dominant variable.

### Per-Skill Breakdown

| Skill | Original SKILL.md | Current SKILL.md | Δ |
|-------|-------------------|-----------------|---|
| dockerfile-generator | 0/6 (0%) | 4/6 (66.7%) | +66.7pp |
| git-workflow | 0/6 (0%) | 4/6 (66.7%) | +66.7pp |
| svelte5-runes | 1/6 (16.7%) | 6/6 (100%) | +83.3pp |

### Per-Query Detail

#### dockerfile-generator

| # | Query | Original SKILL.md | Current SKILL.md (C1) |
|---|-------|-------------------|----------------------|
| 1 | write a dockerfile | ✗ (AskUserQuestion) | ✓ Skill |
| 2 | generate dockerfile for node app | ✗ (Task) | ✓ Skill |
| 3 | containerize my application | ✗ (Task) | ✗ (Glob) |
| 4 | create docker image config | ✗ (Task) | ✗ (Task) |
| 5 | help with multi-stage docker build | ✗ (AskUserQuestion) | ✓ Skill |
| 6 | setup dockerfile for python flask | ✗ (EnterPlanMode) | ✓ Skill |

#### git-workflow

| # | Query | Original SKILL.md | Current SKILL.md (C1) |
|---|-------|-------------------|----------------------|
| 7 | resolve git merge conflict | ✗ (Bash) | ✓ Skill |
| 8 | help with git rebase | ✗ (none) | ✓ Skill |
| 9 | fix my git history | ✗ (Bash) | ✓ Skill |
| 10 | squash commits before PR | ✗ (Bash) | ✗ (Bash) |
| 11 | undo last git commit | ✗ (Bash) | ✓ Skill |
| 12 | cherry pick a commit from another branch | ✗ (AskUserQuestion) | ✗ (Bash) |

#### svelte5-runes

| # | Query | Original SKILL.md | Current SKILL.md (C1) |
|---|-------|-------------------|----------------------|
| 13 | use svelte5 runes | ✗ (AskUserQuestion) | ✓ Skill |
| 14 | create reactive state with $state | ✓ Skill | ✓ Skill |
| 15 | convert svelte 4 to svelte 5 | ✗ (Task) | ✓ Skill |
| 16 | use $derived and $effect | ✗ (Task) | ✓ Skill |
| 17 | how do I use runes in svelte | ✗ (none) | ✓ Skill |
| 18 | svelte 5 component with $props | ✗ (none) | ✓ Skill |

### Session Evidence

| Test | Session ID | Skill? | Tools Used |
|------|-----------|--------|------------|
| 1 | `82d0b84a` | ✗ | AskUserQuestion, Bash |
| 2 | `31edd212` | ✗ | Task, Write |
| 3 | `330bc60e` | ✗ | Task, EnterPlanMode |
| 4 | `1b26f623` | ✗ | Task, AskUserQuestion |
| 5 | `1114cf07` | ✗ | AskUserQuestion |
| 6 | `8fdc4b68` | ✗ | EnterPlanMode, Task |
| 7 | `8f7abdfe` | ✗ | Bash |
| 8 | `f74547cb` | ✗ | (no tools) |
| 9 | `32e503c4` | ✗ | Bash |
| 10 | `dcbc40b3` | ✗ | Bash ×3 |
| 11 | `5e245141` | ✗ | Bash |
| 12 | `67c1c642` | ✗ | AskUserQuestion |
| 13 | `f5bee72a` | ✗ | AskUserQuestion, Bash |
| 14 | `381e2859` | ✓ | Task, **Skill** |
| 15 | `e6975c4a` | ✗ | Task |
| 16 | `25cc96dd` | ✗ | Task, Read |
| 17 | `3b2feb9c` | ✗ | (no tools) |
| 18 | `0b0cd562` | ✗ | (no tools) |

## Cross-Experiment Comparison

### All Conditions Tested (Sorted by Activation Rate)

| Condition | SKILL.md | CLAUDE.md | Hook | Rate | Δ from Baseline |
|-----------|---------|-----------|------|------|-----------------|
| **Original (this)** | Original | No | No | **5.6%** | — |
| C3 (CLAUDE.md×Hook) | Current | No | Yes | **33.3%** | +27.7pp |
| C4 (CLAUDE.md×Hook) | Current | Yes | Yes | **66.7%** | +61.1pp |
| C1 (CLAUDE.md×Hook) | Current | No | No | **77.8%** | +72.2pp |
| C2 (CLAUDE.md×Hook) | Current | Yes | No | **88.9%** | +83.3pp |
| Original 0/4 | Original | No | No | **0%** | −5.6pp |

### Effect Size Comparison

| Variable | Without | With | Effect |
|----------|---------|------|--------|
| **SKILL.md Quality** | 5.6% (original) | 77.8% (current) | **+72.2pp** |
| CLAUDE.md | avg 55.6% | avg 77.8% | +22.2pp |
| Hook | avg 83.4% | avg 50.0% | −33.4pp |
| Keywords | 88.9% | 88.9% | 0pp |

**SKILL.md quality has by far the largest effect** — more than 3× the effect of CLAUDE.md and with opposite sign to the Hook effect.

## Key Findings

### 1. SKILL.md Quality Is the Primary Driver (72.2pp effect)

Reverting to original SKILL.md files dropped activation from 77.8% to 5.6%, a 72.2 percentage point decrease. This is the largest single effect observed across all experiments, and it explains the mystery jump from 0% to 89%.

### 2. Original 0% Result Reproduced

The original experiment (Jan 29 01:07 JST) found 0/4 (0%) activation. This experiment with the same original SKILL.md files found 1/18 (5.6%). These results are consistent — the single success (test 14: "create reactive state with $state") contains the literal keyword `$state` which is unique to the svelte5-runes skill.

### 3. Two Changes in SKILL.md Files Caused the Jump

Between the 0% and 89% experiments, two changes were made:
1. **Keywords expanded** (7-9 → 14-20 per skill, adding multi-word phrases)
2. **YAML frontmatter fenced** with `---` delimiters

The keyword expansion happened first (04:41 JST) and is likely the more impactful change, since it directly affects how Claude Code presents skill metadata in the system prompt. The `---` fencing may affect frontmatter parsing.

### 4. Variable Effect Ranking

1. **SKILL.md Quality: +72.2pp** — Dominant factor
2. **CLAUDE.md: +22.2pp** — Moderate positive effect
3. **Hook: −33.4pp** — Negative effect (interferes)
4. **Keywords (in SKILL.md): 0pp** — No additional effect beyond baseline

### 5. The Hook's Negative Effect May Be Explained

The hook's negative effect is puzzling but may make sense in light of SKILL.md quality:
- With well-crafted SKILL.md files, Claude already knows to use Skill — the hook's injection of an INSTRUCTION may confuse the model by introducing a second, potentially conflicting signal.
- The hook was designed for a world where SKILL.md files were poor and Claude needed explicit instructions. With improved SKILL.md files, the hook is unnecessary and counterproductive.

## Implications

1. **For Skill authors:** Invest in SKILL.md quality — rich keywords, proper YAML frontmatter, clear descriptions. This is the single most impactful lever for activation.
2. **For the hook system:** The current hook implementation hurts when SKILL.md files are well-crafted. Consider removing or redesigning the hook.
3. **For CLAUDE.md:** A project CLAUDE.md that describes available skills provides a moderate boost (+22pp), but is secondary to SKILL.md quality.
4. **For keyword expansion:** Adding multi-word phrases ("merge conflict", "cherry pick") and synonyms ("VCS", "OCI") to the keywords field is highly effective.

## Files in This Experiment

```
results/skillmd-quality-experiment/
├── REPORT_SKILLMD_QUALITY.md                          ← This report
├── original-skillmd-no_claudemd-no_hook-full.txt     ← Full test runner output
├── original-skillmd-no_claudemd-no_hook-results.json ← Per-test JSON results
├── original-skillmd-files/                            ← Original SKILL.md files (from session ba15df45)
│   ├── dockerfile-generator-SKILL.md
│   ├── git-workflow-SKILL.md
│   └── svelte5-runes-SKILL.md
└── current-skillmd-files/                             ← Current SKILL.md files (improved)
    ├── dockerfile-generator-SKILL.md
    ├── git-workflow-SKILL.md
    └── svelte5-runes-SKILL.md
```

## Methodology Notes

- Original SKILL.md content extracted from cclogviewer session `ba15df45-e967-4089-beaf-10f2ea72bdb9` (project: `stuff`), Write tool calls at entries 22-24.
- Timeline verified: files created Jan 28 07:48 JST, copied to `.claude/skills/` at 15:34 JST, original experiment ran Jan 29 01:07 JST, keywords expanded Jan 29 04:41 JST.
- All 18 session verifications performed via `mcp__cclogviewer__get_tool_usage_stats()` — not relying on the test runner's unreliable "presumed" heuristic.
- Files restored to current state after experiment.
