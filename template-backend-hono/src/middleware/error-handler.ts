import type { ErrorHandler } from 'hono';
import { ZodError } from 'zod';

/**
 * Global error handler middleware for the Hono application.
 * Handles Zod validation errors with structured 400 responses
 * and all other errors with a generic 500 response.
 *
 * @param err - The error that was thrown
 * @param c - The Hono context
 * @returns A JSON error response with appropriate HTTP status
 */
export const errorHandler: ErrorHandler = (err, c) => {
  if (err instanceof ZodError) {
    return c.json(
      {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: err.errors.map((e) => ({ field: e.path.join('.'), message: e.message })),
        },
      },
      400,
    );
  }

  console.error('Unhandled error:', err);
  return c.json(
    {
      error: { code: 'INTERNAL_ERROR', message: 'Internal server error' },
    },
    500,
  );
};
