import { Hono } from 'hono';

export const healthRoute = new Hono();

/** Health-Check Endpunkt */
healthRoute.get('/', (c) => c.json({ status: 'ok', timestamp: new Date().toISOString() }));
