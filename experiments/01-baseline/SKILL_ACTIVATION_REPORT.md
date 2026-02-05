# Skill Activation Test Report

## Executive Summary

| Metric | Baseline (No Hook) | With Hook | Improvement |
|--------|-------------------|-----------|-------------|
| **Skill Tool Invocations** | 0/6 (0%) | 6/6 (100%) | **+100%** |
| **First Tool = Skill** | 0/6 | 6/6 | **+100%** |

**Conclusion:** The scoring hook improved skill activation from **0% to 100%**. Without the hook, Claude never invoked the Skill tool. With the hook's instruction injection, Claude invoked the correct skill as its **first action** in every test case.

---

## Test Configuration

- **Test Date:** 2026-01-29
- **Skills Tested:** 3 (dockerfile-generator, git-workflow, svelte5-runes)
- **Test Cases per Skill:** 2
- **Total Tests:** 6 per condition (12 total)
- **Claude Command:** `claude -p "<query>" --max-turns 3 --allowedTools "Skill"`

### Hook Configuration
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "/path/to/skill-scoring-hook.sh"
      }]
    }]
  }
}
```

The hook uses a scoring algorithm (`score.sh`) to match user queries against skill metadata and injects an instruction like:
> "INSTRUCTION: The skill 'dockerfile-generator' matches this request (score: 24). Use the Skill tool to invoke /dockerfile-generator before proceeding."

---

## Detailed Results

### Baseline Test (No Hook)

| # | Query | Expected Skill | Skill Invoked? | Tools Used |
|---|-------|----------------|----------------|------------|
| 1 | write a dockerfile | dockerfile-generator | ❌ NO | AskUserQuestion, Glob, Read |
| 2 | generate dockerfile for node app | dockerfile-generator | ❌ NO | Write |
| 3 | resolve git merge conflict | git-workflow | ❌ NO | Bash |
| 4 | help with git rebase | git-workflow | ❌ NO | None |
| 5 | use svelte5 runes | svelte5-runes | ❌ NO | AskUserQuestion |
| 6 | create reactive state with $state | svelte5-runes | ❌ NO | None |

**Result: 0/6 Skill invocations**

### Hook Test (With Scoring Hook)

| # | Query | Expected Skill | Skill Invoked? | Tools Used |
|---|-------|----------------|----------------|------------|
| 1 | write a dockerfile | dockerfile-generator | ✅ YES | **Skill**, AskUserQuestion |
| 2 | generate dockerfile for node app | dockerfile-generator | ✅ YES | **Skill**, Glob, Write |
| 3 | resolve git merge conflict | git-workflow | ✅ YES | **Skill**, Bash |
| 4 | help with git rebase | git-workflow | ✅ YES | **Skill** |
| 5 | use svelte5 runes | svelte5-runes | ✅ YES | **Skill** |
| 6 | create reactive state with $state | svelte5-runes | ✅ YES | **Skill** |

**Result: 6/6 Skill invocations (100%)**

---

## Session Evidence

### Example: "write a dockerfile"

#### Baseline Session (2adf4897-bdc9-4a2d-afdd-9a198ad9ad59)

```
Timeline:
Step 2 [16:20:40] user: "write a dockerfile"
Step 3 [16:20:43] assistant: "I'd be happy to help you write a Dockerfile..."
Step 4 [16:20:46] tool_call: AskUserQuestion (failed)
Step 6 [16:20:48] tool_call: Glob (success)
Step 9 [16:20:53] tool_call: Read - reads SKILL.md manually
```

**Observation:** Claude did NOT invoke the Skill tool. It tried AskUserQuestion first, then explored the filesystem and manually read the skill file.

#### Hook Session (82c26d5f-6bea-45af-aaf5-ef3f70057128)

```
Timeline:
Step 2 [16:22:09] user: "write a dockerfile"
Step 3 [16:22:13] tool_call: Skill (SUCCESS) ← FIRST ACTION
Step 5 [16:22:13] user: [Skill content injected]
Step 6 [16:22:16] assistant: "I can help you create a Dockerfile..."
```

**Observation:** Claude invoked the Skill tool as its **FIRST action** before any other response.

---

## Tool Usage Statistics

### Baseline Sessions

| Session ID | Skill Calls | Other Tools |
|------------|-------------|-------------|
| 2adf4897-bdc9-4a2d-afdd-9a198ad9ad59 | 0 | AskUserQuestion(1), Glob(1), Read(1) |
| 3dda37e1-40e3-4b6c-b7a6-943fe6e67276 | 0 | Write(1) |
| 96349014-b829-4091-9ee8-5ff41c2be869 | 0 | Bash(1) |
| efd64ed2-4db6-4b9c-b400-5e5705dbc5b2 | 0 | None |
| 3413c046-3275-48f6-bc4e-0cd0d843d3f0 | 0 | AskUserQuestion(1) |
| a4e417e7-4b70-42b0-83f0-b5c80b56af5a | 0 | None |

### Hook Sessions

| Session ID | Skill Calls | Skill Status | Other Tools |
|------------|-------------|--------------|-------------|
| 82c26d5f-6bea-45af-aaf5-ef3f70057128 | 1 | ✅ success | AskUserQuestion(1) |
| b19bc9e5-deb7-4557-8239-ca3cca3c0462 | 1 | ✅ success | Glob(1), Write(1) |
| b4647fb4-89b0-49e0-80da-033de3604690 | 1 | ✅ success | Bash(1) |
| 359940a6-33ed-4c2a-8ca3-8a7489797279 | 1 | ✅ success | None |
| 17ee7998-e5e0-43f4-bad7-7b32667aad5d | 1 | ✅ success | None |
| a105681a-e176-4bad-b705-d2175c4a0eb1 | 1 | ✅ success | None |

---

## Key Findings

1. **Without the hook, Claude NEVER invokes the Skill tool** - Even when skills are available in `.claude/skills/`, Claude does not automatically use the Skill tool to load them.

2. **The hook reliably triggers Skill invocation** - In 100% of test cases, the hook's instruction caused Claude to invoke the Skill tool as its first action.

3. **Skill is invoked FIRST with the hook** - The `first_tool` pattern in all hook sessions is "Skill", meaning Claude prioritizes the skill before other actions.

4. **Skills provide context for better responses** - When skills are loaded, Claude has access to specialized instructions (e.g., best practices for Dockerfiles, git workflows, Svelte 5 runes syntax).

---

## Reproduction Commands

### Run Baseline Test (No Hook)
```bash
cd /Users/ivanseleznov/Projects/claude-stuff/skill-test
./skill-test-runner.sh --no-hook --max-cases 2
```

### Run Hook Test
```bash
cd /Users/ivanseleznov/Projects/claude-stuff/skill-test
./skill-test-runner.sh --max-cases 2
```

### Analyze a Session
```bash
# Using cclogviewer MCP (from Claude Code)
mcp__cclogviewer__get_tool_usage_stats session_id="<session-id>"
mcp__cclogviewer__get_session_timeline session_id="<session-id>"
```

---

## Files

| File | Purpose |
|------|---------|
| `skill-test-runner.sh` | Main test runner script |
| `skill-scoring-hook.sh` | UserPromptSubmit hook using score.sh |
| `score.sh` | Skill scoring algorithm |
| `.claude/settings.json` | Hook configuration |
| `.claude/skills/*/test-cases.json` | Test cases for each skill |
| `results/baseline-results.json` | Baseline test results |
| `results/hook-results.json` | Hook test results |

---

*Report generated: 2026-01-29*
