#!/usr/bin/env python3
"""
analyze-v2.py — Statistical analysis & visualization for replication experiment.

Usage:
    .venv/bin/python3 analyze-v2.py --results-dir data/ [--verified] --output-dir analysis/

Produces:
  - 7 figures (PNG + PDF, 300 DPI)
  - 4 CSV tables
  - stats.json with raw statistical results
  - report.md scientific report
"""

import argparse
import json
import os
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats as scipy_stats
from statsmodels.stats.proportion import proportion_confint
from statsmodels.stats.contingency_tables import StratifiedTable
import statsmodels.api as sm
import statsmodels.formula.api as smf

warnings.filterwarnings('ignore', category=FutureWarning)
warnings.filterwarnings('ignore', category=RuntimeWarning)

# ---- Constants ----
VARIANTS = ['a', 'b', 'c']
CONDITIONS = ['c1', 'c2', 'c3', 'c4']
VARIANT_LABELS = {'a': 'A: Current', 'b': 'B: Expanded', 'c': 'C: Directive'}
CONDITION_LABELS = {
    'c1': 'C1: Bare',
    'c2': 'C2: +CLAUDE.md',
    'c3': 'C3: +Hook',
    'c4': 'C4: +Both'
}
SKILL_COLORS = {
    'dockerfile-generator': '#e74c3c',
    'git-workflow': '#3498db',
    'svelte5-runes': '#2ecc71'
}

# ---- Utility functions ----

def wilson_ci(successes, n, alpha=0.05):
    """Wilson score confidence interval for a proportion."""
    if n == 0:
        return 0.0, 0.0, 0.0
    lo, hi = proportion_confint(successes, n, alpha=alpha, method='wilson')
    return successes / n, lo, hi


def cohens_h(p1, p2):
    """Cohen's h effect size for two proportions."""
    h = 2 * np.arcsin(np.sqrt(p1)) - 2 * np.arcsin(np.sqrt(p2))
    return h


def cohens_h_ci(p1, n1, p2, n2, alpha=0.05):
    """Cohen's h with bootstrap CI."""
    if n1 == 0 or n2 == 0:
        return np.nan, np.nan, np.nan
    h = cohens_h(p1, p2)
    # SE approximation for arcsin transformation
    se = np.sqrt(1 / (4 * n1) + 1 / (4 * n2))
    z = scipy_stats.norm.ppf(1 - alpha / 2)
    return h, h - z * se, h + z * se


def odds_ratio_with_ci(a, b, c, d, alpha=0.05):
    """Odds ratio with Haldane-Anscombe correction for zero cells."""
    # Add 0.5 to all cells if any are zero
    if a == 0 or b == 0 or c == 0 or d == 0:
        a, b, c, d = a + 0.5, b + 0.5, c + 0.5, d + 0.5
    or_val = (a * d) / (b * c)
    log_or = np.log(or_val)
    se_log_or = np.sqrt(1/a + 1/b + 1/c + 1/d)
    z = scipy_stats.norm.ppf(1 - alpha / 2)
    lo = np.exp(log_or - z * se_log_or)
    hi = np.exp(log_or + z * se_log_or)
    return or_val, lo, hi


def holm_bonferroni(p_values):
    """Holm-Bonferroni correction for multiple comparisons."""
    n = len(p_values)
    if n == 0:
        return []
    sorted_indices = np.argsort(p_values)
    adjusted = np.zeros(n)
    for rank, idx in enumerate(sorted_indices):
        adjusted[idx] = min(p_values[idx] * (n - rank), 1.0)
    # Enforce monotonicity
    for i in range(1, n):
        idx = sorted_indices[i]
        prev_idx = sorted_indices[i - 1]
        adjusted[idx] = max(adjusted[idx], adjusted[prev_idx])
    return adjusted.tolist()


# ---- Data loading ----

def load_data(results_dir, verified=False):
    """Load all JSONL files into a single DataFrame."""
    rows = []

    if verified:
        # Load from single combined verified file
        verified_path = Path(results_dir) / 'verified' / 'verified_results.jsonl'
        if verified_path.exists():
            print(f"Loading verified data from {verified_path}")
            with open(verified_path) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        row = json.loads(line)
                        rows.append(row)
                    except json.JSONDecodeError:
                        print(f"  Warning: bad JSON line in {verified_path}")
        else:
            print(f"ERROR: Verified data file not found: {verified_path}")
            sys.exit(1)
    else:
        # Load from separate condition directories
        for v in VARIANTS:
            for c in CONDITIONS:
                path = Path(results_dir) / f'{v}-{c}' / 'results.jsonl'

                if not path.exists():
                    print(f"  Warning: {path} not found, skipping")
                    continue

                with open(path) as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            row = json.loads(line)
                            rows.append(row)
                        except json.JSONDecodeError:
                            print(f"  Warning: bad JSON line in {path}")

    df = pd.DataFrame(rows)
    if len(df) == 0:
        print("ERROR: No data loaded!")
        sys.exit(1)

    # Add derived columns
    if 'skill_invoked_heuristic' in df.columns:
        # Use verified ground truth if available, else heuristic
        if 'skill_invoked_verified' in df.columns:
            df['success'] = df['skill_invoked_verified'].astype(bool)
        else:
            df['success'] = df['skill_invoked_heuristic'].astype(bool)
    else:
        df['success'] = False

    # Binary flags for condition components
    df['has_claude_md'] = df['condition'].isin(['c2', 'c4']).astype(int)
    df['has_hook'] = df['condition'].isin(['c3', 'c4']).astype(int)

    print(f"Loaded {len(df)} trials ({df['success'].sum()} successes)")
    return df


