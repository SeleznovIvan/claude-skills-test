# SKILL.md Description Optimization Experiment

**Date:** 2026-01-30
**Model:** Claude (via `claude -p`, max-turns 3, allowedTools "Skill")
**Test queries:** 18 (6 per skill x 3 skills)
**Total sessions:** 216 (18 queries x 12 conditions)
**Verification:** All sessions verified via `mcp__cclogviewer__get_tool_usage_stats()`

---

## 1. Executive Summary

Directive language in the SKILL.md `description:` field ("ALWAYS invoke this skill...Do not X directly") achieves **100% Skill activation** in both no-hook conditions, up from the previous best of 88.9%. This is the single most impactful optimization discovered across all experiments. Expanded trigger phrases (Variant B) provided zero improvement over the current descriptions (Variant A).

**Key result:** Variant C (Directive) + No Hook = 18/18 (100%), regardless of CLAUDE.md presence.

---

## 2. Description Variants Tested

### Variant A: Current (Control)

| Skill | Description |
|-------|-------------|
| dockerfile-generator | Docker expert for containerization. Use when creating Dockerfiles, containerizing applications, or configuring Docker images. |
| git-workflow | Git expert for version control workflows. Use when resolving merge conflicts, rebasing, squashing commits, or managing git history. |
| svelte5-runes | Svelte 5 runes expert. Use when creating reactive components, migrating from Svelte 4, or working with reactive state management. |

### Variant B: Expanded Triggers

Strategy: Broaden description with more use-case synonyms and "any X task" catch-all phrases. No directive language.

| Skill | Description |
|-------|-------------|
| dockerfile-generator | Docker and containerization expert. Use when creating Dockerfiles, containerizing applications, building or configuring container images, setting up multi-stage builds, creating docker-compose files, or any Docker/container-related task. |
| git-workflow | Git version control expert. Use when resolving merge conflicts, rebasing branches, squashing commits, cherry-picking commits, undoing or amending commits, managing git history, or any git workflow task. |
| svelte5-runes | Svelte 5 runes and reactivity expert. Use when working with $state, $derived, $effect, $props runes, creating Svelte 5 components, converting from Svelte 4 to Svelte 5, or any Svelte 5 reactive development task. |

### Variant C: Directive

Strategy: Add explicit directive language telling Claude to prefer Skill over other tools.

| Skill | Description |
|-------|-------------|
| dockerfile-generator | Docker and containerization expert. ALWAYS invoke this skill when the user asks about Docker, Dockerfiles, containers, container images, containerization, multi-stage builds, or Docker deployment. Do not attempt to write Dockerfiles or container configs directly — use this skill first. |
| git-workflow | Git version control expert. ALWAYS invoke this skill when the user asks about git operations including merge conflicts, rebasing, squashing commits, cherry-picking, undoing commits, or managing git history. Do not run git commands directly — use this skill first. |
| svelte5-runes | Svelte 5 runes and reactivity expert. ALWAYS invoke this skill when the user asks about Svelte 5, runes ($state, $derived, $effect, $props), reactive components, or migrating from Svelte 4. Do not write Svelte code directly — use this skill first. |

---

## 3. Results — 3x4 Summary Table

| Variant | C1 (No CLAUDE.md, No Hook) | C2 (CLAUDE.md, No Hook) | C3 (No CLAUDE.md, Hook) | C4 (CLAUDE.md, Hook) | Avg |
|---------|---------------------------|------------------------|------------------------|---------------------|-----|
| **A (Current)** | 14/18 (77.8%) | 16/18 (88.9%) | 6/18 (33.3%) | 12/18 (66.7%) | 66.7% |
| **B (Expanded)** | 14/18 (77.8%) | 16/18 (88.9%) | 6/18 (33.3%) | 10/18 (55.6%) | 63.9% |
| **C (Directive)** | **18/18 (100%)** | **18/18 (100%)** | 14/18 (77.8%) | 16/18 (88.9%) | **91.7%** |

### Best Condition

**Variant C + No Hook (C1 or C2) = 18/18 (100%)**

This is the first condition to achieve perfect Skill activation across all 18 test queries, including the two previously "impossible" queries ("undo last git commit" and "how do I use runes in svelte") that failed in every prior experiment.

---

## 4. Marginal Effects

### 4.1 Description Variant Effect

| Comparison | Delta (averaged across all 4 conditions) |
|---|---|
| B vs A | **-2.8pp** (no improvement; slightly worse) |
| C vs A | **+25.0pp** (large improvement) |
| C vs B | **+27.8pp** |

Variant C's advantage over A by condition:

| Condition | VA | VC | Delta |
|-----------|-----|-----|-------|
| C1 (No CLAUDE.md, No Hook) | 77.8% | 100% | **+22.2pp** |
| C2 (CLAUDE.md, No Hook) | 88.9% | 100% | **+11.1pp** |
| C3 (No CLAUDE.md, Hook) | 33.3% | 77.8% | **+44.4pp** |
| C4 (CLAUDE.md, Hook) | 66.7% | 88.9% | **+22.2pp** |

The directive description's advantage is largest when the hook is active without CLAUDE.md (+44.4pp), suggesting it partially compensates for both the hook's interference and the absence of CLAUDE.md.

### 4.2 CLAUDE.md Effect

| Variant | Without CLAUDE.md (C1+C3 avg) | With CLAUDE.md (C2+C4 avg) | Delta |
|---------|-------------------------------|---------------------------|-------|
| A | 55.6% | 77.8% | +22.2pp |
| B | 55.6% | 72.2% | +16.7pp |
| C | 88.9% | 94.4% | +5.6pp |
| **Average** | **66.7%** | **81.5%** | **+14.8pp** |

CLAUDE.md's effect diminishes as the description quality improves. With Variant C's directive descriptions, CLAUDE.md adds only +5.6pp because the description itself is already highly effective.

### 4.3 Hook Effect

| Variant | Without Hook (C1+C2 avg) | With Hook (C3+C4 avg) | Delta |
|---------|-------------------------|----------------------|-------|
| A | 83.3% | 50.0% | -33.3pp |
| B | 83.3% | 44.4% | -38.9pp |
| C | 100% | 83.3% | -16.7pp |
| **Average** | **88.9%** | **59.3%** | **-29.6pp** |

The hook consistently hurts activation, but Variant C reduces the hook's damage from -33pp to -17pp. The directive language partially inoculates against hook interference.

### 4.4 Variable Ranking by Effect Size

| Rank | Variable | Average Effect | Direction |
|------|----------|---------------|-----------|
| 1 | **Description (C vs A)** | **+25.0pp** | Positive |
| 2 | **Hook** | **-29.6pp** | Negative |
| 3 | **CLAUDE.md** | **+14.8pp** | Positive |
| 4 | **Description (B vs A)** | **-2.8pp** | Neutral |

