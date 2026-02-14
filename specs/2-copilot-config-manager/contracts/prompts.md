# Prompt Specifications: Copilot Config Manager

**Feature**: Copilot Config Manager  
**Spec Directory**: `specs/2-copilot-config-manager`  
**Date**: January 22, 2026

## Overview

This document specifies the Copilot prompt files that comprise the Copilot Config Manager. Each prompt is a `.prompt.md` file that users invoke via Copilot Chat to manage their repository's Copilot configuration.

---

## Prompt File Location

All prompts are stored in `.github/prompts/copilot-config/` and can be invoked using the `/` command in Copilot Chat.

---

## Prompts

### 1. `cpcontext.scan-configs.prompt.md`

**Purpose**: Discover existing Copilot configuration files in the repository.

```yaml
---
description: 'Scan repository for existing Copilot configuration files'
agent: 'agent'
tools: ['read', 'search']
---
```

**Prompt Content**:

```markdown
Scan this repository for GitHub Copilot configuration files and provide a summary.

## Files to Locate

1. **Repository-wide instructions**: `.github/copilot-instructions.md`
2. **Path-specific instructions**: `.github/instructions/*.instructions.md`
3. **Agent configurations**: `.github/agents/*.agent.md`
4. **Prompt files**: `.github/prompts/*.prompt.md` and `.github/prompts/**/*.prompt.md`
5. **Other agent files**: `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` in repository root

## Output Format

Provide a summary table:

| Configuration Type | Files Found | Locations |
|-------------------|-------------|-----------|
| Repository-wide instructions | Yes/No | path |
| Path-specific instructions | count | paths |
| Agent configurations | count | paths |
| Prompt files | count | paths |

For each file found, report:
- File path
- Description (from frontmatter if available)
- Key configuration details (applyTo patterns, tools, etc.)

If no configuration files are found, suggest starting with `cpcontext.create-instructions.prompt.md`.
```

---

### 2. `cpcontext.analyze-technologies.prompt.md`

**Purpose**: Detect languages, frameworks, and libraries to recommend appropriate configurations.

```yaml
---
description: 'Analyze repository technologies and recommend Copilot configurations'
agent: 'agent'
tools: ['read', 'search']
---
```

**Prompt Content**:

```markdown
Analyze this repository to detect technologies and recommend appropriate Copilot configurations.

## Detection Steps

1. **Languages**: Scan for file extensions (.py, .ts, .js, .go, .rs, .java, .rb, etc.)
2. **Package Manifests**: Read `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `Gemfile`
3. **Frameworks**: Identify from dependencies (React, FastAPI, Django, Express, etc.)
4. **Configuration Files**: Check for `tsconfig.json`, `.eslintrc`, `pytest.ini`, etc.
5. **Testing Tools**: Identify test frameworks (pytest, jest, vitest, etc.)

## Output Format

### Detected Technologies

| Category | Technology | Version | Confidence | Evidence |
|----------|------------|---------|------------|----------|
| Language | Python | 3.11 | High | pyproject.toml |
| Framework | FastAPI | 0.109 | High | requirements.txt |
| Testing | pytest | - | High | pytest.ini |

### Recommended Configurations

For each detected technology, recommend:

1. **Instructions file**: `{technology}.instructions.md` with specific coding guidelines
2. **Agent** (if applicable): Specialized agent for complex frameworks
3. **Prompts** (if applicable): Common task prompts for the technology

Priority:
- **P1**: Primary language/framework configurations
- **P2**: Testing and documentation configurations
- **P3**: Specialized agents for complex workflows
```

---

### 3. `cpcontext.create-instructions.prompt.md`

**Purpose**: Create a new Copilot instructions file with proper frontmatter.

```yaml
---
description: 'Create a new Copilot instructions file'
agent: 'agent'
tools: ['read', 'edit']
argument-hint: 'Enter technology name (e.g., python, typescript, react)'
---
```

**Prompt Content**:

```markdown
Create a Copilot instructions file for the specified technology.

## User Input Required

Technology: {{technology}}

## File Creation

Create `.github/instructions/{{technology}}.instructions.md` with:

### Frontmatter

```yaml
---
description: '{{technology}} development guidelines for this repository'
applyTo: '{{glob_pattern}}'
---
```

### Content Structure

1. **Overview**: Brief description of coding standards for this technology
2. **Code Style**: Formatting, naming conventions, patterns to use
3. **Best Practices**: Technology-specific recommendations
4. **Patterns to Avoid**: Anti-patterns and common mistakes
5. **Testing Guidelines**: How tests should be written
6. **Documentation**: Comment and docstring standards

## Before Creating

1. Check if `.github/instructions/{{technology}}.instructions.md` already exists
2. If it exists, ask user if they want to update or create a new variant
3. Ensure `.github/instructions/` directory exists

