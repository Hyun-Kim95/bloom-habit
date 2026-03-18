import { useEffect, useState } from 'react'
import { api } from '../api'

type Notice = { id: string; title: string; body: string; publishedAt?: string }

export default function Notices() {
  const [list, setList] = useState<Notice[]>([])
  const [error, setError] = useState('')
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Notice | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const [editBody, setEditBody] = useState('')
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
      await api.createNotice({ title: title.trim(), body: body.trim() })
      setTitle('')
      setBody('')
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '생성 실패')
    } finally {
      setLoading(false)
    }
  }

  const startEdit = (n: Notice) => {
    setEditing(n)
    setEditTitle(n.title)
    setEditBody(n.body)
  }

  const saveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    setEditSaving(true)
    try {
      await api.updateNotice(editing.id, { title: editTitle.trim(), body: editBody.trim() })
      setEditing(null)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '수정 실패')
    } finally {
      setEditSaving(false)
    }
  }

  const remove = async (id: string) => {
    if (!confirm('이 공지를 삭제할까요?')) return
    try {
      await api.deleteNotice(id)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '삭제 실패')
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">공지 / 운영 콘텐츠</h2>

      <form onSubmit={create} className="space-y-3 rounded-lg border border-border bg-card p-4">
        <div>
          <label className="block text-sm font-medium text-foreground">제목</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">본문</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            rows={3}
          />
        </div>
        <button
          type="submit"
          disabled={loading}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground"
        >
          공지 추가
        </button>
      </form>

      {editing && (
        <form
          onSubmit={saveEdit}
          className="space-y-3 rounded-lg border border-border bg-card p-4"
        >
          <h3 className="text-sm font-medium text-foreground">공지 수정</h3>
          <div>
            <label className="block text-xs text-muted-foreground">제목</label>
            <input
              value={editTitle}
              onChange={(e) => setEditTitle(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            />
          </div>
          <div>
            <label className="block text-xs text-muted-foreground">본문</label>
            <textarea
              value={editBody}
              onChange={(e) => setEditBody(e.target.value)}
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
              저장
            </button>
            <button
              type="button"
              onClick={() => setEditing(null)}
              className="rounded-md border border-border px-4 py-2 text-sm"
            >
              취소
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
              <h3 className="font-medium text-foreground">{n.title}</h3>
              <p className="text-sm text-muted-foreground mt-1 whitespace-pre-wrap">{n.body}</p>
            </div>
            <div className="flex gap-2 shrink-0">
              <button
                type="button"
                onClick={() => startEdit(n)}
                className="text-muted-foreground hover:text-foreground text-sm"
              >
                수정
              </button>
              <button
                type="button"
                onClick={() => remove(n.id)}
                className="text-destructive hover:underline text-sm"
              >
                삭제
              </button>
            </div>
          </div>
        ))}
        {list.length === 0 && <p className="text-muted-foreground">공지가 없습니다.</p>}
      </div>
    </div>
  )
}
