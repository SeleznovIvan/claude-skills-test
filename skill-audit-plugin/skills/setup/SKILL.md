---
name: skill-audit:setup
description: Set up the skill-audit plugin environment. ALWAYS invoke this skill when the user says "skill-audit setup", "setup skill audit", or "initialize skill audit". Do not attempt to configure the audit environment directly — use this skill first.
keywords: setup, initialize, install, configure, skill-audit, cclogviewer
---

# /skill-audit:setup — Initialize Skill Audit Environment

Run this once per project to prepare the skill-audit plugin.

## Steps

### 1. Check cclogviewer MCP availability

Use ToolSearch to find cclogviewer MCP tools. Verify that at least `mcp__cclogviewer__list_sessions` is available.

If not available, tell the user:

```
cclogviewer MCP server is required but not found.

Install it:
  go install github.com/anthropics/cclogviewer@latest

Then add to your project .mcp.json:
  {
    "mcpServers": {
      "cclogviewer": {
        "command": "cclogviewer",
        "args": ["mcp"]
      }
    }
  }
```

### 2. Auto-discover project

- Read the current working directory
- Use `mcp__cclogviewer__list_projects` to find matching project entries
- Identify the project name that matches the current directory

### 3. Scan skills

- Use Glob to find `.claude/skills/*/SKILL.md` files
- Count how many skills exist
- Report findings to the user

### 4. Write setup config

Write a setup config to `.claude/skill-audit-setup.json`:

```json
{
  "project_name": "<detected project name>",
  "project_path": "<current working directory>",
  "skills_found": <count>,
  "skill_names": ["<name1>", "<name2>", ...],
  "cclogviewer_available": true,
  "setup_at": "<ISO timestamp>"
}
```

### 5. Report

Print a summary:

```
skill-audit setup complete.

Project: <name>
Skills found: <count>
  - <skill1>
  - <skill2>
  ...

cclogviewer: OK

Run /skill-audit:audit to start the activation experiment.
```