## Glob Pattern Reference

| Technology | Pattern |
|------------|---------|
| Python | `**/*.py` |
| TypeScript | `**/*.ts,**/*.tsx` |
| JavaScript | `**/*.js,**/*.jsx` |
| React | `**/*.tsx,**/*.jsx` |
| Go | `**/*.go` |
| Rust | `**/*.rs` |
| Java | `**/*.java` |
| Ruby | `**/*.rb` |

```

---

### 4. `cpcontext.create-agent.prompt.md`

**Purpose**: Create a new Copilot agent configuration file.

```yaml
---
description: 'Create a new Copilot custom agent'
agent: 'agent'
tools: ['read', 'edit']
argument-hint: 'Enter agent name and purpose (e.g., "reviewer - code review specialist")'
---
```

**Prompt Content**:

```markdown
Create a Copilot custom agent configuration file.

## User Input Required

Agent name: {{name}}
Purpose: {{purpose}}

## File Creation

Create `.github/agents/{{name}}.agent.md` with:

### Frontmatter

```yaml
---
description: '{{purpose}}'
name: '{{display_name}}'
tools: ['read', 'edit', 'search']
---
```

### Content Structure

The agent prompt should include:

1. **Identity**: Who the agent is and their expertise
2. **Responsibilities**: What tasks the agent handles
3. **Approach**: How the agent works through problems
4. **Constraints**: What the agent should avoid
5. **Output Format**: How responses should be structured

## Tool Options

| Tool | Purpose |
|------|---------|
| `read` | Read file contents |
| `edit` | Modify files |
| `search` | Find files and code |
| `execute` | Run shell commands |
| `agent` | Invoke sub-agents |
| `web` | Fetch URLs (IDE only) |

## Before Creating

1. Check if `.github/agents/{{name}}.agent.md` already exists
2. Ensure `.github/agents/` directory exists
3. Validate agent name is lowercase with hyphens

## Example Agents

- `test-specialist`: Focus on test coverage and quality
- `implementation-planner`: Create detailed plans before coding
- `security-reviewer`: Review for security vulnerabilities
- `documentation-writer`: Generate and maintain docs

```

---

### 5. `cpcontext.create-prompt.prompt.md`

**Purpose**: Create a new Copilot prompt file for reusable tasks.

```yaml
---
description: 'Create a new Copilot prompt file'
agent: 'agent'
tools: ['read', 'edit']
argument-hint: 'Enter prompt name and task (e.g., "write-tests - generate unit tests")'
---
```

**Prompt Content**:

```markdown
Create a Copilot prompt file for a reusable task.

## User Input Required

Prompt name: {{name}}
Task: {{task}}

## File Creation

Create `.github/prompts/{{name}}.prompt.md` with:

### Frontmatter

```yaml
---
description: '{{task}}'
agent: 'agent'
tools: ['read', 'edit', 'search']
argument-hint: '{{hint}}'
---
```

### Content Structure

1. **Task Description**: Clear statement of what the prompt accomplishes
2. **Input Requirements**: What information the user needs to provide
3. **Steps**: How the task should be executed
4. **Output Format**: Expected results and file changes
5. **Validation**: How to verify the task was successful

## Before Creating

1. Check if `.github/prompts/{{name}}.prompt.md` already exists
2. Ensure `.github/prompts/` directory exists
3. Validate prompt name is lowercase with hyphens

## Common Prompt Types

- **Generation**: Create new code or files
- **Refactoring**: Improve existing code
- **Analysis**: Review and report on code
- **Documentation**: Generate docs and comments
- **Testing**: Create or improve tests

```

---

### 6. `cpcontext.create-skill.prompt.md`

**Purpose**: Create a new Copilot skill definition with bundled assets.

```yaml
---
description: 'Create a new Copilot agent skill'
agent: 'agent'
tools: ['read', 'edit']
argument-hint: 'Enter skill name and capability (e.g., "api-design - REST API design patterns")'
---
```

**Prompt Content**:

```markdown
Create a Copilot skill definition folder with SKILL.md and optional assets.

## User Input Required

Skill name: {{name}}
Capability: {{capability}}

## Folder Structure

Create `skills/{{name}}/` with:

```

skills/{{name}}/
├── SKILL.md           # Skill definition
├── templates/         # Optional: template files
├── examples/          # Optional: example files
└── schemas/           # Optional: schema files

```

### SKILL.md Frontmatter

```yaml
---
name: '{{display_name}}'
description: '{{capability}}'
applyTo: '{{glob_pattern}}'  # Optional
---
```

### SKILL.md Content

1. **Overview**: What capability this skill provides
2. **When to Use**: Scenarios where this skill applies
3. **Instructions**: Detailed guidance for the agent
4. **Bundled Assets**: Reference to templates, examples, schemas

