// Typed message envelopes shared by panel.ts (extension side) and src/webview/ (webview side).
// Keep the type strings in sync on both sides so TypeScript can narrow correctly.

import type { SessionState, UsageStats } from '../session/types';
import type { SkillCategory } from '../session/categorize';
import type { CliInfo } from '../session/clis';
import type { TokenEvent } from '../session/tokenActivity';
import type { ScrumTask } from '../session/scrumBoard';
import type { FsdActivity } from '../session/fsdLayerMonitor';
import type { AgentSession } from '../session/agentOrchestration';

export interface RepoInfo {
  workspace: string;
  workspacePath: string;
  gitBranch: string;
  gitRemote: string;
  gitUser: string;
  gitLastCommit: string;
  uncommittedCount: number;
  ahead: number;
  behind: number;
  totalCommits: number;
  lastCommitDate: string;
  contributors: number;
  stashCount: number;
  branchCount: number;
  tagCount: number;
  isPrivate: boolean | null;
  stars: number;
  forks: number;
  openIssues: number;
  openPRs: number;
  lastPushed: string;
  repoCreated: string;
  diskUsage: string;
}

export interface ProjectInfo {
  activeFile: string;
  repos: RepoInfo[];
}

export interface EnvData {
  recentFiles: string[];
  mcpServers: string[];
  recentSessions: { sessionId: string; title: string; lastSeen: number; activity: string }[];
  skills: { name: string; source: string; description: string; category: SkillCategory }[];
  clis: CliInfo[];
}

export type ExtensionToWebview =
  | { type: 'sessionsUpdate'; sessions: SessionState[] }
  | { type: 'projectInfo'; data: ProjectInfo }
  | { type: 'envData'; data: EnvData }
  | { type: 'usageUpdate'; usage: UsageStats }
  | { type: 'tokenActivity'; events: TokenEvent[]; windowHours: number }
  | { type: 'scrumTasks'; tasks: ScrumTask[] }
  | { type: 'fsdActivity'; layers: FsdActivity[] }
  | { type: 'agentStatus'; agents: AgentSession[] };

export type WebviewToExtension =
  | { type: 'ready' }
  | { type: 'refreshUsage' }
  | { type: 'refreshTokenActivity' }
  | { type: 'openUrl'; url: string }
  | { type: 'openFile'; file: string }
  | { type: 'openFolder'; path: string }
  | { type: 'inputSkill'; name: string }
  | { type: 'openSession'; sessionId: string }
  | { type: 'newSession' }
  | { type: 'moveTask'; filePath: string; newStatus: string }
  | { type: 'refreshScrum' };
