import { useEffect, useState } from 'react'
import { api } from '../api'
import { adminErrorMessage } from '../apiErrors'
import { useI18n } from '../i18n/I18nContext'

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
  userReadAt: string | null
  createdAt: string
  updatedAt: string
}

export default function Inquiries() {
  const { t, locale } = useI18n()
  const [list, setList] = useState<Inquiry[]>([])
  const [error, setError] = useState('')
  const [selected, setSelected] = useState<Inquiry | null>(null)
  const [adminReply, setAdminReply] = useState('')
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)

  const load = () =>
    api.getInquiries().then(setList).catch((e) => setError(adminErrorMessage(e, t('errors.generic'))))

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
      setError(adminErrorMessage(e, t('inquiries.saveFail')))
    } finally {
      setSaving(false)
    }
  }

  const cancelReply = async () => {
    if (!selected) return
    if (!confirm('답변을 취소하시겠습니까?')) return
    setSaving(true)
    try {
      const updated = await api.updateInquiryReply(selected.id, { adminReply: '' })
      setSelected(updated)
      setList((prev) => prev.map((i) => (i.id === updated.id ? updated : i)))
    } catch (e) {
      setError(adminErrorMessage(e, t('inquiries.saveFail')))
    } finally {
      setSaving(false)
    }
  }

  const deleteInquiry = async () => {
    if (!selected) return
    if (!confirm('문의를 삭제하시겠습니까?')) return
    setDeleting(true)
    try {
      await api.deleteInquiry(selected.id)
      setList((prev) => prev.filter((i) => i.id !== selected.id))
      setSelected(null)
    } catch (e) {
      setError(adminErrorMessage(e, t('inquiries.saveFail')))
    } finally {
      setDeleting(false)
    }
  }

  const formatDate = (s: string) => {
    try {
      const d = new Date(s)
      return d.toLocaleString(locale, {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
      })
    } catch {
      return s
    }
  }

  if (error && list.length === 0) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">{t('inquiries.title')}</h2>

      {error && list.length > 0 && <p className="text-sm text-destructive">{error}</p>}

      <div className="flex gap-4 flex-1 min-h-0">
        <div className="w-96 flex-shrink-0 rounded-lg border border-border bg-card overflow-hidden flex flex-col">
          <div className="p-3 border-b border-border font-medium text-card-foreground">
            {t('inquiries.list')}
          </div>
          <ul className="overflow-auto flex-1 divide-y divide-border">
            {list.length === 0 && (
              <li className="p-4 text-sm text-muted-foreground">{t('inquiries.empty')}</li>
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
                      {item.status === 'answered' ? t('inquiries.answered') : t('inquiries.pending')}
                    </span>
                    {item.status === 'answered' && item.repliedAt && (
                      <span className="text-xs text-muted-foreground ml-2">
                        {t('inquiries.replyAt', { date: formatDate(item.repliedAt) })}
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
            <p className="text-muted-foreground">{t('inquiries.selectPrompt')}</p>
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
                  <label className="block text-sm font-medium text-foreground mb-1">
                    {t('inquiries.adminReply')}
                  </label>
                  <textarea
                    value={adminReply}
                    onChange={(e) => setAdminReply(e.target.value)}
                    rows={5}
                    className="w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
                    placeholder={t('inquiries.replyPlaceholder')}
                  />
                </div>
                {selected.repliedAt && (
                  <p className="text-xs text-muted-foreground">
                    {t('inquiries.lastReply', { date: formatDate(selected.repliedAt) })}
                  </p>
                )}
                <div className="flex flex-wrap gap-2 items-center">
                  <button
                    type="submit"
                    disabled={saving}
                    className="px-4 py-2 rounded-md bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 disabled:opacity-50"
                  >
                    {saving ? t('inquiries.saving') : t('inquiries.save')}
                  </button>
                  <button
                    type="button"
                    disabled={saving || deleting || !selected.adminReply}
                    onClick={cancelReply}
                    className="px-3 py-2 rounded-md border border-border text-sm disabled:opacity-50"
                  >
                    답변취소
                  </button>
                  <button
                    type="button"
                    disabled={saving || deleting}
                    onClick={deleteInquiry}
                    className="px-3 py-2 rounded-md border border-destructive text-destructive text-sm disabled:opacity-50"
                  >
                    {deleting ? '삭제중...' : '문의삭제'}
                  </button>
                </div>
              </form>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
