import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { healthRoute } from './routes/health';

export const app = new Hono().basePath('/api');

app.use('*', logger());
app.use('*', cors({ origin: ['http://localhost:3000'], credentials: true }));

app.route('/health', healthRoute);

/** Catch-All 404 */
app.notFound((c) => c.json({ error: 'Not Found' }, 404));

/** Global Error Handler */
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  return c.json({ error: 'Internal Server Error' }, 500);
});
