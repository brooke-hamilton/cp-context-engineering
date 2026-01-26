# Research: Copilot Config Manager

**Feature**: Copilot Config Manager  
**Spec Directory**: `specs/2-copilot-config-manager`  
**Date**: January 22, 2026

## Research Tasks

This document consolidates research findings for building tooling that manages GitHub Copilot configurations.

---

## 1. Copilot Configuration File Types & Locations

### Decision

Support four distinct configuration types with standardized locations per GitHub documentation:

| Configuration Type | Location | File Pattern | Purpose |
|-------------------|----------|--------------|---------|
| Repository-wide Instructions | `.github/copilot-instructions.md` | Single file | Global Copilot behavior for repository |
| Path-specific Instructions | `.github/instructions/*.instructions.md` | Multiple files | Technology/path-specific guidance |
| Agent Configurations | `.github/agents/*.agent.md` | Multiple files | Custom agent definitions |
| Prompt Files | `.github/prompts/*.prompt.md` | Multiple files | Reusable task prompts |

### Rationale

- GitHub documentation explicitly defines these locations as standard
- Path-specific instructions support frontmatter with `applyTo` glob patterns
- Agent files support extensive YAML frontmatter configuration
- Skills are bundled in folders with `SKILL.md` files (emerging pattern from awesome-copilot)

### Alternatives Considered

- **Single consolidated file**: Rejected because GitHub's architecture separates concerns
- **Root-level agent files (AGENTS.md, CLAUDE.md)**: Supported for cross-agent compatibility but `.github/agents/` is canonical for Copilot

### Sources

