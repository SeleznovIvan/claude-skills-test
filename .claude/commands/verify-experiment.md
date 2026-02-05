# Verify Experiment Sessions

Verify all sessions from the replication experiment v2 by checking actual Skill tool usage via cclogviewer MCP.

## Instructions

1. Read the verification manifest (or all JSONL files) to get session IDs:
   - Check if `results/replication-experiment/data/verification_manifest.json` exists
   - If not, read all `results/replication-experiment/data/*/results.jsonl` files

2. For each session ID, call `mcp__cclogviewer__get_tool_usage_stats` with the session ID

3. For each session, determine if the Skill tool was invoked:
   - Check if "Skill" appears in the tool usage stats
   - A session counts as "skill invoked" if the Skill tool has at least 1 successful call

4. Collect all verification results into a JSON object:
   ```json
   {
     "session_id_1": {"skill_invoked": true, "skill_tool_calls": 1},
     "session_id_2": {"skill_invoked": false, "skill_tool_calls": 0},
     ...
   }
   ```

5. Write results to `results/replication-experiment/data/verification_results.json`

6. Then run the verification script to apply results:
   ```bash
   results/replication-experiment/.venv/bin/python3 results/replication-experiment/verify-sessions.py \
     --results-dir results/replication-experiment/data/ \
     --output-dir results/replication-experiment/data/verified/
   ```

## Notes

- Process sessions in batches of 50 to manage context
- Skip sessions with empty session IDs
- If a session is not found in cclogviewer, mark it as `skill_invoked: false`
- Report progress every 100 sessions