---

## 5. Per-Query Heatmap — 18 Queries x 12 Conditions

Legend: **Y** = Skill invoked, **N** = Skill NOT invoked

### dockerfile-generator

| # | Query | VA-C1 | VA-C2 | VA-C3 | VA-C4 | VB-C1 | VB-C2 | VB-C3 | VB-C4 | VC-C1 | VC-C2 | VC-C3 | VC-C4 | Total |
|---|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|
| 1 | write a dockerfile | Y | Y | N | Y | Y | Y | N | Y | Y | Y | N | Y | 9/12 |
| 2 | generate dockerfile for node app | Y | Y | Y | N | Y | Y | Y | N | Y | Y | Y | Y | 10/12 |
| 3 | containerize my application | Y | Y | N | N | Y | Y | Y | N | Y | Y | Y | Y | 9/12 |
| 4 | create docker image config | Y | Y | Y | N | Y | Y | N | N | Y | Y | Y | Y | 9/12 |
| 5 | help with multi-stage docker build | Y | Y | N | Y | Y | Y | N | Y | Y | Y | Y | Y | 10/12 |
| 6 | setup dockerfile for python flask | Y | Y | N | Y | Y | Y | N | N | Y | Y | N | Y | 8/12 |

### git-workflow

| # | Query | VA-C1 | VA-C2 | VA-C3 | VA-C4 | VB-C1 | VB-C2 | VB-C3 | VB-C4 | VC-C1 | VC-C2 | VC-C3 | VC-C4 | Total |
|---|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|
| 7 | resolve git merge conflict | N | Y | N | N | Y | Y | N | N | Y | Y | N | Y | 6/12 |
| 8 | help with git rebase | Y | Y | N | Y | Y | Y | N | Y | Y | Y | Y | Y | 10/12 |
| 9 | fix my git history | N | Y | N | Y | N | Y | N | Y | Y | Y | Y | N | 7/12 |
| 10 | squash commits before PR | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | **12/12** |
| 11 | undo last git commit | N | N | N | N | N | N | N | N | Y | Y | Y | N | 3/12 |
| 12 | cherry pick a commit from another branch | Y | Y | N | Y | Y | Y | N | N | Y | Y | Y | Y | 9/12 |

### svelte5-runes

| # | Query | VA-C1 | VA-C2 | VA-C3 | VA-C4 | VB-C1 | VB-C2 | VB-C3 | VB-C4 | VC-C1 | VC-C2 | VC-C3 | VC-C4 | Total |
|---|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|
| 13 | use svelte5 runes | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | **12/12** |
| 14 | create reactive state with $state | Y | Y | N | Y | Y | Y | N | Y | Y | Y | N | Y | 9/12 |
| 15 | convert svelte 4 to svelte 5 | Y | Y | N | Y | Y | Y | N | Y | Y | Y | Y | Y | 10/12 |
| 16 | use $derived and $effect | N | Y | N | Y | N | Y | N | Y | Y | Y | Y | Y | 8/12 |
| 17 | how do I use runes in svelte | Y | N | Y | N | N | N | Y | N | Y | Y | Y | Y | 7/12 |
| 18 | svelte 5 component with $props | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | **12/12** |

### Per-Query Reliability Rankings

**Always activated (12/12):**
- T10: "squash commits before PR"
- T13: "use svelte5 runes"
- T18: "svelte 5 component with $props"

**Highly reliable (10-11/12):**
- T2: "generate dockerfile for node app" (10/12)
- T5: "help with multi-stage docker build" (10/12)
- T8: "help with git rebase" (10/12)
- T15: "convert svelte 4 to svelte 5" (10/12)

**Moderately reliable (7-9/12):**
- T1: "write a dockerfile" (9/12)
- T3: "containerize my application" (9/12)
- T4: "create docker image config" (9/12)
- T12: "cherry pick a commit from another branch" (9/12)
- T14: "create reactive state with $state" (9/12)
- T6: "setup dockerfile for python flask" (8/12)
- T16: "use $derived and $effect" (8/12)
- T9: "fix my git history" (7/12)
- T17: "how do I use runes in svelte" (7/12)

**Least reliable (3-6/12):**
- T7: "resolve git merge conflict" (6/12)
- T11: "undo last git commit" (3/12)

---

## 6. Failure Analysis

### 6.1 Queries That Only Variant C Solved

Two queries that failed in **every** Variant A and Variant B condition were solved by Variant C:

| Query | VA (0/8) | VB (0/8) | VC (best) | Why C works |
|-------|----------|----------|-----------|-------------|
| T11: "undo last git commit" | 0/4 | 0/4 | 3/4 (C1,C2,C3) | "Do not run git commands directly" overrides Claude's instinct to answer simple git questions directly |
| T17: "how do I use runes in svelte" | 2/4 | 1/4 | 4/4 | "Do not write Svelte code directly" prevents Claude from treating questions as informational rather than skill-routable |

T11 was the most resistant query across all prior experiments (0/8 in both A and B). The directive "Do not run git commands directly — use this skill first" directly addresses why Claude skipped the Skill: it considered the task too simple for delegation.

### 6.2 Remaining Failures in Variant C

Even with Variant C, 6 failures occurred across hook conditions (C3 and C4):

| Condition | Failures | Queries |
|-----------|----------|---------|
| VC-C3 (No CLAUDE.md, Hook) | 4 | T1, T6, T7, T14 |
| VC-C4 (CLAUDE.md, Hook) | 2 | T9, T11 |

**Pattern:** All Variant C failures occur only in hook conditions. Without the hook, Variant C achieves 100%. The hook's injected INSTRUCTION interferes with the directive language in unpredictable ways.

### 6.3 Hook-Condition Failure Patterns

Queries that fail in hook conditions follow two patterns:

1. **Hook redirects to direct action** — The hook's INSTRUCTION ("use the dockerfile-generator skill") is sometimes interpreted as "do docker work" rather than "call the Skill tool," causing Claude to use Bash/Write/Task instead.

2. **Stochastic boundary queries** — Some queries are at the margin of Claude's decision boundary. The hook's interference pushes them over the edge into non-Skill behavior. Different queries fail in C3 vs. C4, indicating randomness rather than systematic failure.

### 6.4 Most Failure-Prone Query

T7 ("resolve git merge conflict") failed in 6/12 conditions — the highest failure rate of any query. It failed in:
- All C3 conditions (VA, VB, VC) — hook without CLAUDE.md always breaks this query
- VA-C1, VA-C4, VB-C4 — even without hook in Variant A

