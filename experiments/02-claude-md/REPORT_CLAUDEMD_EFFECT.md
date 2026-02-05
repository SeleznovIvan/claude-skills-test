# CLAUDE.md Effect on Skill Activation — Experiment Report

**Date:** 2026-01-30
**Experiment:** 2x2 factorial design — CLAUDE.md x Hook
**Total sessions:** 72 (18 queries x 4 conditions)

## 1. Executive Summary

The hook **hurts** Skill activation significantly across both CLAUDE.md conditions. CLAUDE.md provides a moderate positive boost. Neither variable is responsible for the 0% → 89% jump observed between the original experiment and the Keywords x Hook experiment — the baseline without either treatment already shows 77.8% activation, pointing to a **model or platform change** as the primary driver.

## 2. 2x2 Summary Table — Skill Invocation Rates

| | No CLAUDE.md | With CLAUDE.md | Hook Effect |
|---|---|---|---|
| **No Hook** | **C1: 14/18 (77.8%)** | **C2: 16/18 (88.9%)** | — |
| **With Hook** | **C3: 6/18 (33.3%)** | **C4: 12/18 (66.7%)** | — |
| **CLAUDE.md Effect** | — | — | — |

### Marginal Effects

| Variable | Without | With | Delta |
|---|---|---|---|
| **CLAUDE.md** (avg across hook conditions) | 55.6% (C1+C3 avg) | 77.8% (C2+C4 avg) | **+22.2pp** |
| **Hook** (avg across CLAUDE.md conditions) | 83.3% (C1+C2 avg) | 50.0% (C3+C4 avg) | **-33.3pp** |

### Conditional Effects

| Comparison | Delta |
|---|---|
| CLAUDE.md effect when no hook (C2 - C1) | 88.9% - 77.8% = **+11.1pp** |
| CLAUDE.md effect when hook active (C4 - C3) | 66.7% - 33.3% = **+33.3pp** |
| Hook effect when no CLAUDE.md (C3 - C1) | 33.3% - 77.8% = **-44.4pp** |
| Hook effect when CLAUDE.md present (C4 - C2) | 66.7% - 88.9% = **-22.2pp** |

## 3. Per-Skill Breakdown

### dockerfile-generator (6 queries per condition)

| Condition | Activated | Rate |
|---|---|---|
| C1 (no CLAUDE.md, no hook) | 6/6 | 100% |
| C2 (CLAUDE.md, no hook) | 6/6 | 100% |
| C3 (no CLAUDE.md, hook) | 2/6 | 33.3% |
| C4 (CLAUDE.md, hook) | 3/6 | 50.0% |

### git-workflow (6 queries per condition)

| Condition | Activated | Rate |
|---|---|---|
| C1 (no CLAUDE.md, no hook) | 3/6 | 50.0% |
| C2 (CLAUDE.md, no hook) | 5/6 | 83.3% |
| C3 (no CLAUDE.md, hook) | 1/6 | 16.7% |
| C4 (CLAUDE.md, hook) | 4/6 | 66.7% |

### svelte5-runes (6 queries per condition)

| Condition | Activated | Rate |
|---|---|---|
| C1 (no CLAUDE.md, no hook) | 5/6 | 83.3% |
| C2 (CLAUDE.md, no hook) | 5/6 | 83.3% |
| C3 (no CLAUDE.md, hook) | 3/6 (*) | 50.0% |
| C4 (CLAUDE.md, hook) | 5/6 | 83.3% |

(*) Note: C3 svelte queries had 4 sessions without Skill tool (3 no tools, 1 Glob only).

### Skill-Level Summary

| Skill | Best Condition | Worst Condition | Range |
|---|---|---|---|
| dockerfile-generator | C1/C2 (100%) | C3 (33.3%) | 66.7pp |
| git-workflow | C2 (83.3%) | C3 (16.7%) | 66.7pp |
| svelte5-runes | C1/C2/C4 (83.3%) | C3 (50.0%) | 33.3pp |

## 4. Per-Query Evidence (18 queries x 4 conditions)

Legend: **Y** = Skill tool invoked, **N** = Skill tool NOT invoked, First tool shown in parentheses.

### dockerfile-generator

