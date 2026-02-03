# .github Directory Overview

This directory contains all GitHub-specific configuration, workflows, and documentation for the benpy repository.

## 📁 Directory Structure

```
.github/
├── workflows/                    # GitHub Actions CI/CD workflows
│   ├── ci.yml                   # Build and test workflow
│   ├── codeql.yml               # Security scanning workflow
│   └── dependency-scan.yml      # Dependency audit workflow
│
├── agents/                      # Custom Copilot agent definitions
│   ├── README.md                # Agent system overview
│   ├── AGENT_COORDINATION.md    # Agent selection and coordination guide
│   ├── cicd-agent.md           # CI/CD automation expert
│   ├── crossplatform-compiler.md # Cross-platform compilation expert
│   ├── dev_base.md             # Python/Cython development expert
│   ├── docagent.md             # Documentation expert
│   ├── performance-agent.md    # Performance optimization expert
│   ├── security-agent.md       # Security and code quality expert
│   └── testing-agent.md        # Testing and QA expert
│
├── copilot-instructions.md      # Main Copilot configuration
├── COPILOT_ACCESS_SUMMARY.md    # Service access implementation summary
├── GITHUB_ACTIONS_ACCESS.md     # Complete GitHub Actions access guide
├── MCP_RESOURCES.md             # External MCP resource recommendations
├── SERVICE_ACCESS_QUICK_REF.md  # Quick reference for service access
├── AGENT_IMPROVEMENT_REPORT.md  # Agent system improvement history
└── README.md                    # This file
```

## 🚀 Quick Start

### For New Contributors
1. Read `copilot-instructions.md` for project overview
2. Review `agents/README.md` to understand available agents
3. Check `workflows/` to see CI/CD setup

### For Copilot Agents
1. Start with `SERVICE_ACCESS_QUICK_REF.md` for quick commands
2. Consult `GITHUB_ACTIONS_ACCESS.md` for detailed examples
3. Check `agents/AGENT_COORDINATION.md` for task delegation
4. Review `MCP_RESOURCES.md` for external resource options

### For Debugging CI/CD Issues
1. Use `summarize_run_log_failures()` first
2. Consult `GITHUB_ACTIONS_ACCESS.md` for tool documentation
3. Check workflow files in `workflows/` for configuration
4. Review agent coordination for specialized help

## 📚 Documentation Guide

### Core Configuration
- **copilot-instructions.md**: Main instructions for Copilot agents
  - Project overview and structure
  - Technology stack and dependencies
  - Development environment setup
  - Coding standards and best practices
  - CI/CD and service access information

### Agent System (7 Specialized Agents)
- **agents/README.md**: Overview of all agents and how to use them
- **agents/AGENT_COORDINATION.md**: How to choose and coordinate agents
- **agents/[agent-name].md**: Individual agent definitions with expertise areas

**Available Agents:**
1. `dev_base` - Python/Cython development
2. `crossplatform-compiler` - Build and compilation
3. `testing-agent` - Testing and QA
4. `security-agent` - Security and code quality
5. `performance-agent` - Performance optimization
6. `docagent` - Documentation
7. `cicd-agent` - CI/CD automation

### Service Access
- **COPILOT_ACCESS_SUMMARY.md**: Complete overview of service access setup
  - What was implemented
  - Available tools for agents
  - Agent capabilities enhanced
  - Best practices and examples
  
- **GITHUB_ACTIONS_ACCESS.md**: Detailed guide for GitHub Actions access
  - Complete tool documentation (9 tools)
  - Agent-specific workflows
  - Code examples and best practices
  - Troubleshooting guide
  
- **SERVICE_ACCESS_QUICK_REF.md**: Quick reference card
  - Common commands
  - Quick workflows
  - Agent-specific tips
  - Troubleshooting shortcuts
  
- **MCP_RESOURCES.md**: External MCP recommendations
  - 8 recommended MCPs
  - Implementation priorities
  - Agent-to-MCP mapping
  - Security considerations

### Historical Documentation
- **AGENT_IMPROVEMENT_REPORT.md**: Agent system enhancement history (Nov 2024)
  - Documents the complete agent system overhaul
  - Shows before/after comparisons
  - Describes all 7 agents and their purposes

## 🔧 GitHub Actions Workflows

### CI - Build and Test (`workflows/ci.yml`)
**Triggers**: Push to master/development, PRs, manual dispatch  
**What it does**:
- Tests on Linux, macOS, and Windows
- Supports Python 3.9, 3.10, 3.11, 3.12
- Installs GLPK automatically for each platform
- Runs example tests
- Performs code quality checks (flake8, cython-lint)
- Uploads build logs on failure

**Permissions**: `actions: read`, `contents: read`, `pull-requests: read`, `checks: write`

### CodeQL Security Analysis (`workflows/codeql.yml`)
**Triggers**: Push to master/development, PRs, weekly on Monday, manual dispatch  
**What it does**:
- Scans Python code for vulnerabilities
- Scans C/C++ code for security issues
- Uploads results to GitHub Security tab
- Creates security alerts for findings

**Permissions**: `actions: read`, `contents: read`, `security-events: write`, `pull-requests: read`

### Dependency Security Scan (`workflows/dependency-scan.yml`)
**Triggers**: Push to master/development, PRs, daily at 6 AM UTC, manual dispatch  
**What it does**:
- Reviews dependencies on PRs
- Runs pip-audit for Python package vulnerabilities
- Checks for outdated packages
- Creates reports in JSON and Markdown

**Permissions**: `actions: read`, `contents: read`, `security-events: write`, `pull-requests: write`

## 🎯 How to Use This System

### For Different Roles

#### Repository Maintainers
```
1. Monitor Actions tab for workflow runs
2. Review Security tab for alerts
3. Check PR dependency reviews before merging
4. Consult documentation when needed
5. Update workflows as project evolves
```

