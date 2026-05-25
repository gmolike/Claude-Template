import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import {
  ExtensionToAgentPanel,
  AgentPanelToExtension,
  AgentPanelData,
} from './shared/agentMessages';

export class AgentPanel implements vscode.WebviewViewProvider {
  private static instance: AgentPanel | undefined;
  private view: vscode.WebviewView | undefined;
  private context: vscode.ExtensionContext;
  private lastData: AgentPanelData | null = null;
  private onReadyCallback: (() => void) | null = null;
  private onRefreshCallback: (() => void) | null = null;
  private disposables: vscode.Disposable[] = [];

  private constructor(context: vscode.ExtensionContext) {
    this.context = context;
  }

  static createProvider(context: vscode.ExtensionContext): AgentPanel {
    if (!AgentPanel.instance) {
      AgentPanel.instance = new AgentPanel(context);
    }
    return AgentPanel.instance;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  resolveWebviewView(
    webviewView: vscode.WebviewView,
    _ctx: vscode.WebviewViewResolveContext,
    _tok: vscode.CancellationToken,
  ): void {
    this.view = webviewView;
    const extensionUri = this.context.extensionUri;

    webviewView.webview.options = {
      enableScripts: true,
      localResourceRoots: [vscode.Uri.joinPath(extensionUri, 'out', 'webview')],
    };

    webviewView.webview.html = this.buildHtml(webviewView.webview);
    webviewView.webview.onDidReceiveMessage((msg) => this.handleMessage(msg));

    webviewView.onDidDispose(() => {
      this.view = undefined;
    });
  }

  private handleMessage(msg: AgentPanelToExtension): void {
    switch (msg.type) {
      case 'agentPanelReady':
        if (this.lastData) {
          this.postMessage({ type: 'agentPanelUpdate', data: this.lastData });
        }
        this.onReadyCallback?.();
        break;
      case 'agentPanelRefresh':
        this.onRefreshCallback?.();
        break;
      case 'agentPanelOpenFile':
        if (msg.file) {
          const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
          if (workspaceFolder) {
            const uri = vscode.Uri.joinPath(workspaceFolder.uri, msg.file);
            vscode.workspace.openTextDocument(uri).then(
              (doc) => vscode.window.showTextDocument(doc),
              () => {},
            );
          }
        }
        break;
    }
  }

  sendAgentData(data: AgentPanelData): void {
    this.lastData = data;
    this.postMessage({ type: 'agentPanelUpdate', data });
  }

  onReady(callback: () => void): void {
    this.onReadyCallback = callback;
  }

  onRefresh(callback: () => void): void {
    this.onRefreshCallback = callback;
  }

  private postMessage(msg: ExtensionToAgentPanel): void {
    this.view?.webview.postMessage(msg);
  }

  dispose(): void {
    this.disposables.forEach((d) => d.dispose());
    AgentPanel.instance = undefined;
  }

  private static _cachedAssets: Record<string, string> = {};
  private static readAsset(name: string): string {
    if (!AgentPanel._cachedAssets[name]) {
      AgentPanel._cachedAssets[name] = fs.readFileSync(
        path.join(__dirname, 'webview', 'agent-panel', name),
        'utf8',
      );
    }
    return AgentPanel._cachedAssets[name];
  }

  private buildHtml(webview: vscode.Webview): string {
    const bundleUri = webview
      .asWebviewUri(
        vscode.Uri.joinPath(
          this.context.extensionUri,
          'out',
          'webview',
          'agent-panel',
          'agent-panel.js',
        ),
      )
      .toString();

    const styles = AgentPanel.readAsset('styles.css');
    const body = AgentPanel.readAsset('body.html');

    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy"
  content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline' ${webview.cspSource};">
<style>${styles}</style>
</head>
<body>
${body}
<script src="${bundleUri}"></script>
</body>
</html>`;
  }
}
