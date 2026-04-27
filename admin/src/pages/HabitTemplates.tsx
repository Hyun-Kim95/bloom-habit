import { useCallback, useEffect, useMemo, useState } from 'react'
import { api } from '../api'
import { useI18n } from '../i18n/I18nContext'
import {
  displayCategory,
  displayTemplateCategoryStored,
  displayTemplateNameStored,
} from '../i18n/dataDisplay'
import { interpolate } from '../i18n/messages'

type Template = {
  id: string
  name: string
  nameEn?: string
  category?: string
  categoryEn?: string
  goalType: string
  numberDirection?: 'gte' | 'lte'
  goalValue?: number | null
  colorHex?: string
  iconName?: string
  isActive: boolean
}

const CONFIG_KEY = 'habit_categories'

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

function goalTypeLabel(
  code: string,
  goalLabels: { completion: string; count: string; duration: string; number: string },
): string {
  const map: Record<string, string> = {
    completion: goalLabels.completion,
    count: goalLabels.count,
    duration: goalLabels.duration,
    number: goalLabels.number,
  }
  return map[code] ?? code
}

function formatGoalCell(
  tpl: Template,
  goalLabels: { completion: string; count: string; duration: string; number: string },
  t: (k: string, v?: Record<string, string | number>) => string,
): string {
  const label = goalTypeLabel(tpl.goalType, goalLabels)
  if (tpl.goalType === 'completion') return label
  const v = tpl.goalValue
  if (v != null && Number.isFinite(Number(v))) {
    const n = Number(v)
    if (tpl.goalType === 'duration')
      return `${label} (${interpolate(t('habit.goalValueMin'), { n })})`
    if (tpl.goalType === 'count')
      return `${label} (${interpolate(t('habit.goalValueCount'), { n })})`
    if (tpl.goalType === 'number') {
      const dir = tpl.numberDirection === 'lte' ? t('habit.numberDirectionLte') : t('habit.numberDirectionGte')
      return `${label} (${dir} ${n})`
    }
    return `${label} (${n})`
  }
  return `${label} (${t('habit.goalValueMissing')})`
}

