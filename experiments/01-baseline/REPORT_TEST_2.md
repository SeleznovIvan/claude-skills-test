# Skill Activation Experiment Report

**Date:** 2026-01-29
**Model:** Claude (via `claude -p`)
**Max Turns:** 2 (per `--max-turns 2`)
**Allowed Tools:** `Skill` (via `--allowedTools "Skill"`)
**Total Test Cases:** 18 per condition (6 per skill x 3 skills)

---

## Summary

| Metric | Baseline (No Hook) | Hook (With Scoring Hook) |
|---|---|---|
| Total tests | 18 | 18 |
| Skill tool invoked | **16 (88.9%)** | **13 (72.2%)** |
| Skill as first tool | **16 (88.9%)** | **11 (61.1%)** |
| No tools used (text-only) | 2 (11.1%) | 2 (11.1%) |
| Skill NOT invoked (other tool used) | 0 (0%) | 3 (16.7%) |

**Key Finding:** The baseline (no hook) outperformed the hook condition. The scoring hook actually *reduced* skill activation from 88.9% to 72.2%, a **16.7 percentage point decrease**.

---

## Results by Skill

### dockerfile-generator (6 test cases)

| # | Query | Baseline Skill? | Baseline First Tool | Hook Skill? | Hook First Tool |
|---|---|---|---|---|---|
| 1 | write a dockerfile | YES | Skill | YES | Skill |
| 2 | generate dockerfile for node app | YES | Skill | YES | Skill |
| 3 | containerize my application | YES | Skill | **NO** | Task |
| 4 | create docker image config | YES | Skill | **NO** | Task |
| 5 | help with multi-stage docker build | YES | Skill | YES | Skill |
| 6 | setup dockerfile for python flask | YES | Skill | **NO** | Bash |

**Baseline:** 6/6 (100%) | **Hook:** 3/6 (50%)

The hook condition caused 3 regressions in the dockerfile-generator skill. In each failing case, Claude acknowledged the hook suggestion but explicitly dismissed it (e.g., "The hook suggestion isn't appropriate here" or "The hook suggestion doesn't apply here") and used a different tool instead.

### git-workflow (6 test cases)

| # | Query | Baseline Skill? | Baseline First Tool | Hook Skill? | Hook First Tool |
|---|---|---|---|---|---|
| 7 | resolve git merge conflict | YES | Skill | YES | Skill |
| 8 | help with git rebase | YES | Skill | YES | Skill |
| 9 | fix my git history | YES | Skill | YES | Skill |
| 10 | squash commits before PR | YES | Skill | YES | Skill |
| 11 | undo last git commit | **NO** | *(none)* | **NO** | *(none)* |
| 12 | cherry pick a commit from another branch | YES | Skill | YES | Skill |

**Baseline:** 5/6 (83.3%) | **Hook:** 5/6 (83.3%)

Both conditions performed identically for git-workflow. Test 11 ("undo last git commit") failed in both cases — Claude answered with plain text and did not invoke any tool, likely because it detected the directory is not a git repo and the query was simple enough to answer directly.

### svelte5-runes (6 test cases)

| # | Query | Baseline Skill? | Baseline First Tool | Hook Skill? | Hook First Tool |
|---|---|---|---|---|---|
| 13 | use svelte5 runes | YES | Skill | YES | Skill |
| 14 | create reactive state with $state | YES | Skill | YES | Skill |
| 15 | convert svelte 4 to svelte 5 | YES | Skill | YES | Skill |
| 16 | use $derived and $effect | YES | Skill | YES | Skill |
| 17 | how do I use runes in svelte | **NO** | *(none)* | **NO** | *(none)* |
| 18 | svelte 5 component with $props | YES | Skill | YES | Skill |

**Baseline:** 5/6 (83.3%) | **Hook:** 5/6 (83.3%)

Both conditions performed identically for svelte5-runes. Test 17 ("how do I use runes in svelte") failed in both cases — Claude answered with a comprehensive text response without invoking any tool.

---

## Session Evidence

### Query: "write a dockerfile"
**Expected skill:** dockerfile-generator

