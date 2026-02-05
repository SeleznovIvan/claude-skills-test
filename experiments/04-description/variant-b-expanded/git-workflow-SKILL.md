---
name: git-workflow
description: Git version control expert. Use when resolving merge conflicts, rebasing branches, squashing commits, cherry-picking commits, undoing or amending commits, managing git history, or any git workflow task.
keywords: git, merge, rebase, conflict, squash, commit, branch, history, merge conflict, version control, VCS, undo commit, amend, stash, checkout, pull request, PR, cherry pick, reset, reflog
---

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

```bash
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
```
