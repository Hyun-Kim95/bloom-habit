/** Admin-facing API error with a safe UI message (technical detail is log-only). */
export class AdminApiError extends Error {
  readonly userMessage: string
  readonly logDetail: string

  constructor(userMessage: string, logDetail: string) {
    super(userMessage)
    this.name = 'AdminApiError'
    this.userMessage = userMessage
    this.logDetail = logDetail
  }
}

function containsHangul(s: string): boolean {
  return /[\uAC00-\uD7A3]/.test(s)
}

function isUserSafeServerMessage(msg: string): boolean {
  const t = msg.trim()
  if (!t || t.length > 200) return false
  if (t.startsWith('{') || t.includes('statusCode') || t.includes('DioException')) {
    return false
  }
  if (containsHangul(t)) return true
  const lower = t.toLowerCase()
  return (
    lower.includes('invalid email') ||
    lower.includes('invalid password') ||
    lower.includes('inactive user') ||
    lower.includes('not found')
  )
}

export function parseApiErrorBody(
  text: string,
  status: number,
  fallback: string,
): { userMessage: string; logDetail: string } {
  const logDetail = text.trim() || `HTTP ${status}`
  let userMessage = fallback

  try {
    const data = JSON.parse(text) as { message?: unknown }
    const raw = data.message
    if (typeof raw === 'string' && isUserSafeServerMessage(raw)) {
      userMessage = raw.trim()
    } else if (Array.isArray(raw) && raw.length > 0) {
      const first = String(raw[0])
      if (isUserSafeServerMessage(first)) userMessage = first.trim()
    }
  } catch {
    if (isUserSafeServerMessage(text)) {
      userMessage = text.trim()
    }
  }

  return { userMessage, logDetail }
}

export function adminErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof AdminApiError) return error.userMessage
  return fallback
}
