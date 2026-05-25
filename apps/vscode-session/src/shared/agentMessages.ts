import type { TrackedAgent, AgentFlowNode } from '../session/agentTracker';

export interface AgentPanelData {
  agents: TrackedAgent[];
  flow: AgentFlowNode[];
  bottlenecks: string[];
  totalTokens: { input: number; output: number };
  activeCount: number;
  completedCount: number;
  sessionTitle: string;
  workflowStage: string;
  otherSessionCount: number;
}

export type ExtensionToAgentPanel =
  | { type: 'agentPanelUpdate'; data: AgentPanelData }
  | { type: 'agentPanelTheme'; isDark: boolean };

export type AgentPanelToExtension =
  | { type: 'agentPanelReady' }
  | { type: 'agentPanelRefresh' }
  | { type: 'agentPanelFocusAgent'; agentId: string }
  | { type: 'agentPanelOpenFile'; file: string };
