# GitHub Actions Access Guide for Copilot Agents

This guide explains how Copilot agents can access and utilize GitHub Actions logs and resources when working on the benpy repository.

## Overview

Copilot agents have built-in tools for accessing GitHub Actions workflows, job logs, and artifacts. This document provides practical examples and best practices for utilizing these capabilities.

---

## Available Tools

### 1. Workflow Management

#### `list_workflows`
Lists all workflows in the repository.

```
list_workflows(
  owner="markobud",
  repo="benpy"
)
```

**Returns**: List of workflow IDs, names, and states

---

#### `list_workflow_runs`
Lists runs for a specific workflow.

```
list_workflow_runs(
  owner="markobud",
  repo="benpy",
  workflow_id="ci.yml",
  status="completed",    # Optional: queued, in_progress, completed
  branch="master",       # Optional: filter by branch
  event="pull_request"   # Optional: filter by trigger event
)
```

**Use Cases**:
- Find recent CI/CD runs
- Check status of builds on specific branches
- Identify patterns in workflow failures

---

#### `get_workflow_run`
Get detailed information about a specific workflow run.

```
get_workflow_run(
  owner="markobud",
  repo="benpy",
  run_id=12345
)
```

**Returns**:
- Run status (success, failure, cancelled)
- Trigger event and branch
- Start/end times
- Associated commit SHA
- Conclusion and summary

---

### 2. Job Management

#### `list_workflow_jobs`
Lists all jobs in a workflow run.

```
list_workflow_jobs(
  owner="markobud",
  repo="benpy",
  run_id=12345,
  filter="latest"  # or "all"
)
```

**Returns**: List of jobs with their:
- Job ID and name
- Status and conclusion
- Start/end times
- Runner information (OS, platform)

**Use Cases**:
- Identify which specific job failed
- Find platform-specific failures
- Analyze job timing and performance

---

### 3. Log Access

#### `get_job_logs`
Download and analyze logs from workflow jobs.

```
get_job_logs(
  owner="markobud",
  repo="benpy",
  job_id=67890,
  return_content=true,
  tail_lines=500
)
```

**Options**:
- `job_id`: Specific job to get logs from
- `run_id` + `failed_only=true`: Get all failed job logs
- `tail_lines`: Number of lines from end (default: 500)
- `return_content`: Return actual logs vs. URLs

**Use Cases**:
- Debugging compilation errors
- Analyzing test failures
- Finding error patterns

---

#### `get_workflow_run_logs`
Download all logs for a workflow run (⚠️ EXPENSIVE).

```
# WARNING: Downloads ALL logs as ZIP
# Use get_job_logs with failed_only=true instead

get_workflow_run_logs(
  owner="markobud",
  repo="benpy",
  run_id=12345
)
```

**Note**: This downloads a complete ZIP archive of all logs. For most debugging tasks, use `get_job_logs` with `failed_only=true` instead.

---

#### `summarize_run_log_failures` (RECOMMENDED)
AI-powered analysis of workflow failures.

```
summarize_run_log_failures(
  owner="markobud",
  repo="benpy",
  run_id=12345
)
```

**Returns**:
- Summary of what went wrong
- Key error messages
- Suggested fixes
- Related file locations

**Best Practice**: Use this FIRST when debugging failures instead of manually reviewing logs.

---

#### `summarize_job_log_failures`
AI-powered analysis of specific job failures.

```
summarize_job_log_failures(
  owner="markobud",
  repo="benpy",
  run_id=12345,
  job_id=67890
)
```

**Use Cases**:
- Focus on specific platform failures
- Deep dive into a particular failing job
- Get targeted suggestions for fixes

---

### 4. Artifact Management

#### `list_workflow_run_artifacts`
Lists artifacts uploaded during a workflow run.

```
list_workflow_run_artifacts(
  owner="markobud",
  repo="benpy",
  run_id=12345
)
```

**Returns**: Artifacts with:
- Artifact ID and name
- Size and expiration date
- Download URL

---

#### `download_workflow_run_artifact`
Download a specific artifact.