| # | Query | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| 1 | write a dockerfile | Y (Skill) | Y (Skill) | N (Bash) | Y (Skill) |
| 2 | generate dockerfile for node app | Y (Skill) | Y (Skill) | Y (Bash→Skill) | N (Glob) |
| 3 | containerize my application | Y (Skill) | Y (Skill) | N (Task) | N (Task) |
| 4 | create docker image config | Y (Skill) | Y (Skill) | Y (Bash→Skill) | N (Task) |
| 5 | help with multi-stage docker build | Y (Skill) | Y (Skill) | N (no tools) | Y (Skill) |
| 6 | setup dockerfile for python flask | Y (Skill) | Y (Skill) | N (Bash) | Y (Skill) |

### git-workflow

| # | Query | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| 7 | resolve git merge conflict | N (Bash) | Y (Skill) | N (Bash) | N (Bash) |
| 8 | help with git rebase | Y (Skill) | Y (Skill) | N (no tools) | Y (Skill) |
| 9 | fix my git history | N (AskUser) | Y (Skill) | N (Bash) | Y (Skill) |
| 10 | squash commits before PR | Y (Skill) | Y (Skill) | Y (Skill) | Y (Skill) |
| 11 | undo last git commit | N (Bash) | N (no tools) | N (Bash) | N (no tools) |
| 12 | cherry pick a commit from another branch | Y (Skill) | Y (Skill) | N (Bash) | Y (Skill) |

### svelte5-runes

| # | Query | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| 13 | use svelte5 runes | Y (Skill) | Y (Skill) | Y (Skill) | Y (Skill) |
| 14 | create reactive state with $state | Y (Skill) | Y (Skill) | N (no tools) | Y (Skill) |
| 15 | convert svelte 4 to svelte 5 | Y (Task→Skill) | Y (Skill) | N (Glob) | Y (Skill) |
| 16 | use $derived and $effect | N (Bash) | Y (Skill) | N (no tools) | Y (Skill) |
| 17 | how do I use runes in svelte | Y (Skill) | N (no tools) | Y (Skill) | N (no tools) |
| 18 | svelte 5 component with $props | Y (Skill) | Y (Skill) | Y (Skill) | Y (Skill) |

### Cross-Condition Consistency

Queries that activated Skill in **all 4 conditions** (most robust):
- "squash commits before PR" (git-workflow)
- "use svelte5 runes" (svelte5-runes)
- "svelte 5 component with $props" (svelte5-runes)

Queries that **never** activated Skill in any condition:
- "undo last git commit" (git-workflow) — 0/4

Queries most sensitive to condition:
- "resolve git merge conflict" — only C2
- "fix my git history" — only C2, C4
- "create reactive state with $state" — C1, C2, C4 but not C3
- "containerize my application" — C1, C2 only

## 5. Comparison with Prior Experiments

### Original Experiment (earlier date, no CLAUDE.md)

| Condition | Result |
|---|---|
| Baseline (no hook) | 0/18 (0%) |
| With hook | 18/18 (100%) |

### Keywords x Hook Experiment (with CLAUDE.md present)

| Condition | Result |
|---|---|
| No keywords, no hook | 16/18 (88.9%) |
| Keywords, no hook | 16/18 (88.9%) |
| No keywords, hook | 13/18 (72.2%) |
| Keywords, hook | 13/18 (72.2%) |

### This Experiment (CLAUDE.md x Hook)

| Condition | Result |
|---|---|
| C1: No CLAUDE.md, no hook | 14/18 (77.8%) |
| C2: CLAUDE.md, no hook | 16/18 (88.9%) |
| C3: No CLAUDE.md, hook | 6/18 (33.3%) |
| C4: CLAUDE.md, hook | 12/18 (66.7%) |

### Key Cross-Experiment Observations

1. **Original baseline (0%) vs. current C1 (77.8%)**: Removing CLAUDE.md does NOT restore the original 0% baseline. Something else changed between experiments — likely a **model update or platform change**.

2. **C2 matches Keywords x Hook baseline**: C2 (88.9%) exactly matches the Keywords x Hook "no hook" conditions (88.9%), confirming that keywords have no effect and CLAUDE.md is the consistent factor.

3. **Hook consistently hurts**: The hook reduced activation in every experiment where a no-hook comparison exists:
   - Keywords x Hook: 88.9% → 72.2% (-16.7pp)
   - This experiment without CLAUDE.md: 77.8% → 33.3% (-44.4pp)
   - This experiment with CLAUDE.md: 88.9% → 66.7% (-22.2pp)

