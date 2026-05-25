declare function acquireVsCodeApi(): {
  postMessage(msg: unknown): void;
  getState(): unknown;
  setState(state: unknown): void;
};

interface TrackedAgent {
  id: string;
  toolUseId: string;
  type: string;
  name: string;
  description: string;
  status: 'spawning' | 'running' | 'completed' | 'failed';
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

interface AgentFlowNode {
  agentId: string;
  type: string;
  name: string;
  status: 'spawning' | 'running' | 'completed' | 'failed';
  children: string[];
  depth: number;
  parallel: boolean;
}

interface AgentPanelData {
  agents: TrackedAgent[];
  flow: AgentFlowNode[];
  bottlenecks: string[];
  totalTokens: { input: number; output: number };
  activeCount: number;
  completedCount: number;
  sessionTitle: string;
  workflowStage: string;
}

// ── Init ──────────────────────────────────────────────────────
const vscode = acquireVsCodeApi();
let _data: AgentPanelData | null = null;
let _durationTimerId: number | null = null;

// ── DOM refs ──────────────────────────────────────────────────
const $cardsContainer = document.getElementById('cards-container')!;
const $emptyState = document.getElementById('empty-state')!;
const $statActive = document.getElementById('stat-active')!;
const $statCompleted = document.getElementById('stat-completed')!;
const $statTokens = document.getElementById('stat-tokens')!;
const $statStage = document.getElementById('stat-stage')!;
const $overviewSession = document.getElementById('overview-session')!;
const $overviewIcon = document.querySelector('.overview-icon')!;
const $flowSection = document.getElementById('flow-section')!;
const $flowCanvas = document.getElementById('flow-canvas') as HTMLCanvasElement;
const $btnRefresh = document.getElementById('btn-refresh')!;

// ── Event Handlers ────────────────────────────────────────────
$btnRefresh.addEventListener('click', () => {
  vscode.postMessage({ type: 'agentPanelRefresh' });
});

window.addEventListener('message', (event) => {
  const msg = event.data;
  if (msg.type === 'agentPanelUpdate') {
    _data = msg.data as AgentPanelData;
    render();
  }
});

window.addEventListener('resize', () => {
  if (_data && _data.flow.length > 0) {
    renderFlow(_data.flow, _data.bottlenecks);
  }
});

// ── Tell the extension we're ready ────────────────────────────
vscode.postMessage({ type: 'agentPanelReady' });

// ── Render ────────────────────────────────────────────────────
function render(): void {
  if (!_data) return;

  renderOverview(_data);
  renderCards(_data.agents, _data.bottlenecks);
  renderFlow(_data.flow, _data.bottlenecks);
  startDurationUpdater();
}

function renderOverview(data: AgentPanelData): void {
  $statActive.textContent = `${data.activeCount} active`;
  $statCompleted.textContent = `${data.completedCount} done`;
  $statTokens.textContent = formatTokens(data.totalTokens.input + data.totalTokens.output);
  $overviewSession.textContent = data.sessionTitle || '';

  if (data.workflowStage) {
    $statStage.textContent = data.workflowStage;
    $statStage.style.display = '';
  } else {
    $statStage.style.display = 'none';
  }

  if (data.activeCount > 0) {
    $overviewIcon.classList.remove('inactive');
  } else {
    $overviewIcon.classList.add('inactive');
  }
}

function renderCards(agents: TrackedAgent[], bottlenecks: string[]): void {
  if (agents.length === 0) {
    $cardsContainer.style.display = 'none';
    $emptyState.classList.add('visible');
    return;
  }

  $emptyState.classList.remove('visible');
  $cardsContainer.style.display = '';

  const sorted = [...agents].sort((a, b) => {
    const statusOrder: Record<string, number> = {
      running: 0,
      spawning: 1,
      completed: 2,
      failed: 3,
    };
    const diff = (statusOrder[a.status] ?? 9) - (statusOrder[b.status] ?? 9);
    if (diff !== 0) return diff;
    return a.spawnedAt - b.spawnedAt;
  });

  $cardsContainer.innerHTML = '';

  for (const agent of sorted) {
    const isBottleneck = bottlenecks.includes(agent.id);
    const card = createCard(agent, isBottleneck);
    $cardsContainer.appendChild(card);
  }
}

function createCard(agent: TrackedAgent, isBottleneck: boolean): HTMLElement {
  const card = document.createElement('div');
  card.className = `agent-card ${agent.status}`;
  card.dataset.agentId = agent.id;
  if (isBottleneck) card.classList.add('bottleneck');

  const label = TYPE_LABELS[agent.type] || agent.type;
  const totalTokens = agent.tokens.input + agent.tokens.output;

  card.innerHTML = `
    <div class="card-header">
      <span class="card-type">${escHtml(label)}</span>
      <span class="card-status-dot ${agent.status}" title="${agent.status}"></span>
    </div>
    <div class="card-description" title="${escHtml(agent.description)}">${escHtml(agent.description || agent.lastAction)}</div>
    <div class="card-meta">
      <div class="card-meta-row">
        <span class="card-meta-label">Duration</span>
        <span class="card-meta-value duration-val" data-spawned="${agent.spawnedAt}" data-completed="${agent.completedAt}" data-status="${agent.status}">${formatDuration(agent.durationMs)}</span>
      </div>
      ${
        totalTokens > 0
          ? `
      <div class="card-meta-row">
        <span class="card-meta-label">Tokens</span>
        <span class="card-meta-value">${formatTokens(agent.tokens.input)}&#8595; ${formatTokens(agent.tokens.output)}&#8593;</span>
      </div>`
          : ''
      }
    </div>
    ${renderMeter(agent)}
    ${renderBadges(agent)}
  `;

  return card;
}

function renderMeter(agent: TrackedAgent): string {
  if (agent.status === 'completed' || agent.status === 'failed') return '';

  const elapsed = Date.now() - agent.spawnedAt;
  const maxExpected = 10 * 60 * 1000;
  const pct = Math.min(100, Math.round((elapsed / maxExpected) * 100));
  const level = pct < 40 ? 'low' : pct < 70 ? 'mid' : pct < 90 ? 'high' : 'critical';

  return `
    <div class="card-meter">
      <div class="card-meter-fill ${level}" style="width: ${pct}%"></div>
    </div>
  `;
}

function renderBadges(agent: TrackedAgent): string {
  const badges: string[] = [];

  if (agent.background) {
    badges.push('<span class="card-badge bg">BG</span>');
  }
  if (agent.isolation === 'worktree') {
    badges.push('<span class="card-badge iso">WT</span>');
  }
  badges.push(`<span class="card-badge model">${escHtml(agent.model)}</span>`);

  return badges.length > 0 ? `<div class="card-badges">${badges.join('')}</div>` : '';
}

// ── Flow Diagram (Canvas) ─────────────────────────────────────
function renderFlow(flow: AgentFlowNode[], bottlenecks: string[]): void {
  if (flow.length === 0) {
    $flowSection.classList.add('hidden');
    return;
  }
  $flowSection.classList.remove('hidden');

  const container = $flowCanvas.parentElement!;
  const dpr = window.devicePixelRatio || 1;

  const nodeW = 80;
  const nodeH = 36;
  const gapX = 32;
  const gapY = 16;
  const padX = 16;
  const padY = 12;

  const groups = groupByPhase(flow);
  const cols = groups.length;
  const maxRows = Math.max(1, ...groups.map((g) => g.length));

  const canvasW = padX * 2 + cols * nodeW + (cols - 1) * gapX;
  const canvasH = padY * 2 + maxRows * nodeH + (maxRows - 1) * gapY;

  $flowCanvas.style.width = canvasW + 'px';
  $flowCanvas.style.height = canvasH + 'px';
  $flowCanvas.width = canvasW * dpr;
  $flowCanvas.height = canvasH * dpr;

  const ctx = $flowCanvas.getContext('2d')!;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, canvasW, canvasH);

