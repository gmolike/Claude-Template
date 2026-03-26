/**
 * Global app configuration.
 * All values are read from environment variables with safe defaults.
 */
export const config = {
  apiUrl: process.env['EXPO_PUBLIC_API_URL'] ?? 'http://localhost:3001/api',
  appName: '{{PROJECT_NAME}}',
} as const;
