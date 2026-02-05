# 4-Condition Skill Activation Experiment Report

**Date:** 2026-01-29
**Model:** Claude (via `claude -p`, max-turns 2, allowedTools "Skill")
**Test queries:** 18 (6 per skill × 3 skills)

---

## 1. Summary Table — 2×2 Matrix

| | No Keywords | With Keywords |
|---|---|---|
| **No Hook** | **C1: 16/18 (88.9%)** | **C2: 16/18 (88.9%)** |
| **With Hook** | **C3: 15/18 (83.3%)** | **C4: 13/18 (72.2%)** |

### Key Takeaway

The **baseline condition (C1: No Hook, No Keywords)** tied with C2 for the best Skill activation rate. The hook **decreased** activation rate in both keyword conditions, and the combination of hook + keywords (C4) produced the **worst** result at 72.2%.

---

## 2. Results by Skill

### dockerfile-generator (6 queries)

| | C1 | C2 | C3 | C4 |
|---|---|---|---|---|
| Skill invoked | 6/6 | 6/6 | 5/6 | 4/6 |
| Rate | 100% | 100% | 83.3% | 66.7% |

**Failures:**
- C3 Test 4 ("create docker image config") — used Task+Write instead of Skill
- C4 Test 2 ("generate dockerfile for node app") — used Bash+Write instead of Skill
- C4 Test 6 ("setup dockerfile for python flask") — used Bash+AskUserQuestion instead of Skill

### git-workflow (6 queries)

| | C1 | C2 | C3 | C4 |
|---|---|---|---|---|
| Skill invoked | 5/6 | 5/6 | 5/6 | 4/6 |
| Rate | 83.3% | 83.3% | 83.3% | 66.7% |

**Failures:**
- ALL conditions: Test 11 ("undo last git commit") — Claude answered directly with no tools
- C4 Test 7 ("resolve git merge conflict") — used Bash only instead of Skill

### svelte5-runes (6 queries)

| | C1 | C2 | C3 | C4 |
|---|---|---|---|---|
| Skill invoked | 5/6 | 5/6 | 5/6 | 5/6 |
| Rate | 83.3% | 83.3% | 83.3% | 83.3% |

**Failures:**
- ALL conditions: Test 17 ("how do I use runes in svelte") — Claude answered directly with no tools

---

## 3. Session Evidence — All 18 Queries Across 4 Conditions

Legend: ✅ = Skill invoked | ❌ = Skill NOT invoked | First tool shown in parentheses

### dockerfile-generator

| # | Query | C1 | C2 | C3 | C4 |
|---|-------|-----|-----|-----|-----|
| 1 | write a dockerfile | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 2 | generate dockerfile for node app | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ❌ (Bash) |
| 3 | containerize my application | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 4 | create docker image config | ✅ (Skill) | ✅ (Skill) | ❌ (Task) | ✅ (Skill) |
| 5 | help with multi-stage docker build | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 6 | setup dockerfile for python flask | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ❌ (Bash) |

### git-workflow

| # | Query | C1 | C2 | C3 | C4 |
|---|-------|-----|-----|-----|-----|
| 7 | resolve git merge conflict | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ❌ (Bash) |
| 8 | help with git rebase | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 9 | fix my git history | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 10 | squash commits before PR | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 11 | undo last git commit | ❌ (none) | ❌ (none) | ❌ (none) | ❌ (none) |
| 12 | cherry pick a commit from another branch | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |

### svelte5-runes

| # | Query | C1 | C2 | C3 | C4 |
|---|-------|-----|-----|-----|-----|
| 13 | use svelte5 runes | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 14 | create reactive state with $state | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 15 | convert svelte 4 to svelte 5 | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 16 | use $derived and $effect | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |
| 17 | how do I use runes in svelte | ❌ (none) | ❌ (none) | ❌ (none) | ❌ (none) |
| 18 | svelte 5 component with $props | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) | ✅ (Skill) |

---

## 4. Tool Usage Statistics

### Aggregate tool counts per condition

