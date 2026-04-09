import { useEffect, useState } from 'react'
import { api } from '../api'
import { useI18n } from '../i18n/I18nContext'
import { displayNoticeBody, displayNoticeTitle } from '../i18n/dataDisplay'

type Notice = {
  id: string
  title: string
  body: string
  titleEn?: string
  bodyEn?: string
  publishedAt?: string
}

export default function Notices() {
  const { t, lang } = useI18n()
  const [list, setList] = useState<Notice[]>([])
  const [error, setError] = useState('')
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [titleEn, setTitleEn] = useState('')
  const [bodyEn, setBodyEn] = useState('')
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Notice | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const [editBody, setEditBody] = useState('')
  const [editTitleEn, setEditTitleEn] = useState('')
  const [editBodyEn, setEditBodyEn] = useState('')
  const [editSaving, setEditSaving] = useState(false)

  const load = () => api.getNotices().then(setList).catch((e) => setError(e.message))

  useEffect(() => {
    load()
  }, [])

  const create = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) return
    setLoading(true)
    try {
      await api.createNotice({
        title: title.trim(),
        body: body.trim(),
        titleEn: titleEn.trim() || undefined,
        bodyEn: bodyEn.trim() || undefined,
      })
      setTitle('')
      setBody('')
      setTitleEn('')
      setBodyEn('')
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('notices.createFail'))
    } finally {
      setLoading(false)
    }
  }

  const startEdit = (n: Notice) => {
    setEditing(n)
    setEditTitle(n.title)
    setEditBody(n.body)
    setEditTitleEn(n.titleEn ?? '')
    setEditBodyEn(n.bodyEn ?? '')
  }

  const saveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    setEditSaving(true)
    try {
      await api.updateNotice(editing.id, {
        title: editTitle.trim(),
        body: editBody.trim(),
        titleEn: editTitleEn.trim(),
        bodyEn: editBodyEn.trim(),
      })
      setEditing(null)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('notices.updateFail'))
    } finally {
      setEditSaving(false)
    }
  }

  const remove = async (id: string) => {
    if (!confirm(t('notices.confirmDelete'))) return
    try {
      await api.deleteNotice(id)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('notices.deleteFail'))
    }
  }

  if (error && list.length === 0) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">{t('notices.title')}</h2>

      {error && list.length > 0 && <p className="text-sm text-destructive">{error}</p>}

      <form onSubmit={create} className="space-y-3 rounded-lg border border-border bg-card p-4">
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.titleLabel')}</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.body')}</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            rows={3}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.titleEn')}</label>
          <input
            value={titleEn}
            onChange={(e) => setTitleEn(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.bodyEn')}</label>
          <textarea
            value={bodyEn}
            onChange={(e) => setBodyEn(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            rows={3}
          />
        </div>
        <button
          type="submit"
          disabled={loading}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground"
        >
          {t('notices.add')}
        </button>
      </form>

      {editing && (
        <form
          onSubmit={saveEdit}
          className="space-y-3 rounded-lg border border-border bg-card p-4"
        >
          <h3 className="text-sm font-medium text-foreground">{t('notices.editTitle')}</h3>
          <div>
            <label className="block text-xs text-muted-foreground">{t('notices.titleLabel')}</label>
            <input
              value={editTitle}
              onChange={(e) => setEditTitle(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            />
          </div>
          <div>
            <label className="block text-xs text-muted-foreground">{t('notices.body')}</label>
            <textarea
              value={editBody}
              onChange={(e) => setEditBody(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
              rows={3}
            />
          </div>
          <div>
            <label className="block text-xs text-muted-foreground">{t('notices.titleEn')}</label>
            <input
              value={editTitleEn}
              onChange={(e) => setEditTitleEn(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            />
          </div>
          <div>
            <label className="block text-xs text-muted-foreground">{t('notices.bodyEn')}</label>
            <textarea
              value={editBodyEn}
              onChange={(e) => setEditBodyEn(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
              rows={3}
            />
          </div>
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={editSaving}
              className="rounded-md bg-primary px-4 py-2 text-primary-foreground text-sm"
            >
              {t('common.save')}
            </button>
            <button
              type="button"
              onClick={() => setEditing(null)}
              className="rounded-md border border-border px-4 py-2 text-sm"
            >
              {t('common.cancel')}
            </button>
          </div>
        </form>
      )}

      <div className="space-y-2">
        {list.map((n) => (
          <div
            key={n.id}
            className="rounded-lg border border-border bg-card p-4 flex justify-between items-start"
          >
            <div>
              <h3 className="font-medium text-foreground">{displayNoticeTitle(n, lang)}</h3>
              <p className="text-sm text-muted-foreground mt-1 whitespace-pre-wrap">
                {displayNoticeBody(n, lang)}
              </p>
            </div>
            <div className="flex gap-2 shrink-0">
              <button
                type="button"
                onClick={() => startEdit(n)}
                className="text-muted-foreground hover:text-foreground text-sm"
              >
                {t('common.edit')}
              </button>
              <button
                type="button"
                onClick={() => remove(n.id)}
                className="text-destructive hover:underline text-sm"
              >
                {t('common.delete')}
              </button>
            </div>
          </div>
        ))}
        {list.length === 0 && <p className="text-muted-foreground">{t('notices.empty')}</p>}
      </div>
    </div>
  )
}