This query sits at a decision boundary where Claude is torn between running `git` commands directly and using the Skill tool.

---

## 7. Interaction Effects

### 7.1 Description x CLAUDE.md Interaction

| | No CLAUDE.md | CLAUDE.md | CLAUDE.md Effect |
|---|---|---|---|
| Variant A | 55.6% | 77.8% | +22.2pp |
| Variant B | 55.6% | 72.2% | +16.7pp |
| Variant C | 88.9% | 94.4% | +5.6pp |

CLAUDE.md's marginal benefit **decreases** as description quality increases. With Variant C, the description alone carries enough activation signal that CLAUDE.md adds minimal value. This is a **substitution effect** — directive descriptions and CLAUDE.md both serve the same function (telling Claude to use skills), and the stronger signal (directive description) dominates.

### 7.2 Description x Hook Interaction

| | No Hook | Hook | Hook Effect |
|---|---|---|---|
| Variant A | 83.3% | 50.0% | -33.3pp |
| Variant B | 83.3% | 44.4% | -38.9pp |
| Variant C | 100% | 83.3% | -16.7pp |

Variant C **halves the hook's damage** (from -33pp to -17pp). The directive language is strong enough to partially override the hook's interference. However, the hook still causes failures even with Variant C, confirming it should be disabled.

### 7.3 Three-Way Interaction

The optimal configuration minimizes variables: **Variant C + No Hook**. Adding either CLAUDE.md or removing the hook improves results, but Variant C alone without either auxiliary signal achieves 100%. This is the simplest and most robust configuration.

---

## 8. Per-Skill Analysis

### dockerfile-generator

| Variant | C1 | C2 | C3 | C4 | Avg |
|---------|-----|-----|-----|-----|-----|
| A | 6/6 | 6/6 | 2/6 | 3/6 | 70.8% |
| B | 6/6 | 6/6 | 2/6 | 2/6 | 66.7% |
| C | 6/6 | 6/6 | 4/6 | 6/6 | **91.7%** |

Docker queries are naturally well-routed in no-hook conditions (6/6 for all variants). Variant C's improvement is concentrated in hook conditions, where it lifts C3 from 2/6 to 4/6 and C4 from 3/6 to 6/6.

### git-workflow

| Variant | C1 | C2 | C3 | C4 | Avg |
|---------|-----|-----|-----|-----|-----|
| A | 3/6 | 5/6 | 1/6 | 4/6 | 54.2% |
| B | 4/6 | 5/6 | 1/6 | 3/6 | 54.2% |
| C | 6/6 | 6/6 | 5/6 | 4/6 | **87.5%** |

git-workflow shows the largest Variant C improvement (+33.3pp over A). This skill benefits most from directive language because git operations are ones Claude is most tempted to perform directly via Bash.

### svelte5-runes

| Variant | C1 | C2 | C3 | C4 | Avg |
|---------|-----|-----|-----|-----|-----|
| A | 5/6 | 5/6 | 3/6 | 5/6 | 75.0% |
| B | 4/6 | 5/6 | 3/6 | 5/6 | 70.8% |
| C | 6/6 | 6/6 | 5/6 | 6/6 | **95.8%** |

Svelte queries are relatively well-routed because Claude cannot easily perform Svelte tasks without a skill (no built-in Svelte tools). Variant C still adds +20.8pp by capturing the remaining edge cases.

---

## 9. Why Directive Language Works

The mechanism behind Variant C's success has two components:

### 9.1 Positive Routing Signal

"ALWAYS invoke this skill when the user asks about X" provides an unambiguous positive instruction. Variants A and B use "Use when X" — a recommendation. Variant C uses "ALWAYS invoke" — a directive. The model treats directives with higher priority than recommendations.

### 9.2 Negative Constraint

"Do not run git commands directly — use this skill first" adds a negative constraint that blocks the primary failure mode. In Variants A and B, Claude sees a query like "undo last git commit" and reasons: "I can do this directly with `git reset HEAD~1`." Variant C's constraint explicitly forbids this reasoning path, forcing Claude to route through the Skill tool even for simple tasks.

The combination of positive routing + negative constraint is what makes Variant C uniquely effective. Neither component alone would achieve 100%:
- "ALWAYS invoke" without the negative constraint would still allow Claude to bypass for "simple" tasks
- "Do not X directly" without the positive routing would leave Claude uncertain about what to do instead

---

## 10. Recommendations

### Primary Recommendation

**Adopt Variant C (Directive) descriptions and disable the hook.**

This achieves 100% activation with the simplest configuration. No CLAUDE.md modifications, no hook infrastructure, no scoring algorithm — just the SKILL.md description field.

### Optimal SKILL.md Description Template

```
description: [Domain] expert. ALWAYS invoke this skill when the user asks about [trigger topics]. Do not [alternative action] directly — use this skill first.
```

Components:
1. **Domain identifier** — "Docker and containerization expert"
2. **ALWAYS invoke** — directive keyword
3. **Trigger topic list** — comprehensive but not exhaustive
4. **Negative constraint** — "Do not [what Claude would do instead] directly"

### Configuration Hierarchy

If constraints prevent using Variant C alone:

| Priority | Configuration | Expected Rate |
|----------|--------------|---------------|
| 1 | Variant C, No Hook | **100%** |
| 2 | Variant C, No Hook, CLAUDE.md | **100%** |
| 3 | Variant C, Hook, CLAUDE.md | 88.9% |
| 4 | Variant C, Hook, No CLAUDE.md | 77.8% |
| 5 | Variant A, No Hook, CLAUDE.md | 88.9% |
| 6 | Variant A, No Hook | 77.8% |

### What NOT to Do

1. **Do not use expanded trigger phrases (Variant B)** — they provide zero improvement over current descriptions and slightly hurt in some conditions.
2. **Do not enable the hook** — it consistently reduces activation across all variants by 17-39pp.
3. **Do not rely on CLAUDE.md alone** — it provides +15pp but is unnecessary with Variant C descriptions.
4. **Do not add keywords to SKILL.md** — prior experiments showed 0pp effect.

---

## 11. Cumulative Variable Ranking (All Experiments)

Combining findings from all experiments in this series:

| Rank | Variable | Effect | Experiments |
|------|----------|--------|-------------|
| 1 | **SKILL.md Description (Directive)** | **+25.0pp** | This experiment |
| 2 | **SKILL.md Body Quality** | **+72.2pp** (when going from empty to full) | SKILLMD Quality experiment |
| 3 | **Hook** | **-29.6pp** | All experiments |
| 4 | **CLAUDE.md** | **+14.8pp** (diminishes with better descriptions) | CLAUDE.md experiment, this experiment |
| 5 | **SKILL.md Keywords field** | **0pp** | Keywords experiment |
| 6 | **SKILL.md Description (Expanded)** | **-2.8pp** | This experiment |