| Tool | C1 | C2 | C3 | C4 |
|------|-----|-----|-----|-----|
| **Skill** | 16 | 16 | 15 | 13 |
| Bash | 3 | 4 | 5 | 6 |
| Glob | 3 | 3 | 3 | 0 |
| Task | 1 | 1 | 2 | 1 |
| Write | 0 | 0 | 1 | 1 |
| AskUserQuestion | 2 | 2 | 1 | 3 |

**Pattern:** As the hook is added (C3, C4), Bash usage increases and Skill usage decreases. The hook appears to encourage Claude to attempt the task directly rather than delegating to the Skill tool.

### First-tool analysis

| First Tool | C1 | C2 | C3 | C4 |
|-----------|-----|-----|-----|-----|
| Skill | 16 | 16 | 15 | 12 |
| Bash | 0 | 0 | 0 | 2 |
| Task | 0 | 0 | 1 | 0 |
| None (text only) | 2 | 2 | 2 | 2 |
| Other | 0 | 0 | 0 | 2 |

---

## 5. Key Findings

### Q1: Does adding `keywords:` to SKILL.md improve Skill activation rate?

**No.** Keywords had no measurable positive effect:
- Without hook: C1 (no keywords) = C2 (keywords) = 88.9%
- With hook: C3 (no keywords) = 83.3% > C4 (keywords) = 72.2%

Keywords actually **decreased** activation when combined with the hook. This may be because the scoring hook generates higher confidence scores with keywords, producing a more assertive INSTRUCTION that paradoxically causes Claude to attempt the task directly rather than invoking Skill.

### Q2: Does the scoring hook improve Skill activation rate?

**No. The hook decreased activation rate.**
- No hook: 16/18 (88.9%) across both C1 and C2
- With hook: 15/18 (83.3%) for C3, 13/18 (72.2%) for C4

The hook's injected INSTRUCTION appears to have an adversarial effect, causing Claude to bypass the Skill tool and attempt work directly using Bash, Write, or Task tools.

### Q3: Is there an interaction effect?

**Yes — a negative interaction.** The combination of hook + keywords (C4) performed significantly worse than any single variable:
- Neither (C1): 88.9%
- Keywords only (C2): 88.9%
- Hook only (C3): 83.3%
- Both (C4): 72.2%

The interaction is subadditive — each variable alone has little/no effect, but together they cause the most failures.

### Q4: Which condition achieves the highest Skill activation rate?

**C1 (No Hook, No Keywords) and C2 (No Hook, With Keywords)** — tied at 88.9% (16/18).

Claude's built-in skill routing (matching available skills from the system prompt) is already highly effective. External interventions degraded performance.

### Q5: Are there specific queries that only activate under certain conditions?

**Two queries NEVER activated Skill in any condition:**
- "undo last git commit" (Test 11) — Claude considered this simple enough to answer directly
- "how do I use runes in svelte" (Test 17) — Claude treated this as a knowledge question, not a task

**Three queries showed variable activation:**
- "create docker image config" (Test 4) — failed only in C3
- "generate dockerfile for node app" (Test 2) — failed only in C4
- "setup dockerfile for python flask" (Test 6) — failed only in C4
- "resolve git merge conflict" (Test 7) — failed only in C4

### Q6: Does the hook's adversarial effect persist when keywords are present?

**Yes, and it worsens.** The hook's adversarial effect was worse with keywords (5 failures in C4) than without (3 failures in C3). The higher-confidence scoring from keyword matches appears to produce more aggressive hook instructions that more frequently cause Claude to bypass Skill.

---

## 6. Session IDs

### C1 — No Hook, No Keywords