- [GitHub Docs: Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [GitHub Docs: Creating custom agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)
- [GitHub Docs: Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

---

## 2. Instructions File Format & Frontmatter

### Decision

Instructions files use Markdown with YAML frontmatter specifying path-scoping:

```yaml
---
description: 'Brief description of instructions purpose'
applyTo: '**/*.py'  # Glob pattern for file matching
excludeAgent: 'code-review'  # Optional: exclude from specific agents
---

# Instruction content in markdown
```

### Rationale

- `applyTo` uses standard glob syntax matching file paths
- Multiple patterns can be comma-separated: `'**/*.ts,**/*.tsx'`
- `description` is required for discoverability
- `excludeAgent` allows environment-specific instructions

### Frontmatter Properties for Instructions Files

| Property | Required | Description |
|----------|----------|-------------|
| `description` | Yes | Clear purpose description (single-quoted string) |
| `applyTo` | Yes | Glob pattern(s) for file matching |
| `excludeAgent` | No | Exclude from `'code-review'` or `'coding-agent'` |

### Sources

- [GitHub awesome-copilot: instructions.instructions.md](https://github.com/github/awesome-copilot/tree/main/instructions/instructions.instructions.md)
- [GitHub Docs: Path-specific custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions#creating-path-specific-custom-instructions)

---

## 3. Agent Configuration Format & Properties

### Decision

Agent files use Markdown with YAML frontmatter defining agent identity, capabilities, and tools:

```yaml
---
description: 'Agent purpose and domain expertise'
name: 'Display Name'
model: 'Claude Sonnet 4.5'
tools: ['read', 'edit', 'search', 'execute']
target: 'vscode'  # or 'github-copilot' or omit for both
infer: true
handoffs:
  - label: 'Next Step'
    agent: 'implementation'
    prompt: 'Implement the plan.'
    send: false
---

# Agent prompt and instructions
```

### Rationale

- `description` is the only required property
- `tools` can be omitted to enable all tools, or specified as array
- Tool aliases supported: `execute`=shell, `read`=view, `edit`=write, `search`=grep
- `handoffs` enable agent orchestration workflows (VS Code only currently)

### Agent Frontmatter Properties

| Property | Required | Environment | Description |
|----------|----------|-------------|-------------|
| `description` | Yes | All | Agent purpose (50-150 chars) |
| `name` | No | All | Display name (defaults to filename) |
| `tools` | No | All | Tool list or `*` for all |
| `model` | No | IDEs only | AI model selection |
| `target` | No | All | `vscode`, `github-copilot`, or both |
| `infer` | No | All | Auto-selection based on context (default: true) |
| `metadata` | No | GitHub.com | Key-value annotations |
| `mcp-servers` | No | Org/Enterprise | MCP server configuration |
| `handoffs` | No | VS Code | Agent workflow transitions |

### Tool Aliases

| Alias | Alternative Names | Purpose |
|-------|-------------------|---------|
| `execute` | shell, bash, powershell | Run shell commands |
| `read` | view, NotebookRead | Read file contents |
| `edit` | Write, MultiEdit, NotebookEdit | Modify files |
| `search` | Grep, Glob | Search files/text |
| `agent` | custom-agent, Task | Invoke sub-agents |
| `web` | WebSearch, WebFetch | Fetch URLs (IDE only) |

### Sources

- [GitHub Docs: Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [GitHub awesome-copilot: agents.instructions.md](https://github.com/github/awesome-copilot/tree/main/instructions/agents.instructions.md)

---

## 4. Prompt File Format

### Decision

Prompt files define reusable task templates with YAML frontmatter:

```yaml
---
description: 'Brief task description'
agent: 'agent'  # or 'ask', 'edit', or custom agent name
model: 'Claude Sonnet 4'
tools: ['edit', 'search', 'web/fetch']
argument-hint: 'Provide the component name'
---

# Prompt instructions and template
```

### Rationale

- `agent` field specifies which agent executes the prompt
- `argument-hint` provides user guidance in chat input
- Tools specification overrides agent defaults for this prompt

### Prompt Frontmatter Properties

| Property | Required | Description |
|----------|----------|-------------|
| `description` | Recommended | Short actionable description |
| `name` | No | Name shown after `/` in chat (defaults to filename) |
| `agent` | Recommended | Target agent: `ask`, `edit`, `agent`, or custom |
| `model` | No | Override default model |
| `tools` | No | Tools available for this prompt |
| `argument-hint` | No | Hint text in chat input |

### Sources

- [GitHub awesome-copilot: prompt.instructions.md](https://github.com/github/awesome-copilot/tree/main/instructions/prompt.instructions.md)
- [VS Code Docs: Prompt file format](https://code.visualstudio.com/docs/copilot/customization/prompt-files#_prompt-file-format)

---

## 5. Agent Skills Format

### Decision

Skills are self-contained folders containing a `SKILL.md` file with frontmatter and optional bundled assets:

```
skills/
└── my-skill/
    ├── SKILL.md           # Skill definition with frontmatter
    ├── templates/         # Optional templates
    ├── examples/          # Optional examples
    └── schemas/           # Optional schemas
```

### Skill Frontmatter

```yaml
---
name: 'Skill Name'
description: 'What this skill does (10-1024 chars)'
applyTo: '**/*.py'  # Optional file scope
---

# Skill instructions
```

### Rationale

- Skills bundle related instructions with supporting assets
- `SKILL.md` serves as entry point with metadata
- Assets are read on-demand by agents
- Emerging pattern from awesome-copilot, not yet in core GitHub docs

### Sources

- [GitHub awesome-copilot: agent-skills.instructions.md](https://github.com/github/awesome-copilot/tree/main/instructions/agent-skills.instructions.md)
- [GitHub awesome-copilot: CONTRIBUTING.md](https://github.com/github/awesome-copilot/tree/main/CONTRIBUTING.md)

---

## 6. Technology Detection Strategies

### Decision

Implement multi-signal technology detection:

1. **Package manifest analysis**: `package.json`, `requirements.txt`, `Cargo.toml`, `pom.xml`, `go.mod`, etc.
2. **File extension scanning**: Count files by extension to identify primary languages
3. **Framework indicators**: Specific files/patterns (e.g., `next.config.js`, `angular.json`, `Dockerfile`)
4. **Configuration file presence**: `.eslintrc`, `tsconfig.json`, `pyproject.toml`

### Rationale

- Multiple signals provide confidence in detection
- Package manifests give dependency information for framework detection
- File counts help prioritize which technologies are "primary"
- Configuration files indicate tooling already in use

### Alternatives Considered

- **GitHub Linguist only**: Rejected because we need framework-level detection, not just languages
- **LLM-based analysis**: Considered for complex cases but adds latency and cost

---

## 7. Recommendation Engine Design

### Decision

Map detected technologies to Copilot configuration templates:

```
Technology Profile → Recommendation Set → Template Selection
```

**Recommendation Types**:

1. **Instructions Files**: Language/framework-specific coding guidance
2. **Agent Configurations**: Specialized agents for tech stack (e.g., React agent, FastAPI agent)
3. **Prompt Templates**: Common tasks for the stack (e.g., "Write pytest tests", "Generate OpenAPI docs")

### Rationale

- Recommendations should be additive (suggest what's missing)
- Technology-specific content improves Copilot effectiveness
- Templates reduce creation friction and ensure best practices

---

## 8. Example Repository Integration

### Decision

Integrate with curated example repositories:

- `github/awesome-copilot`: Primary source for community examples
- `microsoft/hve-core`: Reference implementations (if available)

**Integration approach**:

1. Fetch raw files via GitHub API or raw.githubusercontent.com
2. Cache responses with TTL (e.g., 1 hour)
3. Parse frontmatter for categorization and filtering
4. Display examples with full metadata and preview capability

### Rationale

- GitHub's official awesome-copilot is authoritative and actively maintained
- Raw file access avoids API rate limits for content fetching
- Caching improves UX and reduces external dependencies

### Alternatives Considered

- **Bundled examples**: Rejected because examples would become stale
- **Multiple community repos**: Start with official repos, expand later

---

## 9. Validation & Compliance Checking

### Decision

Implement validation at multiple levels:

1. **Syntax Validation**: YAML frontmatter parsing, required fields present
2. **Schema Validation**: Field types match expected (e.g., `tools` is array or string)
3. **Best Practice Checks**: Descriptions non-empty, reasonable length, patterns valid
4. **Compliance Comparison**: Gap analysis against GitHub recommendations

### Validation Rules

| Check | Severity | Description |
|-------|----------|-------------|
| Missing `description` | Error | Required for all config types |
| Invalid `applyTo` glob | Error | Pattern must be parseable |
| Empty tools array | Warning | Disables all tools (intentional?) |
| Description too short | Warning | Less than 10 characters |
| Unknown tool name | Warning | May be product-specific |
| Missing `model` in agent | Info | Recommended for agents |

### Rationale

- Graduated severity prevents blocking on style issues
- Unknown tools are warnings because cross-IDE compatibility allows unrecognized names
- Validation before creation prevents debugging cycles

---

## 10. Prompt-Based Architecture

### Decision

Implement as **Copilot prompt files** rather than a standalone CLI:

**Prompt Files** (`.github/prompts/copilot-config/*.prompt.md`):

```
/scan-configs              → Discover existing configs
/analyze-technologies      → Detect technologies
/create-instructions       → Create instructions file
/compare-recommendations   → Compare with recommendations
/validate-configs          → Validate configuration files
```

### Rationale

- Aligns with repository's context engineering mission
- Zero dependencies—just Markdown files
- Native integration with Copilot Chat
- Users already in the Copilot environment
- Self-documenting and easy to customize

### Alternatives Considered

- **Node.js CLI tool**: More powerful automation but adds dependencies
- **VS Code extension**: Better UX but higher maintenance burden
- **Bash scripts**: Limited for complex logic and cross-platform

---

## 11. Implementation Language & Framework

### Decision

Implement as **pure Markdown prompt files**:

- **Format**: Markdown with YAML frontmatter
- **Location**: `.github/prompts/copilot-config/`
- **Invocation**: `/prompt-name` in Copilot Chat
- **Tools Used**: read, edit, search, web (within prompts)

### Rationale

- No build step or dependencies required
- Prompts leverage Copilot's existing capabilities
- Easy to share, customize, and extend
- Consistent with Spec Kit's documentation-first approach

### Alternatives Considered

- **Node.js CLI**: Viable but adds npm package overhead
- **Python**: Would require runtime installation
- **Go**: Fast but overkill for prompt generation

---

## 12. File System Operations & Safety

### Decision

Implement defensive file operations:

1. **Pre-creation checks**: Verify target path doesn't exist or prompt for overwrite
2. **Directory creation**: Ensure `.github/instructions/`, `.github/agents/` exist
3. **Backup on overwrite**: Optional backup of existing files before modification
4. **Dry-run mode**: Preview changes without writing files

### Rationale

- Prevents accidental data loss
- Matches user expectation from spec (prompt before overwrite)
- Dry-run enables validation workflows

---

## Summary of Key Decisions

| Area | Decision | Confidence |
|------|----------|------------|
| Config Locations | Standard GitHub paths (`.github/`) | High |
| File Format | Markdown + YAML frontmatter | High |
| Technology Detection | Multi-signal (manifests + extensions + configs) | Medium |
| Example Sources | github/awesome-copilot primary | High |
| Implementation | Node.js + TypeScript CLI | Medium |
| Validation | Multi-level with graduated severity | High |
| CLI Design | Commands + Interactive mode | High |

---

## Open Questions (Resolved)

1. ~~What frontmatter properties are required vs optional?~~ → Documented above
2. ~~How to handle agent skills (emerging pattern)?~~ → Folder-based with SKILL.md
3. ~~Rate limiting for GitHub API access?~~ → Use raw file URLs + caching
4. ~~Cross-platform CLI considerations?~~ → Node.js handles this

## References

- [GitHub Docs: Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [GitHub Docs: Creating custom agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)
- [GitHub Docs: Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [GitHub awesome-copilot repository](https://github.com/github/awesome-copilot)
- [VS Code Docs: Custom agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code Docs: Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