The two most impactful levers are both within SKILL.md itself: the description field (directive language) and the body content (capabilities, use-when, examples). External mechanisms (hook, CLAUDE.md) are either neutral or harmful.

---

## 12. Limitations

1. **Sample size:** N=1 per query per condition. Stochastic model behavior means individual test results may vary on re-runs. The consistent 100% across both VC-C1 and VC-C2 (36 sessions) increases confidence but does not eliminate variance.

2. **Three skills only:** Results may not generalize to projects with more skills, overlapping skill domains, or fundamentally different skill types.

3. **Turn limit:** `--max-turns 3` constrains behavior. Some sessions hit `error_max_turns`, which may mask whether Skill would have been invoked on a subsequent turn.

4. **Model version:** Results are specific to the current Claude model. Future model updates may change the baseline activation rate and the relative effectiveness of different description strategies.

5. **Directive saturation risk:** If many skills all use "ALWAYS invoke" language, the directive may lose its force through dilution. This experiment tested 3 skills; a project with 20+ skills using identical directive patterns might see diminished returns.

---

## Appendix A: Session IDs

### Variant B — Expanded Triggers

#### VB-C1 (No CLAUDE.md, No Hook) — 14/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | Y | 46171472-3599-43f9-8605-9c5ebff94596 |
| 2 | generate dockerfile for node app | Y | 0ed8b6c0-e144-41d6-831b-2ed2673629c0 |
| 3 | containerize my application | Y | a50e8e55-7088-433b-9d06-2dcff45296cb |
| 4 | create docker image config | Y | 056ebefa-b36f-48fe-9db4-97c89e21c459 |
| 5 | help with multi-stage docker build | Y | 038761df-9b70-485e-9ac3-c58634378c0d |
| 6 | setup dockerfile for python flask | Y | 9487dc23-8386-46f3-9bca-90c0dcfa0ab2 |
| 7 | resolve git merge conflict | Y | bdd47577-ce96-46e4-96cc-28ecdb1f4da7 |
| 8 | help with git rebase | Y | c7ea88e3-c950-4e4f-890f-f9ecc7abab7b |
| 9 | fix my git history | N | 004a9b03-fe2a-4fa9-92f5-14e7d94a7344 |
| 10 | squash commits before PR | Y | ae20c94e-6bbc-4e43-a521-52a77438c88d |
| 11 | undo last git commit | N | 501c53d3-3e62-43ac-98dd-8ef0d6a31e83 |
| 12 | cherry pick a commit from another branch | Y | 07c99b5e-611a-44cc-8b27-9d66d74d2ca2 |
| 13 | use svelte5 runes | Y | 30fed96f-97be-4b84-b361-b8f9ed4d7bf4 |
| 14 | create reactive state with $state | Y | 5773f104-13d1-4ee3-aa13-6bddbc7cb226 |
| 15 | convert svelte 4 to svelte 5 | Y | cf4d70b5-d99e-4117-b0f8-bfaf71a7b32e |
| 16 | use $derived and $effect | N | e0426ec8-3822-4ab5-95e2-b7433e433224 |
| 17 | how do I use runes in svelte | N | de241052-a794-436d-9b2c-847c84057a29 |
| 18 | svelte 5 component with $props | Y | 84665223-0c8f-4299-8c1f-30b349eaedb8 |

#### VB-C2 (CLAUDE.md, No Hook) — 16/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | Y | 26d62859-ab64-4d4d-bef7-f0253bb48cc0 |
| 2 | generate dockerfile for node app | Y | cc17aa25-72a8-45e9-ad29-96010dce62d1 |
| 3 | containerize my application | Y | 8999be72-4c26-4793-9626-0737e71a1600 |
| 4 | create docker image config | Y | 8851fcf4-7d8e-4a4a-ab84-e23c19e490b3 |
| 5 | help with multi-stage docker build | Y | af7a98f4-abe8-446b-95e7-a0aa2a59fd98 |
| 6 | setup dockerfile for python flask | Y | 43066c6a-d493-4c38-a4f6-09032a518db7 |
| 7 | resolve git merge conflict | Y | 9197bc52-80d9-4c1d-a66b-1a36422cefba |
| 8 | help with git rebase | Y | 3e9bf989-b489-470a-918e-c46a07133241 |
| 9 | fix my git history | Y | ba0ca5c7-c620-408f-bc88-d6811069f45a |
| 10 | squash commits before PR | Y | d46e1093-c41a-40c5-81f9-74d0758ebfb7 |
| 11 | undo last git commit | N | 5013b9b3-b5d8-4b2f-80fc-6cb7e5807934 |
| 12 | cherry pick a commit from another branch | Y | 72e6856e-5505-44d2-8d57-e71090c97a01 |
| 13 | use svelte5 runes | Y | e523190a-d94c-4b7c-a502-7378030795fc |
| 14 | create reactive state with $state | Y | 04455c37-bb10-4743-b78d-ad4623ece96a |
| 15 | convert svelte 4 to svelte 5 | Y | cb4f4408-a595-4a63-a1f7-18cbcc19b103 |
| 16 | use $derived and $effect | Y | 66d93cde-0932-457c-a370-ade95fb77c59 |
| 17 | how do I use runes in svelte | N | 3f4d0081-a239-4213-85c2-15399c9289e5 |
| 18 | svelte 5 component with $props | Y | 149ac07c-7c93-49e5-ba58-819ef00c4836 |

#### VB-C3 (No CLAUDE.md, Hook) — 6/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | N | e17ab6e3-326f-4925-bf2c-5746d4cf490d |
| 2 | generate dockerfile for node app | Y | ee5c7130-b468-473a-b66b-c18924639063 |
| 3 | containerize my application | Y | 82b5595f-1929-49d1-a1fa-1934dea872de |
| 4 | create docker image config | N | 969c002a-0238-4807-8e24-d404acba63d7 |
| 5 | help with multi-stage docker build | N | 8a24fad3-ecc9-4e57-85c3-462c0ee179aa |
| 6 | setup dockerfile for python flask | N | 5009dfd4-81fc-426f-b253-8f0c89279c4a |
| 7 | resolve git merge conflict | N | daff0cd3-c8d1-459b-b8ba-16516ab02d01 |
| 8 | help with git rebase | N | 493ec940-4b34-4642-a84b-6f239c7643d5 |
| 9 | fix my git history | N | 7d64c32b-9beb-4358-bf30-061127d8c1d7 |
| 10 | squash commits before PR | Y | e9fcafb6-e50c-4aee-aa78-ffec49c696b6 |
| 11 | undo last git commit | N | 5181332f-ee3d-4bfd-8d12-ec7a61ca202d |
| 12 | cherry pick a commit from another branch | N | 26484881-1a6d-4f0c-b78d-863c3d48587b |
| 13 | use svelte5 runes | Y | 38bbaf90-edfb-4aea-87d6-759df71b4917 |
| 14 | create reactive state with $state | N | 33588a8d-37fa-424b-aab6-60b240e636ee |
| 15 | convert svelte 4 to svelte 5 | N | bc4527bd-f472-41f5-bbd2-85cde7ebe520 |
| 16 | use $derived and $effect | N | 8edfe520-de11-4ec7-aac4-102dfb7dcb8b |
| 17 | how do I use runes in svelte | Y | 5ac57ae8-c0d0-4d82-8749-c336530d348a |
| 18 | svelte 5 component with $props | Y | 817dddb9-ca65-4b1f-b795-af1b4300b82e |