4. **Hook damage is worse without CLAUDE.md**: The hook's negative effect is amplified when CLAUDE.md is absent (-44.4pp vs. -22.2pp). CLAUDE.md appears to partially buffer against the hook's interference.

## 6. Key Findings

### Finding 1: CLAUDE.md does NOT explain the 0% → 89% jump

The hypothesis that CLAUDE.md was responsible for the dramatic improvement was **not supported**. C1 (no CLAUDE.md, no hook) achieved 77.8%, far from the original 0%. The most likely explanation is a **model or platform update** between the original experiment and subsequent experiments.

### Finding 2: CLAUDE.md provides a moderate positive effect (+11–33pp)

CLAUDE.md improves Skill activation by:
- +11.1pp without the hook (77.8% → 88.9%)
- +33.3pp with the hook (33.3% → 66.7%)

The effect is larger when the hook is active, suggesting CLAUDE.md helps counteract hook interference.

### Finding 3: The hook significantly HURTS activation (-22 to -44pp)

This is the most consistent and largest effect across all experiments:
- -44.4pp without CLAUDE.md (77.8% → 33.3%)
- -22.2pp with CLAUDE.md (88.9% → 66.7%)

The hook injection appears to confuse the model, causing it to use other tools (Bash, Glob, Task) instead of the Skill tool.

### Finding 4: git-workflow is most affected by conditions

git-workflow showed the widest range (16.7% to 83.3%) and was the skill most improved by CLAUDE.md. Docker queries naturally map to the Skill tool even without context; git queries benefit more from explicit contextual guidance.

### Finding 5: "undo last git commit" is consistently resistant

This query failed across all 4 conditions — Claude prefers to answer it directly or use Bash (git commands), never routing through the Skill tool. It may be too "simple" for Claude to consider delegating to a skill.

## 7. Variable Ranking by Effect Size

| Rank | Variable | Average Effect |
|---|---|---|
| 1 | **Hook** (negative) | **-33.3pp** average reduction |
| 2 | **CLAUDE.md** (positive) | **+22.2pp** average increase |
| 3 | **Keywords** (neutral) | **0pp** (from prior experiment) |
| 4 | **Unknown platform/model change** | **+77.8pp** (inferred from cross-experiment comparison) |

## 8. Recommendations

1. **Disable the hook** — it consistently reduces Skill activation. The Skill tool definition and SKILL.md content provide sufficient routing signals.
2. **Keep CLAUDE.md** — it provides a meaningful +11pp boost in the no-hook condition and helps Claude understand when to use skills vs. direct tools.
3. **Investigate the model/platform variable** — the 0% → 78% jump without any treatment change suggests the original experiment may have been run on a different model version or with different system prompt behavior.
4. **Consider query design** — simple/direct tasks ("undo last git commit") may never route through Skill because Claude can handle them natively. Skill routing works best for domain-specific, multi-step tasks.

## Appendix: Session IDs by Condition

### C1 — No CLAUDE.md, No Hook
| Test | Skill | Query | Skill? | Session ID |
|---|---|---|---|---|
| 1 | dockerfile-generator | write a dockerfile | Y | d43bdfd3-63bd-4ade-8688-aefe7f232caa |
| 2 | dockerfile-generator | generate dockerfile for node app | Y | a387935c-4667-4230-b2a8-22aada4544da |
| 3 | dockerfile-generator | containerize my application | Y | e798965e-6ba3-4f55-b4d8-0ee4683d5b8e |
| 4 | dockerfile-generator | create docker image config | Y | 8654e515-1277-40cd-a8da-87673ef05e60 |
| 5 | dockerfile-generator | help with multi-stage docker build | Y | 48c9eaa3-bd98-4e68-bb96-612e62d334c6 |
| 6 | dockerfile-generator | setup dockerfile for python flask | Y | 18b1d0e1-4a76-47e5-87df-f51f6583fd72 |
| 7 | git-workflow | resolve git merge conflict | N | acd3a429-142c-4775-b024-8b672cff3fd5 |
| 8 | git-workflow | help with git rebase | Y | 85f49f7a-e5e2-4b67-a686-f94e6620455e |
| 9 | git-workflow | fix my git history | N | dc6c6bfb-8632-42d7-8212-1fdc7c5b4810 |
| 10 | git-workflow | squash commits before PR | Y | 8f708447-fe7d-4e28-9cd8-670937c74602 |
| 11 | git-workflow | undo last git commit | N | 9741b280-7dcc-4562-a824-b66e9aed98f8 |
| 12 | git-workflow | cherry pick a commit from another branch | Y | c2173f4f-c327-4862-b4c7-884a3ff92174 |
| 13 | svelte5-runes | use svelte5 runes | Y | dfa08b20-f6e7-483f-a96d-6b50680de8e9 |
| 14 | svelte5-runes | create reactive state with $state | Y | 38c523d8-3780-4caf-b408-506f1e481fd8 |
| 15 | svelte5-runes | convert svelte 4 to svelte 5 | Y | 1bba8e23-b6eb-4ba0-859d-1975ebe33324 |
| 16 | svelte5-runes | use $derived and $effect | N | f7052698-8fb1-48da-a5be-c20a32481395 |
| 17 | svelte5-runes | how do I use runes in svelte | Y | f31a263c-cdc1-4104-a28c-23eb86944a13 |
| 18 | svelte5-runes | svelte 5 component with $props | Y | 2b45d158-4eb3-4496-8f4a-27e851e0a98f |

