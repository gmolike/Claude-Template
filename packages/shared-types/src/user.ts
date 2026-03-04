import { z } from 'zod';

/** Zod Schema für User — Runtime-Validierung + Type-Inference */
export const UserSchema = z.object({
  id: z.string().cuid(),
  email: z.string().email(),
  name: z.string().nullable(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

/** TypeScript Type — abgeleitet aus dem Zod Schema */
export type User = z.infer<typeof UserSchema>;

/** Schema für User-Erstellung */
export const CreateUserSchema = UserSchema.pick({ email: true, name: true });
export type CreateUser = z.infer<typeof CreateUserSchema>;

/** Schema für User-Update */
export const UpdateUserSchema = UserSchema.pick({ name: true }).partial();
export type UpdateUser = z.infer<typeof UpdateUserSchema>;