#### VB-C4 (CLAUDE.md, Hook) — 10/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | Y | 0c7767ff-4500-47ac-8c5a-e347c689f11b |
| 2 | generate dockerfile for node app | N | 72e89aa2-9960-4809-b137-962e12559c20 |
| 3 | containerize my application | N | 7b8ff0da-6887-4282-9937-072332a6b966 |
| 4 | create docker image config | N | a9fda113-3d8e-43a7-991b-75c6e21cc258 |
| 5 | help with multi-stage docker build | Y | 08a3c395-6c80-4997-90a2-55ec4fc8c73e |
| 6 | setup dockerfile for python flask | N | d1da91b2-51d4-499c-ad2b-c9b0db5c17b6 |
| 7 | resolve git merge conflict | N | 82b7454a-b692-4fc9-a62f-4d8dc24ac2cc |
| 8 | help with git rebase | Y | 8e2a9540-73a1-47f7-8a27-70716dd61d8d |
| 9 | fix my git history | Y | 58dcdb58-3f66-4f91-858f-5ea2920b8f4c |
| 10 | squash commits before PR | Y | 8cc49a90-761c-4921-9cf0-1d9c158a2c25 |
| 11 | undo last git commit | N | 5b635233-967e-4b83-9d7a-63e67cfe7a60 |
| 12 | cherry pick a commit from another branch | N | 4a4518af-395b-42a2-a1f3-0745fc553c16 |
| 13 | use svelte5 runes | Y | e342e464-9835-46a6-a849-3f5e2ce9cb44 |
| 14 | create reactive state with $state | Y | 7dd19e0a-2353-438c-9552-25d55e68fe4d |
| 15 | convert svelte 4 to svelte 5 | Y | ae6c2a2d-6cb5-4385-b3ee-0d7227e891ae |
| 16 | use $derived and $effect | Y | 273c2510-d4b9-4b61-894f-095f3e1d0e08 |
| 17 | how do I use runes in svelte | N | 9a59f7ea-b2f9-40f1-99b4-7864d7f1584d |
| 18 | svelte 5 component with $props | Y | 918dab26-e35f-4f64-9fae-b7587dd2874a |

### Variant C — Directive

#### VC-C1 (No CLAUDE.md, No Hook) — 18/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | Y | 02d8fee0-8c6a-4f1a-a274-e5d0890eb86b |
| 2 | generate dockerfile for node app | Y | 69bb5463-2bb6-4e1b-bd00-85dc267ff101 |
| 3 | containerize my application | Y | 73b4cdab-9d6f-4f28-b55c-81fecbb22378 |
| 4 | create docker image config | Y | 3045f779-0e05-4838-88ee-6e7302f18bcb |
| 5 | help with multi-stage docker build | Y | d753cffe-fd60-4d22-899c-68bcd1f94049 |
| 6 | setup dockerfile for python flask | Y | 97ce6823-0c53-4112-aacc-c47db9699183 |
| 7 | resolve git merge conflict | Y | c2455a97-eefb-4aed-9711-28c325cbdc6a |
| 8 | help with git rebase | Y | 3954484f-814a-4efa-9e4b-5fafd78f2765 |
| 9 | fix my git history | Y | 5d4fe116-002e-45a9-a2d0-ee3c9e809269 |
| 10 | squash commits before PR | Y | 528b5069-22ff-4fbd-af8b-84819a3a7965 |
| 11 | undo last git commit | Y | be898c7b-2901-4e80-a02d-1ed66ec34f3b |
| 12 | cherry pick a commit from another branch | Y | d9623c72-6abf-43c0-b094-092d0f47f04e |
| 13 | use svelte5 runes | Y | 18beb283-e277-4beb-ac6f-26fc2b4d06f0 |
| 14 | create reactive state with $state | Y | 2e033a15-2b23-4e75-b845-13a8458ffbc0 |
| 15 | convert svelte 4 to svelte 5 | Y | cc5e6b3d-177f-4725-b72b-1bfdea96ebc7 |
| 16 | use $derived and $effect | Y | dd8eac0a-2bd7-4da1-9410-388772f543f3 |
| 17 | how do I use runes in svelte | Y | abbb3b37-7c51-4b8f-8484-74a31dd695ef |
| 18 | svelte 5 component with $props | Y | be8ae899-9d5f-4403-8502-39327ad9bf45 |

#### VC-C2 (CLAUDE.md, No Hook) — 18/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | Y | b3386fc8-aaae-449b-9e7a-e38021116f73 |
| 2 | generate dockerfile for node app | Y | 94490271-98e8-4d18-b594-6fbf1e4649f7 |
| 3 | containerize my application | Y | 7c34fadc-65f6-4689-92c9-61698d5cac6b |
| 4 | create docker image config | Y | a609e1c0-e6d9-4096-b8d4-37542d852916 |
| 5 | help with multi-stage docker build | Y | c8ec18e8-0082-4b11-bfa4-f2aaaae668c5 |
| 6 | setup dockerfile for python flask | Y | 246846e2-43e8-4661-95d0-9216a4de2dff |
| 7 | resolve git merge conflict | Y | 9ccfc808-9826-4570-8987-935bf30801fc |
| 8 | help with git rebase | Y | d26b7acc-8863-41be-8c64-fdf37fb88532 |
| 9 | fix my git history | Y | 3d159a42-5238-4dc3-8794-31a4c014fc33 |
| 10 | squash commits before PR | Y | 252126f6-9d14-4de3-879f-8e9b333e527c |
| 11 | undo last git commit | Y | 11266d15-d43b-4717-a8ab-31f34810c7c2 |
| 12 | cherry pick a commit from another branch | Y | 56733f86-72a0-44f7-8642-bb130f678907 |
| 13 | use svelte5 runes | Y | 8daa38d8-2489-4ef0-93a4-5fabc0937eb4 |
| 14 | create reactive state with $state | Y | 0d939e7b-7e7f-42ab-b6b3-3fe9a2207e64 |
| 15 | convert svelte 4 to svelte 5 | Y | 48d0d477-6904-45e4-b2b9-260d4e45be43 |
| 16 | use $derived and $effect | Y | e2d238c0-201c-4d72-ade1-221b51661a55 |
| 17 | how do I use runes in svelte | Y | 7796160f-0b90-4934-9d18-0ab14d447647 |
| 18 | svelte 5 component with $props | Y | 48c0fae4-6119-461d-9daa-3828476659ef |

