---
name: checking-ci-jobs
description: Debug and inspect GitHub Actions CI job failures using gh CLI. Use when user provides a GitHub Actions URL (e.g., github.com/*/actions/runs/*), asks to check CI status, debug a failing build, view workflow run logs, or investigate why a CI job failed.
---

# Checking CI Jobs with gh CLI

Inspect GitHub Actions workflow runs and job logs using the `gh` CLI. Useful for debugging CI failures when the GitHub web UI isn't directly accessible (e.g., from a terminal or when `read_web_page` returns 404 for authenticated pages).

## Prerequisites

1. `gh` CLI must be installed: `gh --version`
2. `gh` must be authenticated: `gh auth status`

## Parsing CI URLs

GitHub Actions URLs follow these patterns:

| URL Pattern | IDs to Extract |
|---|---|
| `github.com/{owner}/{repo}/actions/runs/{run_id}` | run ID |
| `github.com/{owner}/{repo}/actions/runs/{run_id}/job/{job_id}` | run ID + job ID |
| `github.com/{owner}/{repo}/actions/runs/{run_id}/job/{job_id}?pr={pr_number}` | run ID + job ID + PR number |

Extract `owner/repo`, `run_id`, and `job_id` from the URL before running commands.

## Core Commands

### View run summary

```bash
gh run view {run_id} --repo {owner}/{repo}
```

### View failed job logs (most useful for debugging)

```bash
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log-failed
```

This shows only the log output from failed steps — typically the most useful starting point.

### View full job logs

```bash
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log
```

**Tip:** Pipe through `tail` or `grep` to manage large output:

```bash
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log-failed 2>&1 | tail -100
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log 2>&1 | grep -i "error"
```

### List jobs in a run

```bash
gh run view {run_id} --repo {owner}/{repo} --json jobs --jq '.jobs[] | {name, databaseId, conclusion}'
```

### View run status as JSON

```bash
gh run view {run_id} --repo {owner}/{repo} --json conclusion,status,name,displayTitle,url
```

### List recent runs for a workflow

```bash
gh run list --repo {owner}/{repo} --workflow {workflow_name} --limit 10
```

### List failed runs

```bash
gh run list --repo {owner}/{repo} --status failure --limit 10
```

## Debugging Workflow

1. **Start with `--log-failed`** to see only the failing steps
2. **Identify the error** in the output (look for `ERROR:`, `fatal`, `bbfatal`, exit codes)
3. **Check the PR diff** if the failure is in a PR context: `gh pr diff {pr_number} --repo {owner}/{repo}`
4. **Compare with the workflow file** to understand what the failing step does
5. **Check recent changes** to the workflow or related files that may have caused the regression

## Related Commands

```bash
# View PR checks status
gh pr checks {pr_number} --repo {owner}/{repo}

# Re-run failed jobs
gh run rerun {run_id} --repo {owner}/{repo} --failed

# Watch a run in progress
gh run watch {run_id} --repo {owner}/{repo}

# Download run logs as zip
gh run view {run_id} --repo {owner}/{repo} --log > logs.txt
```
