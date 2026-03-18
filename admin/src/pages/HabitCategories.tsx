import { useEffect, useState } from 'react'
import { api } from '../api'

const CONFIG_KEY = 'habit_categories'

function parseCategories(raw: string | undefined): string[] {
  if (!raw || raw.trim() === '') return []
  try {
    const arr = JSON.parse(raw) as unknown
    return Array.isArray(arr) ? arr.filter((x): x is string => typeof x === 'string') : []
  } catch {
    return []
  }
}

export default function HabitCategories() {
  const [list, setList] = useState<string[]>([])
  const [newName, setNewName] = useState('')
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    api.getConfig().then((c) => {
      setList(parseCategories(c[CONFIG_KEY]))
    }).catch((e) => setError(e.message))
  }, [])

  const add = () => {
    const name = newName.trim()
    if (!name) return
    if (list.includes(name)) {
      setError('이미 있는 카테고리입니다.')
      return
    }
    setList((prev) => [...prev, name])
    setNewName('')
    setError('')
  }

  const remove = (index: number) => {
    setList((prev) => prev.filter((_, i) => i !== index))
  }

  const save = async () => {
    setSaving(true)
    setError('')
    try {
      await api.patchConfig({ [CONFIG_KEY]: JSON.stringify(list) })
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  if (error && !list.length) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">습관 카테고리</h2>
      <p className="text-sm text-muted-foreground">
        앱에서 습관 만들 때 선택할 수 있는 카테고리 목록입니다. 추가·삭제 후 저장하세요.
      </p>

      <div className="rounded-lg border border-border bg-card p-4 space-y-4">
        <div className="flex gap-2">
          <input
            type="text"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && add()}
            placeholder="새 카테고리 이름"
            className="flex-1 rounded-md border border-input bg-background px-3 py-2 text-foreground"
          />
          <button
            type="button"
            onClick={add}
            className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
          >
            추가
          </button>
        </div>
        {error && <p className="text-sm text-destructive">{error}</p>}
        <ul className="space-y-2">
          {list.length === 0 ? (
            <li className="text-sm text-muted-foreground">등록된 카테고리가 없습니다.</li>
          ) : (
            list.map((name, index) => (
              <li
                key={`${name}-${index}`}
                className="flex items-center justify-between rounded-md border border-border bg-background px-3 py-2"
              >
                <span className="text-foreground">{name}</span>
                <button
                  type="button"
                  onClick={() => remove(index)}
                  className="text-sm text-destructive hover:underline"
                >
                  삭제
                </button>
              </li>
            ))
          )}
        </ul>
        <div className="flex justify-end">
          <button
            type="button"
            onClick={save}
            disabled={saving}
            className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
          >
            {saving ? '저장 중…' : '저장'}
          </button>
        </div>
      </div>
    </div>
  )
}
