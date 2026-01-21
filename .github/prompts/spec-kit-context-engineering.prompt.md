# Radius Context Engineering

Upcoming Radius expirments will rely heavily on GitHub copilot to generate code based on specifications using Spec Kit. Context engineering applied to the expirments will involve three main components:

- Spec kit constitution.
- GitHub Copilot configuration: instructions, agents, and skills, etc.
- Definition of the human interactions with copilot.

## Constitution

Spec Kit constitution determines the overall scope of the repo, plus technology selection.

## Github Copilot Configuration

GitHub copilot configuration is the definition of how copilot will use the technology.

For example, if the spec kit constitution defines a web application using React and Node.js, the GitHub copilot configuration would include instructions for generating code snippets, agents for handling specific tasks (like form validation or API calls), and skills related to React components and Node.js backend logic.

Some copilot configuration will be at the organization level, e.g. git operations, shell scripting standards, etc. Some will be at the repo level, e.g. specific instructions for the application being built. 

## Human Interactions with Copilot

How do humans interact with Copilot to ensure the generated code meets the specifications and quality standards?

Examples:

- How to generate a new constitution. (Prompt to prompt?)
- What are the steps to ensure that we get the speed we want out of the experiment?
- Who is involved in each step?

## Proposed next steps

We create a context engineering repo that contains:

- Instructions for bootstrapping new repos.
- Prompts, instructions, agents, and skills that are common to all repos.
- Documentation on human processes to interact with copilot effectively.

# Problems

- How to effectively review specs.
- How to reuse copilot configuration across repos.