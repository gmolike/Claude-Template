import { QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { RouterProvider, createRouter } from '@tanstack/react-router';
import { queryClient } from '@shared/api';
import { routeTree } from '../routeTree.gen';

const router = createRouter({ routeTree, context: { queryClient }, defaultPreloadStaleTime: 0 });

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

/** Root App-Komponente mit allen Providern. */
export const App = () => (
  <QueryClientProvider client={queryClient}>
    <RouterProvider router={router} />
    <ReactQueryDevtools initialIsOpen={false} />
  </QueryClientProvider>
);