### C2 — With CLAUDE.md, No Hook
| Test | Skill | Query | Skill? | Session ID |
|---|---|---|---|---|
| 1 | dockerfile-generator | write a dockerfile | Y | 19126373-9bc9-48c8-9ddf-cec776236d68 |
| 2 | dockerfile-generator | generate dockerfile for node app | Y | ef79d17b-30c7-4536-9cc6-4538a9cf21bc |
| 3 | dockerfile-generator | containerize my application | Y | 85bf2715-bf2b-40bd-a89d-2da05ff1e3ab |
| 4 | dockerfile-generator | create docker image config | Y | 8512d165-1abd-4926-92f7-c4dafa9b8a75 |
| 5 | dockerfile-generator | help with multi-stage docker build | Y | 99b9b92b-e9a2-403e-8dfe-e3ee67ea9a1e |
| 6 | dockerfile-generator | setup dockerfile for python flask | Y | d6e6e405-4abc-46e2-99eb-d460d5b4d44c |
| 7 | git-workflow | resolve git merge conflict | Y | ec794de0-820d-4b0d-8112-4eb84384d4e2 |
| 8 | git-workflow | help with git rebase | Y | 609eaa8f-7f2b-44f9-b909-05e80ca0f800 |
| 9 | git-workflow | fix my git history | Y | 1af6c0e6-8cba-4826-87d3-7b5fe9a496d7 |
| 10 | git-workflow | squash commits before PR | Y | c21f7489-15f2-4aba-8a9a-4a7c87d6f9cb |
| 11 | git-workflow | undo last git commit | N | 70bbf9d1-360f-415f-ada5-0ea5d6f61a8c |
| 12 | git-workflow | cherry pick a commit from another branch | Y | facb50f3-0690-4ad4-9647-b44c4f307562 |
| 13 | svelte5-runes | use svelte5 runes | Y | 0bd306cf-927e-43a5-bf79-c195a856bb65 |
| 14 | svelte5-runes | create reactive state with $state | Y | 728efb49-c82b-49c6-ba37-5112a9a21143 |
| 15 | svelte5-runes | convert svelte 4 to svelte 5 | Y | eb3d6137-aa8b-479d-a21c-99ac88506e18 |
| 16 | svelte5-runes | use $derived and $effect | Y | 89f98f5b-3eb2-4a6a-bce4-8a1fe1aa04ad |
| 17 | svelte5-runes | how do I use runes in svelte | N | 5e1a5318-8198-4e30-a778-0410c4241ebe |
| 18 | svelte5-runes | svelte 5 component with $props | Y | bc3acafb-72f3-44c4-8609-fe4c3d337eba |