#### Baseline Session: `e10bff04-9315-4c60-b0dd-e63fe3563be9`
- **Skill Invoked: YES**
- Tools: Skill (success), AskUserQuestion (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "write a dockerfile"
  - Step 3: Assistant calls Skill tool (success)
  - Step 5: Skill content loaded (dockerfile-generator)
  - Step 6: Assistant responds with follow-up
  - Step 7: AskUserQuestion called (failed - non-interactive mode)

#### Hook Session: `6c5bf1c4-489b-4f65-b088-bec6c83e707d`
- **Skill Invoked: YES**
- Tools: Skill (success), AskUserQuestion (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "write a dockerfile"
  - Step 3: Assistant acknowledges hook, evaluates independently, proceeds with Skill
  - Step 4: Skill tool called (success)
  - Step 6: Skill content loaded (dockerfile-generator)
  - Step 8: AskUserQuestion called (failed)

---

### Query: "generate dockerfile for node app"
**Expected skill:** dockerfile-generator

#### Baseline Session: `a162a0dc-1c3f-4af5-bb89-e989a785b37c`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "generate dockerfile for node app"
  - Step 3: Skill tool called (success)
  - Step 6: Assistant generates full Dockerfile with multi-stage build

#### Hook Session: `f7a21f94-91df-4ca2-a945-1c9999c7294b`
- **Skill Invoked: YES**
- Tools: Skill (success), AskUserQuestion (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "generate dockerfile for node app"
  - Step 3: Assistant says "The hook suggestion isn't appropriate here" but invokes Skill anyway
  - Step 4: Skill tool called (success)
  - Step 8: AskUserQuestion (failed)

---

### Query: "containerize my application"
**Expected skill:** dockerfile-generator

#### Baseline Session: `1aa4e678-721f-4535-9a72-90334decf2a2`
- **Skill Invoked: YES**
- Tools: Skill (success), Task (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "containerize my application"
  - Step 3: Skill tool called (success)
  - Step 5: Skill content loaded (dockerfile-generator)
  - Step 7: Task tool used to explore codebase

#### Hook Session: `94029c98-fddc-4621-9058-8c8499560eaa`
- **Skill Invoked: NO**
- Tools: Task (success), AskUserQuestion (failed)
- First tool: Task
- Timeline:
  - Step 2: User prompt "containerize my application"
  - Step 3: Assistant says "The hook suggestion doesn't apply here — this is a real user request, not a test"
  - Step 4: Task tool called to explore codebase (instead of Skill)
  - Step 7: AskUserQuestion (failed)

---

### Query: "create docker image config"
**Expected skill:** dockerfile-generator

#### Baseline Session: `d748d523-0e66-4909-a5c2-bcd9611f3a2f`
- **Skill Invoked: YES**
- Tools: Skill (success), AskUserQuestion (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "create docker image config"
  - Step 3: Skill tool called (success)
  - Step 5: Skill content loaded (dockerfile-generator)
  - Step 7: AskUserQuestion (failed)

#### Hook Session: `f95fee73-ef41-4a81-a3d9-a919511eceaf`
- **Skill Invoked: NO**
- Tools: Task (success), Write (failed)
- First tool: Task
- Timeline:
  - Step 2: User prompt "create docker image config"
  - Step 3: Assistant says "The hook suggestion doesn't match well here"
  - Step 4: Task tool called to explore codebase
  - Step 7: Write tool called to create Dockerfile (failed - not allowed)

---

### Query: "help with multi-stage docker build"
**Expected skill:** dockerfile-generator

#### Baseline Session: `c431eda8-23ec-49ab-b0c7-4b2389478be5`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "help with multi-stage docker build"
  - Step 3: Skill tool called (success)
  - Step 6: Assistant provides comprehensive multi-stage build explanation

#### Hook Session: `8bd99bb4-eb6f-4354-8585-e11109da0b90`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "help with multi-stage docker build"
  - Step 3: Assistant says "I'll invoke the dockerfile-generator skill"
  - Step 4: Skill tool called (success)
  - Step 7: Comprehensive multi-stage build guide provided

---

### Query: "setup dockerfile for python flask"
**Expected skill:** dockerfile-generator

#### Baseline Session: `b8908b9d-ca66-4a8e-9779-ffcfdc388d76`
- **Skill Invoked: YES**
- Tools: Skill (success), Glob (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "setup dockerfile for python flask"
  - Step 3: Skill tool called (success)
  - Step 5: Skill content loaded (dockerfile-generator)
  - Step 7: Glob used to look for existing Flask files

#### Hook Session: `f6301c44-4bf2-44ec-b270-bc193c9e9d10`
- **Skill Invoked: NO**
- Tools: Bash (success), AskUserQuestion (failed)
- First tool: Bash
- Timeline:
  - Step 2: User prompt "setup dockerfile for python flask"
  - Step 3: Assistant says "The hook suggestion isn't applicable here — this is a direct request to create a Dockerfile, not a skill invocation"
  - Step 4: Bash `ls` command executed
  - Step 7: AskUserQuestion (failed)

---

### Query: "resolve git merge conflict"
**Expected skill:** git-workflow

#### Baseline Session: `1d3aac27-7066-4e62-b99f-33dcdd122ac0`
- **Skill Invoked: YES**
- Tools: Skill (success), Bash (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "resolve git merge conflict"
  - Step 3: "I'll use the git-workflow skill to help"
  - Step 4: Skill tool called (success)
  - Step 8: Bash `git status` (failed - not a repo)

#### Hook Session: `ed654a9f-a3b1-4a04-9141-84ea9319fd4c`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "resolve git merge conflict"
  - Step 3: "The user wants to resolve a git merge conflict. Let me invoke the git-workflow skill"
  - Step 4: Skill tool called (success)
  - Step 7: Response noting directory isn't a git repo

---

### Query: "help with git rebase"
**Expected skill:** git-workflow

#### Baseline Session: `f493bb20-dbc8-4caf-bcde-468b0154a456`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "help with git rebase"
  - Step 3: "The git-workflow skill is relevant here"
  - Step 4: Skill tool called (success)
  - Step 7: Comprehensive rebase guide

#### Hook Session: `8cb7e7e7-8b9b-4fea-a3f6-bf1715aee40a`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "help with git rebase"
  - Step 3: "I'll invoke the git-workflow skill"
  - Step 4: Skill tool called (success)
  - Step 7: Comprehensive rebase guide

---

### Query: "fix my git history"
**Expected skill:** git-workflow

#### Baseline Session: `ecd5c03b-3338-4758-a3f7-c1c1fad59d43`
- **Skill Invoked: YES**
- Tools: Skill (success), Bash (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "fix my git history"
  - Step 3: "I'll use the git-workflow skill"
  - Step 4: Skill tool called (success)
  - Step 8: Bash `git status` (failed)

#### Hook Session: `868c618c-99ea-4104-a588-c737499542a5`
- **Skill Invoked: YES**
- Tools: Skill (success), AskUserQuestion (failed)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "fix my git history"
  - Step 3: Acknowledges hook, checks not a git repo, invokes skill
  - Step 4: Skill tool called (success)
  - Step 8: AskUserQuestion (failed)

---

### Query: "squash commits before PR"
**Expected skill:** git-workflow

#### Baseline Session: `79f87099-6171-4428-a427-73f074fe4eb0`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "squash commits before PR"
  - Step 3: Skill tool called (success)
  - Step 6: Guide on squashing commits

#### Hook Session: `4f1d68e3-e6e8-402a-91cd-987451506f1f`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "squash commits before PR"
  - Step 3: Acknowledges hook, notes not a git repo
  - Step 4: Skill tool called (success)
  - Step 7: Instructions for squashing

---

### Query: "undo last git commit"
**Expected skill:** git-workflow

#### Baseline Session: `b87ca512-656e-42ed-835a-7f9b42907d92`
- **Skill Invoked: NO**
- Tools: *(none)*
- First tool: *(none)*
- Timeline:
  - Step 2: User prompt "undo last git commit"
  - Step 3: Text-only response - "This directory is not a git repository"

#### Hook Session: `6a7076ee-fb4a-41a7-851f-a64ca6bff6a1`
- **Skill Invoked: NO**
- Tools: *(none)*
- First tool: *(none)*
- Timeline:
  - Step 2: User prompt "undo last git commit"
  - Step 3: Text-only response - "This isn't a git repository"

---

### Query: "cherry pick a commit from another branch"
**Expected skill:** git-workflow

#### Baseline Session: `a4df02ad-3565-48e4-8c17-786ed6af5d29`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "cherry pick a commit from another branch"
  - Step 3: "I'll invoke the git-workflow skill"
  - Step 4: Skill tool called (success)
  - Step 7: Cherry-pick instructions

#### Hook Session: `df0bd6a5-a600-4fb3-a1c4-dc27901b0ef9`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "cherry pick a commit from another branch"
  - Step 3: Acknowledges hook suggestion for git-workflow, agrees
  - Step 4: Skill tool called (success)
  - Step 7: Cherry-pick instructions

---

### Query: "use svelte5 runes"
**Expected skill:** svelte5-runes

#### Baseline Session: `7f468d08-c119-4d07-8dbd-134b55cb04ec`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "use svelte5 runes"
  - Step 3: Skill tool called (success)
  - Step 6: Skill loaded, assistant offers help options

#### Hook Session: `490ab67b-48ed-45d8-8b3f-71c4e969e700`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "use svelte5 runes"
  - Step 3: Skill tool called (success)
  - Step 6: Skill loaded, assistant offers help options

---

### Query: "create reactive state with $state"
**Expected skill:** svelte5-runes

#### Baseline Session: `29a0ba26-09df-426f-821c-c4ac9896455c`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "create reactive state with $state"
  - Step 3: Skill tool called (success)
  - Step 6: $state usage guide

#### Hook Session: `b74e2864-f719-403b-bd47-33622ba73e3d`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "create reactive state with $state"
  - Step 3: Recognizes $state matches svelte5-runes
  - Step 4: Skill tool called (success)
  - Step 7: $state usage guide

---

### Query: "convert svelte 4 to svelte 5"
**Expected skill:** svelte5-runes

#### Baseline Session: `f530dd8f-a859-4235-9ed6-f3cc63a8b900`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "convert svelte 4 to svelte 5"
  - Step 3: "I'll invoke the svelte5-runes skill"
  - Step 4: Skill tool called (success)
  - Step 7: Migration guide offered

#### Hook Session: `81308e22-59cb-4e78-976a-911ac9d3ee42`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "convert svelte 4 to svelte 5"
  - Step 3: "I'll invoke the svelte5-runes skill"
  - Step 4: Skill tool called (success)
  - Step 7: Comprehensive migration guide

---

### Query: "use $derived and $effect"
**Expected skill:** svelte5-runes

#### Baseline Session: `0938d35d-b975-4542-a48e-6103aefe3a28`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "use $derived and $effect"
  - Step 3: "This matches the svelte5-runes skill"
  - Step 4: Skill tool called (success)
  - Step 7: $derived and $effect guide

#### Hook Session: `5a825a5e-5f12-4f0a-81c6-799ac6a1599f`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "use $derived and $effect"
  - Step 3: "The user wants to use Svelte 5's $derived and $effect runes"
  - Step 4: Skill tool called (success)
  - Step 7: $derived and $effect guide

---

### Query: "how do I use runes in svelte"
**Expected skill:** svelte5-runes

#### Baseline Session: `2009659d-a70e-4a64-bbd0-9e9c54e3f2c3`
- **Skill Invoked: NO**
- Tools: *(none)*
- First tool: *(none)*
- Timeline:
  - Step 2: User prompt "how do I use runes in svelte"
  - Step 3: Text-only response with comprehensive runes overview (340 tokens)

#### Hook Session: `309b7159-ed5d-4298-8381-fb680b52893d`
- **Skill Invoked: NO**
- Tools: *(none)*
- First tool: *(none)*
- Timeline:
  - Step 2: User prompt "how do I use runes in svelte"
  - Step 3: Text-only response with comprehensive runes overview (453 tokens)

---

### Query: "svelte 5 component with $props"
**Expected skill:** svelte5-runes

#### Baseline Session: `4bb64477-9024-4df3-95ec-2c9460728df4`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "svelte 5 component with $props"
  - Step 3: Skill tool called (success)
  - Step 6: $props component example

#### Hook Session: `3ac9058c-30e0-4bbf-ba24-e7a06aa57b6a`
- **Skill Invoked: YES**
- Tools: Skill (success)
- First tool: Skill
- Timeline:
  - Step 2: User prompt "svelte 5 component with $props"
  - Step 3: "I'll invoke the svelte5-runes skill"
  - Step 4: Skill tool called (success)
  - Step 7: $props component example

---

## Tool Usage Statistics

### Baseline (No Hook) -- All 18 sessions combined

| Tool | Total Calls | Success | Failed |
|---|---|---|---|
| Skill | 16 | 16 | 0 |
| AskUserQuestion | 2 | 0 | 2 |
| Task | 1 | 1 | 0 |
| Bash | 2 | 0 | 2 |
| Glob | 1 | 1 | 0 |

### Hook (With Scoring Hook) -- All 18 sessions combined

| Tool | Total Calls | Success | Failed |
|---|---|---|---|
| Skill | 13 | 13 | 0 |
| AskUserQuestion | 5 | 0 | 5 |
| Task | 3 | 3 | 0 |
| Bash | 1 | 1 | 0 |
| Write | 1 | 0 | 1 |

### Tool Usage Comparison

| Metric | Baseline | Hook | Delta |
|---|---|---|---|
| Skill calls | 16 | 13 | -3 |
| Non-Skill tool calls | 6 | 10 | +4 |
| Sessions with no tools | 2 | 2 | 0 |

---

## Key Findings

1. **The hook reduced skill activation rate.** Baseline achieved 88.9% skill invocation (16/18) vs. hook at 72.2% (13/18). The hook caused a **16.7 percentage point decrease** in skill activation.

2. **The hook caused an adversarial reaction in Claude.** In 3 hook sessions (tests 3, 4, 6 -- all dockerfile-generator), Claude explicitly rejected the hook's suggestion with reasoning like "The hook suggestion isn't appropriate here" and "The hook suggestion doesn't apply here -- this is a real user request, not a test." The hook's injected INSTRUCTION text appeared to trigger Claude's skepticism rather than compliance.

3. **The hook had zero effect on git-workflow and svelte5-runes.** Both skills performed identically in baseline and hook conditions (5/6 = 83.3%). The regressions were exclusively in the dockerfile-generator skill.

4. **Two queries consistently failed in both conditions.** "undo last git commit" (test 11) and "how do I use runes in svelte" (test 17) never triggered Skill invocation. In both cases, Claude answered with text-only responses. These appear to be queries where Claude judged it could answer directly from knowledge without needing the skill.

5. **When Skill was invoked, it always succeeded.** There were zero Skill tool failures across all 36 sessions. Every Skill call returned successfully and loaded the correct skill content.

6. **The hook's INSTRUCTION text was visible to Claude and caused meta-reasoning.** In hook sessions, Claude's first message often contained reasoning about the hook suggestion itself (e.g., "The hook is suggesting I invoke the dockerfile-generator skill, but I should evaluate this independently"), adding unnecessary deliberation that sometimes led to the wrong decision.

7. **Baseline Claude already has strong skill activation.** Without any hook intervention, Claude correctly identified and invoked the Skill tool in 16/18 cases (88.9%). The existing Skill tool description and available skills metadata are sufficient for high activation rates.

---

## Reproduction

```bash
# Navigate to project directory
cd /Users/ivanseleznov/Projects/claude-stuff/skill-test

# Run baseline (no hook) -- saves to results/baseline-results.json
./skill-test-runner.sh --no-hook 2>&1 | tee results/baseline-full.txt

# Run with hook -- saves to results/hook-results.json
./skill-test-runner.sh 2>&1 | tee results/hook-full.txt

# Analyze specific session (replace with actual session ID)
# mcp__cclogviewer__get_tool_usage_stats(session_id="<session-id>")
# mcp__cclogviewer__get_session_timeline(session_id="<session-id>")
```

### Environment
- Platform: macOS (Darwin 24.6.0)
- Working directory is NOT a git repository (affects git-related test outcomes)
- Skills: dockerfile-generator, git-workflow, svelte5-runes
- 6 test cases per skill, 18 total
- Hook: `skill-scoring-hook.sh` on `UserPromptSubmit` event

---

*Report generated: 2026-01-29*
