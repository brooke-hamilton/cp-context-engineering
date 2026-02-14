import * as vscode from 'vscode';
import { resolveProfilePaths } from './profile-paths';
import { listDirectoryFiles, downloadFileContent } from './github-api';

const DIR_MAPPINGS = [
    { remote: '.github/agents', local: 'agents' },
    { remote: '.github/instructions', local: 'instructions' },
    { remote: '.github/prompts', local: 'prompts' },
] as const;

let isSyncing = false;

export async function syncCopilotTools(context: vscode.ExtensionContext): Promise<void> {
    if (isSyncing) {
        vscode.window.showWarningMessage('A sync is already in progress.');
        return;
    }

    isSyncing = true;
    try {
        const config = vscode.workspace.getConfiguration('copilotToolsSync');
        let repository = config.get<string>('repository', 'brooke-hamilton/cp-context-engineering');

        if (!repository) {
            repository = 'brooke-hamilton/cp-context-engineering';
        }

        const slashIndex = repository.indexOf('/');
        if (slashIndex <= 0 || slashIndex === repository.length - 1 || repository.indexOf('/', slashIndex + 1) !== -1) {
            vscode.window.showErrorMessage(`Invalid repository format: "${repository}". Expected "owner/repo".`);
            return;
        }

        const owner = repository.substring(0, slashIndex);
        const repo = repository.substring(slashIndex + 1);
        const profilePaths = resolveProfilePaths(context);

        let successCount = 0;
        let failedCount = 0;
        const failures: { fileName: string; error: string }[] = [];

        for (const mapping of DIR_MAPPINGS) {
            let entries;
            try {
                entries = await listDirectoryFiles(owner, repo, mapping.remote);
            } catch (err) {
                const message = err instanceof Error ? err.message : String(err);
                if (message.includes('rate limit')) {
                    vscode.window.showErrorMessage('Sync failed: GitHub API rate limit exceeded. Try again later.');
                    return;
                }
                if (message.includes('Unable to reach')) {
                    vscode.window.showErrorMessage(`Sync failed: unable to reach repository "${owner}/${repo}".`);
                    return;
                }
                vscode.window.showErrorMessage(`Sync failed: ${message}`);
                return;
            }

            const matchingFiles = entries.filter(
                (e) => e.type === 'file' && e.name.startsWith('cp.') && e.download_url
            );

            if (matchingFiles.length === 0) {
                continue;
            }

            const destDir = profilePaths[mapping.local as keyof typeof profilePaths];
            await vscode.workspace.fs.createDirectory(destDir);

            for (const file of matchingFiles) {
                try {
                    const content = await downloadFileContent(file.download_url!);
                    const destUri = vscode.Uri.joinPath(destDir, file.name);
                    await vscode.workspace.fs.writeFile(destUri, content);
                    successCount++;
                } catch (err) {
                    failedCount++;
                    failures.push({
                        fileName: file.name,
                        error: err instanceof Error ? err.message : String(err),
                    });
                }
            }
        }

        if (successCount === 0 && failedCount === 0) {
            vscode.window.showInformationMessage('No Copilot tool files found matching the "cp." prefix.');
        } else if (failedCount === 0) {
            vscode.window.showInformationMessage(`Synced ${successCount} Copilot tool files.`);
        } else if (successCount > 0) {
            vscode.window.showWarningMessage(`Synced ${successCount} files. ${failedCount} files failed to sync.`);
        } else {
            vscode.window.showErrorMessage(`Sync failed: all ${failedCount} files failed to sync.`);
        }
    } finally {
        isSyncing = false;
    }
}
