import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { updateUserSchema } from '../validators/users';
import { userService } from '../services/user-service';

export const userRoutes = new Hono();

userRoutes.get('/me', async (c) => {
  // TODO: Get user ID from auth middleware
  const userId = c.req.header('X-User-Id');
  if (!userId) return c.json({ error: { code: 'UNAUTHORIZED', message: 'Unauthorized' } }, 401);

  const user = await userService.getById(userId);
  if (!user) return c.json({ error: { code: 'NOT_FOUND', message: 'User not found' } }, 404);

  return c.json(user);
});

userRoutes.patch('/me', zValidator('json', updateUserSchema), async (c) => {
  const userId = c.req.header('X-User-Id');
  if (!userId) return c.json({ error: { code: 'UNAUTHORIZED', message: 'Unauthorized' } }, 401);

  const data = c.req.valid('json');
  const user = await userService.update(userId, data);

  return c.json(user);
});

userRoutes.get('/:id', async (c) => {
  const user = await userService.getById(c.req.param('id'));
  if (!user) return c.json({ error: { code: 'NOT_FOUND', message: 'User not found' } }, 404);
  return c.json(user);
});