#### Copilot Agents
```
1. Check SERVICE_ACCESS_QUICK_REF.md for commands
2. Use summarize_run_log_failures() first for debugging
3. Follow best practices in GITHUB_ACTIONS_ACCESS.md
4. Coordinate with other agents via AGENT_COORDINATION.md
5. Access appropriate MCP resources per task
```

#### Contributors
```
1. Workflows run automatically on PR
2. Check Actions tab if CI fails
3. Review security alerts in Security tab
4. Copilot agents can help debug issues
5. Documentation explains all features
```

## 🔐 Security Configuration

### Workflow Permissions
All workflows use **least privilege** permissions:
- `actions: read` - Access workflow runs and logs
- `contents: read` - Read repository contents
- `security-events: write` - Write security scan results
- `pull-requests: read/write` - Access/update PR information
- `checks: write` - Write check run results

### Security Scanning
- **CodeQL**: Python and C/C++ analysis
- **pip-audit**: Python dependency vulnerabilities
- **Dependency Review**: PR-based dependency scanning
- **Secret Scanning**: GitHub native feature (enabled in Settings)

### Best Practices
- ✅ Minimal permissions by default
- ✅ Read-only access when possible
- ✅ Automated security scanning
- ✅ Regular dependency audits
- ✅ Security documentation

## 📊 Key Metrics

### Documentation Coverage
- **Total Files**: 18 files in .github/
- **Total Size**: ~47 KB of documentation
- **Workflows**: 3 comprehensive CI/CD pipelines
- **Agents**: 7 specialized agents
- **MCP Resources**: 8 recommended integrations

### Workflow Coverage
- **Platforms**: Linux, macOS, Windows
- **Python Versions**: 3.9, 3.10, 3.11, 3.12
- **Security Scans**: CodeQL (Python + C/C++), pip-audit
- **Frequency**: On-demand, daily, and weekly scans

### Agent Capabilities
- **GitHub Actions Access**: 9 tools available
- **Security Access**: 4 scanning tools
- **Documentation**: 5 comprehensive guides
- **Coordination**: Complete delegation system

## 🌟 Recent Updates

### November 2025: Service Access Enhancement
- ✅ Added 3 GitHub Actions workflows
- ✅ Created 5 service access documentation files
- ✅ Updated copilot-instructions.md with CI/CD section
- ✅ Enhanced AGENT_COORDINATION.md with service access
- ✅ Configured all workflows with agent access permissions

### November 2024: Agent System Overhaul
- ✅ Improved existing agents (dev_base, docagent, cicd-agent)
- ✅ Created 3 new specialized agents
- ✅ Added comprehensive coordination documentation
- ✅ Established agent selection guidelines
- ✅ Documented all agent workflows

## 🔗 Key Links

### Internal Documentation
- [Copilot Instructions](copilot-instructions.md)
- [Agent Coordination](agents/AGENT_COORDINATION.md)
- [Service Access Summary](COPILOT_ACCESS_SUMMARY.md)
- [GitHub Actions Guide](GITHUB_ACTIONS_ACCESS.md)
- [Quick Reference](SERVICE_ACCESS_QUICK_REF.md)
- [MCP Resources](MCP_RESOURCES.md)

### External Resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CodeQL Documentation](https://codeql.github.com/docs/)
- [benpy Repository](https://github.com/markobud/benpy)
- [Bensolve Project](http://www.bensolve.org/)
- [GLPK Documentation](https://www.gnu.org/software/glpk/)

## 💡 Tips and Tricks

### For Debugging
1. Always start with `summarize_run_log_failures()`
2. Use `failed_only=true` to filter job logs
3. Check patterns across multiple runs
4. Correlate failures with commit changes
5. Use platform-specific analysis for cross-platform issues

### For Agents
1. Check quick reference first for common commands
2. Delegate to specialized agents for best results
3. Use service access tools appropriate to your role
4. Follow best practices in documentation
5. Coordinate with other agents for complex tasks

### For Maintainers
1. Monitor workflow success rates
2. Review security alerts regularly
3. Keep dependencies updated
4. Update documentation when changing workflows
5. Leverage agent system for maintenance tasks

## 🆘 Getting Help

### For Workflow Issues
- Check Actions tab for run details
- Use `summarize_run_log_failures()` for AI analysis
- Consult GITHUB_ACTIONS_ACCESS.md for examples
- Review workflow YAML files for configuration

### For Agent Questions
- Read agents/README.md for overview
- Check agents/AGENT_COORDINATION.md for guidance
- Review specific agent files for capabilities
- Try delegating to the most specialized agent

### For Security Concerns
- Review Security tab for alerts
- Check CodeQL results in workflow runs
- Run pip-audit manually: `pip-audit -r requirements.txt`
- Consult security-agent for analysis

## 📝 Maintenance

### Regular Tasks
- [ ] Review workflow runs monthly
- [ ] Update dependencies quarterly
- [ ] Review and address security alerts
- [ ] Update documentation as needed
- [ ] Monitor workflow performance

### When to Update
- **Workflows**: When changing build process or adding platforms
- **Agent Definitions**: When agent behavior should change
- **Documentation**: When features change or new patterns emerge
- **Permissions**: When new features need different access

## ✅ Quality Standards

This directory maintains high standards:
- ✅ All workflows validated with yamllint
- ✅ All documentation reviewed for accuracy
- ✅ Agent definitions tested and proven
- ✅ Security best practices followed
- ✅ Comprehensive examples provided
- ✅ Regular maintenance performed

---

**Last Updated**: 2025-11-09  
**Maintained By**: benpy project team  
**Repository**: [markobud/benpy](https://github.com/markobud/benpy)
