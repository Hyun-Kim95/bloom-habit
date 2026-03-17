import { useEffect, useState } from 'react'
import { api } from '../api'

type Template = { id: string; name: string; category?: string; goalType: string; isActive: boolean }

export default function HabitTemplates() {
  const [list, setList] = useState<Template[]>([])
  const [error, setError] = useState('')
  const [name, setName] = useState('')
  const [category, setCategory] = useState('')
  const [loading, setLoading] = useState(false)

  const load = () => api.getTemplates().then(setList).catch((e) => setError(e.message))

  useEffect(() => {
    load()
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
          <input
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground"
            placeholder="선택"
          />
        </div>
        <button
          type="submit"
          disabled={loading}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground"
        >
          추가
        </button>
      </form>

      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">이름</th>
              <th className="text-left p-3 font-medium">카테고리</th>
              <th className="text-left p-3 font-medium">목표 유형</th>
              <th className="text-right p-3 font-medium">삭제</th>
            </tr>
          </thead>
          <tbody>
            {list.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="p-3">{t.name}</td>
                <td className="p-3">{t.category ?? '-'}</td>
                <td className="p-3">{t.goalType}</td>
                <td className="p-3 text-right">
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
