import { queryOptions } from '@tanstack/react-query';
import type { User } from '@repo/shared-types';

/**
 * Query Factory für User-Entity (TanStack Query v5 Pattern).
 *
 * @example
 * ```tsx
 * const { data } = useQuery(userQueries.list());
 * const { data } = useQuery(userQueries.detail('user-123'));
 * ```
 */
export const userQueries = {
  all: () => ['users'] as const,
  lists: () => [...userQueries.all(), 'list'] as const,
  list: () =>
    queryOptions({
      queryKey: userQueries.lists(),
      queryFn: async (): Promise<User[]> => {
        const res = await fetch('/api/users');
        if (!res.ok) throw new Error('Failed to fetch users');
        return res.json();
      },
    }),
  details: () => [...userQueries.all(), 'detail'] as const,
  detail: (id: string) =>
    queryOptions({
      queryKey: [...userQueries.details(), id],
      queryFn: async (): Promise<User> => {
        const res = await fetch(`/api/users/${id}`);
        if (!res.ok) throw new Error(`Failed to fetch user ${id}`);
        return res.json();
      },
      staleTime: 5000,
    }),
};
