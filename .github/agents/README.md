# benpy Custom Agents

This directory contains custom GitHub Copilot agents specialized for different aspects of the benpy project.

## What are Custom Agents?

Custom agents are specialized AI assistants configured with specific expertise and instructions for particular domains. When you work on benpy, you can delegate tasks to these agents to leverage their specialized knowledge.

## Available Agents

### Core Development
- **[dev_base.md](dev_base.md)** - Python/Cython Developer
  - General Python/Cython development
  - New features and API design
  - Bug fixes and refactoring

### Platform & Build
- **[crossplatform-compiler.md](crossplatform-compiler.md)** - Cross-Platform Compiler Expert
  - Build issues and compilation problems
  - Platform-specific fixes (Linux, macOS, Windows)
  - GLPK dependency configuration

- **[cicd-agent.md](cicd-agent.md)** - CI/CD Expert
  - GitHub Actions workflows
  - Automated testing and deployment
  - Multi-platform build automation

### Quality & Testing
- **[testing-agent.md](testing-agent.md)** - Testing Expert
  - Unit and integration tests
  - Numerical validation
  - Test infrastructure

- **[security-agent.md](security-agent.md)** - Security & Code Quality Expert
  - Security audits and vulnerability fixes
  - Memory safety (critical for Cython/C code)
  - Code quality and best practices

### Performance & Docs
- **[performance-agent.md](performance-agent.md)** - Performance Optimization Expert
  - Profiling and optimization
  - Cython performance tuning
  - Benchmarking

- **[docagent.md](docagent.md)** - Documentation Expert
  - README and documentation updates
  - API documentation and examples
  - Installation guides

## How to Use Agents

### Basic Usage

When working on an issue or task, consider which agent(s) are most appropriate:

1. **Identify the domain** of your task (development, build, testing, docs, etc.)
2. **Consult the coordination guide** in [AGENT_COORDINATION.md](AGENT_COORDINATION.md)
3. **Use the appropriate agent** for the task
4. **Chain agents** for complex multi-domain tasks

### Examples

**Building fails on Windows:**
→ Use `crossplatform-compiler` agent

**Adding a new feature:**
→ Use `dev_base` → `testing-agent` → `docagent`

**Optimizing slow code:**
→ Use `performance-agent` → `testing-agent`

**Security review needed:**
→ Use `security-agent`

**Writing documentation:**
→ Use `docagent`

## Agent Coordination

For complex tasks involving multiple domains, see [AGENT_COORDINATION.md](AGENT_COORDINATION.md) for:
- Task-to-agent mapping
- Multi-agent workflows
- Best practices for agent coordination
- Common scenarios and examples

## Agent Design Principles

All agents in this directory follow these principles:

1. **Specialized Expertise**: Each agent has deep knowledge in a specific domain
2. **Clear Scope**: Well-defined responsibilities and boundaries
3. **Actionable Guidance**: Specific instructions and examples
4. **Project Context**: Understanding of benpy's architecture and goals
5. **Best Practices**: Following industry standards and project conventions
6. **Minimal Changes**: Making surgical, targeted modifications

## Updating Agents

When updating agent configurations:

1. **Test changes**: Ensure agent instructions are clear and effective
2. **Maintain consistency**: Follow the established format and style
3. **Document expertise**: Clearly define what the agent can help with
4. **Provide examples**: Include concrete code examples where relevant
5. **Keep focused**: Don't make agents too broad or overlapping

## File Naming Convention

- Agent files use descriptive names: `{domain}-agent.md`
- Main agents may use shorter names: `dev_base.md`, `docagent.md`
- All agents have YAML frontmatter with name and description

## YAML Frontmatter Format

```yaml
---
name: Agent Display Name
description: Brief description of agent's purpose
---
```

## Need Help?

- See [AGENT_COORDINATION.md](AGENT_COORDINATION.md) for guidance on choosing agents
- Read individual agent files for their specific capabilities
- Consult the main [copilot-instructions.md](../copilot-instructions.md) for project overview

## Contributing

When adding new agents:

1. Identify a clear, unmet need
2. Define the agent's scope and expertise
3. Write comprehensive instructions with examples
4. Update [AGENT_COORDINATION.md](AGENT_COORDINATION.md)
5. Update this README

Avoid creating agents with overlapping responsibilities or agents that are too narrow to be useful.
