import { useEffect, useState } from 'react'
import {
  CategoryScale,
  Chart as ChartJS,
  Filler,
  Legend,
  LinearScale,
  LineElement,
  PointElement,
  Tooltip,
  BarElement,
} from 'chart.js'
import { Bar, Line } from 'react-chartjs-2'
import { api } from '../api'

const COMPLETION_BUCKETS = [
  { key: '0-20', label: '0~20%' },
  { key: '21-40', label: '21~40%' },
  { key: '41-60', label: '41~60%' },
  { key: '61-80', label: '61~80%' },
  { key: '81-100', label: '81~100%' },
] as const

type OverTimePoint = {
  period: string
  newUsers: number
  newHabits: number
  newRecords: number
}

type UserStat = {
  id: string
  habitCount: number
  totalRecords: number
  completionRatePercent: number | null
}

type RangeDays = 7 | 30 | 90

function dateToYmd(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Tooltip,
  Legend,
  Filler,
)

export default function Dashboard() {
  const [stats, setStats] = useState<{ totalUsers: number; totalHabits: number; totalRecords: number } | null>(null)
  const [overTime, setOverTime] = useState<OverTimePoint[]>([])
  const [users, setUsers] = useState<UserStat[]>([])
  const [rangeDays, setRangeDays] = useState<RangeDays>(30)
  const [isDark, setIsDark] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    const now = new Date()
    const from = new Date(now)
    from.setDate(from.getDate() - (rangeDays - 1))
    Promise.all([
      api.getStats(),
      api.getStatsOverTime(dateToYmd(from), dateToYmd(now)),
      api.getUsers(),
    ])
      .then(([statsRes, overTimeRes, usersRes]) => {
        setStats(statsRes)
        setOverTime(overTimeRes)
        setUsers(usersRes)
      })
      .catch((e) => setError(e.message))
  }, [rangeDays])

  useEffect(() => {
    const update = () => {
      setIsDark(document.documentElement.classList.contains('dark'))
    }
    update()
    const observer = new MutationObserver(update)
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['class'],
    })
    return () => observer.disconnect()
  }, [])

  if (error) return <p className="text-destructive">{error}</p>
  if (!stats) return <p className="text-muted-foreground">로딩 중...</p>

  const avgHabitsPerUser = stats.totalUsers > 0 ? (stats.totalHabits / stats.totalUsers).toFixed(1) : '-'
  const avgRecordsPerHabit = stats.totalHabits > 0 ? (stats.totalRecords / stats.totalHabits).toFixed(1) : '-'

  const distribution = COMPLETION_BUCKETS.map((b) => {
    const count = users.filter((u) => {
      const v = u.completionRatePercent
      if (v == null) return false
      if (b.key === '0-20') return v >= 0 && v <= 20
      if (b.key === '21-40') return v >= 21 && v <= 40
      if (b.key === '41-60') return v >= 41 && v <= 60
      if (b.key === '61-80') return v >= 61 && v <= 80
      return v >= 81 && v <= 100
    }).length
    return { ...b, count }
  })

  const usersWithHabit = users.filter((u) => u.habitCount > 0).length
  const usersWithRecord = users.filter((u) => u.totalRecords > 0).length
  const funnel = [
    { label: '가입 회원', value: stats.totalUsers },
    { label: '습관 생성 회원', value: usersWithHabit },
    { label: '기록 작성 회원', value: usersWithRecord },
  ]
  const periodLabels = overTime.map((p) => p.period.slice(5))
  const tickColor = isDark ? '#D1D5DB' : '#4B5563'
  const gridColor = isDark ? 'rgba(148,163,184,0.18)' : 'rgba(148,163,184,0.28)'

  const growthLineData = {
    labels: periodLabels,
    datasets: [
      {
        label: '신규 회원',
        data: overTime.map((p) => p.newUsers),
        borderColor: '#22C55E',
        backgroundColor: 'rgba(34,197,94,0.18)',
        fill: true,
        tension: 0.3,
      },
      {
        label: '신규 습관',
        data: overTime.map((p) => p.newHabits),
        borderColor: '#3B82F6',
        backgroundColor: 'rgba(59,130,246,0.16)',
        fill: true,
        tension: 0.3,
      },
      {
        label: '신규 기록',
        data: overTime.map((p) => p.newRecords),
        borderColor: '#8B5CF6',
        backgroundColor: 'rgba(139,92,246,0.15)',
        fill: true,
        tension: 0.3,
      },
    ],
  }

  const growthBarData = {
    labels: periodLabels,
    datasets: [
      {
        label: '신규 회원',
        data: overTime.map((p) => p.newUsers),
        backgroundColor: '#22C55E',
      },
      {
        label: '신규 습관',
        data: overTime.map((p) => p.newHabits),
        backgroundColor: '#3B82F6',
      },
      {
        label: '신규 기록',
        data: overTime.map((p) => p.newRecords),
        backgroundColor: '#8B5CF6',
      },
    ],
  }

  const distributionData = {
    labels: distribution.map((d) => d.label),
    datasets: [
      {
        label: '사용자 수',
        data: distribution.map((d) => d.count),
        backgroundColor: ['#F97316', '#F59E0B', '#84CC16', '#14B8A6', '#22C55E'],
        borderRadius: 8,
      },
    ],
  }

  const funnelData = {
    labels: funnel.map((f) => f.label),
    datasets: [
      {
        label: '사용자 수',
        data: funnel.map((f) => f.value),
        backgroundColor: ['#6366F1', '#8B5CF6', '#A855F7'],
        borderRadius: 8,
      },
    ],
  }

  const commonOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        labels: {
          boxWidth: 12,
          color: tickColor,
        },
      },
    },
    scales: {
      x: {
        ticks: {
          color: tickColor,
        },
        grid: {
          color: gridColor,
        },
      },
      y: {
        beginAtZero: true,
        ticks: {
          color: tickColor,
        },
        grid: {
          color: gridColor,
        },
      },
    },
  } as const

  const horizontalBarOptions = {
    ...commonOptions,
    indexAxis: 'y' as const,
    scales: {
      x: {
        beginAtZero: true,
        ticks: {
          color: tickColor,
        },
        grid: {
          color: gridColor,
        },
      },
      y: {
        ticks: {
          color: tickColor,
        },
        grid: {
          color: gridColor,
        },
      },
    },
  }

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

      <div className="rounded-lg border border-border bg-card p-4">
        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-sm font-medium text-foreground">성장 추이 (기간별)</h3>
          <div className="inline-flex rounded-md border border-border bg-background p-1">
            {[7, 30, 90].map((d) => (
              <button
                key={d}
                type="button"
                onClick={() => setRangeDays(d as RangeDays)}
                className={`rounded px-3 py-1 text-xs ${
                  rangeDays === d
                    ? 'bg-primary text-primary-foreground'
                    : 'text-muted-foreground hover:bg-muted'
                }`}
              >
                {d}일
              </button>
            ))}
          </div>
        </div>
        {overTime.length === 0 ? (
          <p className="text-sm text-muted-foreground">표시할 데이터가 없습니다.</p>
        ) : (
          <div className="grid gap-4 lg:grid-cols-2">
            <div className="rounded-md border border-border p-3">
              <p className="mb-2 text-xs text-muted-foreground">라인 차트</p>
              <div className="h-64">
                <Line data={growthLineData} options={commonOptions} />
              </div>
            </div>
            <div className="rounded-md border border-border p-3">
              <p className="mb-2 text-xs text-muted-foreground">그룹 막대 차트</p>
              <div className="h-64">
                <Bar data={growthBarData} options={commonOptions} />
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="rounded-lg border border-border bg-card p-4">
          <h3 className="text-sm font-medium text-foreground mb-3">완료율 분포</h3>
          <div className="h-72">
            <Bar data={distributionData} options={commonOptions} />
          </div>
        </div>

        <div className="rounded-lg border border-border bg-card p-4">
          <h3 className="text-sm font-medium text-foreground mb-3">활동 퍼널</h3>
          <div className="h-72">
            <Bar data={funnelData} options={horizontalBarOptions} />
          </div>
        </div>
      </div>
    </div>
  )
}
