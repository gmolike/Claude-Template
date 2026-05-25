import * as vscode from 'vscode';
import { SessionManager } from './sessionManager';
import { Panel } from './panel';
import { AgentPanel } from './agentPanel';
import { parseAgentsFromJsonl } from './session/agentTracker';
import type { AgentPanelData } from './shared/agentMessages';

const TOKEN_WINDOW_HOURS = 24;

let sessionManager: SessionManager | undefined;
let panel: Panel | undefined;
let agentPanel: AgentPanel | undefined;

export function activate(context: vscode.ExtensionContext) {
  panel = Panel.createProvider(context);
  agentPanel = AgentPanel.createProvider(context);

  sessionManager = new SessionManager((sessions) => {
    panel!.sendSessions(sessions);
  });

  // Register sidebar webview provider
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider('claude-code-monitor.sidebar', panel, {
      webviewOptions: { retainContextWhenHidden: true },
    }),
  );

  // Register agent panel in bottom area
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider('claude-code-monitor.agentPanel', agentPanel, {
      webviewOptions: { retainContextWhenHidden: true },
    }),
  );

  // Keep the command for opening as an editor panel
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-code-monitor.open', () => {
      panel!.openAsPanel();
    }),
  );

  // Command to focus the agent panel
  context.subscriptions.push(
    vscode.commands.registerCommand('claude-code-monitor.openAgentPanel', () => {
      vscode.commands.executeCommand('claude-code-monitor.agentPanel.focus');
    }),
  );

  const usageTick = () => {
    panel!.sendUsage(sessionManager!.computeUsageFromLogs());
  };
  usageTick();
  const usageTimer = setInterval(usageTick, 60_000);

  const agentTick = () => {
    const activeEntry = sessionManager!.getMostRecentEntry();
    if (activeEntry) {
      const summary = parseAgentsFromJsonl(activeEntry.filePath);
      const session = activeEntry.state;
      const stage =
        summary.agents.length > 5 ? 'Stufe 3' : summary.agents.length > 1 ? 'Stufe 2' : '';
      const data: AgentPanelData = {
        ...summary,
        sessionTitle: session.chatTitle || session.projectName || '',
        workflowStage: stage,
      };
      agentPanel!.sendAgentData(data);
    }
  };

  const envTick = () => {
    panel!.sendEnvData({
      recentFiles: sessionManager!.getRecentFiles(),
      mcpServers: sessionManager!.getMcpServers(),
      recentSessions: sessionManager!.getRecentSessions(),
      skills: sessionManager!.getSkills(),
      clis: sessionManager!.getInstalledClis(),
    });
    panel!.sendProjectInfo();
    panel!.sendScrumTasks();
    panel!.sendFsdActivity(sessionManager!.getRecentFilePaths());
    panel!.sendAgentStatus();
    agentTick();
  };
  envTick();
  const envTimer = setInterval(envTick, 10_000);

  // Scan JSONL for the last 24h of token events every 30s
  const tokenTick = () => {
    panel!.sendTokenActivity(
      sessionManager!.getTokenActivity(TOKEN_WINDOW_HOURS),
      TOKEN_WINDOW_HOURS,
    );
  };
  tokenTick();
  const tokenTimer = setInterval(tokenTick, 30_000);

  // Fresh data on sidebar open
  panel.onReady(() => {
    usageTick();
    envTick();
    tokenTick();
  });

  // Fresh data on agent panel open
  agentPanel.onReady(() => {
    agentTick();
  });
  agentPanel.onRefresh(() => {
    agentTick();
  });

  // Manual refresh from the webview
  panel.onRefreshTokenActivity(() => tokenTick());

  // Agent panel fast-refresh (3s) for live agent tracking
  const agentTimer = setInterval(agentTick, 3_000);

  context.subscriptions.push({
    dispose: () => {
      clearInterval(usageTimer);
      clearInterval(envTimer);
      clearInterval(tokenTimer);
      clearInterval(agentTimer);
      sessionManager?.dispose();
      panel?.dispose();
      agentPanel?.dispose();
    },
  });
}

export function deactivate() {
  sessionManager?.dispose();
  panel?.dispose();
  agentPanel?.dispose();
}
