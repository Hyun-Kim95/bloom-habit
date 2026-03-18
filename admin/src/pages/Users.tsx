import { useEffect, useMemo, useState } from 'react'
import { api } from '../api'

type User = {
  id: string
  email: string | null
  displayName: string | null
  createdAt: string
  habitCount: number
  totalRecords: number
  completedRecords: number
  completionRatePercent: number | null
}

type StatusFilter = 'all' | 'linked' | 'unlinked'

function userStatus(u: User): '연동' | '미연동' {
  return u.email && u.email.trim() !== '' ? '연동' : '미연동'
}

export default function Users() {
  const [users, setUsers] = useState<User[]>([])
  const [error, setError] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [search, setSearch] = useState('')

  useEffect(() => {
    api.getUsers().then(setUsers).catch((e) => setError(e.message))
  }, [])

  const filtered = useMemo(() => {
    let list = users
    if (statusFilter === 'linked') list = list.filter((u) => userStatus(u) === '연동')
    else if (statusFilter === 'unlinked') list = list.filter((u) => userStatus(u) === '미연동')
    if (search.trim()) {
      const q = search.trim().toLowerCase()
      list = list.filter(
        (u) =>
          u.id.toLowerCase().includes(q) ||
          (u.email ?? '').toLowerCase().includes(q) ||
          (u.displayName ?? '').toLowerCase().includes(q)
      )
    }
    return list
  }, [users, statusFilter, search])

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">회원 관리</h2>

      <div className="flex flex-wrap items-center gap-3">
        <span className="text-sm text-muted-foreground">상태 필터</span>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as StatusFilter)}
          className="rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground"
        >
          <option value="all">전체</option>
          <option value="linked">이메일 연동</option>
          <option value="unlinked">미연동</option>
        </select>
        <input
          type="search"
          placeholder="ID·이메일·표시명 검색"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground w-48"
        />
        <span className="text-sm text-muted-foreground">
          {filtered.length}명 / 전체 {users.length}명
        </span>
      </div>

      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">ID</th>
              <th className="text-left p-3 font-medium">이메일</th>
              <th className="text-left p-3 font-medium">표시명</th>
              <th className="text-left p-3 font-medium">가입일</th>
              <th className="text-right p-3 font-medium">습관 수</th>
              <th className="text-right p-3 font-medium">완료율</th>
              <th className="text-left p-3 font-medium">상태</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0">
                <td className="p-3">{u.id}</td>
                <td className="p-3">{u.email ?? '-'}</td>
                <td className="p-3">{u.displayName ?? '-'}</td>
                <td className="p-3 text-muted-foreground">
                  {new Date(u.createdAt).toLocaleDateString('ko-KR')}
                </td>
                <td className="p-3 text-right">{u.habitCount}</td>
                <td className="p-3 text-right">
                  {u.completionRatePercent != null ? `${u.completionRatePercent}%` : '-'}
                </td>
                <td className="p-3">
                  <span
                    className={
                      userStatus(u) === '연동'
                        ? 'text-primary font-medium'
                        : 'text-muted-foreground'
                    }
                  >
                    {userStatus(u)}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <p className="p-4 text-muted-foreground">
            {users.length === 0 ? '등록된 회원이 없습니다.' : '조건에 맞는 회원이 없습니다.'}
          </p>
        )}
      </div>
    </div>
  )
}
