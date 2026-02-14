import * as vscode from 'vscode';
import { syncCopilotTools } from './sync';

export function activate(context: vscode.ExtensionContext): void {
    const disposable = vscode.commands.registerCommand(
        'copilotToolsSync.sync',
        () => syncCopilotTools(context)
    );
    context.subscriptions.push(disposable);
}

export function deactivate(): void {
    // No cleanup required
}
