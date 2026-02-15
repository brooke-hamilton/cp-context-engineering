# cp-context-engineering Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-18

## Active Technologies
- Node.js 18+ with TypeScript 5.x + Commander.js (CLI), gray-matter (frontmatter parsing), glob (file matching), chalk (output), inquirer (prompts) (2-copilot-config-manager)
- File system (configuration files), optional cache for example repository content (2-copilot-config-manager)
- Markdown with YAML frontmatter (prompt files) + GitHub Copilot Chat, VS Code or GitHub.com (2-copilot-config-manager)
- File system (prompt files in `.github/prompts/`) (2-copilot-config-manager)
- Bash 5.3 + GitHub CLI (`gh`), GitHub Copilot CLI (`copilot`), Git (3-pr-creation-script)
- TypeScript 5.x + VS Code Extension API, Node.js `https` module, `@vscode/vsce` (packaging) (4-copilot-tools-sync)
- Local filesystem (VS Code user profile directories) (4-copilot-tools-sync)

- Markdown with Mermaid diagram support + GitHub Copilot documentation, Spec Kit documentation, academic papers (arXiv:2510.26493, arXiv:2510.04618), Anthropic engineering blog, awesome-context-engineering repositories (1-context-engineering-guide)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Markdown with Mermaid diagram support

## Code Style

Markdown with Mermaid diagram support: Follow standard conventions

## Recent Changes
- 4-copilot-tools-sync: Added TypeScript 5.x + VS Code Extension API, Node.js `https` module, `@vscode/vsce` (packaging)
- 3-pr-creation-script: Added Bash 5.3 + GitHub CLI (`gh`), GitHub Copilot CLI (`copilot`), Git
- 2-copilot-config-manager: Added Markdown with YAML frontmatter (prompt files) + GitHub Copilot Chat, VS Code or GitHub.com


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
