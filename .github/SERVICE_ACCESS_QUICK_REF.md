# Service Access Quick Reference for Copilot Agents

Quick reference card for accessing external services and resources in the benpy repository.

## 🚀 Quick Commands

### Debug Build Failures
```python
# BEST: AI-powered failure analysis
summarize_run_log_failures(owner="markobud", repo="benpy", run_id=RUN_ID)

# Get all failed job logs
get_job_logs(owner="markobud", repo="benpy", run_id=RUN_ID, failed_only=true)

# Analyze specific job failure
summarize_job_log_failures(owner="markobud", repo="benpy", run_id=RUN_ID, job_id=JOB_ID)
```

### Check CI/CD Status
```python
# List recent workflow runs
list_workflow_runs(owner="markobud", repo="benpy", workflow_id="ci.yml")

# Get run details
get_workflow_run(owner="markobud", repo="benpy", run_id=RUN_ID)

# List jobs in a run
list_workflow_jobs(owner="markobud", repo="benpy", run_id=RUN_ID)
```

### Security Scanning
```python
# List open security alerts
list_code_scanning_alerts(owner="markobud", repo="benpy", state="open")

# Get alert details
get_code_scanning_alert(owner="markobud", repo="benpy", alertNumber=ALERT_NUM)

# Check for exposed secrets
list_secret_scanning_alerts(owner="markobud", repo="benpy")
```

### Artifacts
```python
# List available artifacts
list_workflow_run_artifacts(owner="markobud", repo="benpy", run_id=RUN_ID)

# Download artifact
download_workflow_run_artifact(owner="markobud", repo="benpy", artifact_id=ARTIFACT_ID)
```

---

## 📋 Common Workflows

### 1. "CI is failing on PR #X"
```python
# Step 1: Find the PR's workflow runs
runs = list_workflow_runs(owner="markobud", repo="benpy", workflow_id="ci.yml")

# Step 2: Get failure summary
summary = summarize_run_log_failures(owner="markobud", repo="benpy", run_id=runs[0]['id'])

# Step 3: Analyze and fix
# Review summary, identify issue, make changes
```

### 2. "Build works on Linux but fails on Windows"
```python
# Step 1: Get the run
jobs = list_workflow_jobs(owner="markobud", repo="benpy", run_id=RUN_ID)

# Step 2: Find Windows job
windows_job = [j for j in jobs if 'windows' in j['name'] and j['conclusion'] == 'failure'][0]

# Step 3: Analyze Windows-specific failure
analysis = summarize_job_log_failures(
  owner="markobud", 
  repo="benpy", 
  run_id=RUN_ID, 
  job_id=windows_job['id']
)
```

### 3. "New security alert appeared"
```python
# Step 1: List all alerts
alerts = list_code_scanning_alerts(owner="markobud", repo="benpy", state="open")

# Step 2: Get details for new alert
alert_details = get_code_scanning_alert(
  owner="markobud", 
  repo="benpy", 
  alertNumber=alerts[0]['number']
)

# Step 3: Fix the vulnerability
# Review alert details, location, and suggested fixes
```

---

## 🎯 Agent-Specific Quick Reference

### cicd-agent
**Primary Tools**: `summarize_run_log_failures`, `list_workflow_runs`, `get_job_logs`  
**Use For**: CI/CD debugging, workflow optimization, build automation

### crossplatform-compiler
**Primary Tools**: `get_job_logs`, `list_workflow_jobs`, `summarize_job_log_failures`  
**Use For**: Platform-specific compilation errors, GLPK issues, linker problems

### testing-agent
**Primary Tools**: `get_job_logs`, `list_workflow_jobs`  
**Use For**: Test failure analysis, flaky test detection, test result patterns

### security-agent
**Primary Tools**: `list_code_scanning_alerts`, `get_code_scanning_alert`, `list_secret_scanning_alerts`  
**Use For**: Security vulnerability analysis, dependency audits, code quality

### performance-agent
**Primary Tools**: `get_workflow_run`, `list_workflow_jobs`  
**Use For**: Build timing analysis, performance regression detection

---

## ⚡ Best Practices

### DO ✅
- **Start with summarization tools** (`summarize_run_log_failures`)
- **Filter for failures** (`failed_only=true`)
- **Use tail_lines** to limit log output (100-500 lines usually enough)
- **Check patterns** across multiple runs
- **Correlate with commits** to identify root causes

### DON'T ❌
- **Don't download full logs** unless necessary
- **Don't analyze single run in isolation** - check trends
- **Don't skip summarization** - it saves time
- **Don't ignore platform patterns** - check all OS/versions

---

## 📊 Available Workflows

| Workflow | Trigger | Purpose | Agent Use |
|----------|---------|---------|-----------|
| **ci.yml** | push, PR | Build & test across platforms | cicd-agent, crossplatform-compiler, testing-agent |
| **codeql.yml** | push, PR, weekly | Security scanning | security-agent |
| **dependency-scan.yml** | push, PR, daily | Dependency vulnerabilities | security-agent, dev_base |

---

## 🔧 Troubleshooting

### Can't access logs
**Check**: Workflow has `actions: read` permission

### Logs expired
**Note**: Logs retained for 90 days (public repos)

### Run ID not found
**Fix**: Use `list_workflow_runs` to find correct ID

### Too much data
**Solution**: Use `tail_lines` parameter and `failed_only=true`

---

## 📚 Full Documentation

- **Complete Guide**: `.github/GITHUB_ACTIONS_ACCESS.md`
- **MCP Resources**: `.github/MCP_RESOURCES.md`
- **Workflow Files**: `.github/workflows/`

---

## 💡 Quick Tips

1. **Always summarize first**: `summarize_run_log_failures` is your friend
2. **Platform matters**: Check OS in job name for cross-platform issues
3. **Look for patterns**: Recent history shows trends
4. **Context is key**: Check commit changes that triggered failure
5. **Artifacts help**: Download build logs for deep analysis

---

**Repository**: markobud/benpy  
**Last Updated**: 2025-11-09
