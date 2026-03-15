import { describe, it, expect } from 'vitest';

describe('config', () => {
  it('should export config with apiUrl and appTitle', async () => {
    const { config } = await import('./index');
    expect(config).toBeDefined();
    expect(config.apiUrl).toBeDefined();
    expect(config.appTitle).toBeDefined();
  });
});
