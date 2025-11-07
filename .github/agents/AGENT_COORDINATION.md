# Agent Coordination Guide

This document helps you choose the right specialized agent for different tasks in the benpy project.

## Available Agents

### 1. Python/Cython Developer (`dev_base`)
**Use for**: General Python/Cython development, new features, API design
- Adding new wrapper functions for Bensolve C API
- Implementing new Python-facing features
- Refactoring Python/Cython code
- Creating or modifying example scripts
- General bug fixes in Python/Cython code

### 2. Cross-Platform Compiler Expert (`crossplatform-compiler`)
**Use for**: Build issues, platform-specific compilation problems
- Fixing compilation errors on specific platforms
- Resolving GLPK linking issues
- Setting up compiler flags and build options
- Handling platform-specific include/library paths
- Debugging setuptools/Cython build problems
- Cross-platform compatibility fixes

### 3. Documentation Expert (`docagent`)
**Use for**: All documentation-related tasks
- Writing or updating README
- Creating usage examples and tutorials
- Maintaining CHANGELOG
- Writing API docstrings
- Creating installation guides
- Removing outdated documentation

### 4. CI/CD Expert (`cicd-agent`)
**Use for**: Build automation and deployment
- Setting up GitHub Actions workflows
- Configuring multi-platform CI builds
- Automating package publishing to PyPI
- Setting up test automation in CI
- Troubleshooting CI/CD failures
- Optimizing build caching and performance

### 5. Testing Expert (`testing-agent`)
**Use for**: Testing and quality assurance
- Creating test suites (unit, integration)
- Writing tests for new features
- Validating numerical accuracy
- Testing edge cases and error handling
- Setting up test infrastructure
- Debugging test failures
- Improving test coverage

### 6. Security & Code Quality Expert (`security-agent`)
**Use for**: Security audits and code quality
- Finding and fixing memory safety issues
- Input validation and error handling
- Code security reviews
- Dependency vulnerability scanning
- Static analysis and linting
- Code quality improvements
- Preventing common vulnerabilities

### 7. Performance Optimization Expert (`performance-agent`)
**Use for**: Performance improvements
- Profiling and identifying bottlenecks
- Optimizing Cython code with type declarations
- Improving NumPy array operations
- Reducing memory allocations
- Adding performance benchmarks
- Algorithmic optimizations
- Memory usage optimization

## Task-to-Agent Mapping

### Common Scenarios

| Task | Primary Agent | Supporting Agents |
|------|---------------|-------------------|
| Add new VLP feature | dev_base | testing-agent, docagent |
| Fix build on Windows | crossplatform-compiler | - |
| Update README | docagent | - |
| Setup CI pipeline | cicd-agent | crossplatform-compiler |
| Make code faster | performance-agent | testing-agent |
| Fix memory leak | security-agent | testing-agent |
| Add unit tests | testing-agent | - |
| Platform-specific bug | crossplatform-compiler | dev_base |
| API documentation | docagent | dev_base |
| Package release | cicd-agent | docagent |

### Multi-Agent Workflows

#### New Feature Development
1. **dev_base**: Implement the feature
2. **testing-agent**: Create comprehensive tests
3. **security-agent**: Review for security issues
4. **docagent**: Document the new feature
5. **performance-agent**: Optimize if performance-critical

#### Build System Update
1. **crossplatform-compiler**: Update build configuration
2. **cicd-agent**: Update CI/CD workflows
3. **testing-agent**: Test builds on all platforms
4. **docagent**: Update installation instructions

#### Bug Fix Process
1. **testing-agent**: Create failing test that reproduces bug
2. **dev_base** or **security-agent**: Fix the bug (depending on type)
3. **testing-agent**: Verify fix with tests
4. **docagent**: Update CHANGELOG

#### Release Process
1. **testing-agent**: Run full test suite
2. **security-agent**: Security audit
3. **docagent**: Update CHANGELOG and version docs
4. **cicd-agent**: Trigger release build and PyPI upload

## Agent Selection Guidelines

### When to use multiple agents:
- Complex tasks spanning multiple domains (e.g., feature with docs and tests)
- Major changes requiring comprehensive review
- Release preparation
- Architecture changes

### When to use a single agent:
- Focused, domain-specific tasks
- Quick fixes in a specific area
- Documentation-only changes
- CI/CD configuration updates

### Coordination Tips:
1. **Start specific**: Use the most specialized agent first
2. **Add breadth**: Bring in supporting agents as needed
3. **Document handoffs**: When switching agents, provide context
4. **Avoid duplication**: Don't ask multiple agents to do the same task
5. **Iterate**: Some tasks may need multiple rounds with different agents

## Agent Strengths

### Best for Quick Fixes
- **docagent**: Documentation typos, quick updates
- **security-agent**: Simple input validation additions
- **testing-agent**: Adding a single test case

### Best for Complex Tasks
- **dev_base**: Major feature implementation
- **crossplatform-compiler**: Cross-platform build systems
- **performance-agent**: Algorithm optimization

### Best for Reviews
- **security-agent**: Security review of changes
- **testing-agent**: Test coverage analysis
- **docagent**: Documentation review

## Example Usage

### Example 1: "Add support for sparse matrices in VLP"
```
Agent sequence:
1. dev_base: Implement sparse matrix support in benpy.pyx
2. testing-agent: Create tests with sparse matrix inputs
3. performance-agent: Ensure sparse operations are efficient
4. docagent: Document sparse matrix usage
5. security-agent: Review for any memory issues with new code
```

### Example 2: "Build fails on macOS with M1 chip"
```
Agent sequence:
1. crossplatform-compiler: Diagnose and fix build issue
2. cicd-agent: Add M1 macOS to CI matrix if needed
3. docagent: Update installation instructions for M1 Macs
```

### Example 3: "Improve performance of large VLP solving"
```
Agent sequence:
1. performance-agent: Profile and optimize bottlenecks
2. testing-agent: Verify optimizations don't break correctness
3. testing-agent: Add performance regression tests
4. docagent: Document performance characteristics
```

### Example 4: "Security vulnerability in input handling"
```
Agent sequence:
1. security-agent: Fix vulnerability with proper validation
2. testing-agent: Add tests for the vulnerable scenario
3. docagent: Update CHANGELOG with security fix note
```

## Questions to Ask When Choosing Agents

1. **What is the primary domain?** (code, docs, build, test, security, performance)
2. **Is it cross-cutting?** (Does it touch multiple areas?)
3. **What's the complexity?** (Simple fix vs. major feature)
4. **What's the urgency?** (Hot fix vs. planned enhancement)
5. **Are there dependencies?** (Does this need other changes first?)

## Anti-Patterns to Avoid

❌ Using dev_base for build issues (use crossplatform-compiler)
❌ Using docagent to write code (use dev_base)
❌ Using performance-agent before proving there's a performance issue
❌ Skipping security-agent for code that handles user input
❌ Skipping testing-agent for new features
❌ Using cicd-agent for local development issues

## Getting Started

If you're unsure which agent to use:

1. Read the task description carefully
2. Identify the primary domain (code, docs, build, etc.)
3. Check the "Task-to-Agent Mapping" table above
4. If still unsure, start with the most specific agent for your domain
5. Add supporting agents as you discover additional needs

Remember: The goal is to leverage each agent's specialized expertise for the best results!