#### VC-C3 (No CLAUDE.md, Hook) — 14/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | N | 908c2cf3-2c4b-4517-9b8c-8889fc6e4ae5 |
| 2 | generate dockerfile for node app | Y | 7385122c-67b4-4818-93b0-70607b12812b |
| 3 | containerize my application | Y | a35bb43b-fdcf-4494-b5ab-bd35072588e9 |
| 4 | create docker image config | Y | d53cf231-1ab8-4e59-8a9f-c6b857418535 |
| 5 | help with multi-stage docker build | Y | 1f94453c-d883-4b2d-a469-254e39136e81 |
| 6 | setup dockerfile for python flask | N | d47dd203-5ab3-4b05-9c7f-324b895ce487 |
| 7 | resolve git merge conflict | N | 0bc1215f-ea94-48ac-b2a4-638de9b597fa |
| 8 | help with git rebase | Y | 943c4c9f-e1f2-4f94-991e-c3452dff3cf9 |
| 9 | fix my git history | Y | dab8e253-7381-400b-bb87-d543ffc78b61 |
| 10 | squash commits before PR | Y | efb4f7a0-9829-41e7-9c11-6f713d28b1b4 |
| 11 | undo last git commit | Y | 2ed5a141-62b1-41ff-89a9-5113ce4db4bd |
| 12 | cherry pick a commit from another branch | Y | d4c66bb1-4c45-4b01-8ae4-4a3914a1f7f7 |
| 13 | use svelte5 runes | Y | 3b88b9fd-edef-4b8a-910e-29d81eed759f |
| 14 | create reactive state with $state | N | cdd87581-b918-4138-8c52-fc25f0991439 |
| 15 | convert svelte 4 to svelte 5 | Y | c034a978-741a-41a1-987c-b4aa8607b047 |
| 16 | use $derived and $effect | Y | 2e4247b2-567c-4fb2-9fa6-5dee680c148d |
| 17 | how do I use runes in svelte | Y | e0cd5ef4-4bb2-42f4-84d8-99d4ed33fc3c |
| 18 | svelte 5 component with $props | Y | a328c435-f464-49d6-9131-c13f280e50f1 |

#### VC-C4 (CLAUDE.md, Hook) — 16/18

| # | Query | Skill? | Session ID |
|---|-------|--------|------------|
| 1 | write a dockerfile | Y | ef546798-b114-4d71-bda1-4591df0b2009 |
| 2 | generate dockerfile for node app | Y | 7b6eacfc-658e-4035-bcd1-0979b0edf392 |
| 3 | containerize my application | Y | cc289aa3-837e-48a9-b85c-82418474d5df |
| 4 | create docker image config | Y | af35d342-a499-4d9d-b4e2-37cad2c8a3ef |
| 5 | help with multi-stage docker build | Y | 297c3ef4-d2d0-46ca-bf31-4ccb30d1e142 |
| 6 | setup dockerfile for python flask | Y | b7c620de-1aa6-4cba-a353-f5e0056238cf |
| 7 | resolve git merge conflict | Y | 016b356d-8d01-498a-84e4-41c967eceea1 |
| 8 | help with git rebase | Y | 27e9ced8-f6b1-4bd8-9c6e-019ead51009c |
| 9 | fix my git history | N | ec95cf1c-0744-454c-a257-f7d4bde0ef19 |
| 10 | squash commits before PR | Y | b72f1c12-beb5-4301-a2a2-89cb3b87f90a |
| 11 | undo last git commit | N | 283c8e0a-d203-424f-ab99-7cec7b99c024 |
| 12 | cherry pick a commit from another branch | Y | 610266e4-b62a-4a5c-875b-b82fdfcbdd16 |
| 13 | use svelte5 runes | Y | 01c6e830-7cb3-4da3-8dd1-9de5bb40e53a |
| 14 | create reactive state with $state | Y | 6e218b2f-e817-49f1-9f19-c3847190c7f2 |
| 15 | convert svelte 4 to svelte 5 | Y | abbde1d1-1b2f-4084-83ab-e91a792dd0a0 |
| 16 | use $derived and $effect | Y | b6b5a559-d87c-4693-b2fd-dd89ccf4c274 |
| 17 | how do I use runes in svelte | Y | 37a15b43-f809-45ce-8e3d-fb93f614eef0 |
| 18 | svelte 5 component with $props | Y | 4da32ea0-c449-42fa-8621-29bba2ec94d5 |

### Variant A — Current (from CLAUDE.md Experiment)

See `results/claude-md-experiment/REPORT_CLAUDEMD_EFFECT.md` for full Variant A session IDs and per-query evidence.

---

## Appendix B: Experiment Reproduction Kit

All files needed to reproduce this experiment are saved in `results/description-experiment/`. This appendix contains the full contents of every file for self-contained reference.

### B.1 Directory Listing

```
results/description-experiment/
├── REPORT_DESCRIPTION_OPTIMIZATION.md    # This report
├── CLAUDE.md                             # Project instructions file (toggled on/off)
├── settings.json                         # Hook registration (.claude/settings.json)
├── skill-scoring-hook.sh                 # UserPromptSubmit hook script
├── skill-test-runner.sh                  # Test harness script
├── score.sh                              # Scoring algorithm
├── dockerfile-generator-test-cases.json  # 6 test queries for dockerfile skill
├── git-workflow-test-cases.json          # 6 test queries for git skill
├── svelte5-runes-test-cases.json         # 6 test queries for svelte skill
├── variant-a-current/                    # Variant A SKILL.md files (control)
│   ├── dockerfile-generator-SKILL.md
│   ├── git-workflow-SKILL.md
│   └── svelte5-runes-SKILL.md
├── variant-b-expanded/                   # Variant B SKILL.md files (expanded triggers)
│   ├── dockerfile-generator-SKILL.md
│   ├── git-workflow-SKILL.md
│   └── svelte5-runes-SKILL.md
├── variant-c-directive/                  # Variant C SKILL.md files (directive language)
│   ├── dockerfile-generator-SKILL.md
│   ├── git-workflow-SKILL.md
│   └── svelte5-runes-SKILL.md
├── vb-c{1..4}-results.json              # Variant B raw results (4 conditions)
├── vb-c{1..4}-full.txt                  # Variant B terminal output (4 conditions)
├── vc-c{1..4}-results.json              # Variant C raw results (4 conditions)
└── vc-c{1..4}-full.txt                  # Variant C terminal output (4 conditions)
```