function directionLabel(
  dir: 'gte' | 'lte' | undefined,
  t: (k: string, v?: Record<string, string | number>) => string,
): string {
  return dir === 'lte' ? t('habit.numberDirectionLte') : t('habit.numberDirectionGte')
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
  const { t } = useI18n()
  return (
    <div className="mt-1 flex flex-wrap items-center gap-2">
      <button
        type="button"
        onClick={() => onChange('')}
        className={`rounded-md border px-2 py-1 text-xs ${
          value === '' ? 'border-primary text-primary' : 'border-border text-muted-foreground'
        }`}
      >
        {t('habit.colorNone')}
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
  const { t, lang } = useI18n()
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
      .catch((e) => setError(e instanceof Error ? e.message : t('habit.loadFail')))
      .finally(() => setLoading(false))
  }, [t])

  useEffect(() => {
    if (open) load()
  }, [open, load])

  if (!open) return null

  const add = () => {
    const name = newName.trim()
    if (!name) return
    if (list.includes(name)) {
      setError(t('habit.catDuplicate'))
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
      setError(t('habit.catInUseDelete'))
      return
    }
    setList((prev) => prev.filter((_, i) => i !== index))
    setError('')
  }

  const save = async () => {
    const missing = [...inUse].filter((c) => !list.includes(c))
    if (missing.length > 0) {
      setError(t('habit.catMustInclude', { list: missing.join(', ') }))
      return
    }
    setSaving(true)
    setError('')
    try {
      await api.patchConfig({ [CONFIG_KEY]: JSON.stringify(list) })
      onSaved()
      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('habit.saveFail'))
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
            {t('habit.modalTitle')}
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="rounded-md px-2 py-1 text-sm text-muted-foreground hover:bg-accent hover:text-accent-foreground"
          >
            {t('habit.close')}
          </button>
        </div>
        <div className="max-h-[70vh] overflow-y-auto p-4 space-y-4">
          <p className="text-sm text-muted-foreground">{t('habit.catIntro')}</p>
          {loading ? (
            <p className="text-sm text-muted-foreground">{t('habit.loading')}</p>
          ) : (
            <>
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && add()}
                  placeholder={t('habit.newCategoryPlaceholder')}
                  className="flex-1 rounded-md border border-input bg-background px-3 py-2 text-foreground"
                />
                <button
                  type="button"
                  onClick={add}
                  className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:opacity-90"
                >
                  {t('habit.add')}
                </button>
              </div>
              {error && <p className="text-sm text-destructive">{error}</p>}
              <ul className="space-y-2">
                {list.length === 0 ? (
                  <li className="text-sm text-muted-foreground">{t('habit.noCategories')}</li>
                ) : (
                  list.map((name, index) => {
                    const locked = inUse.has(name.trim())
                    return (
                      <li
                        key={`${name}-${index}`}
                        className="flex items-center justify-between gap-2 rounded-md border border-border bg-background px-3 py-2"
                      >
                        <span className="text-foreground">{displayCategory(name, lang)}</span>
                        <div className="flex items-center gap-2 shrink-0">
                          {locked && (
                            <span className="text-xs text-muted-foreground whitespace-nowrap">
                              {t('habit.inUse')}
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
                            {t('habit.delete')}
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
                  {t('common.cancel')}
                </button>
                <button
                  type="button"
                  onClick={save}
                  disabled={saving}
                  className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground disabled:opacity-50"
                >
                  {saving ? t('habit.saving') : t('habit.save')}
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

export default function HabitTemplates() {
  const { t, lang } = useI18n()
  const goalLabels = useMemo(
    () => ({
      completion: t('habit.goalCompletion'),
      count: t('habit.goalCount'),
      duration: t('habit.goalDuration'),
      number: t('habit.goalNumber'),
    }),
    [t],
  )
  const goalTypeOptions = useMemo(
    () =>
      [
        { value: 'completion' as const, label: t('habit.goalCompletion') },
        { value: 'count' as const, label: t('habit.goalCount') },
        { value: 'duration' as const, label: t('habit.goalDuration') },
        { value: 'number' as const, label: t('habit.goalNumber') },
      ],
    [t],
  )

  const goalValueLabel = (goalType: string) => {
    if (goalType === 'count') return t('habit.goalTargetCount')
    if (goalType === 'duration') return t('habit.goalTargetDuration')
    return t('habit.goalTargetNumber')
  }

  const [list, setList] = useState<Template[]>([])
  const [categories, setCategories] = useState<string[]>([])
  const [error, setError] = useState('')
  const [name, setName] = useState('')
  const [nameEn, setNameEn] = useState('')
  const [category, setCategory] = useState('')
  const [categoryEn, setCategoryEn] = useState('')
  const [goalType, setGoalType] = useState<string>('completion')
  const [numberDirection, setNumberDirection] = useState<'gte' | 'lte'>('gte')
  const [goalValueInput, setGoalValueInput] = useState('')
  const [colorHex, setColorHex] = useState('')
  const [iconName, setIconName] = useState('')
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Template | null>(null)
  const [editName, setEditName] = useState('')
  const [editNameEn, setEditNameEn] = useState('')
  const [editCategory, setEditCategory] = useState('')
  const [editCategoryEn, setEditCategoryEn] = useState('')
  const [editGoalType, setEditGoalType] = useState<string>('completion')
  const [editNumberDirection, setEditNumberDirection] = useState<'gte' | 'lte'>('gte')
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
      setError(t('habit.colorIconRequired'))
      return
    }
    setLoading(true)
    try {
      await api.createTemplate({
        name: name.trim(),
        nameEn: nameEn.trim() || undefined,
        category: category.trim() || undefined,
        categoryEn: categoryEn.trim() || undefined,
        goalType,
        numberDirection: goalType === 'number' ? numberDirection : 'gte',
        goalValue: parseGoalValue(goalType, goalValueInput),
        colorHex: colorHex.trim() || undefined,
        iconName: iconName.trim() || undefined,
      })
      setName('')
      setNameEn('')
      setCategory('')
      setCategoryEn('')
      setGoalType('completion')
      setNumberDirection('gte')
      setGoalValueInput('')
      setColorHex('')
      setIconName('')
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('habit.createFail'))
    } finally {
      setLoading(false)
    }
  }

  const startEdit = (t: Template) => {
    setEditing(t)
    setEditName(t.name)
    setEditNameEn(t.nameEn ?? '')
    setEditCategory(t.category ?? '')
    setEditCategoryEn(t.categoryEn ?? '')
    setEditGoalType(t.goalType || 'completion')
    setEditNumberDirection(t.numberDirection === 'lte' ? 'lte' : 'gte')
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
      setError(t('habit.colorIconRequired'))
      return
    }
    setEditSaving(true)
    try {
      await api.updateTemplate(editing.id, {
        name: editName.trim(),
        nameEn: editNameEn.trim(),
        category: editCategory.trim() || undefined,
        categoryEn: editCategoryEn.trim(),
        goalType: editGoalType,
        numberDirection: editGoalType === 'number' ? editNumberDirection : 'gte',
        goalValue: parseGoalValue(editGoalType, editGoalValueInput),
        colorHex: editColorHex.trim() || undefined,
        iconName: editIconName.trim() || undefined,
      })
      setEditing(null)
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('habit.editFail'))
    } finally {
      setEditSaving(false)
    }
  }

  const remove = async (id: string) => {
    if (!confirm(t('habit.confirmDelete'))) return
    try {
      await api.deleteTemplate(id)
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('habit.deleteFail'))
    }
  }

  const reseedDefaults = async () => {
    if (!confirm(t('habit.reseedConfirm'))) {
      return
    }
    setReseeding(true)
    setError('')
    try {
      const r = await api.reseedHabitTemplates()
      await load()
      alert(t('habit.reseedDone', { n: r.inserted }))
    } catch (e) {
      setError(e instanceof Error ? e.message : t('habit.reseedFail'))
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
        <h2 className="text-lg font-semibold text-foreground">{t('habit.title')}</h2>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={reseedDefaults}
            disabled={reseeding}
            className="rounded-md border border-destructive/50 bg-background px-4 py-2 text-sm font-medium text-destructive hover:bg-destructive/10 disabled:opacity-50"
          >
            {reseeding ? t('habit.reseeding') : t('habit.reseed')}
          </button>
          <button
            type="button"
            onClick={() => setCategoryModalOpen(true)}
            className="rounded-md border border-border bg-background px-4 py-2 text-sm font-medium text-foreground hover:bg-accent"
          >
            {t('habit.categories')}
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
          <label className="block text-sm font-medium text-foreground">{t('habit.name')}</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground"
            placeholder={t('habit.namePlaceholder')}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('habit.nameEn')}</label>
          <input
            value={nameEn}
            onChange={(e) => setNameEn(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[180px]"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('habit.category')}</label>
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[120px]"
          >
            <option value="">{t('habit.selectNone')}</option>
            {categories.map((c) => (
              <option key={c} value={c}>
                {displayCategory(c, lang)}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('habit.categoryEn')}</label>
          <input
            value={categoryEn}
            onChange={(e) => setCategoryEn(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[160px]"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('habit.goalType')}</label>
          <select
            value={goalType}
            onChange={(e) => {
              const v = e.target.value
              setGoalType(v)
              if (v === 'completion') setGoalValueInput('')
            }}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[140px]"
          >
            {goalTypeOptions.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
        </div>
        {goalType === 'number' && (
          <div>
            <label className="block text-sm font-medium text-foreground">{t('habit.numberDirection')}</label>
            <select
              value={numberDirection}
              onChange={(e) => setNumberDirection((e.target.value as 'gte' | 'lte') ?? 'gte')}
              className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[140px]"
            >
              <option value="gte">{t('habit.numberDirectionGte')}</option>
              <option value="lte">{t('habit.numberDirectionLte')}</option>
            </select>
          </div>
        )}
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
              placeholder={t('habit.numberPlaceholder')}
            />
          </div>
        )}
        <div>
          <label className="block text-sm font-medium text-foreground">{t('habit.color')}</label>
          <ColorPicker value={colorHex} onChange={setColorHex} />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('habit.icon')}</label>
          <select
            value={iconName}
            onChange={(e) => setIconName(e.target.value)}
            className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground min-w-[170px]"
          >
            <option value="">{t('habit.selectNone')}</option>
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
          {t('habit.add')}
        </button>
      </form>

      {editing && (
        <form
          onSubmit={saveEdit}
          className="rounded-lg border border-border bg-card p-4 space-y-3"
        >
          <h3 className="text-sm font-medium text-foreground">{t('habit.editTitle')}</h3>
          <div className="flex flex-wrap gap-3 items-end">
            <div>
              <label className="block text-xs text-muted-foreground">{t('habit.name')}</label>
              <input
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm"
              />
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">{t('habit.nameEn')}</label>
              <input
                value={editNameEn}
                onChange={(e) => setEditNameEn(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[180px]"
              />
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">{t('habit.category')}</label>
              <select
                value={editCategory}
                onChange={(e) => setEditCategory(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[120px]"
              >
                <option value="">{t('habit.selectNone')}</option>
                {categories.map((c) => (
                  <option key={c} value={c}>
                    {displayCategory(c, lang)}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">{t('habit.categoryEn')}</label>
              <input
                value={editCategoryEn}
                onChange={(e) => setEditCategoryEn(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[160px]"
              />
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">{t('habit.goalType')}</label>
              <select
                value={editGoalType}
                onChange={(e) => {
                  const v = e.target.value
                  setEditGoalType(v)
                  if (v === 'completion') setEditGoalValueInput('')
                }}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[140px]"
              >
                {goalTypeOptions.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </div>
            {editGoalType === 'number' && (
              <div>
                <label className="block text-xs text-muted-foreground">{t('habit.numberDirection')}</label>
                <select
                  value={editNumberDirection}
                  onChange={(e) =>
                    setEditNumberDirection((e.target.value as 'gte' | 'lte') ?? 'gte')
                  }
                  className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[140px]"
                >
                  <option value="gte">{t('habit.numberDirectionGte')}</option>
                  <option value="lte">{t('habit.numberDirectionLte')}</option>
                </select>
              </div>
            )}
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
              <label className="block text-xs text-muted-foreground">{t('habit.color')}</label>
              <ColorPicker value={editColorHex} onChange={setEditColorHex} />
            </div>
            <div>
              <label className="block text-xs text-muted-foreground">{t('habit.icon')}</label>
              <select
                value={editIconName}
                onChange={(e) => setEditIconName(e.target.value)}
                className="mt-1 rounded-md border border-input bg-background px-3 py-2 text-foreground text-sm min-w-[170px]"
              >
                <option value="">{t('habit.selectNone')}</option>
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
              {t('common.save')}
            </button>
            <button
              type="button"
              onClick={() => setEditing(null)}
              className="rounded-md border border-border px-3 py-2 text-sm"
            >
              {t('common.cancel')}
            </button>
          </div>
        </form>
      )}

      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">{t('habit.colName')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colCategory')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colGoal')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colDirection')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colColor')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colIcon')}</th>
              <th className="text-right p-3 font-medium">{t('habit.colActions')}</th>
            </tr>
          </thead>
          <tbody>
            {list.map((row) => (
              <tr key={row.id} className="border-b border-border last:border-0">
                <td className="p-3">{displayTemplateNameStored(row, lang)}</td>
                <td className="p-3">
                  {row.category || row.categoryEn
                    ? displayTemplateCategoryStored(row, lang) || '-'
                    : '-'}
                </td>
                <td className="p-3">{formatGoalCell(row, goalLabels, t)}</td>
                <td className="p-3">
                  {row.goalType === 'number'
                    ? directionLabel(row.numberDirection, t)
                    : '-'}
                </td>
                <td className="p-3">
                  {row.colorHex ? (
                    <div className="flex items-center gap-2">
                      <span
                        className="inline-block h-4 w-4 rounded-full border border-border"
                        style={{ backgroundColor: `#${row.colorHex}` }}
                      />
                      <span>#{row.colorHex}</span>
                    </div>
                  ) : (
                    '-'
                  )}
                </td>
                <td className="p-3">
                  {row.iconName ? (
                    <div className="flex items-center gap-2">
                      <span
                        className="inline-flex h-6 w-6 items-center justify-center rounded-md border border-border bg-muted/40"
                        aria-label={row.iconName}
                        title={row.iconName}
                      >
                        {iconPreview(row.iconName)}
                      </span>
                      <span>{row.iconName}</span>
                    </div>
                  ) : (
                    '-'
                  )}
                </td>
                <td className="p-3 text-right space-x-2">
                  <button
                    type="button"
                    onClick={() => startEdit(row)}
                    className="text-muted-foreground hover:text-foreground"
                  >
                    {t('common.edit')}
                  </button>
                  <button
                    type="button"
                    onClick={() => remove(row.id)}
                    className="text-destructive hover:underline"
                  >
                    {t('common.delete')}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.length === 0 && (
          <p className="p-4 text-muted-foreground">{t('habit.empty')}</p>
        )}
      </div>
    </div>
  )
}
