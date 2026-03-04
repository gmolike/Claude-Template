import { serve } from '@hono/node-server';
import { app } from './app';

const port = Number(process.env.PORT) || 3001;

console.log(`🚀 API Server läuft auf http://localhost:${port}`);

serve({ fetch: app.fetch, port });
