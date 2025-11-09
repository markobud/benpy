# External MCP Resources for benpy Development

This document describes recommended Model Context Protocol (MCP) servers and external resources that can enhance Copilot agent capabilities when working on the benpy repository.

## Overview

External MCPs provide Copilot agents with access to additional services, tools, and data sources beyond the base GitHub capabilities. This enables agents to perform more sophisticated tasks like analyzing logs, monitoring builds, accessing package registries, and more.

---

## Recommended MCPs for benpy

### 1. **GitHub Actions MCP** (Built-in)
**Status**: ✅ Already Available  
**Purpose**: Access workflow runs, job logs, and CI/CD artifacts

**Capabilities:**
- List workflow runs and their status
- Download and analyze job logs
- Access build artifacts
- Summarize failure patterns in CI/CD
- Get workflow run details and timing

**Agent Benefits:**
- **cicd-agent**: Can diagnose build failures across platforms
- **crossplatform-compiler**: Can analyze platform-specific compilation errors
- **testing-agent**: Can review test failures and suggest fixes
- **security-agent**: Can review CodeQL scan results

**Usage Examples:**
```
# List recent workflow runs
list_workflow_runs(owner="markobud", repo="benpy", workflow_id="ci.yml")

# Get failed job logs for debugging
get_job_logs(owner="markobud", repo="benpy", run_id=12345, failed_only=true)

# Summarize what went wrong in a workflow
summarize_run_log_failures(owner="markobud", repo="benpy", run_id=12345)
```

**Configuration:**
Workflows must have proper permissions set:
```yaml
permissions:
  actions: read
  contents: read
  pull-requests: read
```

---

### 2. **PyPI Package Registry MCP**
**Status**: 🔧 External MCP Required  
**Purpose**: Access Python Package Index information

**Capabilities:**
- Check package versions and dependencies
- View package release history
- Analyze download statistics
- Compare with other similar packages
- Verify package metadata

**Agent Benefits:**
- **dev_base**: Can research compatible package versions
- **security-agent**: Can check for known vulnerabilities
- **cicd-agent**: Can verify deployment readiness

**Recommended Implementation:**
- Use PyPI JSON API: `https://pypi.org/pypi/{package}/json`
- Create custom MCP server or use REST API wrapper

**Example Queries:**
```
GET https://pypi.org/pypi/benpy/json
GET https://pypi.org/pypi/numpy/json
GET https://pypi.org/pypi/cython/json
```

---

### 3. **Build Artifact Storage MCP**
**Status**: ✅ Available via GitHub Actions  
**Purpose**: Store and retrieve build artifacts across workflow runs

**Capabilities:**
- Upload compiled binaries and wheels
- Download artifacts from previous runs
- Compare artifacts across platforms
- Store test results and coverage reports

**Agent Benefits:**
- **cicd-agent**: Can analyze build outputs
- **crossplatform-compiler**: Can compare binaries across OS
- **testing-agent**: Can access test reports

**Configuration:**
Already configured in workflows:
```yaml
- name: Upload build artifacts on failure
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: build-logs-${{ matrix.os }}-py${{ matrix.python-version }}
    path: |
      build/
      *.log
    retention-days: 7
```

---

### 4. **Log Aggregation MCP**
**Status**: 🔧 External Service Required  
**Purpose**: Centralized log collection and analysis

**Recommended Services:**
- **Option A: GitHub Actions Logs** (Built-in, already configured)
  - Accessible via GitHub Actions MCP
  - Retention: 90 days for public repos
  - Searchable via GitHub UI and API

- **Option B: External Log Aggregators** (For advanced needs)
  - Datadog Logs
  - AWS CloudWatch
  - ELK Stack (Elasticsearch, Logstash, Kibana)
  - Splunk

**Agent Benefits:**
- All agents can access logs for debugging
- Pattern recognition across multiple runs
- Historical trend analysis
- Performance bottleneck identification

**Current Setup:**
GitHub Actions logs are accessible via:
```
get_job_logs(owner="markobud", repo="benpy", job_id=12345)
```

---

### 5. **Code Quality & Security Scanning MCP**
**Status**: ✅ Configured via GitHub Actions  
**Purpose**: Static analysis, security scanning, and code quality checks

**Configured Tools:**
- **CodeQL** (Security vulnerability scanning)
  - C/C++ analysis for Bensolve library
  - Python analysis for wrapper code
  - Weekly scheduled scans
  
