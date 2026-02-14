# Context Engineering for GitHub Copilot

Tools for making tools and bootstrapping assets: this is a personal collection of the custom instructions, agents, prompts, and scripts I use to configure GitHub Copilot for my projects. The meta-tooling and bootstrapping tools for Copilot customization is still maturing across the industry, so this repo fills gaps that will likely be covered by better tooling before long.

There is no attempt to make the assets in this repo generally useful; they are things I use for configuring repos that use Copilot. I use this repo to share links to examples with teammates, and to serve as a starting place for bootstrapping Copilot in my work repos. Sometimes I put things here that I developed in another repo and I want to reuse in other repos.

I use [Spec Kit](https://github.com/github/spec-kit) for some of the work in this repo, so you will see those prompts and agents mixed with the Copilot meta-tooling.

## What's included

### Reusable instructions

Drop-in instruction files that shape Copilot's behavior for specific file types. Each file uses `applyTo` patterns so they activate automatically. See the [instructions folder](.github/instructions/).

For a broader collection of community-maintained instructions, see [Awesome Copilot](https://github.com/github/awesome-copilot).

### Custom agents

Specialized AI personas with defined expertise, tool access, and behavioral guidelines. See the [agents folder](.github/agents/).

Notable: the [Agent Creator](.github/agents/cp.agent-creator.agent.md) is a meta-agent — an agent for building new Copilot custom agents.

### Prompt files

Reusable slash-command prompts that orchestrate multi-step workflows. See the [prompts folder](.github/prompts/).

### Scripts

Shell scripts that rely on Copilot for part of their functionality. See the [scripts folder](scripts/).

### Context engineering materials

Notes on context engineering (`docs/context-engineering-guide.md`) covering context engineering patterns for AI systems. These notes are not authoratative or useful.

## GitHub documentation references

- [Customization overview](https://code.visualstudio.com/docs/copilot/customization/overview) — full reference for all VS Code AI customization options.
- [Custom agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents) — define specialized AI personas with tool restrictions and model preferences.
- [Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files) — create reusable slash-command prompts in `.github/prompts/`.
- [Custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) — always-on and file-based instructions in `.github/copilot-instructions.md` and `.github/instructions/`.
- [Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) — GitHub Docs guide for repository-wide and path-specific instructions.