  const positions = new Map<string, { x: number; y: number }>();

  for (let col = 0; col < groups.length; col++) {
    const group = groups[col];
    const totalGroupH = group.length * nodeH + (group.length - 1) * gapY;
    const startY = padY + (canvasH - padY * 2 - totalGroupH) / 2;

    for (let row = 0; row < group.length; row++) {
      const node = group[row];
      const x = padX + col * (nodeW + gapX);
      const y = startY + row * (nodeH + gapY);
      positions.set(node.agentId, { x, y });
    }
  }

  // Draw edges
  ctx.lineWidth = 1.5;
  for (let col = 0; col < groups.length - 1; col++) {
    const srcGroup = groups[col];
    const dstGroup = groups[col + 1];

    for (const src of srcGroup) {
      const srcPos = positions.get(src.agentId)!;
      const srcRight = srcPos.x + nodeW;
      const srcMidY = srcPos.y + nodeH / 2;

      for (const dst of dstGroup) {
        const dstPos = positions.get(dst.agentId)!;
        const dstLeft = dstPos.x;
        const dstMidY = dstPos.y + nodeH / 2;

        ctx.beginPath();
        ctx.strokeStyle = getStatusColor(src.status, 0.4);
        const cpX = (srcRight + dstLeft) / 2;
        ctx.moveTo(srcRight, srcMidY);
        ctx.bezierCurveTo(cpX, srcMidY, cpX, dstMidY, dstLeft, dstMidY);
        ctx.stroke();

        // Arrow head
        const arrowSize = 5;
        ctx.fillStyle = getStatusColor(src.status, 0.4);
        ctx.beginPath();
        ctx.moveTo(dstLeft, dstMidY);
        ctx.lineTo(dstLeft - arrowSize, dstMidY - arrowSize / 2);
        ctx.lineTo(dstLeft - arrowSize, dstMidY + arrowSize / 2);
        ctx.closePath();
        ctx.fill();
      }
    }
  }

