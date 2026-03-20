import { useCallback, useEffect, useState } from 'react'
import { api } from '../api'

type Template = {
  id: string
  name: string
  category?: string
  goalType: string
  goalValue?: number | null
  colorHex?: string
  iconName?: string
  isActive: boolean
}

const CONFIG_KEY = 'habit_categories'

const GOAL_TYPE_OPTIONS = [
  { value: 'completion', label: '완료 여부' },
  { value: 'count', label: '횟수' },
  { value: 'duration', label: '시간(분)' },
  { value: 'number', label: '수치' },
] as const

const COLOR_PRESETS = ['22C55E', '3B82F6', 'F59E0B', 'EF4444', '8B5CF6', 'EC4899', '14B8A6', '6B7280'] as const

const ICON_OPTIONS = [
  'fitness_center',
  'menu_book',
  'local_drink',
  'self_improvement',
  'bedtime',
  'eco',
  'psychology',
  'work',
  'volunteer_activism',
  'star',
  'check_circle',
  'flag',
] as const

function goalTypeLabel(code: string): string {
  return GOAL_TYPE_OPTIONS.find((o) => o.value === code)?.label ?? code
}

function formatGoalCell(t: Template): string {
  const label = goalTypeLabel(t.goalType)
  if (t.goalType === 'completion') return label
  const v = t.goalValue
  if (v != null && Number.isFinite(Number(v))) {
    const n = Number(v)
    if (t.goalType === 'duration') return `${label} (${n}분)`
    if (t.goalType === 'count') return `${label} (${n}회)`
    return `${label} (${n})`
  }
  return `${label} (목표값 없음)`
}

function iconPreview(name?: string): string {
  switch (name) {
    case 'fitness_center':
      return '🏋️'
    case 'menu_book':
      return '📖'
    case 'local_drink':
      return '💧'
    case 'self_improvement':
      return '🧘'
    case 'bedtime':
      return '🌙'
    case 'eco':
      return '🌿'
    case 'psychology':
      return '🧠'
    case 'work':
      return '💼'
    case 'volunteer_activism':
      return '💖'
    case 'star':
      return '⭐'
    case 'check_circle':
      return '✅'
    case 'flag':
      return '🚩'
    default:
      return '🔹'
  }
}

function iconOptionLabel(name: string): string {
  return `${iconPreview(name)} ${name}`
}

type ColorPickerProps = {
  value: string
  onChange: (next: string) => void
}

function ColorPicker({ value, onChange }: ColorPickerProps) {
  return (
    <div className="mt-1 flex flex-wrap items-center gap-2">
      <button
        type="button"
        onClick={() => onChange('')}
        className={`rounded-md border px-2 py-1 text-xs ${
          value === '' ? 'border-primary text-primary' : 'border-border text-muted-foreground'
        }`}
      >
        선택 안 함
      </button>
      {COLOR_PRESETS.map((c) => {
        const selected = value === c
        return (
          <button
            key={c}
            type="button"
            onClick={() => onChange(c)}
            aria-label={`#${c}`}
            title={`#${c}`}
            className={`inline-flex h-7 w-7 items-center justify-center rounded-full border ${
              selected ? 'border-foreground ring-2 ring-primary/40' : 'border-border'
            }`}
            style={{ backgroundColor: `#${c}` }}
          />
        )
      })}
    </div>
  )
}

function parseCategories(raw: string | undefined): string[] {
  if (!raw || raw.trim() === '') return []
  try {
    const arr = JSON.parse(raw) as unknown
    return Array.isArray(arr) ? arr.filter((x): x is string => typeof x === 'string') : []
  } catch {
    return []
  }
}

type CategoriesModalProps = {
  open: boolean
  onClose: () => void
  onSaved: () => void
}

