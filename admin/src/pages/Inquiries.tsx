import { useEffect, useState } from 'react'
import { api } from '../api'

type Inquiry = {
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
}

export default function Inquiries() {
  const [list, setList] = useState<Inquiry[]>([])
  const [error, setError] = useState('')
  const [selected, setSelected] = useState<Inquiry | null>(null)
  const [adminReply, setAdminReply] = useState('')
  const [saving, setSaving] = useState(false)

  const load = () => api.getInquiries().then(setList).catch((e) => setError(e.message))

  useEffect(() => {
    load()
  }, [])

  useEffect(() => {
    if (selected) setAdminReply(selected.adminReply ?? '')
  }, [selected])

  const select = (item: Inquiry) => {
    setSelected(item)
  }

  const saveReply = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selected) return
    setSaving(true)
    try {
      const updated = await api.updateInquiryReply(selected.id, {
        adminReply: adminReply.trim() || undefined,
      })
      setSelected(updated)
      setList((prev) => prev.map((i) => (i.id === updated.id ? updated : i)))
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  const formatDate = (s: string) => {
    try {
      const d = new Date(s)
      const yyyy = d.getFullYear()
      const mm = String(d.getMonth() + 1).padStart(2, '0')
      const dd = String(d.getDate()).padStart(2, '0')
      const hh = String(d.getHours()).padStart(2, '0')
      const mi = String(d.getMinutes()).padStart(2, '0')
      return `${yyyy}.${mm}.${dd} ${hh}:${mi}`
    } catch {
      return s
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">문의</h2>

      <div className="flex gap-4 flex-1 min-h-0">
        <div className="w-96 flex-shrink-0 rounded-lg border border-border bg-card overflow-hidden flex flex-col">
          <div className="p-3 border-b border-border font-medium text-card-foreground">목록</div>
          <ul className="overflow-auto flex-1 divide-y divide-border">
            {list.length === 0 && (
              <li className="p-4 text-sm text-muted-foreground">문의가 없습니다.</li>
            )}
            {list.map((item) => (
              <li key={item.id}>
                <button
                  type="button"
                  onClick={() => select(item)}
                  className={`w-full text-left p-3 hover:bg-accent transition-colors ${
                    selected?.id === item.id ? 'bg-accent text-accent-foreground' : ''
                  }`}
                >
                  <div className="font-medium text-foreground truncate">{item.subject}</div>
                  <div className="text-xs text-muted-foreground mt-0.5">
                    {item.userEmail ?? item.userDisplayName ?? item.userId} · {formatDate(item.createdAt)}
                  </div>
                  <div className="text-xs mt-0.5">
                    <span
                      className={
                        item.status === 'answered'
                          ? 'text-green-600 dark:text-green-400'
                          : 'text-amber-600 dark:text-amber-400'
                      }
                    >
                      {item.status === 'answered' ? '답변 완료' : '대기 중'}
                    </span>
                    {item.status === 'answered' && item.repliedAt && (
                      <span className="text-xs text-muted-foreground ml-2">
                        · 답변 {formatDate(item.repliedAt)}
                      </span>
                    )}
                  </div>
                </button>
              </li>
            ))}
          </ul>
        </div>

        <div className="flex-1 min-w-0 rounded-lg border border-border bg-card p-4 flex flex-col">
          {!selected ? (
            <p className="text-muted-foreground">목록에서 문의를 선택하세요.</p>
          ) : (
            <>
              <div className="space-y-2 mb-4">
                <h3 className="font-semibold text-foreground">{selected.subject}</h3>
                <p className="text-sm text-muted-foreground">
                  {selected.userEmail ?? selected.userDisplayName ?? selected.userId} ·{' '}
                  {formatDate(selected.createdAt)}
                </p>
              </div>
              <div className="rounded border border-border bg-muted/30 p-3 text-sm text-foreground whitespace-pre-wrap mb-4">
                {selected.body}
              </div>

              <form onSubmit={saveReply} className="space-y-3 flex-1 flex flex-col min-h-0">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-1">관리자 답변</label>
                  <textarea
                    value={adminReply}
                    onChange={(e) => setAdminReply(e.target.value)}
                    rows={5}
                    className="w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    placeholder="답변 내용을 입력하세요."
                  />
                </div>
                {selected.repliedAt && (
                  <p className="text-xs text-muted-foreground">
                    마지막 답변: {formatDate(selected.repliedAt)}
                  </p>
                )}
                <button
                  type="submit"
                  disabled={saving}
                  className="self-start px-4 py-2 rounded-md bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 disabled:opacity-50"
                >
                  {saving ? '저장 중…' : '저장'}
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
