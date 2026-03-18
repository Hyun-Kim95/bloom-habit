import { useEffect, useState } from 'react'
import { api } from '../api'

type Template = { id: string; name: string; category?: string; goalType: string; isActive: boolean }

function parseCategories(raw: string | undefined): string[] {
  if (!raw || raw.trim() === '') return []
  try {
    const arr = JSON.parse(raw) as unknown
    return Array.isArray(arr) ? arr.filter((x): x is string => typeof x === 'string') : []
  } catch {
    return []
  }
}

export default function HabitTemplates() {
  const [list, setList] = useState<Template[]>([])
  const [categories, setCategories] = useState<string[]>([])
  const [error, setError] = useState('')
  const [name, setName] = useState('')
  const [category, setCategory] = useState('')
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Template | null>(null)
  const [editName, setEditName] = useState('')
  const [editCategory, setEditCategory] = useState('')
  const [editSaving, setEditSaving] = useState(false)

  const load = () => api.getTemplates().then(setList).catch((e) => setError(e.message))

  useEffect(() => {
    load()
    api.getConfig().then((c) => setCategories(parseCategories(c.habit_categories))).catch(() => {})
  }, [])

  const create = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return
    setLoading(true)
    try {
      await api.createTemplate({
        name: name.trim(),
        category: category.trim() || undefined,
        goalType: 'completion',
      })
      setName('')
      setCategory('')
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '생성 실패')
    } finally {
      setLoading(false)
    }
  }

  const startEdit = (t: Template) => {
    setEditing(t)
    setEditName(t.name)
    setEditCategory(t.category ?? '')
  }

  const saveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    setEditSaving(true)
    try {
      await api.updateTemplate(editing.id, {
        name: editName.trim(),
        category: editCategory.trim() || undefined,
      })
      setEditing(null)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '수정 실패')
    } finally {
      setEditSaving(false)
    }
  }

  const remove = async (id: string) => {
    if (!confirm('이 템플릿을 삭제할까요?')) return
    try {
      await api.deleteTemplate(id)
      load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '삭제 실패')
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">습관 템플릿 관리</h2>

      <form onSubmit={create} className="flex flex-wrap items-end gap-3 rounded-lg border border-border bg-card p-4">
        <div>
          <label className="block text-sm font-medium text-foreground">이름</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground"
            placeholder="예: 아침 물 마시기"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">카테고리</label>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[120px]"
          >
            <option value="">선택 안 함</option>
            {categories.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        </div>
        <button
          type="submit"
          disabled={loading}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground"
        >
          추가
        </button>
      </form>

      {editing && (
        <form
          onSubmit={saveEdit}
          className="rounded-lg border border-border bg-card p-4 space-y-3"
        >
          <h3 className="text-sm font-medium text-foreground">템플릿 수정</h3>
          <div className="flex flex-wrap gap-3 items-end">
            <div>
              <label className="block text-xs text-muted-foreground">이름</label>
              <input
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm"
              />
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">카테고리</label>
              <select
                value={editCategory}
                onChange={(e) => setEditCategory(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[120px]"
              >
                <option value="">선택 안 함</option>
                {categories.map((c) => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={editSaving}
              className="rounded-md bg-primary px-3 py-2 text-primary-foreground text-sm"
            >
              저장
            </button>
            <button
              type="button"
              onClick={() => setEditing(null)}
              className="rounded-md border border-border px-3 py-2 text-sm"
            >
              취소
            </button>
          </div>
        </form>
      )}

      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">이름</th>
              <th className="text-left p-3 font-medium">카테고리</th>
              <th className="text-left p-3 font-medium">목표 유형</th>
              <th className="text-right p-3 font-medium">수정 / 삭제</th>
            </tr>
          </thead>
          <tbody>
            {list.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="p-3">{t.name}</td>
                <td className="p-3">{t.category ?? '-'}</td>
                <td className="p-3">{t.goalType}</td>
                <td className="p-3 text-right space-x-2">
                  <button
                    type="button"
                    onClick={() => startEdit(t)}
                    className="text-muted-foreground hover:text-foreground"
                  >
                    수정
                  </button>
                  <button
                    type="button"
                    onClick={() => remove(t.id)}
                    className="text-destructive hover:underline"
                  >
                    삭제
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.length === 0 && (
          <p className="p-4 text-muted-foreground">템플릿이 없습니다.</p>
        )}
      </div>
    </div>
  )
}