# ---- Statistical analysis ----

def compute_cell_rates(df):
    """Compute activation rate + Wilson CI for each cell."""
    results = []
    for v in VARIANTS:
        for c in CONDITIONS:
            cell = df[(df['variant'] == v) & (df['condition'] == c)]
            n = len(cell)
            k = cell['success'].sum()
            rate, lo, hi = wilson_ci(k, n)
            results.append({
                'variant': v, 'condition': c,
                'n': n, 'successes': int(k),
                'rate': rate, 'ci_lo': lo, 'ci_hi': hi
            })
    return pd.DataFrame(results)


def pairwise_comparisons(df):
    """Fisher's exact test for all pairwise variant comparisons per condition."""
    results = []
    pairs = [('c', 'a'), ('c', 'b'), ('b', 'a')]

    for cond in CONDITIONS:
        for v1, v2 in pairs:
            g1 = df[(df['variant'] == v1) & (df['condition'] == cond)]
            g2 = df[(df['variant'] == v2) & (df['condition'] == cond)]

            n1, k1 = len(g1), int(g1['success'].sum())
            n2, k2 = len(g2), int(g2['success'].sum())

            p1 = k1 / n1 if n1 > 0 else 0
            p2 = k2 / n2 if n2 > 0 else 0

            # Skip if either group is empty
            if n1 == 0 or n2 == 0:
                results.append({
                    'condition': cond,
                    'comparison': f'{v1.upper()} vs {v2.upper()}',
                    'v1': v1, 'v2': v2,
                    'n1': n1, 'k1': k1, 'rate1': p1,
                    'n2': n2, 'k2': k2, 'rate2': p2,
                    'fisher_p': np.nan,
                    'cohens_h': np.nan, 'h_ci_lo': np.nan, 'h_ci_hi': np.nan,
                    'odds_ratio': np.nan, 'or_ci_lo': np.nan, 'or_ci_hi': np.nan
                })
                continue

            # 2x2 table: [[k1, n1-k1], [k2, n2-k2]]
            table = [[k1, n1 - k1], [k2, n2 - k2]]
            odds, p_val = scipy_stats.fisher_exact(table)

            h, h_lo, h_hi = cohens_h_ci(p1, n1, p2, n2)
            or_val, or_lo, or_hi = odds_ratio_with_ci(k1, n1 - k1, k2, n2 - k2)

            results.append({
                'condition': cond,
                'comparison': f'{v1.upper()} vs {v2.upper()}',
                'v1': v1, 'v2': v2,
                'n1': n1, 'k1': k1, 'rate1': p1,
                'n2': n2, 'k2': k2, 'rate2': p2,
                'fisher_p': p_val,
                'cohens_h': h, 'h_ci_lo': h_lo, 'h_ci_hi': h_hi,
                'odds_ratio': or_val, 'or_ci_lo': or_lo, 'or_ci_hi': or_hi
            })

    pw_df = pd.DataFrame(results)
    # Holm-Bonferroni correction (only on non-NaN p-values)
    valid_mask = ~pw_df['fisher_p'].isna()
    if valid_mask.any():
        pw_df.loc[valid_mask, 'p_adjusted'] = holm_bonferroni(pw_df.loc[valid_mask, 'fisher_p'].values)
    else:
        pw_df['p_adjusted'] = np.nan
    pw_df['significant'] = pw_df['p_adjusted'] < 0.05
    return pw_df


def cmh_test(df):
    """Cochran-Mantel-Haenszel test: variant effect stratified by condition."""
    results = {}
    pairs = [('c', 'a'), ('c', 'b'), ('b', 'a')]

    for v1, v2 in pairs:
        tables = []
        for cond in CONDITIONS:
            g1 = df[(df['variant'] == v1) & (df['condition'] == cond)]
            g2 = df[(df['variant'] == v2) & (df['condition'] == cond)]
            k1, n1 = int(g1['success'].sum()), len(g1)
            k2, n2 = int(g2['success'].sum()), len(g2)
            tables.append(np.array([[k1, n1 - k1], [k2, n2 - k2]]))

        try:
            st = StratifiedTable(tables)
            test_result = st.test_null_odds()
            # test_null_odds returns a Bunch object with statistic and pvalue attributes
            stat = test_result.statistic
            p_val = test_result.pvalue
            common_or = st.oddsratio_pooled
            results[f'{v1.upper()} vs {v2.upper()}'] = {
                'statistic': float(stat),
                'p_value': float(p_val),
                'common_odds_ratio': float(common_or)
            }
        except Exception as e:
            results[f'{v1.upper()} vs {v2.upper()}'] = {
                'statistic': None,
                'p_value': None,
                'common_odds_ratio': None,
                'error': str(e)
            }

    return results