  // Draw nodes
  for (const [agentId, pos] of positions) {
    const node = flow.find((n) => n.agentId === agentId)!;
    const isBottleneck = bottlenecks.includes(agentId);
    drawNode(ctx, pos.x, pos.y, nodeW, nodeH, node, isBottleneck);
  }
}

function drawNode(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  node: AgentFlowNode,
  isBottleneck: boolean,
): void {
  const r = 5;
  const color = getStatusColor(node.status, 1);
  const bgColor = getStatusColor(node.status, 0.12);

  // Rounded rect
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();

  ctx.fillStyle = bgColor;
  ctx.fill();

  ctx.strokeStyle = isBottleneck ? '#f14c4c' : color;
  ctx.lineWidth = isBottleneck ? 2 : 1;
  ctx.stroke();

  // Label
  const label = TYPE_LABELS[node.type] || node.type.slice(0, 8);
  ctx.fillStyle = color;
  ctx.font = '600 10px var(--vscode-editor-fontFamily, monospace)';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(label, x + w / 2, y + h / 2 - 4);

  // Status text
  const statusLabel = node.status === 'running' ? 'active' : node.status;
  const fg = getComputedStyle(document.body).getPropertyValue('--fg-muted').trim() || '#808080';
  ctx.fillStyle = fg;
  ctx.font = '9px var(--vscode-font-family, sans-serif)';
  ctx.fillText(statusLabel, x + w / 2, y + h / 2 + 8);

  // Pulse ring for running
  if (node.status === 'running') {
    ctx.beginPath();
    ctx.arc(x + w - 6, y + 6, 3, 0, Math.PI * 2);
    ctx.fillStyle = color;
    ctx.fill();
  }
}

function groupByPhase(flow: AgentFlowNode[]): AgentFlowNode[][] {
  if (flow.length === 0) return [];

  const phases: AgentFlowNode[][] = [];
  const typeOrder = [
    'product-owner',
    'scrum-master',
    'Plan',
    'senior-frontend',
    'senior-backend',
    'senior-qs',
    'Explore',
    'worker-frontend',
    'worker-backend',
    'worker-qs',
    'debugger',
  ];

  const byType = new Map<string, AgentFlowNode[]>();
  for (const node of flow) {
    const key = node.type;
    if (!byType.has(key)) byType.set(key, []);
    byType.get(key)!.push(node);
  }

  // Group parallel agents of same type together, order by type hierarchy
  const orderedTypes = [...byType.keys()].sort((a, b) => {
    const ai = typeOrder.indexOf(a);
    const bi = typeOrder.indexOf(b);
    return (ai === -1 ? 99 : ai) - (bi === -1 ? 99 : bi);
  });

  for (const t of orderedTypes) {
    phases.push(byType.get(t)!);
  }

  return phases;
}

function getStatusColor(status: string, alpha: number): string {
  switch (status) {
    case 'running':
      return `rgba(0, 122, 204, ${alpha})`;
    case 'completed':
      return `rgba(78, 201, 176, ${alpha})`;
    case 'spawning':
      return `rgba(181, 206, 168, ${alpha})`;
    case 'failed':
      return `rgba(241, 76, 76, ${alpha})`;
    default:
      return `rgba(128, 128, 128, ${alpha})`;
  }
}

// ── Duration Updater ──────────────────────────────────────────
function startDurationUpdater(): void {
  if (_durationTimerId !== null) {
    clearInterval(_durationTimerId);
  }
  _durationTimerId = window.setInterval(() => {
    const els = document.querySelectorAll<HTMLElement>('.duration-val');
    const now = Date.now();
    for (const el of els) {
      const status = el.dataset.status;
      if (status === 'completed' || status === 'failed') continue;
      const spawned = parseInt(el.dataset.spawned || '0', 10);
      if (spawned > 0) {
        el.textContent = formatDuration(now - spawned);
      }
    }
  }, 1000) as unknown as number;
}

// ── Helpers ───────────────────────────────────────────────────
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
  'general-purpose': 'Agent',
  claude: 'Claude',
  'claude-code-guide': 'Guide',
};

function formatDuration(ms: number): string {
  if (ms < 0) ms = 0;
  const secs = Math.floor(ms / 1000);
  if (secs < 60) return `${secs}s`;
  const mins = Math.floor(secs / 60);
  const remSecs = secs % 60;
  if (mins < 60) return `${mins}m ${remSecs}s`;
  const hrs = Math.floor(mins / 60);
  const remMins = mins % 60;
  return `${hrs}h ${remMins}m`;
}

function formatTokens(n: number): string {
  if (n <= 0) return '0';
  if (n < 1000) return String(n);
  if (n < 1_000_000) return (n / 1000).toFixed(1) + 'k';
  return (n / 1_000_000).toFixed(2) + 'M';
}

function escHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