| # | Query | Session ID | Skill? |
|---|-------|-----------|--------|
| 1 | write a dockerfile | cad24d02-2ae4-40f7-99b8-b5f6215e4bdc | ✅ |
| 2 | generate dockerfile for node app | 404ba403-b80a-45bd-93c5-a69176506c84 | ✅ |
| 3 | containerize my application | 9ec06c3d-739e-41e8-bb37-e7c5e1261f1d | ✅ |
| 4 | create docker image config | d223a799-00bf-4218-ac65-5992516c8979 | ✅ |
| 5 | help with multi-stage docker build | f38fa674-746a-4aa7-a72e-c525be167fc9 | ✅ |
| 6 | setup dockerfile for python flask | e7d4bce6-55f2-4f45-9585-d90cd1e68d50 | ✅ |
| 7 | resolve git merge conflict | ee759996-dd0f-46f9-a14a-95075faa0592 | ✅ |
| 8 | help with git rebase | ac9a1f05-ed39-4dba-8348-356291211cb4 | ✅ |
| 9 | fix my git history | 7fe77663-1d81-45da-afc7-a429aed3526b | ✅ |
| 10 | squash commits before PR | c55d967d-cd1c-4b76-85aa-5f8107433b23 | ✅ |
| 11 | undo last git commit | f5d05aa9-4ab5-4845-87ac-852ea6a5d195 | ❌ |
| 12 | cherry pick a commit from another branch | fd5f875b-d79e-4766-9015-1e0bc2be6c80 | ✅ |
| 13 | use svelte5 runes | 95b457db-96a7-4758-a069-2cfd79fcaf4e | ✅ |
| 14 | create reactive state with $state | b2df8bf3-de60-4bbf-ba09-0d8b7b728ea6 | ✅ |
| 15 | convert svelte 4 to svelte 5 | 988aea01-9f24-4db6-93ac-9fa2babb79bc | ✅ |
| 16 | use $derived and $effect | 240e221f-1e4f-467d-83b2-238b224afd82 | ✅ |
| 17 | how do I use runes in svelte | 270e9ae4-5327-49d1-826e-34da9fc94879 | ❌ |
| 18 | svelte 5 component with $props | fe4ca155-aa89-446b-ae89-ddf2f3a7c0fa | ✅ |

### C2 — No Hook, With Keywords

| # | Query | Session ID | Skill? |
|---|-------|-----------|--------|
| 1 | write a dockerfile | f65e9a84-095f-4d31-be3f-14c66873e863 | ✅ |
| 2 | generate dockerfile for node app | c8c5c2bb-6d6f-4692-a421-08a5acf2181a | ✅ |
| 3 | containerize my application | ac796348-cd19-45b6-8f81-46183d54ba69 | ✅ |
| 4 | create docker image config | 64287e27-6801-4d44-b5b8-0fabf20487a6 | ✅ |
| 5 | help with multi-stage docker build | 2650b0d0-29f1-4b1d-9902-48779aee8eee | ✅ |
| 6 | setup dockerfile for python flask | 651c2a10-bfb0-4c1c-8e36-0823279f6a5a | ✅ |
| 7 | resolve git merge conflict | 8ebc7340-bb6d-40cf-be54-5f5de0ae7770 | ✅ |
| 8 | help with git rebase | 754ea1b2-314c-4115-8b12-5eae68e0a019 | ✅ |
| 9 | fix my git history | 261ab787-6fac-4437-a3fc-eaa8910b5b32 | ✅ |
| 10 | squash commits before PR | c1f54587-e784-49b4-8b84-a7d01b22b120 | ✅ |
| 11 | undo last git commit | 7d2d3fa8-ff0e-49a2-b59e-50053dd527ef | ❌ |
| 12 | cherry pick a commit from another branch | 2584a57f-7467-420f-a5f4-4ac2abd40c8d | ✅ |
| 13 | use svelte5 runes | b6d3e67f-7699-4a45-b14a-780d9f36876c | ✅ |
| 14 | create reactive state with $state | a66a4aa7-536f-4806-96f9-56f0c13db91f | ✅ |
| 15 | convert svelte 4 to svelte 5 | 47231eb6-3590-409a-ac04-3dbc0d7edbba | ✅ |
| 16 | use $derived and $effect | 46a80f01-c8cb-40c6-bf5b-4b01096efe74 | ✅ |
| 17 | how do I use runes in svelte | 11f58086-2972-4160-9300-3ed417cf0512 | ❌ |
| 18 | svelte 5 component with $props | ef999e56-a634-4bbd-914f-902377286e0d | ✅ |

