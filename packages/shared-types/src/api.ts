import { z } from 'zod';

/** Standard API-Response Wrapper */
export const ApiResponseSchema = <T extends z.ZodType>(dataSchema: T) =>
  z.object({
    data: dataSchema,
    meta: z
      .object({
        timestamp: z.string(),
      })
      .optional(),
  });

/** Standard API-Error Response */
export const ApiErrorSchema = z.object({
  error: z.string(),
  message: z.string().optional(),
  statusCode: z.number(),
});

export type ApiError = z.infer<typeof ApiErrorSchema>;

/** Pagination Schema */
export const PaginationSchema = z.object({
  page: z.number().int().positive(),
  limit: z.number().int().positive().max(100),
  total: z.number().int().nonnegative(),
  totalPages: z.number().int().nonnegative(),
});

export type Pagination = z.infer<typeof PaginationSchema>;
