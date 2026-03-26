import { prisma } from '../db/client';
import type { UpdateUserInput } from '../validators/users';

/**
 * Service for user-related database operations.
 */
export const userService = {
  /**
   * Retrieves a user by their unique ID.
   *
   * @param id - The user's UUID
   * @returns The user record or null if not found
   */
  async getById(id: string) {
    return prisma.user.findUnique({ where: { id } });
  },

  /**
   * Retrieves a user by their email address.
   *
   * @param email - The user's email address
   * @returns The user record or null if not found
   */
  async getByEmail(email: string) {
    return prisma.user.findUnique({ where: { email } });
  },

  /**
   * Creates a new user record.
   *
   * @param data - The user's email, name, and hashed password
   * @returns The newly created user record
   */
  async create(data: { email: string; name: string; passwordHash: string }) {
    return prisma.user.create({ data });
  },

  /**
   * Updates an existing user's profile fields.
   *
   * @param id - The user's UUID
   * @param data - Partial profile fields to update
   * @returns The updated user record
   */
  async update(id: string, data: UpdateUserInput) {
    return prisma.user.update({ where: { id }, data });
  },
};
