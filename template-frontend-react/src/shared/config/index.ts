export const config = {
  apiUrl: import.meta.env.VITE_API_URL ?? 'http://localhost:3001/api',
  appName: '{{PROJECT_NAME}}',
} as const;
