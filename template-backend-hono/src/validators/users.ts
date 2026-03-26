import { z } from 'zod';

/**
 * Schema for updating a user's profile.
 */
export const updateUserSchema = z.object({
  name: z.string().min(2).max(100).optional(),
  avatarUrl: z.string().url().nullable().optional(),
  bio: z.string().max(500).nullable().optional(),
});

/** Inferred type for user update input. */
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
