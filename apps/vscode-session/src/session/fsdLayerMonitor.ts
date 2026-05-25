import * as path from 'path';

/** A valid FSD layer name as defined in the project architecture. */
export type FsdLayer = 'app' | 'routes' | 'pages' | 'widgets' | 'features' | 'entities' | 'shared';

/** Ordered list of all FSD layers (top → bottom). */
export const FSD_LAYERS: FsdLayer[] = [
  'app',
  'routes',
  'pages',
  'widgets',
  'features',
  'entities',
  'shared',
];

/** Activity record for a single FSD layer. */
export interface FsdActivity {
  layer: FsdLayer;
  files: string[];
  count: number;
}

/**
 * Categorize a list of file paths by their FSD layer.
 * Matches path segments like src/app/, src/pages/, src/features/, etc.
 *
 * @param filePaths - Array of absolute or relative file paths to categorize
 * @returns Array of FsdActivity records for layers that have at least one file,
 *          ordered according to FSD_LAYERS
 * @example
 * ```ts
 * const activity = categorizeFsdFiles([
 *   '/workspace/src/features/auth/model.ts',
 *   '/workspace/src/entities/user/index.ts',
 * ]);
 * // [{ layer: 'features', files: ['model.ts'], count: 1 }, ...]
 * ```
 */
export function categorizeFsdFiles(filePaths: string[]): FsdActivity[] {
  const layerMap = new Map<FsdLayer, string[]>();

  for (const layer of FSD_LAYERS) {
    layerMap.set(layer, []);
  }

  for (const filePath of filePaths) {
    const normalized = filePath.replace(/\\/g, '/').toLowerCase();
    for (const layer of FSD_LAYERS) {
      // Match patterns like src/app/, src/features/, /app/, /features/
      if (
        normalized.includes('/src/' + layer + '/') ||
        normalized.includes('/' + layer + '/') ||
        normalized.endsWith('/' + layer)
      ) {
        const basename = path.basename(filePath);
        layerMap.get(layer)!.push(basename);
        break; // A file belongs to exactly one layer
      }
    }
  }

  return FSD_LAYERS.map((layer) => ({
    layer,
    files: layerMap.get(layer) || [],
    count: (layerMap.get(layer) || []).length,
  })).filter((a) => a.count > 0);
}
