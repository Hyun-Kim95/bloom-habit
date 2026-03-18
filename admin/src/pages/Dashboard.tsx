import { useEffect, useState } from 'react'
import { api } from '../api'

const LABELS = ['가입 회원', '전체 습관', '전체 기록'] as const

export default function Dashboard() {
  const [stats, setStats] = useState<{ totalUsers: number; totalHabits: number; totalRecords: number } | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    api.getStats().then(setStats).catch((e) => setError(e.message))
  }, [])

  if (error) return <p className="text-destructive">{error}</p>
  if (!stats) return <p className="text-muted-foreground">로딩 중...</p>

  const values = [stats.totalUsers, stats.totalHabits, stats.totalRecords]
  const maxVal = Math.max(...values, 1)
  const avgHabitsPerUser = stats.totalUsers > 0 ? (stats.totalHabits / stats.totalUsers).toFixed(1) : '-'
  const avgRecordsPerHabit = stats.totalHabits > 0 ? (stats.totalRecords / stats.totalHabits).toFixed(1) : '-'

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">대시보드</h2>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-lg border border-border bg-card p-4 text-card-foreground">
          <p className="text-sm text-muted-foreground">가입 회원</p>
          <p className="text-2xl font-semibold">{stats.totalUsers}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4 text-card-foreground">
          <p className="text-sm text-muted-foreground">전체 습관</p>
          <p className="text-2xl font-semibold">{stats.totalHabits}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4 text-card-foreground">
          <p className="text-sm text-muted-foreground">전체 기록</p>
          <p className="text-2xl font-semibold">{stats.totalRecords}</p>
        </div>
      </div>

      <div className="rounded-lg border border-border bg-card p-4">
        <h3 className="text-sm font-medium text-foreground mb-3">기본 지표 비교</h3>
        <div className="space-y-2">
          {LABELS.map((label, i) => (
            <div key={label} className="flex items-center gap-3">
              <span className="text-sm text-muted-foreground w-24 shrink-0">{label}</span>
              <div className="flex-1 h-6 bg-muted rounded overflow-hidden">
                <div
                  className="h-full bg-primary rounded transition-all"
                  style={{ width: `${(values[i] / maxVal) * 100}%` }}
                />
              </div>
              <span className="text-sm font-medium text-card-foreground w-12 text-right">
                {values[i]}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-lg border border-border bg-card p-4 text-card-foreground">
          <p className="text-sm text-muted-foreground">회원당 평균 습관 수</p>
          <p className="text-xl font-semibold">{avgHabitsPerUser}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-4 text-card-foreground">
          <p className="text-sm text-muted-foreground">습관당 평균 기록 수</p>
          <p className="text-xl font-semibold">{avgRecordsPerHabit}</p>
        </div>
      </div>
    </div>
  )
}