```
download_workflow_run_artifact(
  owner="markobud",
  repo="benpy",
  artifact_id=99999
)
```

**Use Cases**:
- Download build logs for analysis
- Retrieve compiled binaries
- Access test reports

---

## Workflow Examples for Agents

### Example 1: Debugging a Failed CI Build

**Scenario**: User reports "CI is failing on the latest PR"

**Agent Workflow**:

```python
# Step 1: Find recent workflow runs
runs = list_workflow_runs(
  owner="markobud",
  repo="benpy",
  workflow_id="ci.yml",
  status="completed"
)

# Step 2: Get the latest failed run
failed_run_id = runs[0]['id']

# Step 3: Get AI-powered failure summary (BEST PRACTICE)
summary = summarize_run_log_failures(
  owner="markobud",
  repo="benpy",
  run_id=failed_run_id
)

# Step 4: If more detail needed, get specific job logs
jobs = list_workflow_jobs(
  owner="markobud",
  repo="benpy",
  run_id=failed_run_id
)

# Find failed jobs
failed_jobs = [j for j in jobs if j['conclusion'] == 'failure']

# Step 5: Get logs for failed jobs only
for job in failed_jobs:
  logs = get_job_logs(
    owner="markobud",
    repo="benpy",
    job_id=job['id'],
    return_content=true,
    tail_lines=100
  )
  # Analyze logs...
```

---

### Example 2: Cross-Platform Build Comparison

**Scenario**: Build passes on Linux but fails on Windows

**Agent Workflow**:

```python
# Step 1: Get the workflow run
run_id = 12345

# Step 2: List all jobs
jobs = list_workflow_jobs(
  owner="markobud",
  repo="benpy",
  run_id=run_id
)

# Step 3: Separate by platform
linux_jobs = [j for j in jobs if 'ubuntu' in j['name']]
windows_jobs = [j for j in jobs if 'windows' in j['name']]
macos_jobs = [j for j in jobs if 'macos' in j['name']]

# Step 4: Compare results
for platform, jobs_list in [
  ("Linux", linux_jobs),
  ("Windows", windows_jobs),
  ("macOS", macos_jobs)
]:
  passed = sum(1 for j in jobs_list if j['conclusion'] == 'success')
  failed = sum(1 for j in jobs_list if j['conclusion'] == 'failure')
  print(f"{platform}: {passed} passed, {failed} failed")

# Step 5: Get Windows-specific failure details
windows_failed = [j for j in windows_jobs if j['conclusion'] == 'failure']
for job in windows_failed:
  summary = summarize_job_log_failures(
    owner="markobud",
    repo="benpy",
    run_id=run_id,
    job_id=job['id']
  )
  # Analyze Windows-specific issues...
```

---

### Example 3: Analyzing Test Failures

**Scenario**: Tests are failing intermittently

**Agent Workflow**:

```python
# Step 1: Get recent test runs
runs = list_workflow_runs(
  owner="markobud",
  repo="benpy",
  workflow_id="ci.yml",
  per_page=20
)

# Step 2: Analyze failure patterns
failure_patterns = {}
for run in runs:
  if run['conclusion'] == 'failure':
    jobs = list_workflow_jobs(
      owner="markobud",
      repo="benpy",
      run_id=run['id']
    )
    
    failed_jobs = [j for j in jobs if j['conclusion'] == 'failure']
    for job in failed_jobs:
      # Get failure details
      logs = get_job_logs(
        owner="markobud",
        repo="benpy",
        job_id=job['id'],
        tail_lines=200
      )
      
      # Extract error patterns (simplified)
      for line in logs.split('\n'):
        if 'ERROR' in line or 'FAILED' in line:
          # Track pattern...
          pass

# Step 3: Report findings
# Identify most common failure types
# Suggest fixes for recurring issues
```

---

### Example 4: Build Artifact Analysis

**Scenario**: Need to compare build outputs across platforms

**Agent Workflow**:

