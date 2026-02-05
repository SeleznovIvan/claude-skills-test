# Skill Activation Experiment v2: Replication Report

**Generated:** 2026-02-04 15:11:14
**Data source:** Verified (ground truth)
**Total trials:** 650
**Overall activation rate:** 88.9% (578/650)

## 1. Activation Rates by Cell

| Variant | Condition | N | Successes | Rate | 95% CI |
|---------|-----------|---|-----------|------|--------|
| A: Current | C1: Bare | 56 | 49 | 87.5% | [76.4%, 93.8%] |
| A: Current | C2: +CLAUDE.md | 54 | 44 | 81.5% | [69.2%, 89.6%] |
| A: Current | C3: +Hook | 54 | 20 | 37.0% | [25.4%, 50.4%] |
| A: Current | C4: +Both | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| B: Expanded | C1: Bare | 54 | 46 | 85.2% | [73.4%, 92.3%] |
| B: Expanded | C2: +CLAUDE.md | 54 | 44 | 81.5% | [69.2%, 89.6%] |
| B: Expanded | C3: +Hook | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| B: Expanded | C4: +Both | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C1: Bare | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C2: +CLAUDE.md | 54 | 51 | 94.4% | [84.9%, 98.1%] |
| C: Directive | C3: +Hook | 54 | 54 | 100.0% | [93.4%, 100.0%] |
| C: Directive | C4: +Both | 54 | 54 | 100.0% | [93.4%, 100.0%] |

## 2. Pairwise Comparisons (Fisher's Exact Test)

| Condition | Comparison | Rate 1 | Rate 2 | p (raw) | p (adjusted) | Cohen's h | Sig |
|-----------|-----------|--------|--------|---------|-------------|-----------|-----|
| C1: Bare | C vs A | 100.0% | 87.5% | 0.0129 | 0.1157 | 0.723 | No |
| C1: Bare | C vs B | 100.0% | 85.2% | 0.0059 | 0.0591 | 0.790 | No |
| C1: Bare | B vs A | 85.2% | 87.5% | 0.7860 | 1.0000 | -0.067 | No |
| C2: +CLAUDE.md | C vs A | 94.4% | 81.5% | 0.0729 | 0.5829 | 0.414 | No |
| C2: +CLAUDE.md | C vs B | 94.4% | 81.5% | 0.0729 | 0.5829 | 0.414 | No |
| C2: +CLAUDE.md | B vs A | 81.5% | 81.5% | 1.0000 | 1.0000 | 0.000 | No |
| C3: +Hook | C vs A | 100.0% | 37.0% | 0.0000 | 0.0000 | 1.833 | Yes |
| C3: +Hook | C vs B | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C3: +Hook | B vs A | 100.0% | 37.0% | 0.0000 | 0.0000 | 1.833 | Yes |
| C4: +Both | C vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C4: +Both | C vs B | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |
| C4: +Both | B vs A | 100.0% | 100.0% | 1.0000 | 1.0000 | 0.000 | No |

## 3. Cochran-Mantel-Haenszel Test

Tests variant effect stratified across conditions:

- **C vs A**: statistic=55.001, p=0.0000, common OR=20.584
- **C vs B**: statistic=11.830, p=0.0006, common OR=7.136
- **B vs A**: statistic=20.197, p=0.0000, common OR=3.142

## 4. Logistic Regression

Model: `success ~ C(variant) * hook * claude_md`

- Converged: True
- AIC: 306.3
- Pseudo R²: 0.3675

| Coefficient | Estimate | SE | z | p | 95% CI |
|------------|----------|-----|---|---|--------|
| Intercept | 1.8517 | 0.3902 | 4.746 | 0.0000 | [1.0870, 2.6164] |
| C(variant_cat, Treatment(reference="a"))[T.b] | -0.0578 | 0.5511 | -0.105 | 0.9165 | [-1.1379, 1.0223] |
| C(variant_cat, Treatment(reference="a"))[T.c] | 4.4155 | 3.1206 | 1.415 | 0.1571 | [-1.7008, 10.5317] |
| has_hook | -2.3509 | 0.4806 | -4.892 | 0.0000 | [-3.2928, -1.4090] |
| C(variant_cat, Treatment(reference="a"))[T.b]:has_hook | 6.8478 | 3.2249 | 2.123 | 0.0337 | [0.5271, 13.1685] |
| C(variant_cat, Treatment(reference="a"))[T.c]:has_hook | 2.3965 | 4.4050 | 0.544 | 0.5864 | [-6.2372, 11.0302] |
| has_claude_md | -0.3457 | 0.5261 | -0.657 | 0.5111 | [-1.3767, 0.6854] |
| C(variant_cat, Treatment(reference="a"))[T.b]:has_claude_md | 0.0212 | 0.7416 | 0.029 | 0.9772 | [-1.4324, 1.4747] |
| C(variant_cat, Treatment(reference="a"))[T.c]:has_claude_md | -3.0516 | 3.1947 | -0.955 | 0.3395 | [-9.3131, 3.2099] |
| has_hook:has_claude_md | 7.1587 | 3.2198 | 2.223 | 0.0262 | [0.8480, 13.4695] |
| C(variant_cat, Treatment(reference="a"))[T.b]:has_hook:has_claude_md | 0.0000 | nan | nan | nan | [nan, nan] |
| C(variant_cat, Treatment(reference="a"))[T.c]:has_hook:has_claude_md | 0.0000 | nan | nan | nan | [nan, nan] |

## 5. Per-Skill Summary

### dockerfile-generator
- Overall rate: 94.9% (206/217)
  - A: Current: 84.9%
  - B: Expanded: 100.0%
  - C: Directive: 100.0%

### git-workflow
- Overall rate: 83.3% (180/216)
  - A: Current: 69.4%
  - B: Expanded: 81.9%
  - C: Directive: 98.6%

### svelte5-runes
- Overall rate: 88.5% (192/217)
  - A: Current: 75.3%
  - B: Expanded: 93.1%
  - C: Directive: 97.2%

## 6. Figures

1. `figures/heatmap.png` — Activation rate grid
2. `figures/forest_plot.png` — Pairwise effect sizes
3. `figures/interactions.png` — Interaction effects
4. `figures/per_query_reliability.png` — Per-query rates
5. `figures/turn_distribution.png` — Turn distribution
6. `figures/session_outcomes.png` — Session outcome breakdown
7. `figures/cumulative_evidence.png` — Cumulative evidence plots
