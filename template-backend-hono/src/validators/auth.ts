import { z } from 'zod';

/**
 * Schema for user login input validation.
 */
export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

/**
 * Schema for user registration input validation.
 */
export const registerSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2).max(100),
  password: z.string().min(8),
});

/** Inferred type for login input. */
export type LoginInput = z.infer<typeof loginSchema>;

/** Inferred type for registration input. */
export type RegisterInput = z.infer<typeof registerSchema>;
