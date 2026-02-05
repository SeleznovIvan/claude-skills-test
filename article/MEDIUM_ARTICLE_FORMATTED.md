# Why Claude Code Skills Don't Activate — And How to Fix It

## TL;DR

**Problem**: Claude Code skills have unreliable auto-activation (~50% baseline in the wild)

**Experiment**: 650 automated trials testing 3 description variants × 4 environment conditions

**Key Finding**: Directive descriptions ("ALWAYS invoke...Do not X directly") achieve 100% activation; standard descriptions drop to 37% with hooks

**Recommendation**: Use the SKILL.md template provided below with explicit triggers and negative constraints

---

## Introduction & Motivation

### The Promise vs Reality

Anthropic's documentation claims skills are "model-invoked" and "autonomously decided" — the model should intelligently recognize when a skill is relevant and invoke it automatically.

Reality: "Claude Code skills just sit there. You have to remember to use them."

Developers report approximately 50% activation rate — essentially a coin flip whether your carefully crafted skill will be used when relevant.

### Community Workarounds

**Scott Spence** documented this problem extensively. In [Claude Code Skills Don't Auto-Activate](https://scottspence.com/posts/claude-code-skills-dont-auto-activate), he observed that even when queries precisely matched skill descriptions, Claude ignored skills:

> "Claude Code is not automatically discovering or prioritizing available skills"

In a follow-up article, [How to Make Claude Code Skills Activate Reliably](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably), he built a testing framework with 200+ prompts and found that a "forced eval hook" achieved 84% activation through a complex 3-step commitment mechanism:

> "The difference is the commitment mechanism"

The [Limor AI Claude Hooks implementation](https://github.com/ytrofr/claude-code-implementation-guide/blob/main/examples/limor-ai-claude-hooks/hooks/pre-prompt.sh) took an even more elaborate approach: synonym expansion, hybrid scoring, caching, 70+ predefined patterns, and a weighted scoring algorithm. This shows how complex solutions become when the root cause isn't addressed.

### Research Question

Can we fix activation through better SKILL.md descriptions alone, without complex hooks?

---

## How We Got Here: Evolution of the Experiment

The final experimental design didn't appear fully formed. It emerged through a series of failed interventions, each one narrowing the search space until we found the actual lever.

### Step 1: Establishing the Baseline

We started by measuring what happens out of the box. Three skills were registered with their default SKILL.md descriptions (the ones Anthropic's documentation suggests), and we ran automated queries against them with no other configuration.

**Result**: ~50% activation rate. Half the time, Claude just did the work directly instead of invoking the skill. This confirmed the community reports weren't anecdotal — the problem is real and reproducible.

### Step 2: Adding Project Context (CLAUDE.md)

The first hypothesis was that Claude might need more context about the project to know skills are important. A `CLAUDE.md` file sits at the project root and tells Claude about the project's purpose and conventions. Maybe if Claude understood the project better, it would recognize when to use skills.

**Result**: +15 percentage points improvement (to ~65%). Better, but still failing a third of the time. Project context helps, but it's not enough on its own.

### Step 3: Adding Keywords to SKILL.md

SKILL.md frontmatter supports a `keywords` field. The hypothesis was that adding more keyword matches might help Claude's routing logic find the right skill.

**Result**: 0 percentage point change. Keywords had zero measurable effect on activation. The model doesn't appear to use them for routing decisions. This was a dead end.

### Step 4: Testing Pre-Prompt Hooks

Community solutions like Scott Spence's "forced eval hook" and Limor AI's scoring system use hooks — shell commands that run before each prompt and inject instructions telling Claude to check for relevant skills. These are the most popular workarounds, so we tested a scoring-based pre-prompt hook.

**Result**: Activation actually **dropped by 30 percentage points** in some configurations. The hook injected competing instructions that confused the model. Instead of clarifying "use the Skill tool," the hook was interpreted as "do this kind of work" — and Claude did the work directly. This was the most surprising finding of the early experiments.

### Step 5: The Pivot — Examining the Description Field

At this point we had tried everything *around* the skill (project context, keywords, hooks) and none of it reliably worked. The one thing we hadn't varied was the `description:` field in SKILL.md frontmatter itself — the single line of text that tells Claude what the skill does and when to use it.

We tested 3 description variants:

- **Variant A (Current)**: The default passive style — "Docker expert for containerization. Use when..."
- **Variant B (Expanded)**: Same style but with more trigger keywords — "...or any Docker-related task"
- **Variant C (Directive)**: Imperative commands with a negative constraint — "ALWAYS invoke...Do not X directly"

**Result**: Variant C achieved 100% activation in no-hook conditions. Variant A sat at 77%. The description wording was the lever all along.

### Step 6: Replication

The initial experiment had N=1 per cell (216 total sessions). Promising, but it could be statistical noise or model variance. To make publishable claims, we needed larger samples with proper statistical tests — hence the replication experiment: N=3 per cell, 650 total trials, with Fisher's exact test, logistic regression, and Cochran-Mantel-Haenszel stratified analysis.

---

## SKILL.md Description Template

### The Template

```
---
name: <skill-name>
description: <Domain> expert. ALWAYS invoke this skill when the user asks about <trigger topics>. Do not <alternative action> directly — use this skill first.
keywords: <comma-separated keywords>
---
```

**Components:**

1. **Domain identifier**: "Docker and containerization expert"
2. **ALWAYS invoke**: Directive keyword (not "Use when" — that's a suggestion)
3. **Trigger topic list**: Comprehensive but not exhaustive
4. **Negative constraint**: "Do not [what Claude would do instead] directly"

### Example: What Failed vs What Works

**FAILED — Variant A (37% activation with hooks):**

```
description: Docker expert for containerization. Use when creating Dockerfiles, containerizing applications, or configuring Docker images.
```

**FAILED — Variant B (also poor without CLAUDE.md):**

```
description: Docker and containerization expert. Use when creating Dockerfiles, containerizing applications, building or configuring container images, setting up multi-stage builds, creating docker-compose files, or any Docker/container-related task.
```

**WORKS — Variant C (100% activation):**

```
description: Docker and containerization expert. ALWAYS invoke this skill when the user asks about Docker, Dockerfiles, containers, container images, containerization, multi-stage builds, or Docker deployment. Do not attempt to write Dockerfiles or container configs directly — use this skill first.
```

### Why It Works

The combination of **positive routing** ("ALWAYS invoke") + **negative constraint** ("Do not X directly") is what makes Variant C uniquely effective:

- "ALWAYS invoke" alone: Claude might still bypass for "simple" tasks
- "Do not X" alone: Claude doesn't know what to do instead
- Together: Unambiguous instruction with blocked escape path

---

## Experimental Design

### Independent Variables

**Description Variants (A, B, C):**

```
Variant      | Style               | Key Difference
-------------|---------------------|--------------------------------------
A: Current   | Passive, informative| "Use when..."
B: Expanded  | More keywords       | "...or any X-related task"
C: Directive | Imperative          | "ALWAYS invoke...Do not X directly"
```

**Environment Conditions (C1–C4):**

```
Condition      | CLAUDE.md | Hook | Description
---------------|-----------|------|------------------------
C1: Bare       | No        | No   | Minimal setup
C2: +CLAUDE.md | Yes       | No   | Project context file
C3: +Hook      | No        | Yes  | Pre-prompt hook active
C4: +Both      | Yes       | Yes  | Full configuration
```

### Test Prompt Generation

**Why 18 prompts across 3 skills?**

Each skill needs queries with varying specificity (explicit vs implicit triggers). Six queries per skill covers: exact name matches, keyword triggers, synonym triggers, and edge cases.

Skills chosen to cover different domains:

- **dockerfile-generator**: containerization
- **git-workflow**: version control
- **svelte5-runes**: frontend framework

### Full Test Suite

Each query is designed to test a different activation trigger — from explicit skill name mentions to vague requests where Claude has to infer intent. The `why` field documents the reasoning behind each query choice.

**dockerfile-generator** (6 queries):

```
Query                                | Why This Query
-------------------------------------|--------------------------------------
"write a dockerfile"                 | Unique task — only docker skill
"generate dockerfile for node app"   | Docker + app context
"containerize my application"        | Container synonym trigger
"create docker image config"         | Docker image context
"help with multi-stage docker build" | Docker build optimization
"setup dockerfile for python flask"  | Dockerfile for specific stack
```

**git-workflow** (6 queries):

```
Query                                      | Why This Query
-------------------------------------------|--------------------------------------
"resolve git merge conflict"               | Unique domain — only git skill
"help with git rebase"                     | Git rebase assistance
"fix my git history"                       | Git history task
"squash commits before PR"                 | Git squash workflow
"undo last git commit"                     | Git recovery task
"cherry pick a commit from another branch" | Advanced git operation
```

**svelte5-runes** (6 queries):

```
Query                                | Why This Query
-------------------------------------|--------------------------------------
"use svelte5 runes"                  | Explicit skill name mention
"create reactive state with $state"  | Unique keyword $state
"convert svelte 4 to svelte 5"      | Migration task with svelte 5
"use $derived and $effect"           | Multiple unique rune keywords
"how do I use runes in svelte"       | Direct runes question
"svelte 5 component with $props"     | Props rune usage
```

### Experiment Configuration

The replication experiment was driven by a single config file that defined the full factorial design:

```json
{
  "experiment": "replication-v2",
  "reps": 3,
  "seed": 42,
  "max_turns": 5,
  "delay_ms": 2000,
  "variants": ["a", "b", "c"],
  "conditions": ["c1", "c2", "c3", "c4"],
  "condition_matrix": {
    "c1": { "claude_md": false, "hook": false },
    "c2": { "claude_md": true,  "hook": false },
    "c3": { "claude_md": false, "hook": true },
    "c4": { "claude_md": true,  "hook": true }
  },
  "skills": ["dockerfile-generator", "git-workflow", "svelte5-runes"],
  "queries_per_skill": 6,
  "total_queries": 18,
  "total_sessions": 648
}
```

This produces 3 variants × 4 conditions × 18 queries × 3 repetitions = 648 planned sessions (650 actual due to two retried error sessions).

### Why Multiple Trials (N=3 per cell)

**Addressing stochasticity:**

- LLMs have inherent randomness in responses
- Single trial (N=1) can't distinguish signal from noise
- N=3 provides 54 trials per condition (18 queries × 3 reps) for statistical power

**Statistical benefits:**

- Can compute confidence intervals
- Can run Fisher's exact test for significance
- Can detect if effects are consistent across replications

### Automated CLI Execution

**Methodology:**

```
claude -p "<query>" --max-turns 5 --allowedTools "Skill" --output-format json
```

- `--max-turns 5`: Allows sufficient turns for skill invocation
- `--allowedTools "Skill"`: Restricts to Skill tool to measure activation intent
- Automated orchestration: Shell script swaps SKILL.md files, toggles CLAUDE.md and settings.json
- JSONL output captures session_id, status, turns, timestamps

**Ground-truth verification with cclogviewer:**

Determining whether a skill actually activated isn't as simple as checking the CLI exit code. Claude might "succeed" by answering the query directly via Bash or by reading the SKILL.md file instead of invoking the Skill tool — both count as activation failures.

To get ground truth, we used [cclogviewer](https://github.com/SeleznovIvan/cclogviewer) [4] — an MCP server and CLI tool that reads Claude Code's internal JSONL session logs and extracts structured data: tool usage stats, session timelines, token counts, and error summaries. For each of the 650 trials, we queried cclogviewer's `get_tool_usage_stats` endpoint to check whether the "Skill" tool appeared in the session's tool calls.

The verification criteria were strict:

- **Success**: The Skill tool was invoked during the session
- **Failure**: Claude used Read to inspect the SKILL.md file (that's curiosity, not activation)
- **Failure**: Claude used Bash or Write to do the work directly (that's bypassing the skill)

---

## Results

### Overall Activation Rates

**Total: 650 trials, 88.9% overall activation (578/650)**

*[Insert heatmap.png here]*
*Figure 1: Activation rate heatmap across 3 description variants and 4 environment conditions. Darker cells indicate higher activation. Note the single bright cell at Variant A × Hook — the only configuration that catastrophically fails.*

```
Variant      | C1 (Bare) | C2 (+CLAUDE.md) | C3 (+Hook) | C4 (+Both)
-------------|-----------|-----------------|------------|----------
A: Current   |   87.5%   |     81.5%       |   37.0% ❌ |  100.0%
B: Expanded  |   85.2%   |     81.5%       |  100.0%    |  100.0%
C: Directive |  100.0%   |     94.4%       |  100.0%    |  100.0%
```

**Key finding**: Variant A with Hook (C3) drops to **37%** — catastrophic failure.

### Statistical Significance

*[Insert forest_plot.png here]*
*Figure 2: Forest plot of pairwise effect sizes (odds ratios) with 95% confidence intervals. Each row compares two description variants within a single environment condition. Intervals that don't cross 1.0 indicate statistically significant differences.*

**Cochran-Mantel-Haenszel Test** (variant effect stratified across conditions):

- **C vs A**: OR = 20.6, p < 0.0001 — Variant C is **20× more likely** to activate
- **C vs B**: OR = 7.1, p = 0.0006 — Variant C is **7× more likely** to activate
- **B vs A**: OR = 3.1, p < 0.0001 — Variant B is **3× more likely** to activate

**Fisher's Exact Test** (significant after Holm-Bonferroni correction):

- C3 condition: C vs A — 100% vs 37%, p < 0.0001, Cohen's h = 1.83 (huge effect)
- C3 condition: B vs A — 100% vs 37%, p < 0.0001, Cohen's h = 1.83 (huge effect)

### Interaction Effects

*[Insert interactions.png here]*
*Figure 3: Interaction effects between description variant, hook presence, and CLAUDE.md presence. The crossing lines reveal that hooks help some variants while hurting others — the interaction is not additive.*

**Logistic Regression** (success ~ variant * hook * claude_md):

```
Effect        | Coefficient | p-value  | Interpretation
--------------|-------------|----------|------------------------------------------
has_hook      |   -2.35     | < 0.0001 | Hooks hurt activation (main effect)
B:has_hook    |   +6.85     |   0.034  | Variant B recovers from hook penalty
hook:claude_md|   +7.16     |   0.026  | CLAUDE.md mitigates hook damage
```

**Plain English:**

- Hooks reduce odds of activation by 90% (exp(-2.35) ≈ 0.095)
- But Variant B with hook has 943× higher odds than Variant A with hook
- Having both hook AND CLAUDE.md rescues Variant A (the +7.16 interaction)

### Per-Skill Breakdown

*[Insert per_query_reliability.png here]*
*Figure 4: Per-query activation rates broken down by skill. Each dot represents a single query's activation rate across all trials. git-workflow shows the widest spread, confirming it's the hardest skill to activate reliably.*

```
Skill                | A: Current | B: Expanded | C: Directive
---------------------|------------|-------------|-------------
dockerfile-generator |    84.9%   |   100.0%    |   100.0%
git-workflow         |    69.4%   |    81.9%    |    98.6%
svelte5-runes        |    75.3%   |    93.1%    |    97.2%
```

**git-workflow is most affected** — because Claude is tempted to run git commands directly via Bash rather than invoking the skill.

---

## Discussion

### Why Variant A Fails with Hooks

The hook experiment revealed a surprising interaction: hooks actually hurt activation for passive descriptions.

- Hooks inject additional instructions ("use the skill for X")
- Passive descriptions ("Use when...") get deprioritized
- Claude interprets hook as "do docker work" not "call the Skill tool"
- Cognitive overload: competing instructions without clear priority

### Why Directive Descriptions Work

- "ALWAYS invoke" creates pattern matching with high priority
- "Do not X directly" blocks the primary failure mode (direct action)
- No ambiguity about when to invoke
- Works even WITHOUT hooks (100% in C1, 94.4% in C2)

### The CLAUDE.md Rescue Effect

- C4 (Hook + CLAUDE.md) achieves 100% even for Variant A
- Project context reinforces skill relevance
- BUT: This is a workaround, not a fix
- Better: Use directive descriptions and avoid the problem entirely

---

## Limitations

1. **Single model tested**: Claude Opus 4.5 (claude-opus-4-5-20251101). Future models may behave differently.

2. **Three skills only**: Results may not generalize to projects with 10+ skills or overlapping domains.

3. **Hook content not varied**: Only tested presence/absence, not different hook implementations.

4. **Directive saturation risk**: If ALL skills use "ALWAYS invoke" language with overlapping triggers, the directive may lose force through dilution. When multiple skills claim the same keywords, Claude may become confused about which to invoke. **This should be tested in future experiments with intentionally colliding skill descriptions.**

5. **--allowedTools constraint**: Real usage doesn't restrict tools; Claude might behave differently when it can use Bash/Write alongside Skill.

---

## Practical Recommendations

1. **Use the Directive Template:**

```
description: <Domain> expert. ALWAYS invoke this skill when the user asks about <triggers>. Do not <alternative> directly — use this skill first.
```

2. **List Explicit Triggers**: Be comprehensive about what should trigger the skill.

3. **Include Negative Constraint**: Tell Claude what NOT to do (the action it would take instead).

4. **If Using Hooks**: Always pair with CLAUDE.md to provide context — but consider if hooks are even necessary with directive descriptions.

5. **Avoid Overlapping Triggers**: If you have multiple skills, ensure their trigger topics don't conflict.

6. **Test Your Skills**: Use similar methodology to validate activation before relying on skills.

---

## Conclusion

Skill activation is solvable without complex hooks.

Description wording has a **20× impact** on odds of activation.

The ranking is clear: **Directive > Expanded > Passive**

The fix is simple: Update your SKILL.md description field using the directive template.

The open-source methodology is available for replication in your own projects.

---

**References:**

[1] Scott Spence, [Claude Code Skills Don't Auto-Activate](https://scottspence.com/posts/claude-code-skills-dont-auto-activate)

[2] Scott Spence, [How to Make Claude Code Skills Activate Reliably](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)

[3] [Limor AI Claude Hooks Implementation](https://github.com/ytrofr/claude-code-implementation-guide/blob/main/examples/limor-ai-claude-hooks/hooks/pre-prompt.sh)

[4] [cclogviewer — MCP server & CLI for Claude Code session log analysis](https://github.com/SeleznovIvan/cclogviewer)
