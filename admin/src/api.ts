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
  getUsers: () =>
    request<
      {
        id: string
        email: string | null
        authProvider: 'google' | 'apple' | 'kakao' | 'naver' | 'unknown'
        displayName: string | null
        createdAt: string
        isActive: boolean
        deactivatedAt: string | null
        deactivationReason: string | null
        deactivatedBy: 'self' | 'admin' | null
        habitCount: number
        totalRecords: number
        completedRecords: number
        completionRatePercent: number | null
      }[]
    >('/admin/users'),
  setUserActive: (id: string, isActive: boolean, reason?: string) =>
    request<{ ok: true }>(`/admin/users/${id}/active`, {
      method: 'PATCH',
      body: JSON.stringify({ isActive, reason }),
    }),
  getStats: () => request<{ totalUsers: number; totalHabits: number; totalRecords: number }>('/admin/stats'),
  getStatsOverTime: (from?: string, to?: string) => {
    const params = new URLSearchParams()
    if (from) params.set('from', from)
    if (to) params.set('to', to)
    const q = params.toString()
    return request<{ period: string; newUsers: number; newHabits: number; newRecords: number }[]>(
      `/admin/stats/over-time${q ? `?${q}` : ''}`
    )
  },
  getTemplates: () =>
    request<
      {
        id: string
        name: string
        category?: string
        goalType: string
        goalValue?: number | null
        colorHex?: string
        iconName?: string
        isActive: boolean
      }[]
    >('/admin/habit-templates'),
  getHabitCategoriesInUse: () => request<{ inUse: string[] }>('/admin/habit-categories-in-use'),
  createTemplate: (body: {
    name: string
    category?: string
    goalType?: string
    goalValue?: number | null
    colorHex?: string
    iconName?: string
  }) => request('/admin/habit-templates', { method: 'POST', body: JSON.stringify(body) }),
  updateTemplate: (id: string, body: object) =>
    request(`/admin/habit-templates/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
  deleteTemplate: (id: string) =>
    request(`/admin/habit-templates/${id}`, { method: 'DELETE' }),
  reseedHabitTemplates: () =>
    request<{ inserted: number }>('/admin/habit-templates/reseed', { method: 'POST' }),
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

  getInquiries: () =>
    request<{
      id: string
      userId: string
      userEmail: string | null
      userDisplayName: string | null
      subject: string
      body: string
      status: string
      adminReply: string | null
      repliedAt: string | null
      createdAt: string
      updatedAt: string
    }[]>('/admin/inquiries'),
  updateInquiryReply: (id: string, body: { adminReply?: string; status?: string }) =>
    request<{
      id: string
      userId: string
      userEmail: string | null
      userDisplayName: string | null
      subject: string
      body: string
      status: string
      adminReply: string | null
      repliedAt: string | null
      createdAt: string
      updatedAt: string
    }>(`/admin/inquiries/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),

  getLegalDocuments: (type?: 'terms' | 'privacy') =>
    request<{
      id: string
      type: string
      version: number
      title: string
      content: string
      effectiveFrom: string | null
      createdAt: string
      updatedAt: string
    }[]>(`/admin/legal-documents${type ? `?type=${type}` : ''}`),
  createLegalDocument: (body: { type: 'terms' | 'privacy'; title?: string; content?: string; effectiveFrom?: string }) =>
    request<{
      id: string
      type: string
      version: number
      title: string
      content: string
      effectiveFrom: string | null
      createdAt: string
      updatedAt: string
    }>('/admin/legal-documents', { method: 'POST', body: JSON.stringify(body) }),
  updateLegalDocument: (id: string, body: { title?: string; content?: string; effectiveFrom?: string | null }) =>
    request<{
      id: string
      type: string
      version: number
      title: string
      content: string
      effectiveFrom: string | null
      createdAt: string
      updatedAt: string
    }>(`/admin/legal-documents/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
};
