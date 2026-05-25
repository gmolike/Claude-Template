import { execSync } from 'child_process';

export interface AgentSession {
  name: string;
  domain: string;
  active: boolean;
}

/**
 * Detect active tmux sessions that match the project orchestration pattern.
 * Sessions follow the pattern: {PROJECT_NAME}:{domain}
 * Example: myproject:web, myproject:api, myproject:mobile
 * Returns empty array if tmux is not available.
 *
 * @returns Array of detected agent sessions with name, domain, and active status.
 */
export function getTmuxSessions(): AgentSession[] {
  try {
    const raw = execSync('tmux list-sessions -F "#{session_name}:#{session_attached}"', {
      encoding: 'utf8',
      timeout: 3000,
      stdio: ['pipe', 'pipe', 'pipe'],
    }).trim();

    if (!raw) return [];

    const sessions: AgentSession[] = [];

    for (const line of raw.split('\n')) {
      if (!line.trim()) continue;
      // Format: "session_name:attached_flag"
      // The session_name itself may contain colons (project:domain format)
      const lastColon = line.lastIndexOf(':');
      if (lastColon <= 0) continue;

      const sessionName = line.slice(0, lastColon);
      const attached = line.slice(lastColon + 1) === '1';

      // Extract domain from session name (format: project:domain)
      const colonIdx = sessionName.indexOf(':');
      const domain = colonIdx > 0 ? sessionName.slice(colonIdx + 1) : sessionName;

      sessions.push({
        name: sessionName,
        domain,
        active: attached,
      });
    }

    return sessions;
  } catch {
    // tmux not installed or no sessions running
    return [];
  }
}