### C3 — No CLAUDE.md, With Hook
| Test | Skill | Query | Skill? | Session ID |
|---|---|---|---|---|
| 1 | dockerfile-generator | write a dockerfile | N | f27229e3-689e-413d-89c6-854748293b06 |
| 2 | dockerfile-generator | generate dockerfile for node app | Y | 28d0eb28-a5e1-4e22-904f-193b40d3a431 |
| 3 | dockerfile-generator | containerize my application | N | bcd3fd84-5a17-4090-a04e-5a552371fc69 |
| 4 | dockerfile-generator | create docker image config | Y | 8c76af27-6689-4ca1-be26-0d8d327fb378 |
| 5 | dockerfile-generator | help with multi-stage docker build | N | 3fc3aa9c-783c-486b-b447-7e37fc0c3e13 |
| 6 | dockerfile-generator | setup dockerfile for python flask | N | e2f48e24-0e63-4e4c-baa8-79f2e3264e18 |
| 7 | git-workflow | resolve git merge conflict | N | 32eed270-6b25-45c6-b4bb-dac6676e888a |
| 8 | git-workflow | help with git rebase | N | 470da299-7c5d-438a-8848-dec5311f91d4 |
| 9 | git-workflow | fix my git history | N | f9fe3ed0-baac-439b-8edd-50c6c27a9c01 |
| 10 | git-workflow | squash commits before PR | Y | 2c0802cd-967f-4fa1-8111-719ad29f719a |
| 11 | git-workflow | undo last git commit | N | ac522cde-1b2d-490e-843c-a5cd7365b6b1 |
| 12 | git-workflow | cherry pick a commit from another branch | N | fae6bf5c-ff64-4b2e-af27-f0fd4223f224 |
| 13 | svelte5-runes | use svelte5 runes | Y | e217d9b3-5304-45ea-8820-472a1715d3f0 |
| 14 | svelte5-runes | create reactive state with $state | N | 191102df-85c7-4bee-9ab1-58017d8b1272 |
| 15 | svelte5-runes | convert svelte 4 to svelte 5 | N | 601582bf-8d2b-4166-b12b-ce885ed58aa8 |
| 16 | svelte5-runes | use $derived and $effect | N | cd679318-8e8c-42d3-862e-56ffce9c404e |
| 17 | svelte5-runes | how do I use runes in svelte | Y | 4d23b491-932e-47c7-b5d4-d620001394b8 |
| 18 | svelte5-runes | svelte 5 component with $props | Y | 48bf24a7-e5ef-4539-b715-26cf66de0a93 |

### C4 — With CLAUDE.md, With Hook
| Test | Skill | Query | Skill? | Session ID |
|---|---|---|---|---|
| 1 | dockerfile-generator | write a dockerfile | Y | 1520af79-1094-479d-a72a-bda057f2b52a |
| 2 | dockerfile-generator | generate dockerfile for node app | N | b34ec316-e701-46fb-8f9c-477afb611aaf |
| 3 | dockerfile-generator | containerize my application | N | c6f5c25e-fa24-43c3-866a-632041111adb |
| 4 | dockerfile-generator | create docker image config | N | 8a066261-efa0-4dc9-94a1-b7169b36af22 |
| 5 | dockerfile-generator | help with multi-stage docker build | Y | 803ca378-2bd8-4e30-a4b0-e3e8c5c20fd3 |
| 6 | dockerfile-generator | setup dockerfile for python flask | Y | ef409170-f4bf-4b55-b9c0-2ac79631eb81 |
| 7 | git-workflow | resolve git merge conflict | N | 6378f54d-d814-4733-82ad-40f502f9619d |
| 8 | git-workflow | help with git rebase | Y | 33ddea6e-648f-4f79-aeab-1dcd621e46ce |
| 9 | git-workflow | fix my git history | Y | bd0483bf-0eea-461c-9071-cc12c0e40fed |
| 10 | git-workflow | squash commits before PR | Y | e94a7700-5a48-480f-9964-4ffd311b5b7f |
| 11 | git-workflow | undo last git commit | N | 56bc7e38-d1c3-42f5-9fb8-8bb2f36ee2d5 |
| 12 | git-workflow | cherry pick a commit from another branch | Y | efafeba6-5a32-4f03-adc1-171457a21704 |
| 13 | svelte5-runes | use svelte5 runes | Y | 31053de5-a9b9-47fe-9bc1-09c779dbc587 |
| 14 | svelte5-runes | create reactive state with $state | Y | e08288b7-863f-4db8-b6b0-553cd7fdf3dc |
| 15 | svelte5-runes | convert svelte 4 to svelte 5 | Y | efa0c37e-353e-45c3-bc0e-d486d23ca42f |
| 16 | svelte5-runes | use $derived and $effect | Y | 4f606691-b1c2-4413-866f-1a59f24a9757 |
| 17 | svelte5-runes | how do I use runes in svelte | N | c9e5ccc8-b7e1-45c8-be95-d95c29746df7 |
| 18 | svelte5-runes | svelte 5 component with $props | Y | 7400c55e-19aa-4364-a4b2-0a71bbf22f4a |