### C3 — Hook, No Keywords

| # | Query | Session ID | Skill? |
|---|-------|-----------|--------|
| 1 | write a dockerfile | eeefeb9c-e45b-43f5-8fa5-014b747f2f3b | ✅ |
| 2 | generate dockerfile for node app | bb1d0eff-387f-45e4-88b2-d19f6a648996 | ✅ |
| 3 | containerize my application | 9014d641-9dcb-4096-a557-d448400e1a38 | ✅ |
| 4 | create docker image config | 1ca09d19-ea5d-4983-8f0c-7f4dd54ae6b7 | ❌ |
| 5 | help with multi-stage docker build | 329ce686-f846-4e27-a46f-e035db363b29 | ✅ |
| 6 | setup dockerfile for python flask | a8e54e6a-6f5d-46e0-bac8-5459e8090dc3 | ✅ |
| 7 | resolve git merge conflict | e4ef0c76-c33b-47f3-9cd6-29072dcbc82d | ✅ |
| 8 | help with git rebase | 5f8ef187-c180-454a-b21a-58a643a1e07d | ✅ |
| 9 | fix my git history | 7e3afba7-438f-4a72-96de-e7220e90776c | ✅ |
| 10 | squash commits before PR | 86659dbb-4ab8-438f-b7f5-7821319ae25d | ✅ |
| 11 | undo last git commit | c97d147b-445b-4d92-bb46-d9f1a01b1f43 | ❌ |
| 12 | cherry pick a commit from another branch | 98a05896-a731-45cd-bab4-94f62c8215b0 | ✅ |
| 13 | use svelte5 runes | d87305b0-e5d3-4c32-ad05-18d3dbfc7e45 | ✅ |
| 14 | create reactive state with $state | 898ee755-b06d-437d-9a33-02ca819e9bd6 | ✅ |
| 15 | convert svelte 4 to svelte 5 | ed49d75b-7a37-4ead-8017-6dc99a1f9d08 | ✅ |
| 16 | use $derived and $effect | fb378e5f-96b9-4aae-8fb2-e6cb078a39f2 | ✅ |
| 17 | how do I use runes in svelte | f7a2e398-8d76-41b2-b3a3-c4aa24e944c1 | ❌ |
| 18 | svelte 5 component with $props | f8933547-c121-4e11-96e0-83ebac40f308 | ✅ |

### C4 — Hook, With Keywords

| # | Query | Session ID | Skill? |
|---|-------|-----------|--------|
| 1 | write a dockerfile | 1427d07d-d107-48f0-ac57-2ec8841ee3e8 | ✅ |
| 2 | generate dockerfile for node app | 28bffdeb-7cec-46bc-ba35-8f2302d5c307 | ❌ |
| 3 | containerize my application | ede94314-3b75-4e0e-98cb-740237992bd4 | ✅ |
| 4 | create docker image config | 36e45f6b-fd71-4a08-8d57-d592ff77ba2f | ✅ |
| 5 | help with multi-stage docker build | 5efa4aef-cf19-4cee-bc9f-f9366cff5db5 | ✅ |
| 6 | setup dockerfile for python flask | 9eb6070d-b59e-4c7e-8021-5595bccbe839 | ❌ |
| 7 | resolve git merge conflict | 93e323d2-f7f1-46a4-824c-12cec30e6cf2 | ❌ |
| 8 | help with git rebase | 1dd38163-c3ab-4d18-a8fc-d9f88b3052d5 | ✅ |
| 9 | fix my git history | 17e09d82-46a9-421a-9804-a3e9cf12a287 | ✅ |
| 10 | squash commits before PR | 94dc6340-f452-42bc-8900-794e1539d1e0 | ✅ |
| 11 | undo last git commit | 93260d62-c7e5-4f56-b2d3-ca5dfe41f2dc | ❌ |
| 12 | cherry pick a commit from another branch | 9aecabaa-7a2b-4eec-bfdb-9dcada7ba002 | ✅ |
| 13 | use svelte5 runes | 83b6b8b2-e12f-4b5a-abf9-b4d926c3ebe7 | ✅ |
| 14 | create reactive state with $state | 395709c7-d1f8-4bbd-99e5-1f2d8f32ba52 | ✅ |
| 15 | convert svelte 4 to svelte 5 | 99188b52-0f1f-4489-b3c4-1c9fb084c27f | ✅ |
| 16 | use $derived and $effect | 85bbe72c-8ed0-4f2c-87f9-a8d2101fc586 | ✅ |
| 17 | how do I use runes in svelte | f86b679f-e263-4594-b6cd-7a21b1098256 | ❌ |
| 18 | svelte 5 component with $props | 9bdfdcf4-345c-4583-80ba-f6695ba76f19 | ✅ |