## Before Creating

1. Check if `skills/{{name}}/` already exists
2. Skill name must be 1-64 characters
3. Description must be 10-1024 characters

```

---

### 7. `cpcontext.compare-recommendations.prompt.md`

**Purpose**: Compare repository configuration against GitHub best practices.

```yaml
---
description: 'Compare Copilot configuration with GitHub recommendations'
agent: 'agent'
tools: ['read', 'search', 'web']
---
```

**Prompt Content**:

```markdown
Compare this repository's Copilot configuration against GitHub best practices.

## Analysis Steps

1. **Scan existing configuration** using scan-configs approach
2. **Detect technologies** using analyze-technologies approach
3. **Fetch recommendations** from GitHub documentation:
   - https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions
   - https://docs.github.com/en/copilot/reference/custom-agents-configuration
4. **Compare** existing vs. recommended

## Output Format

### Compliance Score: X/10

### ✅ Configurations Present

| Configuration | Status | Notes |
|--------------|--------|-------|
| Instructions file | ✓ Present | python.instructions.md |

### ⚠️ Gaps Identified

| Recommendation | Priority | Reason | Suggested Action |
|---------------|----------|--------|------------------|
| Add testing instructions | P2 | pytest detected | Create testing.instructions.md |

### 📋 Suggested Actions

For each gap, provide:
1. What to create
2. Why it's recommended
3. How to create it (reference appropriate create-* prompt)
```

---

### 8. `cpcontext.browse-examples.prompt.md`

**Purpose**: Browse examples from github/awesome-copilot repository.

```yaml
---
description: 'Browse Copilot configuration examples from community repositories'
agent: 'agent'
tools: ['web', 'read']
argument-hint: 'Enter type to filter: instructions, agents, prompts, or all'
---
```

**Prompt Content**:

```markdown
Browse Copilot configuration examples from the github/awesome-copilot repository.

## User Input

Filter by type: {{type}} (instructions, agents, prompts, or all)

## Sources

1. **Primary**: https://github.com/github/awesome-copilot
   - Instructions: `/instructions/`
   - Agents: `/agents/`
   - Prompts: `/prompts/`

## Output Format

### Available Examples

| Name | Type | Description | Use As Template |
|------|------|-------------|-----------------|
| python.instructions.md | Instructions | Python coding standards | Yes |
| test-specialist.agent.md | Agent | Testing focus | Yes |

### Example Details

For requested examples, show:
1. Frontmatter configuration
2. Key content sections
3. How to adapt for this repository

## Using an Example

To use an example as a template:
1. Show the full example content
2. Identify repository-specific customizations needed
3. Offer to create a local version with adaptations
```

---

### 9. `cpcontext.validate-configs.prompt.md`

**Purpose**: Validate Copilot configuration file syntax and structure.

```yaml
---
description: 'Validate Copilot configuration files for errors'
agent: 'agent'
tools: ['read', 'search']
---
```

**Prompt Content**:

```markdown
Validate all Copilot configuration files in this repository.

## Validation Rules

### Instructions Files (.instructions.md)

| Rule | Severity | Check |
|------|----------|-------|
| Has frontmatter | Error | YAML block present |
| Has description | Error | description field non-empty |
| Has applyTo | Error | applyTo field present (path-specific) |
| Valid glob | Error | applyTo pattern is valid |
| Description length | Warning | 10+ characters |

### Agent Files (.agent.md)

| Rule | Severity | Check |
|------|----------|-------|
| Has frontmatter | Error | YAML block present |
| Has description | Error | description field non-empty |
| Valid tools | Warning | All tools recognized |
| Prompt length | Warning | Under 30,000 chars |
| Has model | Info | model field recommended |

### Prompt Files (.prompt.md)

| Rule | Severity | Check |
|------|----------|-------|
| Has frontmatter | Error | YAML block present |
| Has description | Warning | description recommended |
| Valid agent | Warning | agent value recognized |

## Output Format

### Validation Results

| File | Status | Errors | Warnings |
|------|--------|--------|----------|
| python.instructions.md | ✓ Valid | 0 | 1 |
| reviewer.agent.md | ✗ Invalid | 1 | 0 |

### Issues Found

For each issue:
- File path
- Line number (if applicable)
- Rule violated
- How to fix

### Summary

- Total files: X
- Passed: X
- Failed: X
- Warnings: X
```

---

## Prompt Invocation

Users invoke prompts in Copilot Chat using:

```
/cpcontext.scan-configs
/cpcontext.analyze-technologies
/cpcontext.create-instructions python
/cpcontext.create-agent reviewer - code review specialist
/cpcontext.compare-recommendations
/cpcontext.browse-examples agents
/cpcontext.validate-configs
```

The prompts are discovered by Copilot from the `.github/prompts/` directory.