def logistic_regression(df):
    """Logistic regression: success ~ C(variant) * hook * claude_md.

    Uses regularization to handle perfect separation (100% cells).
    """
    try:
        df_model = df.copy()
        # Convert success to int (0/1) for logistic regression
        df_model['success_int'] = df_model['success'].astype(int)
        df_model['variant_cat'] = pd.Categorical(df_model['variant'], categories=['a', 'b', 'c'])

        # Try standard logit first
        formula = 'success_int ~ C(variant_cat, Treatment(reference="a")) * has_hook * has_claude_md'
        try:
            model = smf.logit(formula, data=df_model).fit(disp=0, maxiter=100)
        except Exception:
            # If standard fails due to perfect separation, use regularized logit
            # Add small regularization to avoid singular matrix
            model = smf.logit(formula, data=df_model).fit_regularized(
                method='l1', alpha=0.1, disp=0, maxiter=200
            )

        results = {
            'converged': getattr(model, 'mle_retvals', {}).get('converged', True),
            'aic': getattr(model, 'aic', None),
            'bic': getattr(model, 'bic', None),
            'pseudo_r2': getattr(model, 'prsquared', None),
            'coefficients': {}
        }

        # Get confidence intervals if available
        try:
            conf_int = model.conf_int()
        except Exception:
            conf_int = None

        for name, coef in model.params.items():
            coef_info = {
                'coef': float(coef),
                'se': float(model.bse[name]) if hasattr(model, 'bse') and name in model.bse else None,
                'z': float(model.tvalues[name]) if hasattr(model, 'tvalues') and name in model.tvalues else None,
                'p': float(model.pvalues[name]) if hasattr(model, 'pvalues') and name in model.pvalues else None,
            }
            if conf_int is not None and name in conf_int.index:
                coef_info['ci_lo'] = float(conf_int.loc[name, 0])
                coef_info['ci_hi'] = float(conf_int.loc[name, 1])
            results['coefficients'][name] = coef_info
        return results
    except Exception as e:
        # If all else fails, try a simpler model without interactions
        try:
            df_model = df.copy()
            df_model['success_int'] = df_model['success'].astype(int)
            df_model['is_variant_b'] = (df_model['variant'] == 'b').astype(int)
            df_model['is_variant_c'] = (df_model['variant'] == 'c').astype(int)

            formula = 'success_int ~ is_variant_b + is_variant_c + has_hook + has_claude_md'
            model = smf.logit(formula, data=df_model).fit_regularized(
                method='l1', alpha=0.1, disp=0, maxiter=200
            )

            results = {
                'note': 'Simplified model (no interactions) due to perfect separation',
                'coefficients': {}
            }
            for name, coef in model.params.items():
                results['coefficients'][name] = {
                    'coef': float(coef),
                    'odds_ratio': float(np.exp(coef))
                }
            return results
        except Exception as e2:
            return {'error': f'Full model: {str(e)}; Simplified model: {str(e2)}'}


# ---- Visualization ----

def set_plot_style():
    """Set publication-quality plot style."""
    sns.set_theme(style='whitegrid', font_scale=1.1)
    plt.rcParams.update({
        'figure.dpi': 300,
        'savefig.dpi': 300,
        'figure.figsize': (10, 7),
        'font.family': 'sans-serif',
    })


def save_fig(fig, name, output_dir):
    """Save figure as PNG and PDF."""
    fig_dir = Path(output_dir) / 'figures'
    fig_dir.mkdir(parents=True, exist_ok=True)
    fig.savefig(fig_dir / f'{name}.png', bbox_inches='tight', dpi=300)
    fig.savefig(fig_dir / f'{name}.pdf', bbox_inches='tight')
    plt.close(fig)
    print(f"  Saved: {name}.png, {name}.pdf")


