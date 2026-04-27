import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '../api'
import { useI18n } from '../i18n/I18nContext'

type UserDetailResponse = Awaited<ReturnType<typeof api.getUserDetail>>

function formatNumber(value: number | null): string {
  if (value == null) return '-'
  if (Number.isInteger(value)) return `${value}`
  return value.toFixed(1)
}

export default function UserDetail() {
  const { id } = useParams<{ id: string }>()
  const { t, locale } = useI18n()
  const [data, setData] = useState<UserDetailResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!id) return
    setLoading(true)
    setError('')
    api
      .getUserDetail(id)
      .then(setData)
      .catch((e) => setError(e instanceof Error ? e.message : t('users.detailLoadFail')))
      .finally(() => setLoading(false))
  }, [id, t])

  const rows = useMemo(() => data?.habits ?? [], [data])

  if (!id) {
    return <p className="text-destructive">{t('users.detailLoadFail')}</p>
  }
  if (loading) {
    return <p className="text-muted-foreground">{t('users.detailLoading')}</p>
  }
  if (error) {
    return <p className="text-destructive">{error}</p>
  }
  if (!data) {
    return <p className="text-muted-foreground">{t('users.detailEmpty')}</p>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-foreground">{t('users.detailTitle')}</h2>
        <Link to="/users" className="rounded-md border border-border px-3 py-2 text-sm text-foreground hover:bg-accent">
          {t('users.backToList')}
        </Link>
      </div>

      <div className="rounded-lg border border-border bg-card p-4 space-y-1 text-sm text-card-foreground">
        <p><span className="text-muted-foreground">{t('users.colId')}:</span> {data.user.id}</p>
        <p><span className="text-muted-foreground">{t('users.colEmail')}:</span> {data.user.email ?? '-'}</p>
        <p><span className="text-muted-foreground">{t('users.colName')}:</span> {data.user.displayName ?? '-'}</p>
        <p><span className="text-muted-foreground">{t('users.colCreated')}:</span> {new Date(data.user.createdAt).toLocaleDateString(locale)}</p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        <div className="rounded-lg border border-border bg-card p-4">
          <p className="text-sm font-medium text-card-foreground">{t('users.summary30d')}</p>
          <p className="text-xs text-muted-foreground mt-1">
            {data.summary30d.from} ~ {data.summary30d.to}
          </p>
          <div className="mt-3 space-y-1 text-sm">
            <p>{t('users.colHabits')}: {data.summary30d.totalHabits}</p>
            <p>{t('users.trackedHabitCount')}: {data.summary30d.trackedHabitCount}</p>
            <p>{t('users.colRecords')}: {data.summary30d.totalRecords}</p>
            <p>{t('users.completedRecords')}: {data.summary30d.completedRecords}</p>
            <p>{t('users.colRate')}: {data.summary30d.completionRatePercent != null ? `${data.summary30d.completionRatePercent}%` : '-'}</p>
          </div>
        </div>
        <div className="rounded-lg border border-border bg-card p-4">
          <p className="text-sm font-medium text-card-foreground">{t('users.todaySummary')}</p>
          <p className="text-xs text-muted-foreground mt-1">{data.todaySummary.date}</p>
          <div className="mt-3 space-y-1 text-sm">
            <p>{t('users.colHabits')}: {data.todaySummary.totalHabits}</p>
            <p>{t('users.recordedHabits')}: {data.todaySummary.recordedHabits}</p>
            <p>{t('users.completedHabits')}: {data.todaySummary.completedHabits}</p>
            <p>{t('users.colRate')}: {data.todaySummary.completionRatePercent != null ? `${data.todaySummary.completionRatePercent}%` : '-'}</p>
          </div>
        </div>
      </div>

      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">{t('habit.colName')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colCategory')}</th>
              <th className="text-left p-3 font-medium">{t('habit.colGoal')}</th>
              <th className="text-right p-3 font-medium">{t('users.todayProgress')}</th>
              <th className="text-right p-3 font-medium">{t('users.summary30dProgress')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((habit) => {
              const unitSuffix = habit.goalType === 'count' ? '회' : (habit.unit ? ` ${habit.unit}` : '')
              const goalPrefix = habit.goalType === 'number' && habit.numberDirection === 'lte' ? '<= ' : ''
              return (
                <tr key={habit.id} className="border-b border-border last:border-0">
                  <td className="p-3">{habit.name}</td>
                  <td className="p-3">{habit.category ?? '-'}</td>
                  <td className="p-3">
                    {goalPrefix}
                    {habit.goalValue != null ? `${formatNumber(habit.goalValue)}${unitSuffix}` : '-'}
                  </td>
                  <td className="p-3 text-right">
                    {habit.today.hasRecord
                      ? `${formatNumber(habit.today.value)}${unitSuffix} (${habit.today.completed ? t('users.done') : t('users.notDone')})`
                      : '-'}
                  </td>
                  <td className="p-3 text-right">
                    {habit.summary30d.totalRecords > 0
                      ? `${habit.summary30d.completedRecords}/${habit.summary30d.totalRecords} (${habit.summary30d.completionRatePercent ?? 0}%)`
                      : '-'}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        {rows.length === 0 && (
          <p className="p-4 text-muted-foreground">{t('users.detailEmptyHabits')}</p>
        )}
      </div>
    </div>
  )
}