- **pip-audit** (Python dependency vulnerabilities)
  - Daily automated scans
  - JSON and Markdown reports
  
- **flake8** (Python code style)
  - Runs on every PR
  - Enforces PEP 8 compliance
  
- **cython-lint** (Cython code quality)
  - Validates .pyx files

**Agent Benefits:**
- **security-agent**: Full access to vulnerability reports
- **dev_base**: Code quality feedback
- **testing-agent**: Can correlate bugs with code quality issues

**Access Methods:**
```
# List security alerts
list_code_scanning_alerts(owner="markobud", repo="benpy")

# Get specific alert details
get_code_scanning_alert(owner="markobud", repo="benpy", alertNumber=1)

# List secret scanning alerts
list_secret_scanning_alerts(owner="markobud", repo="benpy")
```

---

### 6. **Performance Monitoring MCP**
**Status**: 🔧 Recommended External Tool  
**Purpose**: Profile and monitor runtime performance

**Recommended Tools:**
- **py-spy** (Python/Cython profiler)
  - Low-overhead sampling profiler
  - Can profile running processes
  - Generates flamegraphs
  
- **cProfile + snakeviz** (Built-in Python profiler)
  - Detailed function call analysis
  - Visual call graphs
  
- **valgrind** (Memory profiling for C code)
  - Memory leak detection
  - Cache performance analysis
  - Useful for Bensolve C library

**Agent Benefits:**
- **performance-agent**: Primary beneficiary
- **dev_base**: Performance-aware development
- **testing-agent**: Performance regression testing

**Integration Approach:**
Add performance testing to CI/CD:
```yaml
- name: Run performance benchmarks
  run: |
    python -m cProfile -o profile.stats src/examples/TestVLP.py
    python -m pstats profile.stats
```

---

### 7. **Documentation Build & Preview MCP**
**Status**: 🔧 Can be added to CI/CD  
**Purpose**: Build and preview documentation changes

**Recommended Setup:**
- **Sphinx** for Python documentation
- **ReadTheDocs** integration
- **GitHub Pages** for hosting

**Agent Benefits:**
- **docagent**: Can verify documentation builds correctly
- **dev_base**: Can preview API documentation
- **All agents**: Better understanding of public APIs

**Implementation:**
Create new workflow `.github/workflows/docs.yml`:
```yaml
name: Documentation Build

on:
  pull_request:
    paths:
      - '**.md'
      - 'docs/**'
      - 'src/**.py'
      - 'src/**.pyx'

jobs:
  build-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - run: pip install sphinx sphinx-rtd-theme
      - run: sphinx-build -b html docs/ docs/_build/
```

---

### 8. **GLPK Build Status MCP**
**Status**: 💡 Nice-to-Have  
**Purpose**: Monitor GLPK dependency status across platforms

**Rationale:**
benpy critically depends on GLPK. Having visibility into GLPK's status helps:
- Detect breaking changes early
- Verify compatibility with new GLPK versions
- Track platform-specific GLPK issues

**Recommended Approach:**
- Monitor GLPK release announcements
- Test against multiple GLPK versions in CI/CD
- Document GLPK version compatibility matrix

**Agent Benefits:**
- **crossplatform-compiler**: Can detect GLPK compatibility issues
- **cicd-agent**: Can adjust build scripts for new GLPK versions
- **dev_base**: Aware of dependency constraints

---

## MCP Integration Priority

### High Priority (Implement Now)
1. ✅ **GitHub Actions MCP** - Already configured
2. ✅ **Code Quality & Security Scanning** - Already configured
3. ✅ **Build Artifact Storage** - Already configured

### Medium Priority (Consider Next)
4. 🔧 **PyPI Package Registry MCP** - For version management
5. 🔧 **Performance Monitoring** - For optimization work
6. 🔧 **Documentation Build & Preview** - For documentation quality

### Low Priority (Future Enhancements)
7. 💡 **GLPK Build Status Monitoring** - For proactive maintenance
8. 💡 **External Log Aggregation** - Only if GitHub Actions logs insufficient

---

## Agent-to-MCP Mapping

This table shows which agents benefit most from each MCP:

