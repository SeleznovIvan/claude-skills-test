# Skill Activation Experiment v2: Replication Report

**Generated:** 2026-02-04 07:19:14
**Data source:** Heuristic
**Total trials:** 650
**Overall activation rate:** 100.0% (650/650)

## 1. Activation Rates by Cell

| Variant | Condition | N | Successes | Rate | 95% CI |
|---------|-----------|---|-----------|------|--------|
| A: Current | C1: Bare | 56 | 56 | 100.0% | [93.6%, 100.0%] |
| A: Current | C2: +CLAUDE.md | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| A: Current | C3: +Hook | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| A: Current | C4: +Both | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| B: Expanded | C1: Bare | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| B: Expanded | C2: +CLAUDE.md | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| B: Expanded | C3: +Hook | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| B: Expanded | C4: +Both | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C1: Bare | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C2: +CLAUDE.md | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C3: +Hook | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C4: +Both | 54 | 54 | 100.0% | [93.4%, 100.0%] |

## 2. Pairwise Comparisons (Fisher's Exact Test)

| Condition | Comparison | Rate 1 | Rate 2 | p (raw) | p (adjusted) | Cohen's h | Sig |
|-----------|-----------|--------|--------|---------|-------------|-----------|-----|
| C1: Bare | C vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C1: Bare | C vs B | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C1: Bare | B vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C2: +CLAUDE.md | C vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C2: +CLAUDE.md | C vs B | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C2: +CLAUDE.md | B vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C3: +Hook | C vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C3: +Hook | C vs B | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C3: +Hook | B vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C4: +Both | C vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C4: +Both | C vs B | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C4: +Both | B vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |

## 3. Cochran-Mantel-Haenszel Test

Tests variant effect stratified across conditions:

- **C vs A**: Error — cannot unpack non-iterable _Bunch object
- **C vs B**: Error — cannot unpack non-iterable _Bunch object
- **B vs A**: Error — cannot unpack non-iterable _Bunch object

## 4. Logistic Regression

Model: `success ~ C(variant) * hook * claude_md`

**Error:** endog has evaluated to an array with multiple columns that has shape (650, 2). This occurs when the variable converted to endog is non-numeric (e.g., bool or str).

## 5. Per-Skill Summary

### dockerfile-generator
- Overall rate: 100.0% (217/217)
  - A: Current: 100.0%
  - B: Expanded: 100.0%
  - C: Directive: 100.0%

### git-workflow
- Overall rate: 100.0% (216/216)
  - A: Current: 100.0%
  - B: Expanded: 100.0%
  - C: Directive: 100.0%

### svelte5-runes
- Overall rate: 100.0% (217/217)
  - A: Current: 100.0%
  - B: Expanded: 100.0%
  - C: Directive: 100.0%

## 6. Figures

1. `figures/heatmap.png` — Activation rate grid
2. `figures/forest_plot.png` — Pairwise effect sizes
3. `figures/interactions.png` — Interaction effects
4. `figures/per_query_reliability.png` — Per-query rates
5. `figures/turn_distribution.png` — Turn distribution
6. `figures/session_outcomes.png` — Session outcome breakdown
7. `figures/cumulative_evidence.png` — Cumulative evidence plots
