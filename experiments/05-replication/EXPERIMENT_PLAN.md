# Skill Activation Experiment v2: Statistically Rigorous Replication

## Experiment Directory

All v2 experiment files live in a dedicated folder:

```
results/replication-experiment/
```

This is separate from prior experiments (`results/description-experiment/`, `results/claude-md-experiment/`, etc.). All scripts, data, analysis, and the final report are self-contained in this directory.

**Python:** `/usr/local/bin/python3.11` (3.11.8) — used for venv and all Python scripts.

---

## Implementation Checklist

Use this checklist to track progress and resume after context loss. Each item is a discrete, independently verifiable step. **All steps are executed by Claude Code — no manual user intervention.**

### Phase 1: Script Creation
- [ ] **1.1** Create `results/replication-experiment/` directory structure (including `data/`, `analysis/`)
- [ ] **1.2** Save this plan to `results/replication-experiment/EXPERIMENT_PLAN.md` for reference
- [ ] **1.3** Write `results/replication-experiment/skill-test-runner-v2.sh` (single-condition runner)
- [ ] **1.4** Write `results/replication-experiment/run-experiment-v2.sh` (orchestrator)
- [ ] **1.5** Write `results/replication-experiment/requirements-v2.txt` (Python deps)
- [ ] **1.6** Write `results/replication-experiment/analyze-v2.py` (analysis + visualization)
- [ ] **1.7** Write `results/replication-experiment/verify-sessions.py` (standalone verifier)
- [ ] **1.8** Write `.claude/commands/verify-experiment.md` (Claude Code slash command)
- [ ] **1.9** Make shell scripts executable (`chmod +x`)

### Phase 2: Environment Setup
- [ ] **2.1** Create venv: `/usr/local/bin/python3.11 -m venv results/replication-experiment/.venv`
- [ ] **2.2** Install deps: `results/replication-experiment/.venv/bin/pip install -r results/replication-experiment/requirements-v2.txt`

### Phase 3: Validation
- [ ] **3.1** Run `run-experiment-v2.sh --dry-run` — confirm file swap logic is correct
- [ ] **3.2** Run pilot: `run-experiment-v2.sh --reps 1 --conditions "c-c1" --seed 99` (18 sessions)
- [ ] **3.3** Verify pilot JSONL: 18 lines, correct schema, valid session IDs
- [ ] **3.4** Run `analyze-v2.py` on pilot data — confirm all 7 figures + 4 tables generate

### Phase 4: Full Experiment
- [ ] **4.1** Full run: `./run-experiment-v2.sh --reps 10 --seed 42 --resume` (2,160 sessions)
- [ ] **4.2** Verify all 12 JSONL files have 180 lines each

### Phase 5: Verification
- [ ] **5.1** Run session verification (iterate all session IDs via cclogviewer MCP)
- [ ] **5.2** Verify all 12 verified JSONL files exist in `data/verified/`

### Phase 6: Final Analysis
- [ ] **6.1** Run `analyze-v2.py --verified` on full verified data
- [ ] **6.2** Review generated report, figures, and tables
- [ ] **6.3** Final report at `results/replication-experiment/analysis/report.md`

---

## Goal

Replicate the description-variant experiment with N=10 reps per cell, max-turns 5, randomized trial order, ground-truth verification, and publication-quality statistical analysis with visualizations.

**Total sessions:** 10 reps × 18 queries × 12 conditions = 2,160

---

## Condition Matrix

| Condition | CLAUDE.md | settings.json (hook) |
|-----------|-----------|---------------------|
| c1 | absent | absent |
| c2 | present | absent |
| c3 | absent | present |
| c4 | present | present |

## Variants

| Variant | Description Style | Source |
|---------|------------------|--------|
| a | Current (as-is) | `variant-a-current/` |
| b | Expanded (detailed) | `variant-b-expanded/` |
| c | Directive (ALWAYS invoke) | `variant-c-directive/` |

## Key Improvements Over v1

| Limitation | v1 | v2 |
|-----------|-----|-----|
| Sample size | N=1 per cell | N=10 per cell |
| Max turns | 2-3 (caused false negatives) | 5 |
| Randomization | Fixed query order | Per-rep shuffled (seeded) |
| Verification | Heuristic (no denial = success) | Ground truth via cclogviewer MCP |
| Statistical tests | None | Fisher's exact, CMH, logistic regression, CIs |
| Effect sizes | Point differences only | Cohen's h, odds ratios with CIs |
| Multiple comparisons | None | Holm-Bonferroni correction |
| Visualizations | None | 7 publication-quality figures |
| Reproducibility | Manual | Frozen config.json, deterministic seeds, full JSONL audit trail |
| Resumability | None | `--resume` flag at both runner and orchestrator level |
| Drift detection | None | Cumulative evidence plots |