def plot_heatmap(cell_rates, output_dir):
    """3x4 activation rate heatmap with Wilson CIs."""
    fig, ax = plt.subplots(figsize=(10, 6))

    # Pivot to matrix
    rate_matrix = cell_rates.pivot(index='variant', columns='condition', values='rate')
    rate_matrix = rate_matrix.reindex(index=VARIANTS, columns=CONDITIONS)

    # Annotations with CIs
    annot = np.empty_like(rate_matrix, dtype=object)
    for i, v in enumerate(VARIANTS):
        for j, c in enumerate(CONDITIONS):
            row = cell_rates[(cell_rates['variant'] == v) & (cell_rates['condition'] == c)]
            if len(row) > 0:
                r = row.iloc[0]
                annot[i, j] = f"{r['rate']:.1%}\n[{r['ci_lo']:.1%}, {r['ci_hi']:.1%}]\nn={r['n']}"
            else:
                annot[i, j] = "N/A"

    sns.heatmap(
        rate_matrix, annot=annot, fmt='',
        cmap='RdYlGn', vmin=0, vmax=1,
        linewidths=1, linecolor='white',
        xticklabels=[CONDITION_LABELS[c] for c in CONDITIONS],
        yticklabels=[VARIANT_LABELS[v] for v in VARIANTS],
        ax=ax
    )
    ax.set_title('Skill Activation Rate by Variant × Condition\n(with 95% Wilson CIs)', fontsize=14)
    ax.set_ylabel('Description Variant')
    ax.set_xlabel('Condition')

    save_fig(fig, 'heatmap', output_dir)


def plot_forest(pw_df, output_dir):
    """Forest plot of pairwise effect sizes (C vs A) per condition."""
    fig, ax = plt.subplots(figsize=(10, 6))

    # Filter to C vs A, drop rows with NaN effect sizes
    ca = pw_df[pw_df['comparison'] == 'C vs A'].copy()
    ca = ca.sort_values('condition')
    ca_valid = ca.dropna(subset=['cohens_h'])

    if len(ca_valid) == 0:
        ax.text(0.5, 0.5, 'Insufficient data for forest plot',
                ha='center', va='center', transform=ax.transAxes, fontsize=12)
        ax.set_title("Effect Size: Directive (C) vs Current (A) by Condition\n(Cohen's h with 95% CI)", fontsize=14)
        save_fig(fig, 'forest_plot', output_dir)
        return

    y_pos = range(len(ca_valid))
    ax.errorbar(
        ca_valid['cohens_h'], y_pos,
        xerr=[ca_valid['cohens_h'] - ca_valid['h_ci_lo'], ca_valid['h_ci_hi'] - ca_valid['cohens_h']],
        fmt='o', color='#2c3e50', markersize=8, capsize=5, capthick=2, linewidth=2
    )
    ax.axvline(x=0, color='gray', linestyle='--', linewidth=1)
    ax.set_yticks(list(y_pos))
    ax.set_yticklabels([CONDITION_LABELS[c] for c in ca_valid['condition']])
    ax.set_xlabel("Cohen's h (C vs A)")
    ax.set_title("Effect Size: Directive (C) vs Current (A) by Condition\n(Cohen's h with 95% CI)", fontsize=14)

    # Add significance markers
    for i, (_, row) in enumerate(ca_valid.iterrows()):
        if pd.notna(row['p_adjusted']):
            marker = '*' if row['significant'] else 'ns'
            ax.annotate(
                f"p={row['p_adjusted']:.3f} {marker}",
                xy=(row['cohens_h'], i),
                xytext=(10, 0), textcoords='offset points',
                fontsize=9, va='center'
            )

    save_fig(fig, 'forest_plot', output_dir)