| MCP Resource | Primary Agents | Use Cases |
|--------------|----------------|-----------|
| **GitHub Actions** | cicd-agent, crossplatform-compiler, testing-agent | Build debugging, log analysis, CI/CD optimization |
| **PyPI Registry** | dev_base, security-agent | Dependency management, vulnerability checks |
| **Build Artifacts** | cicd-agent, crossplatform-compiler | Cross-platform comparison, binary analysis |
| **Code Quality Scanning** | security-agent, dev_base | Security audits, code review |
| **Performance Monitoring** | performance-agent | Profiling, optimization |
| **Documentation Build** | docagent | Documentation validation |

---

## Accessing MCP Resources

### For GitHub Copilot Agents

Agents can access MCPs through tools provided in their context. Example workflow:

```
1. User reports: "Build is failing on Windows"

2. cicd-agent receives task:
   - Calls: list_workflow_runs() to find recent runs
   - Calls: get_job_logs() to get Windows job logs
   - Analyzes logs for error patterns
   - Calls: summarize_run_log_failures() for insights
   
3. crossplatform-compiler receives handoff:
   - Reviews log analysis from cicd-agent
   - Checks platform-specific code in src/benpy.pyx
   - Suggests fixes based on Windows compilation errors
```

### For Repository Maintainers

**Granting Access:**
1. Ensure workflows have proper permissions in `.github/workflows/*.yml`
2. Enable GitHub Actions in repository settings
3. Configure branch protection rules if needed
4. Review security settings for external MCP integrations

**Monitoring Usage:**
- Check workflow run history in GitHub Actions tab
- Review security scan results in Security tab
- Monitor artifact storage usage in Settings > Actions

---

## Security Considerations

### Best Practices

1. **Least Privilege Access**
   - Grant minimum permissions required
   - Use read-only access when possible
   - Regularly audit permissions

2. **Secret Management**
   - Never commit secrets to repository
   - Use GitHub Secrets for sensitive data
   - Rotate secrets periodically

3. **External MCP Vetting**
   - Only use trusted MCP servers
   - Review MCP permissions carefully
   - Monitor MCP usage patterns

4. **Data Privacy**
   - Avoid sending sensitive code to external services
   - Review logs before sharing
   - Use on-premises tools for sensitive projects

### Security Checklist

- [x] Workflows have read-only permissions by default
- [x] CodeQL scanning enabled for vulnerability detection
- [x] Dependency scanning enabled for supply chain security
- [x] Secret scanning enabled (GitHub native feature)
- [ ] External MCPs reviewed and approved (if adding custom ones)
- [ ] MCP access logs monitored regularly

---

## Troubleshooting MCP Access

### Common Issues

**Problem**: Agent cannot access workflow logs  
**Solution**: Check workflow permissions include `actions: read`

**Problem**: CodeQL results not visible  
**Solution**: Verify `security-events: write` permission set

**Problem**: Artifacts not uploading  
**Solution**: Check artifact retention settings and storage quota

**Problem**: External MCP not responding  
**Solution**: Verify MCP server is running and accessible

### Getting Help

1. Review workflow run logs in GitHub Actions
2. Check repository security settings
3. Consult GitHub Actions documentation
4. Contact repository maintainers
5. Review MCP-specific documentation

---

## Future MCP Opportunities

### Potential Additions

1. **Test Coverage Reporting**
   - Codecov or Coveralls integration
   - Track coverage trends over time
   - Identify untested code paths

2. **Benchmarking Database**
   - Store performance benchmarks
   - Compare performance across versions
   - Detect performance regressions

3. **Release Automation**
   - Automated version bumping
   - Changelog generation
   - PyPI deployment automation

4. **Community Metrics**
   - GitHub star/fork trends
   - Issue response times
   - Community engagement metrics

5. **Dependency Graph Analysis**
   - Visualize dependency relationships
   - Identify potential conflicts
   - Plan dependency upgrades

---

## Conclusion

This benpy repository now has comprehensive MCP integration through GitHub Actions, providing Copilot agents with access to:

✅ **Build & Test Logs** - For debugging CI/CD issues  
✅ **Security Scanning** - For vulnerability detection  
✅ **Dependency Analysis** - For supply chain security  
✅ **Code Quality Checks** - For maintaining standards  
✅ **Build Artifacts** - For cross-platform analysis  

These resources significantly enhance agent capabilities for:
- Debugging build failures
- Analyzing test results
- Identifying security vulnerabilities
- Optimizing performance
- Maintaining code quality

For questions or suggestions about MCP integration, please open an issue or contact the maintainers.

---

**Last Updated**: 2025-11-09  
**Maintained By**: benpy project maintainers