```python
# Step 1: Get the workflow run
run_id = 12345

# Step 2: List available artifacts
artifacts = list_workflow_run_artifacts(
  owner="markobud",
  repo="benpy",
  run_id=run_id
)

# Step 3: Download build logs from failed builds
for artifact in artifacts:
  if 'build-logs' in artifact['name'] and 'windows' in artifact['name']:
    # Download artifact
    download_workflow_run_artifact(
      owner="markobud",
      repo="benpy",
      artifact_id=artifact['id']
    )
    # Analyze build logs...
```

---

## Agent-Specific Workflows

### cicd-agent (CI/CD Expert)

**Primary Tasks**:
- Debug workflow failures
- Optimize workflow performance
- Configure new workflows

**Key Tools**:
- `summarize_run_log_failures` - First line of defense
- `list_workflow_runs` - Track workflow history
- `get_workflow_run` - Analyze run performance

**Example Task**: "Fix the failing Windows build"

```python
# 1. Find latest Windows failure
runs = list_workflow_runs(
  owner="markobud",
  repo="benpy",
  workflow_id="ci.yml"
)

# 2. Get failure summary
summary = summarize_run_log_failures(
  owner="markobud",
  repo="benpy",
  run_id=runs[0]['id']
)

# 3. Analyze summary and suggest fixes
# 4. Update workflow YAML if needed
```

---

### crossplatform-compiler (Compilation Expert)

**Primary Tasks**:
- Fix platform-specific build errors
- Optimize compilation flags
- Resolve dependency issues

**Key Tools**:
- `get_job_logs` with `failed_only=true`
- `list_workflow_jobs` - Identify failing platforms
- `summarize_job_log_failures` - Platform-specific analysis

**Example Task**: "Windows compilation is failing with GLPK errors"

```python
# 1. Get Windows job logs
jobs = list_workflow_jobs(
  owner="markobud",
  repo="benpy",
  run_id=12345
)

windows_jobs = [j for j in jobs if 'windows' in j['name']]

# 2. Get detailed failure analysis
for job in windows_jobs:
  if job['conclusion'] == 'failure':
    analysis = summarize_job_log_failures(
      owner="markobud",
      repo="benpy",
      run_id=12345,
      job_id=job['id']
    )
    
    # 3. Look for GLPK-related errors in analysis
    # 4. Suggest Windows-specific compilation fixes
```

---

### testing-agent (Testing Expert)

**Primary Tasks**:
- Analyze test failures
- Identify flaky tests
- Improve test coverage

**Key Tools**:
- `get_job_logs` - Extract test output
- `list_workflow_jobs` - Find test jobs
- `summarize_job_log_failures` - Understand test failures

**Example Task**: "TestVLP.py is failing on macOS"

```python
# 1. Find macOS test runs
runs = list_workflow_runs(
  owner="markobud",
  repo="benpy",
  workflow_id="ci.yml"
)

# 2. Get test job details
jobs = list_workflow_jobs(
  owner="markobud",
  repo="benpy",
  run_id=runs[0]['id']
)

macos_jobs = [j for j in jobs if 'macos' in j['name']]

# 3. Get test failure details
for job in macos_jobs:
  if job['conclusion'] == 'failure':
    logs = get_job_logs(
      owner="markobud",
      repo="benpy",
      job_id=job['id'],
      tail_lines=500
    )
    
    # 4. Extract test failure information
    # Look for "FAILED", "ERROR", "Traceback"
    # Identify which test failed and why
```

---

### security-agent (Security Expert)

**Primary Tasks**:
- Review security scan results
- Analyze CodeQL alerts
- Check dependency vulnerabilities

**Key Tools**:
- `list_code_scanning_alerts` - View CodeQL results
- `get_code_scanning_alert` - Get alert details
- `list_secret_scanning_alerts` - Check for exposed secrets
- `get_job_logs` - Review security scan logs

**Example Task**: "Review CodeQL security alerts"

```python
# 1. List current security alerts
alerts = list_code_scanning_alerts(
  owner="markobud",
  repo="benpy",
  state="open"
)

# 2. Analyze each alert
for alert in alerts:
  details = get_code_scanning_alert(
    owner="markobud",
    repo="benpy",
    alertNumber=alert['number']
  )
  
  # 3. Assess severity and impact
  # 4. Suggest fixes
  # 5. Prioritize remediation
```

