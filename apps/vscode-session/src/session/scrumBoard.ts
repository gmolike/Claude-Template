import * as fs from 'fs';
import * as path from 'path';

/** Status of a Scrum task derived from its directory position. */
export type ScrumTaskStatus = 'backlog' | 'in-progress' | 'done';

/** A single Scrum task read from the .scrum/ directory structure. */
export interface ScrumTask {
  /** Unique identifier built from domain + relative file path. */
  id: string;
  /** Human-readable title derived from the markdown filename. */
  title: string;
  /** The domain folder the task lives under (e.g. 'web', 'api'). */
  domain: string;
  /** Current status column of the task. */
  status: ScrumTaskStatus;
  /** Absolute path to the markdown file on disk. */
  filePath: string;
}

/** Known domain directories to scan inside .scrum/. */
const KNOWN_DOMAINS = ['web', 'api', 'mobile', 'shared', 'vscode-session', 'content'] as const;

/** Valid status subdirectory names. */
const STATUS_DIRS: ScrumTaskStatus[] = ['backlog', 'in-progress', 'done'];

/**
 * Derives a display title from a markdown filename.
 * Strips the `.md` extension, replaces hyphens with spaces,
 * and capitalizes the first letter.
 *
 * @param filename - Bare filename including `.md` extension.
 * @returns Human-readable task title.
 * @example
 * titleFromFilename('add-auth-flow.md') // → 'Add auth flow'
 */
function titleFromFilename(filename: string): string {
  const base = filename.endsWith('.md') ? filename.slice(0, -3) : filename;
  const spaced = base.replace(/-/g, ' ');
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

/**
 * Scans the `.scrum/` directory tree inside the given workspace and returns
 * all Scrum tasks found. Each task is a markdown file under
 * `.scrum/{domain}/{status}/*.md`.
 *
 * Errors are handled gracefully: a missing `.scrum/` directory or any
 * unreadable subdirectory returns an empty array rather than throwing.
 *
 * @param workspacePath - Absolute path to the VS Code workspace root.
 * @returns Array of `ScrumTask` objects, sorted by domain then status then title.
 * @example
 * const tasks = getScrumTasks('/home/user/my-project');
 */
export function getScrumTasks(workspacePath: string): ScrumTask[] {
  const scrumRoot = path.join(workspacePath, '.scrum');

  if (!fs.existsSync(scrumRoot)) {
    return [];
  }

  const tasks: ScrumTask[] = [];

  for (const domain of KNOWN_DOMAINS) {
    for (const status of STATUS_DIRS) {
      const dir = path.join(scrumRoot, domain, status);

      let entries: string[];
      try {
        entries = fs.readdirSync(dir);
      } catch {
        // Directory does not exist or is unreadable — skip silently.
        continue;
      }

      for (const entry of entries) {
        // Skip non-markdown files and git placeholder files.
        if (!entry.endsWith('.md') || entry === '.gitkeep') {
          continue;
        }

        const filePath = path.join(dir, entry);
        tasks.push({
          id: `${domain}/${status}/${entry}`,
          title: titleFromFilename(entry),
          domain,
          status,
          filePath,
        });
      }
    }
  }

  return tasks;
}

/**
 * Moves a Scrum task file from its current status directory to the
 * directory matching `newStatus`, keeping the filename unchanged.
 *
 * Fails silently if the source file does not exist.
 *
 * @param task - The task to move.
 * @param newStatus - The target status column.
 * @example
 * moveTask(task, 'in-progress');
 */
export function moveTask(task: ScrumTask, newStatus: ScrumTaskStatus): void {
  if (!fs.existsSync(task.filePath)) {
    return;
  }

  const filename = path.basename(task.filePath);
  // Walk up two levels: status dir → domain dir → .scrum dir → workspace root.
  const domainDir = path.dirname(path.dirname(task.filePath));
  const targetDir = path.join(domainDir, newStatus);

  try {
    // Ensure target directory exists before moving.
    fs.mkdirSync(targetDir, { recursive: true });
    fs.renameSync(task.filePath, path.join(targetDir, filename));
  } catch {
    // Ignore file-system errors (e.g. cross-device rename on some systems).
  }
}
