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
  getUserDetail: (id: string) =>
    request<{
      user: {
        id: string
        email: string | null
        authProvider: 'google' | 'apple' | 'kakao' | 'naver' | 'unknown'
        displayName: string | null
        createdAt: string
        isActive: boolean
        deactivatedAt: string | null
        deactivationReason: string | null
        deactivatedBy: 'self' | 'admin' | null
      }
      summary30d: {
        from: string
        to: string
        totalHabits: number
        trackedHabitCount: number
        totalRecords: number
        completedRecords: number
        completionRatePercent: number | null
      }
      todaySummary: {
        date: string
        totalHabits: number
        recordedHabits: number
        completedHabits: number
        completionRatePercent: number | null
      }
      habits: {
        id: string
        name: string
        category: string | null
        goalType: string
        numberDirection: 'gte' | 'lte'
        unit: string | null
        goalValue: number | null
        today: {
          hasRecord: boolean
          value: number | null
          completed: boolean
        }
        summary30d: {
          totalRecords: number
          completedRecords: number
          completionRatePercent: number | null
          latestValue: number | null
        }
      }[]
    }>(`/admin/users/${id}`),
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
        nameEn?: string
        category?: string
        categoryEn?: string
        goalType: string
        numberDirection?: 'gte' | 'lte'
        goalValue?: number | null
        colorHex?: string
        iconName?: string
        isActive: boolean
      }[]
    >('/admin/habit-templates'),
  getHabitCategoriesInUse: () => request<{ inUse: string[] }>('/admin/habit-categories-in-use'),
  createTemplate: (body: {
    name: string
    nameEn?: string
    category?: string
    categoryEn?: string
    goalType?: string
    numberDirection?: 'gte' | 'lte'
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
  getNotices: () =>
    request<{ id: string; title: string; body: string; titleEn?: string; bodyEn?: string; publishedAt?: string }[]>(
      '/admin/notices',
    ),
  createNotice: (body: { title: string; body: string; titleEn?: string; bodyEn?: string }) =>
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

  getLegalDocuments: (type?: 'terms' | 'privacy', locale?: 'ko' | 'en' | 'all') => {
    const params = new URLSearchParams()
    if (type) params.set('type', type)
    if (locale) params.set('locale', locale)
    const q = params.toString()
    return request<{
      id: string
      type: string
      locale: string
      version: number
      title: string
      content: string
      effectiveFrom: string | null
      createdAt: string
      updatedAt: string
    }[]>(`/admin/legal-documents${q ? `?${q}` : ''}`)
  },
  createLegalDocument: (body: {
    type: 'terms' | 'privacy'
    locale?: 'ko' | 'en'
    title?: string
    content?: string
    effectiveFrom?: string
    titleKo?: string
    contentKo?: string
    titleEn?: string
    contentEn?: string
  }) =>
    request<{
      id: string
      type: string
      locale: string
      version: number
      title: string
      content: string
      effectiveFrom: string | null
      createdAt: string
      updatedAt: string
    }>('/admin/legal-documents', { method: 'POST', body: JSON.stringify(body) }),
  updateLegalDocumentVersion: (body: {
    type: 'terms' | 'privacy'
    version: number
    effectiveFrom?: string | null
    titleKo?: string
    contentKo?: string
    titleEn?: string
    contentEn?: string
  }) =>
    request<{ ok: boolean }>('/admin/legal-documents/version', {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  updateLegalDocument: (id: string, body: { title?: string; content?: string; effectiveFrom?: string | null }) =>
    request<{
      id: string
      type: string
      locale: string
      version: number
      title: string
      content: string
      effectiveFrom: string | null
      createdAt: string
      updatedAt: string
    }>(`/admin/legal-documents/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),
};
