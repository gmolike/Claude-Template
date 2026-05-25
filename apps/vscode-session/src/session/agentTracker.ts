import * as fs from 'fs';

export type AgentStatus = 'spawning' | 'running' | 'completed' | 'failed';

export interface TrackedAgent {
  id: string;
  toolUseId: string;
  type: string;
  name: string;
  description: string;
  status: AgentStatus;
  background: boolean;
  isolation: string;
  model: string;
  spawnedAt: number;
  completedAt: number;
  durationMs: number;
  parentToolUseId: string | null;
  tokens: { input: number; output: number };
  lastAction: string;
  currentFile: string;
}

export interface AgentFlowNode {
  agentId: string;
  type: string;
  name: string;
  status: AgentStatus;
  children: string[];
  depth: number;
  parallel: boolean;
}

export interface AgentSummary {
  agents: TrackedAgent[];
  flow: AgentFlowNode[];
  bottlenecks: string[];
  totalTokens: { input: number; output: number };
  activeCount: number;
  completedCount: number;
}

const MODEL_MAP: Record<string, string> = {
  'product-owner': 'opus',
  'scrum-master': 'opus',
  'senior-frontend': 'sonnet',
  'senior-backend': 'sonnet',
  'senior-qs': 'sonnet',
  'worker-frontend': 'sonnet',
  'worker-backend': 'sonnet',
  'worker-qs': 'sonnet',
  debugger: 'sonnet',
  Plan: 'opus',
  Explore: 'sonnet',
};

const TYPE_LABELS: Record<string, string> = {
  'product-owner': 'PO',
  'scrum-master': 'SM',
  'senior-frontend': 'Sr.FE',
  'senior-backend': 'Sr.BE',
  'senior-qs': 'Sr.QS',
  'worker-frontend': 'W.FE',
  'worker-backend': 'W.BE',
  'worker-qs': 'W.QS',
  debugger: 'Debug',
  Plan: 'Plan',
  Explore: 'Explore',
};

export function getAgentLabel(type: string): string {
  return TYPE_LABELS[type] || type;
}

export function getAgentModel(type: string): string {
  return MODEL_MAP[type] || 'sonnet';
}

interface RawToolUse {
  toolUseId: string;
  name: string;
  input: Record<string, unknown>;
  timestamp: number;
  messageIndex: number;
  blockIndex: number;
}

interface RawToolResult {
  toolUseId: string;
  content: string;
  timestamp: number;
}

/**
 * Parse the active session's JSONL file for Agent tool_use and tool_result blocks.
 * Builds a list of TrackedAgent objects with lifecycle state.
 */
export function parseAgentsFromJsonl(filePath: string): AgentSummary {
  let content: string;
  try {
    content = fs.readFileSync(filePath, 'utf-8');
  } catch {
    return emptySummary();
  }

  const toolUses: RawToolUse[] = [];
  const toolResults: Map<string, RawToolResult> = new Map();
  const allToolUsesInMessage: Map<number, RawToolUse[]> = new Map();

  const lines = content.split('\n');
  let messageIndex = 0;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    let obj: Record<string, unknown>;
    try {
      obj = JSON.parse(trimmed);
    } catch {
      continue;
    }

    const type = obj['type'] as string | undefined;
    const timestamp = extractTimestamp(obj);

    if (type === 'assistant') {
      messageIndex++;
      const message = obj['message'] as Record<string, unknown> | undefined;
      const blocks = (message?.['content'] ?? obj['content']) as unknown[];
      if (!Array.isArray(blocks)) continue;

      const messageAgents: RawToolUse[] = [];

      for (let i = 0; i < blocks.length; i++) {
        const block = blocks[i] as Record<string, unknown>;
        if (block?.['type'] !== 'tool_use') continue;

        const toolName = block['name'] as string;
        const toolUseId = (block['id'] as string) || `tu_${messageIndex}_${i}`;
        const input = (block['input'] as Record<string, unknown>) || {};

        if (toolName === 'Agent') {
          const tu: RawToolUse = {
            toolUseId,
            name: toolName,
            input,
            timestamp,
            messageIndex,
            blockIndex: i,
          };
          toolUses.push(tu);
          messageAgents.push(tu);
        }

        if (toolName === 'SendMessage') {
          const target = input['to'] as string;
          if (target) {
            const tu: RawToolUse = {
              toolUseId,
              name: 'SendMessage',
              input,
              timestamp,
              messageIndex,
              blockIndex: i,
            };
            toolUses.push(tu);
          }
        }
      }

      if (messageAgents.length > 0) {
        allToolUsesInMessage.set(messageIndex, messageAgents);
      }
    }

    if (type === 'user') {
      const message = obj['message'] as Record<string, unknown> | undefined;
      const blocks = (message?.['content'] ?? obj['content']) as unknown[];
      if (!Array.isArray(blocks)) continue;

      for (const block of blocks) {
        const b = block as Record<string, unknown>;
        if (b?.['type'] !== 'tool_result') continue;

        const toolUseId = b['tool_use_id'] as string;
        if (!toolUseId) continue;

        const resultContent =
          typeof b['content'] === 'string' ? b['content'] : JSON.stringify(b['content'] || '');

        toolResults.set(toolUseId, {
          toolUseId,
          content: resultContent,
          timestamp,
        });
      }
    }
  }

  const agents = buildAgents(toolUses, toolResults);
  const flow = buildFlowGraph(agents, allToolUsesInMessage);
  const bottlenecks = detectBottlenecks(agents);

  let totalIn = 0;
  let totalOut = 0;
  let activeCount = 0;
  let completedCount = 0;

  for (const a of agents) {
    totalIn += a.tokens.input;
    totalOut += a.tokens.output;
    if (a.status === 'running' || a.status === 'spawning') activeCount++;
    if (a.status === 'completed') completedCount++;
  }

  return {
    agents,
    flow,
    bottlenecks,
    totalTokens: { input: totalIn, output: totalOut },
    activeCount,
    completedCount,
  };
}