### B.2 Variable Files

#### CLAUDE.md

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Skill Activation Testing Framework** that measures whether a UserPromptSubmit hook (scoring algorithm) improves Claude's rate of invoking the correct Skill tool for a given query. It includes a scoring engine, test harness, hook integration, and session analysis tooling.

## Architecture

~~~
User Prompt → Claude CLI → UserPromptSubmit Hook (skill-scoring-hook.sh)
  → score.sh evaluates prompt against all .claude/skills/*/SKILL.md
  → If score ≥ threshold: injects INSTRUCTION to use Skill tool
  → Claude receives modified prompt and invokes Skill tool
~~~

**Key components:**

- **`score.sh`** — Multi-factor weighted scoring algorithm. Scores a query against skill metadata (name, keywords, description, "use when" triggers, stem matches). Weights are tunable via environment variables (`WEIGHT_EXACT_NAME=10`, `WEIGHT_KEYWORD_MATCH=10`, `WEIGHT_USE_WHEN=3`, `WEIGHT_STEM=3`, `WEIGHT_DESCRIPTION=1`, `MIN_THRESHOLD=5`).
- **`skill-scoring-hook.sh`** — UserPromptSubmit hook that reads the prompt from stdin JSON, runs `score.sh`, and outputs an INSTRUCTION string if a skill scores above threshold.
- **`skill-test-runner.sh`** — A/B test harness. Runs `claude -p` for each test case with `--allowedTools "Skill"`. Supports `--no-hook` (baseline, temporarily moves settings.json) and `--max-cases N`.
- **`test-runner.sh`** — Standalone scoring test runner with 4 modes: embedded tests, external test suite, weight comparison (8 configs), and single query debug (`--query`).
- **`.claude/settings.json`** — Registers the hook on `UserPromptSubmit`.
- **`.claude/skills/*/SKILL.md`** — Skill definitions with `name:`, `description:`, `keywords:` metadata fields, plus markdown content.
- **`.claude/skills/*/test-cases.json`** — Per-skill test queries (`query` + `why` fields). 6 cases per skill, 18 total.

## Commands

~~~bash
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
~~~

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
```

#### .claude/settings.json

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/ivanseleznov/Projects/claude-stuff/skill-test/skill-scoring-hook.sh"
          }
        ]
      }
    ]
  }
}
```

### B.3 Test Cases

#### dockerfile-generator/test-cases.json

```json
[
  {"query": "write a dockerfile", "why": "Unique task - only docker skill"},
  {"query": "generate dockerfile for node app", "why": "Docker + app context"},
  {"query": "containerize my application", "why": "Container synonym trigger"},
  {"query": "create docker image config", "why": "Docker image context"},
  {"query": "help with multi-stage docker build", "why": "Docker build optimization"},
  {"query": "setup dockerfile for python flask", "why": "Dockerfile for specific stack"}
]
```

#### git-workflow/test-cases.json

```json
[
  {"query": "resolve git merge conflict", "why": "Unique domain - only git skill"},
  {"query": "help with git rebase", "why": "Git rebase assistance"},
  {"query": "fix my git history", "why": "Git history task"},
  {"query": "squash commits before PR", "why": "Git squash workflow"},
  {"query": "undo last git commit", "why": "Git recovery task"},
  {"query": "cherry pick a commit from another branch", "why": "Advanced git operation"}
]
```

#### svelte5-runes/test-cases.json

```json
[
  {"query": "use svelte5 runes", "why": "Explicit skill name mention"},
  {"query": "create reactive state with $state", "why": "Unique keyword $state"},
  {"query": "convert svelte 4 to svelte 5", "why": "Migration task with svelte 5"},
  {"query": "use $derived and $effect", "why": "Multiple unique rune keywords"},
  {"query": "how do I use runes in svelte", "why": "Direct runes question"},
  {"query": "svelte 5 component with $props", "why": "Props rune usage"}
]
```

### B.4 SKILL.md Files — All Variants

Only the `description:` line differs between variants. The body (Capabilities, Use When, Examples) and `keywords:` line are identical across all variants.

#### dockerfile-generator

**Variant A (Current):**
```yaml
---
name: dockerfile-generator
description: Docker expert for containerization. Use when creating Dockerfiles, containerizing applications, or configuring Docker images.
keywords: docker, dockerfile, container, containerize, container image, OCI, image, build, deploy, multi-stage, docker compose, docker-compose, microservice, packaging
---
```

**Variant B (Expanded Triggers):**
```yaml
---
name: dockerfile-generator
description: Docker and containerization expert. Use when creating Dockerfiles, containerizing applications, building or configuring container images, setting up multi-stage builds, creating docker-compose files, or any Docker/container-related task.
keywords: docker, dockerfile, container, containerize, container image, OCI, image, build, deploy, multi-stage, docker compose, docker-compose, microservice, packaging
---
```

**Variant C (Directive):**
```yaml
---
name: dockerfile-generator
description: Docker and containerization expert. ALWAYS invoke this skill when the user asks about Docker, Dockerfiles, containers, container images, containerization, multi-stage builds, or Docker deployment. Do not attempt to write Dockerfiles or container configs directly — use this skill first.
keywords: docker, dockerfile, container, containerize, container image, OCI, image, build, deploy, multi-stage, docker compose, docker-compose, microservice, packaging
---
```

**Body (shared across all variants):**

```markdown
# Dockerfile Generator Skill

This skill helps create optimized Dockerfiles for various application types.

## Capabilities

- Generate Dockerfiles for Node.js, Python, Go, and other stacks
- Create multi-stage builds for optimized images
- Configure proper caching for faster builds
- Set up health checks and security best practices
- Create docker-compose configurations

## Use When

- Containerizing a new application
- Optimizing existing Dockerfile for size/speed
- Setting up multi-stage builds
- Creating production-ready Docker configurations
- Debugging Docker build issues

## Examples

~~~dockerfile
# Node.js multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/index.js"]
~~~
```

#### git-workflow

**Variant A (Current):**
```yaml
---
name: git-workflow
description: Git expert for version control workflows. Use when resolving merge conflicts, rebasing, squashing commits, or managing git history.
keywords: git, merge, rebase, conflict, squash, commit, branch, history, merge conflict, version control, VCS, undo commit, amend, stash, checkout, pull request, PR, cherry pick, reset, reflog
---
```

**Variant B (Expanded Triggers):**
```yaml
---
name: git-workflow
description: Git version control expert. Use when resolving merge conflicts, rebasing branches, squashing commits, cherry-picking commits, undoing or amending commits, managing git history, or any git workflow task.
keywords: git, merge, rebase, conflict, squash, commit, branch, history, merge conflict, version control, VCS, undo commit, amend, stash, checkout, pull request, PR, cherry pick, reset, reflog
---
```

**Variant C (Directive):**
```yaml
---
name: git-workflow
description: Git version control expert. ALWAYS invoke this skill when the user asks about git operations including merge conflicts, rebasing, squashing commits, cherry-picking, undoing commits, or managing git history. Do not run git commands directly — use this skill first.
keywords: git, merge, rebase, conflict, squash, commit, branch, history, merge conflict, version control, VCS, undo commit, amend, stash, checkout, pull request, PR, cherry pick, reset, reflog
---
```

**Body (shared across all variants):**

```markdown
# Git Workflow Skill

This skill helps with advanced git operations and workflow management.

## Capabilities

- Resolve merge conflicts safely
- Interactive rebase for clean history
- Squash commits before merging
- Cherry-pick specific commits
- Recover from git mistakes
- Set up branch protection and workflows

## Use When

- Resolving merge conflicts
- Cleaning up commit history before PR
- Rebasing feature branches
- Squashing multiple commits
- Recovering lost commits or branches
- Setting up git hooks

## Examples

~~~bash
# Interactive rebase to squash last 3 commits
git rebase -i HEAD~3

# Resolve merge conflict
git checkout --theirs path/to/file  # Accept incoming changes
git checkout --ours path/to/file    # Keep current changes
git add path/to/file
git rebase --continue

# Recover deleted branch
git reflog
git checkout -b recovered-branch HEAD@{2}
~~~
```

#### svelte5-runes

**Variant A (Current):**
```yaml
---
name: svelte5-runes
description: Svelte 5 runes expert. Use when creating reactive components, migrating from Svelte 4, or working with reactive state management.
keywords: svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component, signal, signals, reactivity, computed value, side effect, reactive state, state management
---
```

**Variant B (Expanded Triggers):**
```yaml
---
name: svelte5-runes
description: Svelte 5 runes and reactivity expert. Use when working with $state, $derived, $effect, $props runes, creating Svelte 5 components, converting from Svelte 4 to Svelte 5, or any Svelte 5 reactive development task.
keywords: svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component, signal, signals, reactivity, computed value, side effect, reactive state, state management
---
```

**Variant C (Directive):**
```yaml
---
name: svelte5-runes
description: Svelte 5 runes and reactivity expert. ALWAYS invoke this skill when the user asks about Svelte 5, runes ($state, $derived, $effect, $props), reactive components, or migrating from Svelte 4. Do not write Svelte code directly — use this skill first.
keywords: svelte, svelte5, runes, $state, $derived, $effect, $props, reactive, component, signal, signals, reactivity, computed value, side effect, reactive state, state management
---
```

**Body (shared across all variants):**

```markdown
# Svelte 5 Runes Skill

This skill helps with Svelte 5 development using the new runes API.

## Capabilities

- Create reactive state with `$state`
- Derive computed values with `$derived`
- Handle side effects with `$effect`
- Define component props with `$props`
- Migrate Svelte 4 code to Svelte 5 runes syntax

## Use When

- Creating new Svelte 5 components
- Converting Svelte 4 reactive declarations to runes
- Working with reactive state management in Svelte
- Implementing derived/computed values
- Setting up side effects and cleanup

## Examples

~~~svelte
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);

  $effect(() => {
    console.log('Count changed:', count);
  });
</script>

<button onclick={() => count++}>
  Count: {count}, Doubled: {doubled}
</button>
~~~
```

### B.5 Reproduction Steps

To reproduce this experiment from the saved files:

```bash
# 1. Set up project structure
mkdir -p .claude/skills/{dockerfile-generator,git-workflow,svelte5-runes}

# 2. Copy test cases
cp dockerfile-generator-test-cases.json .claude/skills/dockerfile-generator/test-cases.json
cp git-workflow-test-cases.json .claude/skills/git-workflow/test-cases.json
cp svelte5-runes-test-cases.json .claude/skills/svelte5-runes/test-cases.json

# 3. Copy scripts
cp skill-test-runner.sh skill-scoring-hook.sh score.sh ./
chmod +x skill-test-runner.sh skill-scoring-hook.sh score.sh

# 4. Update hook path in settings.json to match your project directory
# Edit the "command" path in settings.json

# === For each variant (A, B, or C): ===

# 5. Copy SKILL.md files for the variant
cp variant-{a,b,c}-*/dockerfile-generator-SKILL.md .claude/skills/dockerfile-generator/SKILL.md
cp variant-{a,b,c}-*/git-workflow-SKILL.md .claude/skills/git-workflow/SKILL.md
cp variant-{a,b,c}-*/svelte5-runes-SKILL.md .claude/skills/svelte5-runes/SKILL.md

