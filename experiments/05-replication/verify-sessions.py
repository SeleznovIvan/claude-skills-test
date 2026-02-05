#!/usr/bin/env python3
"""
verify-sessions.py — Session verification for replication experiment.

Reads raw JSONL files, verifies each session via cclogviewer MCP tool usage stats,
and writes verified JSONL with ground-truth skill invocation status.

Since MCP tools only work inside Claude Code, this script is meant to be run
via the .claude/commands/verify-experiment.md slash command, which instructs
Claude Code to iterate sessions and call the MCP tools.

This script can also process pre-verified data (if verification was done via
the slash command and results written to verified/ directory).

Usage:
    .venv/bin/python3 verify-sessions.py --results-dir data/ --output-dir data/verified/

    # Or just validate existing verified data:
    .venv/bin/python3 verify-sessions.py --results-dir data/ --output-dir data/verified/ --validate-only
"""

import argparse
import json
import os
import sys
from pathlib import Path

VARIANTS = ['a', 'b', 'c']
CONDITIONS = ['c1', 'c2', 'c3', 'c4']


def load_raw_results(results_dir):
    """Load all raw JSONL files."""
    all_results = {}
    for v in VARIANTS:
        for c in CONDITIONS:
            key = f'{v}-{c}'
            path = Path(results_dir) / key / 'results.jsonl'
            if not path.exists():
                print(f"  Warning: {path} not found")
                continue
            rows = []
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if line:
                        try:
                            rows.append(json.loads(line))
                        except json.JSONDecodeError:
                            print(f"  Warning: bad JSON in {path}")
            all_results[key] = rows
            print(f"  {key}: {len(rows)} trials")
    return all_results


def extract_session_ids(all_results):
    """Extract all unique session IDs that need verification."""
    session_ids = set()
    for key, rows in all_results.items():
        for row in rows:
            sid = row.get('session_id', '')
            if sid:
                session_ids.add(sid)
    return sorted(session_ids)


def write_verification_manifest(session_ids, output_path):
    """Write a manifest of session IDs for Claude Code to verify."""
    with open(output_path, 'w') as f:
        json.dump({
            'total': len(session_ids),
            'session_ids': session_ids
        }, f, indent=2)
    print(f"  Manifest written: {output_path} ({len(session_ids)} sessions)")


def apply_verification(all_results, verification_results, output_dir):
    """Apply verification results to raw data and write verified JSONL."""
    for key, rows in all_results.items():
        verified_rows = []
        for row in rows:
            verified_row = row.copy()
            sid = row.get('session_id', '')
            if sid in verification_results:
                vr = verification_results[sid]
                verified_row['skill_invoked_verified'] = vr.get('skill_invoked', False)
                verified_row['verification_method'] = 'cclogviewer'
                verified_row['skill_tool_calls'] = vr.get('skill_tool_calls', 0)
            else:
                # Fall back to heuristic
                verified_row['skill_invoked_verified'] = row.get('skill_invoked_heuristic', False)
                verified_row['verification_method'] = 'heuristic_fallback'
                verified_row['skill_tool_calls'] = None

            # Update success based on verified status
            verified_row['success'] = verified_row['skill_invoked_verified']
            verified_rows.append(verified_row)

        # Write verified JSONL
        out_path = Path(output_dir) / key / 'results.jsonl'
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, 'w') as f:
            for row in verified_rows:
                f.write(json.dumps(row) + '\n')
        print(f"  {key}: {len(verified_rows)} verified trials -> {out_path}")


def validate_verified(output_dir):
    """Validate existing verified JSONL files."""
    total = 0
    total_verified = 0
    total_fallback = 0

    for v in VARIANTS:
        for c in CONDITIONS:
            key = f'{v}-{c}'
            path = Path(output_dir) / key / 'results.jsonl'
            if not path.exists():
                print(f"  MISSING: {path}")
                continue
            rows = []
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if line:
                        rows.append(json.loads(line))

            n = len(rows)
            n_verified = sum(1 for r in rows if r.get('verification_method') == 'cclogviewer')
            n_fallback = sum(1 for r in rows if r.get('verification_method') == 'heuristic_fallback')
            n_success = sum(1 for r in rows if r.get('skill_invoked_verified', False))

            total += n
            total_verified += n_verified
            total_fallback += n_fallback

            print(f"  {key}: {n} trials, {n_verified} verified, {n_fallback} fallback, {n_success} successes")

    print(f"\n  Total: {total} trials, {total_verified} verified, {total_fallback} fallback")
    return total > 0


def main():
    parser = argparse.ArgumentParser(description='Verify experiment sessions')
    parser.add_argument('--results-dir', required=True, help='Path to data/ directory with raw JSONL')
    parser.add_argument('--output-dir', required=True, help='Path to data/verified/ output directory')
    parser.add_argument('--validate-only', action='store_true', help='Only validate existing verified data')
    parser.add_argument('--write-manifest', action='store_true',
                       help='Write manifest of session IDs for Claude Code verification')
    args = parser.parse_args()

    if args.validate_only:
        print("=== Validating verified data ===")
        validate_verified(args.output_dir)
        return

    print("=== Loading raw results ===")
    all_results = load_raw_results(args.results_dir)

    if args.write_manifest:
        session_ids = extract_session_ids(all_results)
        manifest_path = Path(args.results_dir) / 'verification_manifest.json'
        write_verification_manifest(session_ids, manifest_path)
        print("\nManifest written. Use .claude/commands/verify-experiment.md to run verification.")
        return

    # Check if verification results exist
    verification_path = Path(args.results_dir) / 'verification_results.json'
    if verification_path.exists():
        print(f"\nLoading verification results from {verification_path}")
        with open(verification_path) as f:
            verification_results = json.load(f)
        print(f"  {len(verification_results)} sessions verified")

        print("\nApplying verification...")
        apply_verification(all_results, verification_results, args.output_dir)
    else:
        print(f"\nNo verification results found at {verification_path}")
        print("Options:")
        print("  1. Run: .venv/bin/python3 verify-sessions.py --results-dir data/ --output-dir data/verified/ --write-manifest")
        print("  2. Then use /verify-experiment slash command in Claude Code")
        print("  3. Then re-run this script to apply results")

    print("\n=== Validating output ===")
    validate_verified(args.output_dir)


if __name__ == '__main__':
    main()
