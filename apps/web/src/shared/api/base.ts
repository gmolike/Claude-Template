const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

/** Basis-Fetch-Wrapper für API-Aufrufe. */
export async function apiFetch<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  });
  if (!res.ok) throw new Error(`API Error: ${res.status} ${res.statusText}`);
  return res.json() as Promise<T>;
}