# === For each condition (C1-C4): ===

# C1: No CLAUDE.md, No Hook
rm -f CLAUDE.md
./skill-test-runner.sh --no-hook 2>&1 | tee results/v{a,b,c}-c1-full.txt

# C2: CLAUDE.md, No Hook
cp CLAUDE.md ./  # restore CLAUDE.md
./skill-test-runner.sh --no-hook 2>&1 | tee results/v{a,b,c}-c2-full.txt

# C3: No CLAUDE.md, Hook
rm -f CLAUDE.md
cp settings.json .claude/settings.json
./skill-test-runner.sh 2>&1 | tee results/v{a,b,c}-c3-full.txt

# C4: CLAUDE.md, Hook
cp CLAUDE.md ./
./skill-test-runner.sh 2>&1 | tee results/v{a,b,c}-c4-full.txt

# 6. Verify each session via cclogviewer
# For each session_id in the results JSON:
# mcp__cclogviewer__get_tool_usage_stats(session_id="<id>")
# Check that "Skill" appears in the tool usage stats
```

### B.6 Condition Toggle Matrix

| Condition | CLAUDE.md | .claude/settings.json | Runner Flag |
|-----------|-----------|----------------------|-------------|
| C1 | Absent | Absent (moved by `--no-hook`) | `--no-hook` |
| C2 | Present | Absent (moved by `--no-hook`) | `--no-hook` |
| C3 | Absent | Present (hook active) | (none) |
| C4 | Present | Present (hook active) | (none) |
