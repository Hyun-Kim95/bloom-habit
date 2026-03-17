const API_BASE = import.meta.env.VITE_API_BASE ?? 'http://localhost:3000';

function getToken(): string | null {
  return localStorage.getItem('bloom_admin_token');
}

export function setAdminToken(token: string) {
  localStorage.setItem('bloom_admin_token', token);
}

export function clearAdminToken() {
  localStorage.removeItem('bloom_admin_token');
}

export async function adminLogin(email: string, password: string): Promise<{ accessToken: string }> {
  const res = await fetch(`${API_BASE}/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  if (res.status === 401) {
    clearAdminToken();
    window.location.href = '/login';
    throw new Error('Unauthorized');
  }
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export const api = {
  getUsers: () => request<{ id: string; email: string | null; displayName: string | null }[]>('/admin/users'),
  getStats: () => request<{ totalUsers: number; totalHabits: number; totalRecords: number }>('/admin/stats'),
  getTemplates: () => request<{ id: string; name: string; category?: string; goalType: string; isActive: boolean }[]>('/admin/habit-templates'),
  createTemplate: (body: { name: string; category?: string; goalType?: string }) =>
    request('/admin/habit-templates', { method: 'POST', body: JSON.stringify(body) }),
  updateTemplate: (id: string, body: object) =>
    request(`/admin/habit-templates/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
  deleteTemplate: (id: string) =>
    request(`/admin/habit-templates/${id}`, { method: 'DELETE' }),
  getNotices: () => request<{ id: string; title: string; body: string; publishedAt?: string }[]>('/admin/notices'),
  createNotice: (body: { title: string; body: string }) =>
    request('/admin/notices', { method: 'POST', body: JSON.stringify(body) }),
  updateNotice: (id: string, body: object) =>
    request(`/admin/notices/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
  deleteNotice: (id: string) =>
    request(`/admin/notices/${id}`, { method: 'DELETE' }),
  getConfig: () => request<Record<string, string>>('/admin/system-config'),
  patchConfig: (body: Record<string, string>) =>
    request('/admin/system-config', { method: 'PATCH', body: JSON.stringify(body) }),
};
