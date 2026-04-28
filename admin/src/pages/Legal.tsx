import { useCallback, useEffect, useMemo, useState } from 'react'
import { api } from '../api'
import { useI18n } from '../i18n/I18nContext'

type LegalDoc = {
  id: string
  type: string
  locale: string
  version: number
  title: string
  content: string
  effectiveFrom: string | null
  createdAt: string
  updatedAt: string
}

type DocType = 'terms' | 'privacy'

type VersionPair = { version: number; ko?: LegalDoc; en?: LegalDoc }

function groupByVersion(list: LegalDoc[]): VersionPair[] {
  const m = new Map<number, { ko?: LegalDoc; en?: LegalDoc }>()
  for (const d of list) {
    const cur = m.get(d.version) ?? {}
    if (d.locale === 'ko') cur.ko = d
    if (d.locale === 'en') cur.en = d
    m.set(d.version, cur)
  }
  return [...m.entries()]
    .map(([version, p]) => ({ version, ko: p.ko, en: p.en }))
    .sort((a, b) => b.version - a.version)
}

export default function Legal() {
  const { t, locale: dateLocale } = useI18n()
  const [activeType, setActiveType] = useState<DocType>('terms')
  const [list, setList] = useState<LegalDoc[]>([])
  const [error, setError] = useState('')
  const [editingVersion, setEditingVersion] = useState<number | null>(null)
  const [creating, setCreating] = useState(false)
  const [titleKo, setTitleKo] = useState('')
  const [titleEn, setTitleEn] = useState('')
  const [contentKo, setContentKo] = useState('')
  const [contentEn, setContentEn] = useState('')
  const [effectiveFrom, setEffectiveFrom] = useState('')
  const [saving, setSaving] = useState(false)

  const typeLabel = (ty: DocType) => (ty === 'terms' ? t('legal.terms') : t('legal.privacy'))

  const versionRows = useMemo(() => groupByVersion(list), [list])

  const resetForm = useCallback(() => {
    setEditingVersion(null)
    setCreating(false)
    setTitleKo('')
    setTitleEn('')
    setContentKo('')
    setContentEn('')
    setEffectiveFrom('')
  }, [])

  const load = useCallback(() => {
    setError('')
    return api
      .getLegalDocuments(activeType, 'all')
      .then(setList)
      .catch((e) => setError(e.message))
  }, [activeType])

  useEffect(() => {
    resetForm()
    void load()
  }, [activeType, load, resetForm])

  const startCreate = () => {
    resetForm()
    setCreating(true)
  }

  const startEdit = (row: VersionPair) => {
    setCreating(false)
    setEditingVersion(row.version)
    setTitleKo(row.ko?.title ?? '')
    setTitleEn(row.en?.title ?? '')
    setContentKo(row.ko?.content ?? '')
    setContentEn(row.en?.content ?? '')
    const eff = row.ko?.effectiveFrom ?? row.en?.effectiveFrom ?? ''
    setEffectiveFrom(eff ?? '')
  }

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!contentKo.trim()) return
    setSaving(true)
    try {
      if (creating) {
        await api.createLegalDocument({
          type: activeType,
          effectiveFrom: effectiveFrom.trim() || undefined,
          titleKo: titleKo.trim(),
          contentKo: contentKo.trim(),
          titleEn: titleEn.trim(),
          contentEn: contentEn.trim(),
        })
      } else if (editingVersion != null) {
        await api.updateLegalDocumentVersion({
          type: activeType,
          version: editingVersion,
          effectiveFrom: effectiveFrom.trim() || null,
          titleKo: titleKo,
          contentKo: contentKo,
          titleEn: titleEn,
          contentEn: contentEn,
        })
      }
      resetForm()
      await load()
    } catch (e) {
      setError(e instanceof Error ? e.message : t('legal.saveFail'))
    } finally {
      setSaving(false)
    }
  }

  const formatDate = (s: string) => {
    try {
      return new Date(s).toLocaleDateString(dateLocale)
    } catch {
      return s
    }
  }

  if (error && list.length === 0) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">{t('legal.title')}</h2>
      <p className="text-sm text-muted-foreground">
        안내 문구에 문의/탈퇴 데이터는 삭제 또는 비활성화 시점부터 최대 1년 보관 후 영구 삭제된다는 정책을 포함해 주세요.
      </p>

      {error && list.length > 0 && <p className="text-sm text-destructive">{error}</p>}

      <div className="flex gap-2">
        {(['terms', 'privacy'] as const).map((ty) => (
          <button
            key={ty}
            type="button"
            onClick={() => {
              setActiveType(ty)
            }}
            className={`rounded-md px-4 py-2 text-sm font-medium ${
              activeType === ty
                ? 'bg-primary text-primary-foreground'
                : 'bg-muted text-muted-foreground hover:bg-accent'
            }`}
          >
            {typeLabel(ty)}
          </button>
        ))}
      </div>

      <div className="flex gap-6 flex-1 min-h-0">
        <div className="w-80 flex-shrink-0 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-foreground">
              {t('legal.versionList', { type: typeLabel(activeType) })}
            </span>
            <button
              type="button"
              onClick={startCreate}
              className="text-sm text-primary hover:underline"
            >
              {t('legal.newVersion')}
            </button>
          </div>
          <ul className="border border-border rounded-lg divide-y divide-border bg-card overflow-hidden">
            {versionRows.length === 0 && (
              <li className="p-4 text-sm text-muted-foreground">{t('legal.noVersions')}</li>
            )}
            {versionRows.map((row) => (
              <li key={row.version}>
                <button
                  type="button"
                  onClick={() => startEdit(row)}
                  className={`w-full text-left p-3 hover:bg-accent transition-colors ${
                    editingVersion === row.version ? 'bg-accent' : ''
                  }`}
                >
                  <div className="font-medium text-foreground">
                    v{row.version}
                    {row.en ? ' · KO+EN' : ' · KO'}
                  </div>
                  <div className="text-xs text-muted-foreground mt-0.5">
                    {row.ko?.effectiveFrom
                      ? formatDate(row.ko.effectiveFrom)
                      : row.en?.effectiveFrom
                        ? formatDate(row.en.effectiveFrom)
                        : '-'}{' '}
                    · {formatDate(row.ko?.updatedAt ?? row.en?.updatedAt ?? '')}
                  </div>
                </button>
              </li>
            ))}
          </ul>
        </div>

        <div className="flex-1 min-w-0 rounded-lg border border-border bg-card p-4">
          {editingVersion != null || creating ? (
            <form onSubmit={save} className="space-y-4">
              <p className="text-xs text-muted-foreground">{t('legal.bilingualHint')}</p>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">
                  {t('legal.effectiveOptional')}
                </label>
                <input
                  type="date"
                  value={effectiveFrom}
                  onChange={(e) => setEffectiveFrom(e.target.value)}
                  className="w-full max-w-xs rounded-md border border-border bg-background px-3 py-2 text-foreground"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">
                  {t('legal.titleKo')}
                </label>
                <input
                  value={titleKo}
                  onChange={(e) => setTitleKo(e.target.value)}
                  className="w-full rounded-md border border-border bg-background px-3 py-2 text-foreground"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">
                  {t('legal.bodyKo')}
                </label>
                <textarea
                  value={contentKo}
                  onChange={(e) => setContentKo(e.target.value)}
                  className="w-full rounded-md border border-border bg-background px-3 py-2 text-foreground font-mono text-sm min-h-[200px]"
                  placeholder={t('legal.bodyPlaceholder')}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">
                  {t('legal.titleEn')}
                </label>
                <input
                  value={titleEn}
                  onChange={(e) => setTitleEn(e.target.value)}
                  className="w-full rounded-md border border-border bg-background px-3 py-2 text-foreground"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">
                  {t('legal.bodyEn')}
                </label>
                <textarea
                  value={contentEn}
                  onChange={(e) => setContentEn(e.target.value)}
                  className="w-full rounded-md border border-border bg-background px-3 py-2 text-foreground font-mono text-sm min-h-[200px]"
                  placeholder={t('legal.bodyPlaceholder')}
                />
              </div>
              <div className="flex gap-2">
                <button
                  type="submit"
                  disabled={saving || !contentKo.trim()}
                  className="rounded-md bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50"
                >
                  {saving ? t('legal.saving') : editingVersion != null ? t('legal.saveEdit') : t('legal.register')}
                </button>
                <button
                  type="button"
                  onClick={resetForm}
                  className="rounded-md border border-border px-4 py-2 text-foreground"
                >
                  {t('legal.cancel')}
                </button>
              </div>
            </form>
          ) : (
            <p className="text-muted-foreground">{t('legal.hintSelect')}</p>
          )}
        </div>
      </div>
    </div>
  )
}