def plot_interactions(df, cell_rates, output_dir):
    """Two-panel interaction plots: Description×Hook and Description×CLAUDE.md."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

    colors = {'a': '#e74c3c', 'b': '#3498db', 'c': '#2ecc71'}

    # Panel 1: Description × Hook
    for v in VARIANTS:
        for has_hook in [0, 1]:
            if has_hook == 0:
                conds = ['c1', 'c2']
            else:
                conds = ['c3', 'c4']
            sub = cell_rates[(cell_rates['variant'] == v) & (cell_rates['condition'].isin(conds))]
            rate = sub['rate'].mean()
            ci_lo = sub['ci_lo'].mean()
            ci_hi = sub['ci_hi'].mean()
            ax1.errorbar(
                has_hook, rate,
                yerr=[[rate - ci_lo], [ci_hi - rate]],
                fmt='o-' if has_hook == 1 else 'o',
                color=colors[v], markersize=8, capsize=4, linewidth=2,
                label=VARIANT_LABELS[v] if has_hook == 0 else None
            )
        # Connect the dots
        rates = []
        for has_hook in [0, 1]:
            conds = ['c1', 'c2'] if has_hook == 0 else ['c3', 'c4']
            sub = cell_rates[(cell_rates['variant'] == v) & (cell_rates['condition'].isin(conds))]
            rates.append(sub['rate'].mean())
        ax1.plot([0, 1], rates, color=colors[v], linewidth=2)

    ax1.set_xticks([0, 1])
    ax1.set_xticklabels(['No Hook', 'Hook'])
    ax1.set_ylabel('Activation Rate')
    ax1.set_title('Description × Hook Interaction')
    ax1.legend()
    ax1.set_ylim(-0.05, 1.05)

    # Panel 2: Description × CLAUDE.md
    for v in VARIANTS:
        rates = []
        for has_cmd in [0, 1]:
            conds = ['c1', 'c3'] if has_cmd == 0 else ['c2', 'c4']
            sub = cell_rates[(cell_rates['variant'] == v) & (cell_rates['condition'].isin(conds))]
            rate = sub['rate'].mean()
            ci_lo = sub['ci_lo'].mean()
            ci_hi = sub['ci_hi'].mean()
            rates.append(rate)
            ax2.errorbar(
                has_cmd, rate,
                yerr=[[rate - ci_lo], [ci_hi - rate]],
                fmt='o', color=colors[v], markersize=8, capsize=4, linewidth=2,
                label=VARIANT_LABELS[v] if has_cmd == 0 else None
            )
        ax2.plot([0, 1], rates, color=colors[v], linewidth=2)

    ax2.set_xticks([0, 1])
    ax2.set_xticklabels(['No CLAUDE.md', 'CLAUDE.md'])
    ax2.set_ylabel('Activation Rate')
    ax2.set_title('Description × CLAUDE.md Interaction')
    ax2.legend()
    ax2.set_ylim(-0.05, 1.05)

    fig.suptitle('Interaction Effects', fontsize=14, y=1.02)
    fig.tight_layout()
    save_fig(fig, 'interactions', output_dir)


def plot_per_query_reliability(df, output_dir):
    """Horizontal bar chart per query, colored by skill, with CIs."""
    # Group by query
    query_stats = []
    for (query, skill), grp in df.groupby(['query', 'skill']):
        n = len(grp)
        k = int(grp['success'].sum())
        rate, lo, hi = wilson_ci(k, n)
        query_stats.append({
            'query': query, 'skill': skill,
            'n': n, 'rate': rate, 'ci_lo': lo, 'ci_hi': hi
        })
    qs = pd.DataFrame(query_stats).sort_values(['skill', 'rate'], ascending=[True, True])

    fig, ax = plt.subplots(figsize=(12, 8))
    y_pos = range(len(qs))

    # Clamp error values to be non-negative (can happen at 0% or 100% rates)
    xerr_lo = np.maximum(0, qs['rate'] - qs['ci_lo'])
    xerr_hi = np.maximum(0, qs['ci_hi'] - qs['rate'])

    bars = ax.barh(
        y_pos, qs['rate'],
        xerr=[xerr_lo, xerr_hi],
        color=[SKILL_COLORS.get(s, 'gray') for s in qs['skill']],
        capsize=3, edgecolor='white', linewidth=0.5
    )

    ax.set_yticks(list(y_pos))
    ax.set_yticklabels(qs['query'], fontsize=9)
    ax.set_xlabel('Activation Rate (across all conditions)')
    ax.set_title('Per-Query Activation Rate\n(colored by skill, with 95% Wilson CIs)', fontsize=14)
    ax.set_xlim(0, 1.05)

    # Legend
    from matplotlib.patches import Patch
    legend_elements = [Patch(facecolor=c, label=s) for s, c in SKILL_COLORS.items()]
    ax.legend(handles=legend_elements, loc='lower right')

    save_fig(fig, 'per_query_reliability', output_dir)


def plot_turn_distribution(df, output_dir):
    """Violin plot of turns-to-activation by cell."""
    fig, ax = plt.subplots(figsize=(14, 7))

    # Filter to successful trials
    success_df = df[df['success']].copy()
    if len(success_df) == 0:
        # If no successes, plot turns for all trials
        success_df = df.copy()

    success_df['cell'] = success_df['variant'].str.upper() + '-' + success_df['condition'].str.upper()

    # Order cells
    cell_order = [f'{v.upper()}-{c.upper()}' for v in VARIANTS for c in CONDITIONS]
    success_df['cell'] = pd.Categorical(success_df['cell'], categories=cell_order, ordered=True)

    sns.violinplot(
        data=success_df, x='cell', y='turns',
        inner='box', palette='Set3', ax=ax
    )
    ax.set_xlabel('Cell (Variant-Condition)')
    ax.set_ylabel('Turns to Activation')
    ax.set_title('Turn Distribution for Successful Activations', fontsize=14)
    plt.xticks(rotation=45, ha='right')

    save_fig(fig, 'turn_distribution', output_dir)


def plot_session_outcomes(df, output_dir):
    """Stacked bar: Skill turn 1 / Skill turn 2+ / No skill (max turns) / No skill (completed)."""
    fig, ax = plt.subplots(figsize=(14, 7))

    cells = [f'{v}-{c}' for v in VARIANTS for c in CONDITIONS]
    categories = ['Skill (turn 1)', 'Skill (turn 2+)', 'No skill (max turns)', 'No skill (completed)']
    data = {cat: [] for cat in categories}

    for cell in cells:
        v, c = cell.split('-')
        sub = df[(df['variant'] == v) & (df['condition'] == c)]
        n = len(sub)
        if n == 0:
            for cat in categories:
                data[cat].append(0)
            continue

        skill_t1 = len(sub[(sub['success']) & (sub['turns'] == 1)])
        skill_t2 = len(sub[(sub['success']) & (sub['turns'] > 1)])
        no_skill_max = len(sub[(~sub['success']) & (sub['status'] == 'error_max_turns')])
        no_skill_done = len(sub[(~sub['success']) & (sub['status'] != 'error_max_turns')])

        data['Skill (turn 1)'].append(skill_t1 / n)
        data['Skill (turn 2+)'].append(skill_t2 / n)
        data['No skill (max turns)'].append(no_skill_max / n)
        data['No skill (completed)'].append(no_skill_done / n)

    x = range(len(cells))
    bottom = np.zeros(len(cells))
    colors_stacked = ['#27ae60', '#82e0aa', '#e74c3c', '#f5b7b1']

    for cat, color in zip(categories, colors_stacked):
        vals = data[cat]
        ax.bar(x, vals, bottom=bottom, label=cat, color=color, edgecolor='white', linewidth=0.5)
        bottom += np.array(vals)

    ax.set_xticks(list(x))
    ax.set_xticklabels([f'{v.upper()}-{c.upper()}' for v, c in [cell.split('-') for cell in cells]],
                       rotation=45, ha='right')
    ax.set_ylabel('Proportion')
    ax.set_title('Session Outcomes by Cell', fontsize=14)
    ax.legend(loc='upper right')
    ax.set_ylim(0, 1.05)

    save_fig(fig, 'session_outcomes', output_dir)


def plot_cumulative_evidence(df, output_dir):
    """3×4 small multiples showing running success rate by trial order."""
    fig, axes = plt.subplots(3, 4, figsize=(16, 10), sharex=True, sharey=True)

    for i, v in enumerate(VARIANTS):
        for j, c in enumerate(CONDITIONS):
            ax = axes[i][j]
            sub = df[(df['variant'] == v) & (df['condition'] == c)].sort_values('trial_order')

            if len(sub) == 0:
                ax.text(0.5, 0.5, 'No data', ha='center', va='center', transform=ax.transAxes)
                if i == 0:
                    ax.set_title(CONDITION_LABELS[c])
                if j == 0:
                    ax.set_ylabel(VARIANT_LABELS[v])
                continue

            cumsum = sub['success'].cumsum()
            cumcount = range(1, len(sub) + 1)
            running_rate = cumsum / np.arange(1, len(sub) + 1)

            ax.plot(cumcount, running_rate, color='#2c3e50', linewidth=1.5)
            ax.axhline(y=sub['success'].mean(), color='#e74c3c', linestyle='--', linewidth=1, alpha=0.7)
            ax.set_ylim(-0.05, 1.05)

            if i == 0:
                ax.set_title(CONDITION_LABELS[c], fontsize=10)
            if j == 0:
                ax.set_ylabel(VARIANT_LABELS[v], fontsize=10)
            if i == 2:
                ax.set_xlabel('Trial #')

    fig.suptitle('Cumulative Success Rate (drift detection)', fontsize=14, y=1.02)
    fig.tight_layout()
    save_fig(fig, 'cumulative_evidence', output_dir)


# ---- Tables ----

def write_tables(df, cell_rates, pw_df, output_dir):
    """Write all CSV tables."""
    table_dir = Path(output_dir) / 'tables'
    table_dir.mkdir(parents=True, exist_ok=True)

    # 1. Main results
    cell_rates.to_csv(table_dir / 'main_results.csv', index=False)
    print(f"  Saved: main_results.csv")

    # 2. Pairwise comparisons
    pw_df.to_csv(table_dir / 'pairwise_comparisons.csv', index=False)
    print(f"  Saved: pairwise_comparisons.csv")

    # 3. Per-skill breakdown
    skill_results = []
    for skill in df['skill'].unique():
        for v in VARIANTS:
            for c in CONDITIONS:
                sub = df[(df['skill'] == skill) & (df['variant'] == v) & (df['condition'] == c)]
                n = len(sub)
                k = int(sub['success'].sum())
                rate, lo, hi = wilson_ci(k, n)
                skill_results.append({
                    'skill': skill, 'variant': v, 'condition': c,
                    'n': n, 'successes': k, 'rate': rate,
                    'ci_lo': lo, 'ci_hi': hi
                })
    pd.DataFrame(skill_results).to_csv(table_dir / 'per_skill_breakdown.csv', index=False)
    print(f"  Saved: per_skill_breakdown.csv")

    # 4. Per-query results
    query_results = []
    for (query, skill) in df.groupby(['query', 'skill']).groups:
        for v in VARIANTS:
            for c in CONDITIONS:
                sub = df[(df['query'] == query) & (df['variant'] == v) & (df['condition'] == c)]
                n = len(sub)
                k = int(sub['success'].sum())
                rate, lo, hi = wilson_ci(k, n)
                query_results.append({
                    'query': query, 'skill': skill, 'variant': v, 'condition': c,
                    'n': n, 'successes': k, 'rate': rate,
                    'ci_lo': lo, 'ci_hi': hi
                })
    pd.DataFrame(query_results).to_csv(table_dir / 'per_query_results.csv', index=False)
    print(f"  Saved: per_query_results.csv")


# ---- Report ----

def generate_report(df, cell_rates, pw_df, cmh_results, logreg_results, output_dir, verified):
    """Generate scientific report as markdown."""
    report_path = Path(output_dir) / 'report.md'

    total = len(df)
    total_success = df['success'].sum()
    overall_rate = total_success / total if total > 0 else 0

    lines = []
    lines.append("# Skill Activation Experiment v2: Replication Report")
    lines.append("")
    lines.append(f"**Generated:** {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"**Data source:** {'Verified (ground truth)' if verified else 'Heuristic'}")
    lines.append(f"**Total trials:** {total}")
    lines.append(f"**Overall activation rate:** {overall_rate:.1%} ({int(total_success)}/{total})")
    lines.append("")

    # Summary table
    lines.append("## 1. Activation Rates by Cell")
    lines.append("")
    lines.append("| Variant | Condition | N | Successes | Rate | 95% CI |")
    lines.append("|---------|-----------|---|-----------|------|--------|")
    for _, row in cell_rates.iterrows():
        lines.append(
            f"| {VARIANT_LABELS.get(row['variant'], row['variant'])} "
            f"| {CONDITION_LABELS.get(row['condition'], row['condition'])} "
            f"| {row['n']} | {row['successes']} "
            f"| {row['rate']:.1%} "
            f"| [{row['ci_lo']:.1%}, {row['ci_hi']:.1%}] |"
        )
    lines.append("")

    # Pairwise comparisons
    lines.append("## 2. Pairwise Comparisons (Fisher's Exact Test)")
    lines.append("")
    lines.append("| Condition | Comparison | Rate 1 | Rate 2 | p (raw) | p (adjusted) | Cohen's h | Sig |")
    lines.append("|-----------|-----------|--------|--------|---------|-------------|-----------|-----|")
    for _, row in pw_df.iterrows():
        if pd.isna(row['fisher_p']):
            lines.append(
                f"| {CONDITION_LABELS.get(row['condition'], row['condition'])} "
                f"| {row['comparison']} "
                f"| {row['rate1']:.1%} | {row['rate2']:.1%} "
                f"| N/A | N/A | N/A | N/A |"
            )
        else:
            sig = "Yes" if row['significant'] else "No"
            lines.append(
                f"| {CONDITION_LABELS.get(row['condition'], row['condition'])} "
                f"| {row['comparison']} "
                f"| {row['rate1']:.1%} | {row['rate2']:.1%} "
                f"| {row['fisher_p']:.4f} | {row['p_adjusted']:.4f} "
                f"| {row['cohens_h']:.3f} | {sig} |"
            )
    lines.append("")

    # CMH test
    lines.append("## 3. Cochran-Mantel-Haenszel Test")
    lines.append("")
    lines.append("Tests variant effect stratified across conditions:")
    lines.append("")
    for name, result in cmh_results.items():
        if result.get('error'):
            lines.append(f"- **{name}**: Error — {result['error']}")
        elif result['p_value'] is not None:
            lines.append(
                f"- **{name}**: statistic={result['statistic']:.3f}, "
                f"p={result['p_value']:.4f}, "
                f"common OR={result['common_odds_ratio']:.3f}"
            )
        else:
            lines.append(f"- **{name}**: Could not compute")
    lines.append("")

    # Logistic regression
    lines.append("## 4. Logistic Regression")
    lines.append("")
    lines.append("Model: `success ~ C(variant) * hook * claude_md`")
    lines.append("")
    if 'error' in logreg_results:
        lines.append(f"**Error:** {logreg_results['error']}")
    else:
        if 'note' in logreg_results:
            lines.append(f"**Note:** {logreg_results['note']}")
            lines.append("")
        if logreg_results.get('converged') is not None:
            lines.append(f"- Converged: {logreg_results['converged']}")
        if logreg_results.get('aic') is not None:
            lines.append(f"- AIC: {logreg_results['aic']:.1f}")
        if logreg_results.get('pseudo_r2') is not None:
            lines.append(f"- Pseudo R²: {logreg_results['pseudo_r2']:.4f}")
        lines.append("")

        # Check what fields are available in coefficients
        coefs = logreg_results.get('coefficients', {})
        if coefs:
            first_coef = list(coefs.values())[0]
            has_full_stats = first_coef.get('se') is not None

            if has_full_stats:
                lines.append("| Coefficient | Estimate | SE | z | p | 95% CI |")
                lines.append("|------------|----------|-----|---|---|--------|")
                for name, coef in coefs.items():
                    se_str = f"{coef['se']:.4f}" if coef.get('se') else "—"
                    z_str = f"{coef['z']:.3f}" if coef.get('z') else "—"
                    p_str = f"{coef['p']:.4f}" if coef.get('p') else "—"
                    if coef.get('ci_lo') is not None:
                        ci_str = f"[{coef['ci_lo']:.4f}, {coef['ci_hi']:.4f}]"
                    else:
                        ci_str = "—"
                    lines.append(
                        f"| {name} | {coef['coef']:.4f} | {se_str} "
                        f"| {z_str} | {p_str} | {ci_str} |"
                    )
            else:
                # Simplified output with just coefficients and odds ratios
                lines.append("| Coefficient | Estimate | Odds Ratio |")
                lines.append("|------------|----------|------------|")
                for name, coef in coefs.items():
                    or_str = f"{coef['odds_ratio']:.3f}" if coef.get('odds_ratio') else f"{np.exp(coef['coef']):.3f}"
                    lines.append(f"| {name} | {coef['coef']:.4f} | {or_str} |")
    lines.append("")

    # Per-skill summary
    lines.append("## 5. Per-Skill Summary")
    lines.append("")
    for skill in sorted(df['skill'].unique()):
        sub = df[df['skill'] == skill]
        rate = sub['success'].mean()
        lines.append(f"### {skill}")
        lines.append(f"- Overall rate: {rate:.1%} ({int(sub['success'].sum())}/{len(sub)})")
        for v in VARIANTS:
            vsub = sub[sub['variant'] == v]
            vrate = vsub['success'].mean() if len(vsub) > 0 else 0
            lines.append(f"  - {VARIANT_LABELS[v]}: {vrate:.1%}")
        lines.append("")

    # Figures reference
    lines.append("## 6. Figures")
    lines.append("")
    lines.append("1. `figures/heatmap.png` — Activation rate grid")
    lines.append("2. `figures/forest_plot.png` — Pairwise effect sizes")
    lines.append("3. `figures/interactions.png` — Interaction effects")
    lines.append("4. `figures/per_query_reliability.png` — Per-query rates")
    lines.append("5. `figures/turn_distribution.png` — Turn distribution")
    lines.append("6. `figures/session_outcomes.png` — Session outcome breakdown")
    lines.append("7. `figures/cumulative_evidence.png` — Cumulative evidence plots")
    lines.append("")

    with open(report_path, 'w') as f:
        f.write('\n'.join(lines))
    print(f"  Saved: report.md")


# ---- Main ----

def main():
    parser = argparse.ArgumentParser(description='Analyze replication experiment results')
    parser.add_argument('--results-dir', required=True, help='Path to data/ directory')
    parser.add_argument('--verified', action='store_true', help='Use verified data from data/verified/')
    parser.add_argument('--output-dir', required=True, help='Path to analysis/ output directory')
    args = parser.parse_args()

    set_plot_style()

    print("=== Replication Experiment v2 Analysis ===")
    print(f"  Results dir: {args.results_dir}")
    print(f"  Verified: {args.verified}")
    print(f"  Output dir: {args.output_dir}")
    print("")

    # Load data
    print("Loading data...")
    df = load_data(args.results_dir, verified=args.verified)
    print("")

    # Compute statistics
    print("Computing cell rates...")
    cell_rates = compute_cell_rates(df)
    print("")

    print("Running pairwise comparisons...")
    pw_df = pairwise_comparisons(df)
    print("")

    print("Running CMH test...")
    cmh_results = cmh_test(df)
    print("")

    print("Fitting logistic regression...")
    logreg_results = logistic_regression(df)
    print("")

    # Save raw stats
    stats_path = Path(args.output_dir) / 'stats.json'
    Path(args.output_dir).mkdir(parents=True, exist_ok=True)
    stats = {
        'cell_rates': cell_rates.to_dict(orient='records'),
        'pairwise_comparisons': pw_df.to_dict(orient='records'),
        'cmh_test': cmh_results,
        'logistic_regression': logreg_results,
        'summary': {
            'total_trials': len(df),
            'total_successes': int(df['success'].sum()),
            'overall_rate': float(df['success'].mean()),
            'verified': args.verified
        }
    }
    with open(stats_path, 'w') as f:
        json.dump(stats, f, indent=2, default=str)
    print(f"  Saved: stats.json")
    print("")

    # Generate figures
    print("Generating figures...")
    plot_heatmap(cell_rates, args.output_dir)
    plot_forest(pw_df, args.output_dir)
    plot_interactions(df, cell_rates, args.output_dir)
    plot_per_query_reliability(df, args.output_dir)
    plot_turn_distribution(df, args.output_dir)
    plot_session_outcomes(df, args.output_dir)
    plot_cumulative_evidence(df, args.output_dir)
    print("")

    # Write tables
    print("Writing tables...")
    write_tables(df, cell_rates, pw_df, args.output_dir)
    print("")

    # Generate report
    print("Generating report...")
    generate_report(df, cell_rates, pw_df, cmh_results, logreg_results, args.output_dir, args.verified)
    print("")

    print("=== Analysis complete ===")
    print(f"  Report: {args.output_dir}/report.md")
    print(f"  Figures: {args.output_dir}/figures/")
    print(f"  Tables: {args.output_dir}/tables/")
    print(f"  Stats: {args.output_dir}/stats.json")


if __name__ == '__main__':
    main()
