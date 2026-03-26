import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { loginSchema, registerSchema } from '../validators/auth';
import { userService } from '../services/user-service';

export const authRoutes = new Hono();

authRoutes.post('/login', zValidator('json', loginSchema), async (c) => {
  const { email } = c.req.valid('json');
  const user = await userService.getByEmail(email);

  if (!user) {
    return c.json({ error: { code: 'INVALID_CREDENTIALS', message: 'Invalid credentials' } }, 401);
  }

  // TODO: Verify password hash
  return c.json({
    accessToken: 'TODO_GENERATE_JWT',
    refreshToken: 'TODO_GENERATE_REFRESH',
    expiresIn: 3600,
    user: { id: user.id, email: user.email, name: user.name },
  });
});

authRoutes.post('/register', zValidator('json', registerSchema), async (c) => {
  const { email, name, password } = c.req.valid('json');

  const existing = await userService.getByEmail(email);
  if (existing) {
    return c.json({ error: { code: 'EMAIL_EXISTS', message: 'Email already exists' } }, 409);
  }

  // TODO: Hash password
  const user = await userService.create({ email, name, passwordHash: password });

  return c.json(
    {
      accessToken: 'TODO_GENERATE_JWT',
      refreshToken: 'TODO_GENERATE_REFRESH',
      expiresIn: 3600,
      user: { id: user.id, email: user.email, name: user.name },
    },
    201,
  );
});
