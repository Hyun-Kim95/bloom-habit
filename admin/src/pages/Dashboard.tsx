import { useEffect, useState } from 'react'
import { api } from '../api'

export default function Dashboard() {
  const [stats, setStats] = useState<{ totalUsers: number; totalHabits: number; totalRecords: number } | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    api.getStats().then(setStats).catch((e) => setError(e.message))
  }, [])

  if (error) return <p className="text-destructive">{error}</p>
  if (!stats) return <p className="text-muted-foreground">로딩 중...</p>

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
    </div>
  )
}
