export const config = {
  apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:3001/api',
  appTitle: import.meta.env.VITE_APP_TITLE || 'claude-template',
} as const;
