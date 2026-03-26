import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { swaggerUI } from '@hono/swagger-ui';
import { authRoutes } from './routes/auth';
import { userRoutes } from './routes/users';
import { errorHandler } from './middleware/error-handler';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', cors());
app.onError(errorHandler);

// Swagger
app.get('/swagger', swaggerUI({ url: '/swagger/doc' }));
app.get('/swagger/doc', (c) => c.json(openApiSpec));

// Routes
app.route('/api/auth', authRoutes);
app.route('/api/users', userRoutes);

// Health check
app.get('/health', (c) => c.json({ status: 'ok' }));

const port = Number(process.env['PORT']) || 3001;
console.log(`Server running on http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch,
};

const openApiSpec = {
  openapi: '3.1.0',
  info: { title: '{{PROJECT_NAME}} API', version: '0.1.0' },
  paths: {},
};