---

## Best Practices

### 1. Always Start with Summarization
❌ **Don't**: Immediately download full logs  
✅ **Do**: Use `summarize_run_log_failures` first

```python
# Good approach
summary = summarize_run_log_failures(owner="markobud", repo="benpy", run_id=12345)
# Review summary, then dig deeper if needed

# Avoid unless necessary
logs = get_workflow_run_logs(owner="markobud", repo="benpy", run_id=12345)
```

---

### 2. Filter for Failed Jobs Only
❌ **Don't**: Get logs from all jobs  
✅ **Do**: Use `failed_only=true` parameter

```python
# Efficient
logs = get_job_logs(
  owner="markobud",
  repo="benpy",
  run_id=12345,
  failed_only=true
)
```

---

### 3. Use Tail Lines Appropriately
❌ **Don't**: Get entire log files unnecessarily  
✅ **Do**: Request only needed lines

```python
# For error messages, last 100-500 lines usually sufficient
logs = get_job_logs(
  owner="markobud",
  repo="benpy",
  job_id=67890,
  tail_lines=200
)
```

---

### 4. Analyze Patterns Across Runs
❌ **Don't**: Focus on single run in isolation  
✅ **Do**: Look for trends across multiple runs

```python
# Get recent history
runs = list_workflow_runs(
  owner="markobud",
  repo="benpy",
  workflow_id="ci.yml",
  per_page=10
)

# Analyze failure trends
failure_rate = sum(1 for r in runs if r['conclusion'] == 'failure') / len(runs)
```

---

### 5. Correlate with Code Changes
❌ **Don't**: Analyze logs without context  
✅ **Do**: Check associated commits and PRs

```python
# Get run details
run = get_workflow_run(
  owner="markobud",
  repo="benpy",
  run_id=12345
)

# Check what changed
commit_sha = run['head_sha']
# Review commit changes to understand potential causes
```

---

## Common Failure Patterns

### Pattern 1: GLPK Installation Failures

**Symptoms**:
- "glpk.h: No such file or directory"
- "cannot find -lglpk"
- Windows: "GLPK not found"

**Investigation**:
```python
logs = get_job_logs(owner="markobud", repo="benpy", job_id=X, tail_lines=200)
# Look for GLPK installation step output
```

**Common Causes**:
- Package manager issues
- Environment variables not set
- Platform-specific path problems

---

### Pattern 2: Cython Compilation Errors

**Symptoms**:
- "error: command 'gcc' failed"
- "unable to find vcvarsall.bat" (Windows)
- Segmentation faults

**Investigation**:
```python
summary = summarize_job_log_failures(
  owner="markobud",
  repo="benpy",
  run_id=12345,
  job_id=67890
)
# Look for C compilation errors, linker errors
```

---

### Pattern 3: Test Failures

**Symptoms**:
- "FAILED src/examples/TestVLP.py"
- "AssertionError"
- Numerical precision issues

**Investigation**:
```python
logs = get_job_logs(owner="markobud", repo="benpy", job_id=X)
# Extract test output, look for "FAILED", "ERROR", "Traceback"
```

---

## Troubleshooting Access Issues

### Issue: "Permission denied" when accessing logs

**Solution**: Check workflow permissions in `.github/workflows/*.yml`:

```yaml
permissions:
  actions: read
  contents: read
```

---

### Issue: "Workflow run not found"

**Solution**: Verify run ID is correct:

```python
# List recent runs to find correct ID
runs = list_workflow_runs(owner="markobud", repo="benpy", workflow_id="ci.yml")
```

---

### Issue: "Logs expired"

**Note**: GitHub Actions logs are retained for:
- 90 days for public repositories
- 400 days for GitHub Enterprise

Artifacts have configurable retention (default 90 days in this repo).

---

## Additional Resources

- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Workflow Syntax**: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- **GitHub REST API**: https://docs.github.com/en/rest
- **benpy CI/CD Workflows**: `.github/workflows/`

---

**Last Updated**: 2025-11-09  
**Maintained By**: benpy project maintainers