---

## 7. Reproduction Commands

```bash
# Condition 1: No Hook, No Keywords
# (Remove keywords: lines from all SKILL.md files first)
./skill-test-runner.sh --no-hook 2>&1 | tee results/c1-no_hook-no_keywords-full.txt

# Condition 2: No Hook, With Keywords
# (Restore keywords: lines to all SKILL.md files)
./skill-test-runner.sh --no-hook 2>&1 | tee results/c2-no_hook-keywords-full.txt

# Condition 3: Hook, No Keywords
# (Remove keywords: lines from all SKILL.md files)
./skill-test-runner.sh 2>&1 | tee results/c3-hook-no_keywords-full.txt

# Condition 4: Hook, With Keywords
# (Restore keywords: lines to all SKILL.md files)
./skill-test-runner.sh 2>&1 | tee results/c4-hook-keywords-full.txt

# Analyze any session
# mcp__cclogviewer__get_tool_usage_stats(session_id="<id>")
# mcp__cclogviewer__get_session_timeline(session_id="<id>")
```

---

## 8. Limitations

1. **Sample size:** N=1 per query per condition (18 tests × 4 conditions = 72 total sessions). Stochastic model behavior means individual results may vary on re-runs.
2. **Turn limit:** `--max-turns 2` constrains behavior — some sessions hit `error_max_turns`, which may mask whether Skill would have been invoked on a subsequent turn.
3. **Allowed tools:** `--allowedTools "Skill"` restricts the tool palette, but Claude still attempts other tools (Bash, Write, etc.) which then fail — this is a known CLI behavior where the allowlist is not strictly enforced for all tool types.
4. **Non-deterministic:** LLM outputs are inherently stochastic. The variable failures in C3/C4 (different queries failing each run) suggest some results are at the margin of Claude's decision boundary.
5. **Hook instruction content:** The specific wording of the hook's INSTRUCTION may be suboptimal. A differently worded instruction might produce different results.

---

## 9. Conclusions

1. **Claude's built-in skill routing is already strong.** Without any external intervention (C1/C2), Claude invokes the correct Skill 88.9% of the time based solely on the skill descriptions in the system prompt.

2. **The scoring hook is counterproductive.** Rather than improving Skill activation, the hook's injected INSTRUCTION appears to cause Claude to attempt tasks directly (using Bash, Write, Task) instead of delegating to the Skill tool. This may be because the INSTRUCTION is interpreted as a directive to "do the work" rather than "use this specific tool."

3. **Keywords have no positive effect.** The `keywords:` field in SKILL.md neither helped nor hurt when used alone (C1 = C2). When combined with the hook, keywords amplified the hook's negative effect (C4 < C3).

4. **Two queries are fundamentally resistant to Skill activation:**
   - "undo last git commit" — too simple; Claude answers from knowledge
   - "how do I use runes in svelte" — phrased as a question, not a task

5. **Recommendation:** Remove the scoring hook. The baseline skill routing built into Claude Code is sufficient for these test cases. If further improvement is needed, focus on improving skill descriptions and "Use When" sections rather than external scoring mechanisms.
