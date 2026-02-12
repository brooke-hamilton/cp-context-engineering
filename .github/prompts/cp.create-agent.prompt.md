---
agent: copilot-agent-creator
---

Create a new GitHub Copilot custom agent based on the user's description. Walk through the following steps:

1. **Validate documentation links.** Fetch each URL listed in the "GitHub documentation references" section below. If any link returns an error or is unreachable, stop and report the broken link(s) to the user before continuing.
2. **Read the linked documentation.** Read the content of every reachable link so you have the latest guidance on agent profile format, frontmatter options, prompt files, and custom instructions.
3. **Check for conflicts.** Compare the guidance in the linked documentation against the instructions defined in the `copilot-agent-creator` agent (`cp.agent-creator.agent.md`). If any instructions in the agent conflict with the official documentation, **stop processing immediately** and report the conflict to the user. Include:
   - The specific conflicting guidance from the agent and from the documentation.
   - A suggested resolution (e.g., which source to follow, or how to reconcile the two).
   Do not proceed to the next steps until the user acknowledges the conflict.
4. Ask the user what the agent's purpose and domain of expertise should be.
5. Suggest a concise, descriptive name using lowercase with hyphens.
6. Define clear responsibilities, constraints, and output guidelines.
7. Generate a complete, production-ready agent profile in Markdown with YAML frontmatter.
8. Save the agent file to `.github/agents/<agent-name>.agent.md`.

## GitHub documentation references

- [Custom agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents) — define specialized AI personas with tool restrictions and model preferences.
- [Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files) — create reusable slash-command prompts in `.github/prompts/`.
- [Custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) — always-on and file-based instructions in `.github/copilot-instructions.md` and `.github/instructions/`.
- [Customization overview](https://code.visualstudio.com/docs/copilot/customization/overview) — full reference for all VS Code AI customization options.
- [Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) — GitHub Docs guide for repository-wide and path-specific instructions.
