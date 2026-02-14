import * as vscode from 'vscode';
import * as path from 'path';

export interface ProfilePaths {
    agents: vscode.Uri;
    instructions: vscode.Uri;
    prompts: vscode.Uri;
}

export function resolveProfilePaths(context: vscode.ExtensionContext): ProfilePaths {
    const globalStoragePath = context.globalStorageUri.fsPath;
    const userDir = path.resolve(globalStoragePath, '..', '..');

    return {
        agents: vscode.Uri.file(path.join(userDir, 'agents')),
        instructions: vscode.Uri.file(path.join(userDir, 'instructions')),
        prompts: vscode.Uri.file(path.join(userDir, 'prompts')),
    };
}
