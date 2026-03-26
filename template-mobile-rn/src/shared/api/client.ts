const API_BASE_URL = process.env['EXPO_PUBLIC_API_URL'] ?? 'http://localhost:3001/api';

/**
 * Minimal HTTP client for API requests in React Native.
 * Uses generated types from OpenAPI codegen.
 * Auth token is retrieved from secure storage via getAuthHeaders().
 */
export const apiClient = {
  /**
   * Performs a GET request.
   *
   * @param path - API path (e.g. '/users')
   * @returns Parsed JSON response typed as T
   */
  async get<T>(path: string): Promise<T> {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json() as Promise<T>;
  },

  /**
   * Performs a POST request.
   *
   * @param path - API path (e.g. '/users')
   * @param body - Request payload (will be JSON-serialized)
   * @returns Parsed JSON response typed as T
   */
  async post<T>(path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json() as Promise<T>;
  },

  /**
   * Performs a PATCH request.
   *
   * @param path - API path (e.g. '/users/1')
   * @param body - Partial update payload
   * @returns Parsed JSON response typed as T
   */
  async patch<T>(path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json() as Promise<T>;
  },

  /**
   * Performs a DELETE request.
   *
   * @param path - API path (e.g. '/users/1')
   * @returns Parsed JSON response typed as T
   */
  async delete<T>(path: string): Promise<T> {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json', ...getAuthHeaders() },
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json() as Promise<T>;
  },
};

/**
 * Returns auth headers if a token is available in secure storage.
 * Replace with actual secure storage implementation (e.g. expo-secure-store).
 */
function getAuthHeaders(): Record<string, string> {
  // TODO: Get token from expo-secure-store
  return {};
}

/**
 * Typed API error with HTTP status code.
 */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}