function CategoriesModal({ open, onClose, onSaved }: CategoriesModalProps) {
  const [list, setList] = useState<string[]>([])
  const [inUse, setInUse] = useState<Set<string>>(new Set())
  const [newName, setNewName] = useState('')
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const [loading, setLoading] = useState(true)

  const load = useCallback(() => {
    setLoading(true)
    Promise.all([api.getConfig(), api.getHabitCategoriesInUse()])
      .then(([c, u]) => {
        setList(parseCategories(c[CONFIG_KEY]))
        setInUse(new Set((u.inUse ?? []).map((s) => s.trim())))
        setError('')
      })
      .catch((e) => setError(e instanceof Error ? e.message : '불러오기 실패'))
      .finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (open) load()
  }, [open, load])

  if (!open) return null

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
    const name = list[index]?.trim()
    if (!name) return
    if (inUse.has(name)) {
      setError('템플릿 또는 회원 습관에서 사용 중인 카테고리는 삭제할 수 없습니다.')
      return
    }
    setList((prev) => prev.filter((_, i) => i !== index))
    setError('')
  }

  const save = async () => {
    const missing = [...inUse].filter((c) => !list.includes(c))
    if (missing.length > 0) {
      setError(
        `다음 카테고리는 사용 중이라 목록에 포함되어야 합니다: ${missing.join(', ')}`,
      )
      return
    }
    setSaving(true)
    setError('')
    try {
      await api.patchConfig({ [CONFIG_KEY]: JSON.stringify(list) })
      onSaved()
      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="categories-modal-title"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="w-full max-w-md rounded-lg border border-border bg-card text-card-foreground shadow-lg"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b border-border px-4 py-3">
          <h3 id="categories-modal-title" className="text-base font-semibold text-foreground">
            습관 카테고리 관리
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md px-2 py-1 text-sm text-muted-foreground hover:bg-accent hover:text-accent-foreground"
          >
            닫기
          </button>
        </div>
        <div className="max-h-[70vh] overflow-y-auto p-4 space-y-4">
          <p className="text-sm text-muted-foreground">
            앱에서 습관·템플릿에 쓸 카테고리입니다. 템플릿 또는 회원 습관에서 쓰는 이름은 삭제할 수 없습니다.
          </p>
          {loading ? (
            <p className="text-sm text-muted-foreground">불러오는 중…</p>
          ) : (
            <>
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
                  list.map((name, index) => {
                    const locked = inUse.has(name.trim())
                    return (
                      <li
                        key={`${name}-${index}`}
                        className="flex items-center justify-between gap-2 rounded-md border border-border bg-background px-3 py-2"
                      >
                        <span className="text-foreground">{name}</span>
                        <div className="flex items-center gap-2 shrink-0">
                          {locked && (
                            <span className="text-xs text-muted-foreground whitespace-nowrap">
                              사용 중
                            </span>
                          )}
                          <button
                            type="button"
                            disabled={locked}
                            onClick={() => remove(index)}
                            className={`text-sm ${
                              locked
                                ? 'text-muted-foreground cursor-not-allowed opacity-50'
                                : 'text-destructive hover:underline'
                            }`}
                          >
                            삭제
                          </button>
                        </div>
                      </li>
                    )
                  })
                )}
              </ul>
              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={onClose}
                  className="rounded-md border border-border px-4 py-2 text-sm"
                >
                  취소
                </button>
                <button
                  type="button"
                  onClick={save}
                  disabled={saving}
                  className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
                >
                  {saving ? '저장 중…' : '저장'}
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

function goalValueLabel(goalType: string): string {
  if (goalType === 'count') return '목표 횟수'
  if (goalType === 'duration') return '목표 시간(분)'
  return '목표 수치'
}

export default function HabitTemplates() {
  const [list, setList] = useState<Template[]>([])
  const [categories, setCategories] = useState<string[]>([])
  const [error, setError] = useState('')
  const [name, setName] = useState('')
  const [category, setCategory] = useState('')
  const [goalType, setGoalType] = useState<string>('completion')
  const [goalValueInput, setGoalValueInput] = useState('')
  const [colorHex, setColorHex] = useState('')
  const [iconName, setIconName] = useState('')
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Template | null>(null)
  const [editName, setEditName] = useState('')
  const [editCategory, setEditCategory] = useState('')
  const [editGoalType, setEditGoalType] = useState<string>('completion')
  const [editGoalValueInput, setEditGoalValueInput] = useState('')
  const [editColorHex, setEditColorHex] = useState('')
  const [editIconName, setEditIconName] = useState('')
  const [editSaving, setEditSaving] = useState(false)
  const [categoryModalOpen, setCategoryModalOpen] = useState(false)
  const [reseeding, setReseeding] = useState(false)

  const loadCategories = useCallback(() => {
    api.getConfig().then((c) => setCategories(parseCategories(c.habit_categories))).catch(() => {})
  }, [])

  const load = useCallback(() => {
    setError('')
    return api.getTemplates().then(setList).catch((e) => setError(e.message))
  }, [])

  useEffect(() => {
    load()
    loadCategories()
  }, [load, loadCategories])

  const parseGoalValue = (gt: string, raw: string): number | null => {
    if (gt === 'completion') return null
    const n = parseFloat(raw.trim())
    return Number.isFinite(n) ? n : null
  }

  const create = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return
    if (!colorHex.trim() || !iconName.trim()) {
      setError('색상과 아이콘은 필수입니다.')
      return
    }
    setLoading(true)
    try {
      await api.createTemplate({
        name: name.trim(),
        category: category.trim() || undefined,
        goalType,
        goalValue: parseGoalValue(goalType, goalValueInput),
        colorHex: colorHex.trim() || undefined,
        iconName: iconName.trim() || undefined,
      })
      setName('')
      setCategory('')
      setGoalType('completion')
      setGoalValueInput('')
      setColorHex('')
      setIconName('')
      await load()
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
    setEditGoalType(t.goalType || 'completion')
    setEditGoalValueInput(
      t.goalValue != null && Number.isFinite(Number(t.goalValue)) ? String(t.goalValue) : '',
    )
    setEditColorHex(t.colorHex ?? '')
    setEditIconName(t.iconName ?? '')
  }

  const saveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    if (!editColorHex.trim() || !editIconName.trim()) {
      setError('색상과 아이콘은 필수입니다.')
      return
    }
    setEditSaving(true)
    try {
      await api.updateTemplate(editing.id, {
        name: editName.trim(),
        category: editCategory.trim() || undefined,
        goalType: editGoalType,
        goalValue: parseGoalValue(editGoalType, editGoalValueInput),
        colorHex: editColorHex.trim() || undefined,
        iconName: editIconName.trim() || undefined,
      })
      setEditing(null)
      await load()
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
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : '삭제 실패')
    }
  }

  const reseedDefaults = async () => {
    if (
      !confirm(
        '등록된 습관 템플릿을 모두 삭제하고, 기본 예시 템플릿으로 다시 채웁니다.\n이 작업은 되돌릴 수 없습니다. 계속할까요?',
      )
    ) {
      return
    }
    setReseeding(true)
    setError('')
    try {
      const r = await api.reseedHabitTemplates()
      await load()
      alert(`기본 예시 ${r.inserted}개로 초기화했습니다.`)
    } catch (e) {
      setError(e instanceof Error ? e.message : '초기화 실패')
    } finally {
      setReseeding(false)
    }
  }

  return (
    <div className="space-y-6">
      <CategoriesModal
        open={categoryModalOpen}
        onClose={() => setCategoryModalOpen(false)}
        onSaved={loadCategories}
      />

      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-lg font-semibold text-foreground">습관 템플릿 관리</h2>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={reseedDefaults}
            disabled={reseeding}
            className="rounded-md border border-destructive/50 bg-background px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10 disabled:opacity-50"
          >
            {reseeding ? '초기화 중…' : '예시 템플릿으로 초기화'}
          </button>
          <button
            type="button"
            onClick={() => setCategoryModalOpen(true)}
            className="rounded-md border border-border bg-background px-4 py-2 text-sm font-medium text-foreground hover:bg-accent"
          >
            카테고리 관리
          </button>
        </div>
      </div>

      {error && (
        <p className="rounded-md border border-destructive/50 bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      )}

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
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">목표 유형</label>
          <select
            value={goalType}
            onChange={(e) => {
              const v = e.target.value
              setGoalType(v)
              if (v === 'completion') setGoalValueInput('')
            }}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[140px]"
          >
            {GOAL_TYPE_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </div>
        {goalType !== 'completion' && (
          <div>
            <label className="block text-sm font-medium text-foreground">{goalValueLabel(goalType)}</label>
            <input
              type="number"
              min={0}
              step="any"
              value={goalValueInput}
              onChange={(e) => setGoalValueInput(e.target.value)}
              className="mt-1 w-28 rounded-md border border-input bg-background px-3 py-2 text-foreground"
              placeholder="숫자"
            />
          </div>
        )}
        <div>
          <label className="block text-sm font-medium text-foreground">색상</label>
          <ColorPicker value={colorHex} onChange={setColorHex} />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">아이콘</label>
          <select
            value={iconName}
            onChange={(e) => setIconName(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[170px]"
          >
            <option value="">선택 안 함</option>
            {ICON_OPTIONS.map((icon) => (
              <option key={icon} value={icon}>
                {iconOptionLabel(icon)}
              </option>
            ))}
          </select>
        </div>
        <button
          type="submit"
          disabled={loading || !name.trim() || !colorHex.trim() || !iconName.trim()}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50"
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
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">목표 유형</label>
              <select
                value={editGoalType}
                onChange={(e) => {
                  const v = e.target.value
                  setEditGoalType(v)
                  if (v === 'completion') setEditGoalValueInput('')
                }}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[140px]"
              >
                {GOAL_TYPE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </div>
            {editGoalType !== 'completion' && (
              <div>
                <label className="block text-xs text-muted-foreground">{goalValueLabel(editGoalType)}</label>
                <input
                  type="number"
                  min={0}
                  step="any"
                  value={editGoalValueInput}
                  onChange={(e) => setEditGoalValueInput(e.target.value)}
                  className="mt-1 w-28 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm"
                />
              </div>
            )}
            <div>
              <label className="block text-xs text-muted-foreground">색상</label>
              <ColorPicker value={editColorHex} onChange={setEditColorHex} />
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">아이콘</label>
              <select
                value={editIconName}
                onChange={(e) => setEditIconName(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[170px]"
              >
                <option value="">선택 안 함</option>
                {ICON_OPTIONS.map((icon) => (
                  <option key={icon} value={icon}>
                    {iconOptionLabel(icon)}
                  </option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={editSaving || !editName.trim() || !editColorHex.trim() || !editIconName.trim()}
              className="rounded-md bg-primary px-3 py-2 text-primary-foreground text-sm disabled:opacity-50"
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
              <th className="text-left p-3 font-medium">색상</th>
              <th className="text-left p-3 font-medium">아이콘</th>
              <th className="text-right p-3 font-medium">수정 / 삭제</th>
            </tr>
          </thead>
          <tbody>
            {list.map((t) => (
              <tr key={t.id} className="border-b border-border last:border-0">
                <td className="p-3">{t.name}</td>
                <td className="p-3">{t.category ?? '-'}</td>
                <td className="p-3">{formatGoalCell(t)}</td>
                <td className="p-3">
                  {t.colorHex ? (
                    <div className="flex items-center gap-2">
                      <span
                        className="inline-block h-4 w-4 rounded-full border border-border"
                        style={{ backgroundColor: `#${t.colorHex}` }}
                      />
                      <span>#{t.colorHex}</span>
                    </div>
                  ) : (
                    '-'
                  )}
                </td>
                <td className="p-3">
                  {t.iconName ? (
                    <div className="flex items-center gap-2">
                      <span
                        className="inline-flex h-6 w-6 items-center justify-center rounded-md border border-border bg-muted/40"
                        aria-label={t.iconName}
                        title={t.iconName}
                      >
                        {iconPreview(t.iconName)}
                      </span>
                      <span>{t.iconName}</span>
                    </div>
                  ) : (
                    '-'
                  )}
                </td>
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