function buildAgents(
  toolUses: RawToolUse[],
  toolResults: Map<string, RawToolResult>,
): TrackedAgent[] {
  const agents: TrackedAgent[] = [];
  const now = Date.now();
  let agentCounter = 0;

  for (const tu of toolUses) {
    if (tu.name !== 'Agent') continue;

    agentCounter++;
    const input = tu.input;
    const agentType = (input['subagent_type'] as string) || 'general-purpose';
    const agentName = (input['name'] as string) || `${getAgentLabel(agentType)}-${agentCounter}`;
    const description = (input['description'] as string) || '';
    const background = Boolean(input['run_in_background']);
    const isolation = (input['isolation'] as string) || '';

    const result = toolResults.get(tu.toolUseId);
    let status: AgentStatus;
    let completedAt = 0;
    let durationMs: number;
    let tokensOut = 0;

    if (result) {
      status = 'completed';
      completedAt = result.timestamp || now;
      durationMs = completedAt - tu.timestamp;
      tokensOut = Math.round((result.content?.length || 0) / 4);
    } else {
      const age = now - tu.timestamp;
      status = age < 2000 ? 'spawning' : 'running';
      durationMs = age;
    }

    agents.push({
      id: `agent-${agentCounter}`,
      toolUseId: tu.toolUseId,
      type: agentType,
      name: agentName,
      description,
      status,
      background,
      isolation,
      model: getAgentModel(agentType),
      spawnedAt: tu.timestamp,
      completedAt,
      durationMs: Math.max(0, durationMs),
      parentToolUseId: null,
      tokens: { input: 0, output: tokensOut },
      lastAction: description,
      currentFile: '',
    });
  }

  return agents;
}

function buildFlowGraph(
  agents: TrackedAgent[],
  messagesMap: Map<number, RawToolUse[]>,
): AgentFlowNode[] {
  const nodes: AgentFlowNode[] = [];
  const parallelSets = new Set<string>();

  for (const [, agentsInMsg] of messagesMap) {
    if (agentsInMsg.length > 1) {
      for (const tu of agentsInMsg) {
        parallelSets.add(tu.toolUseId);
      }
    }
  }

  for (const agent of agents) {
    nodes.push({
      agentId: agent.id,
      type: agent.type,
      name: agent.name,
      status: agent.status,
      children: [],
      depth: 0,
      parallel: parallelSets.has(agent.toolUseId),
    });
  }

  return nodes;
}

function detectBottlenecks(agents: TrackedAgent[]): string[] {
  const bottlenecks: string[] = [];
  const runningAgents = agents.filter((a) => a.status === 'running');

  for (const agent of runningAgents) {
    if (agent.durationMs > 5 * 60 * 1000) {
      bottlenecks.push(agent.id);
    }
  }

  return bottlenecks;
}

function extractTimestamp(obj: Record<string, unknown>): number {
  const ts = obj['timestamp'];
  if (typeof ts === 'string') {
    const parsed = new Date(ts).getTime();
    return isNaN(parsed) ? Date.now() : parsed;
  }
  if (typeof ts === 'number') return ts;
  return Date.now();
}

function emptySummary(): AgentSummary {
  return {
    agents: [],
    flow: [],
    bottlenecks: [],
    totalTokens: { input: 0, output: 0 },
    activeCount: 0,
    completedCount: 0,
  };
}
