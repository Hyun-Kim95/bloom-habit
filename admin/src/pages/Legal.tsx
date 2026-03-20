import { useEffect, useState } from 'react'
import { api } from '../api'

type LegalDoc = {
  id: string
  type: string
  version: number
  title: string
  content: string
  effectiveFrom: string | null
  createdAt: string
  updatedAt: string
}

type DocType = 'terms' | 'privacy'

const TYPE_LABEL: Record<DocType, string> = { terms: '약관', privacy: '개인정보처리방침' }

export default function Legal() {
  const [activeType, setActiveType] = useState<DocType>('terms')
  const [list, setList] = useState<LegalDoc[]>([])
  const [error, setError] = useState('')
  const [editing, setEditing] = useState<LegalDoc | null>(null)
  const [creating, setCreating] = useState(false)
  const [content, setContent] = useState('')
  const [effectiveFrom, setEffectiveFrom] = useState('')
  const [saving, setSaving] = useState(false)

  const load = () =>
    api.getLegalDocuments(activeType).then(setList).catch((e) => setError(e.message))

  useEffect(() => {
    load()
  }, [activeType])

  const resetForm = () => {
    setEditing(null)
    setCreating(false)
    setContent('')
    setEffectiveFrom('')
  }

  const startCreate = () => {
    resetForm()
    setCreating(true)
  }

  const startEdit = (doc: LegalDoc) => {
    setCreating(false)
    setEditing(doc)
    setContent(doc.content)
    setEffectiveFrom(doc.effectiveFrom ?? '')
  }

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      if (editing) {
        await api.updateLegalDocument(editing.id, {
          title: '',
          content: content.trim(),
          effectiveFrom: effectiveFrom.trim() || null,
        })
      } else if (creating) {
        await api.createLegalDocument({
          type: activeType,
          title: '',
          content: content.trim(),
          effectiveFrom: effectiveFrom.trim() || undefined,
        })
      }
      resetForm()
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  const formatDate = (s: string) => {
    try {
      return new Date(s).toLocaleDateString('ko-KR')
    } catch {
      return s
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">약관·개인정보처리방침 (버전 관리)</h2>

      <div className="flex gap-2">
        {(['terms', 'privacy'] as const).map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => {
              setActiveType(t)
              resetForm()
              load()
            }}
            className={`rounded-md px-4 py-2 text-sm font-medium ${
              activeType === t
                ? 'bg-primary text-primary-foreground'
                : 'bg-muted text-muted-foreground hover:bg-accent'
            }`}
          >
            {TYPE_LABEL[t]}
          </button>
        ))}
      </div>

      <div className="flex gap-6 flex-1 min-h-0">
        <div className="w-80 flex-shrink-0 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-foreground">{TYPE_LABEL[activeType]} 버전 목록</span>
            <button
              type="button"
              onClick={startCreate}
              className="text-sm text-primary hover:underline"
            >
              + 새 버전
            </button>
          </div>
          <ul className="border border-border rounded-lg divide-y divide-border bg-card overflow-hidden">
            {list.length === 0 && (
              <li className="p-4 text-sm text-muted-foreground">등록된 버전이 없습니다.</li>
            )}
            {list.map((doc) => (
              <li key={doc.id}>
                <button
                  type="button"
                  onClick={() => startEdit(doc)}
                  className={`w-full text-left p-3 hover:bg-accent transition-colors ${
                    editing?.id === doc.id ? 'bg-accent' : ''
                  }`}
                >
                  <div className="font-medium text-foreground">v{doc.version}</div>
                  <div className="text-xs text-muted-foreground mt-0.5">
                    {doc.effectiveFrom ? formatDate(doc.effectiveFrom) : '-'} · {formatDate(doc.updatedAt)}
                  </div>
                </button>
              </li>
            ))}
          </ul>
        </div>

        <div className="flex-1 min-w-0 rounded-lg border border-border bg-card p-4">
          {(editing || creating) ? (
            <form onSubmit={save} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">시행일 (선택)</label>
                <input
                  type="date"
                  value={effectiveFrom}
                  onChange={(e) => setEffectiveFrom(e.target.value)}
                  className="w-full max-w-xs rounded-md border border-border bg-background px-3 py-2 text-foreground"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">본문</label>
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  className="w-full rounded-md border border-border bg-background px-3 py-2 text-foreground font-mono text-sm min-h-[320px]"
                  placeholder="약관 또는 개인정보처리방침 내용을 입력하세요. (HTML 가능)"
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-md bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50"
                >
                  {saving ? '저장 중…' : editing ? '수정' : '등록'}
                </button>
                <button
                  type="button"
                  onClick={resetForm}
                  className="rounded-md border border-border px-4 py-2 text-foreground"
                >
                  취소
                </button>
              </div>
            </form>
          ) : (
            <p className="text-muted-foreground">왼쪽에서 버전을 선택하거나 「새 버전」을 눌러 등록하세요.</p>
          )}
        </div>
      </div>
    </div>
  )
}
