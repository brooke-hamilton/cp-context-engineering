# Copilot Tools Sync

A VS Code extension that syncs Copilot customization files (agents, instructions, and prompts) from a public GitHub repository into your local VS Code user profile directories.

## Installation

Build and side-load the extension:

```bash
cd extensions/copilot-tools-sync
npm install
npm run compile
npx vsce package --allow-missing-repository
code --install-extension copilot-tools-sync-0.0.1.vsix
```

Or use the Makefile from the repository root:

```bash
make build-extension
make package-extension
make install-extension
```

Reload VS Code after installation.

## Usage

Open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run:

```text
Sync Copilot Tools
```

The extension fetches all files prefixed with `cp.` from the configured repository's `.github/agents/`, `.github/instructions/`, and `.github/prompts/` directories and copies them into your VS Code user profile.

## Configuration

| Setting | Default | Description |
| --- | --- | --- |
| `copilotToolsSync.repository` | `brooke-hamilton/cp-context-engineering` | Source GitHub repository in `owner/repo` format |

Change the source repository in VS Code Settings (`Ctrl+,`) under **Copilot Tools Sync**, or edit `settings.json`:

```json
{
  "copilotToolsSync.repository": "your-org/your-repo"
}
```

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| "Sync failed: unable to reach repository" | Network issue | Check internet connection |
| "Sync failed: repository not found" | Invalid repo or private repo | Verify the repository setting |
| "Sync failed: GitHub API rate limit exceeded" | Over 60 requests/hour | Wait and try again later |
| "No Copilot tool files found" | No `cp.`-prefixed files in source | Verify repository has matching files |
| "A sync is already in progress" | Previous sync still running | Wait for completion |
| Command not found | Extension not installed | Reinstall the VSIX and reload |
