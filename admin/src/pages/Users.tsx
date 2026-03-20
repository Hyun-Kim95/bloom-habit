import { useEffect, useMemo, useState } from 'react'
import { api } from '../api'

type User = {
  id: string
  email: string | null
  authProvider: 'google' | 'apple' | 'kakao' | 'naver' | 'unknown'
  displayName: string | null
  createdAt: string
  isActive: boolean
  deactivatedAt: string | null
  deactivationReason: string | null
  deactivatedBy: 'self' | 'admin' | null
  habitCount: number
  totalRecords: number
  completedRecords: number
  completionRatePercent: number | null
}

type SortKey = 'createdAt' | 'habitCount' | 'completionRatePercent'
type SortDir = 'asc' | 'desc'

export default function Users() {
  const [users, setUsers] = useState<User[]>([])
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [sortKey, setSortKey] = useState<SortKey>('createdAt')
  const [sortDir, setSortDir] = useState<SortDir>('desc')
  const [deactivateTarget, setDeactivateTarget] = useState<User | null>(null)
  const [deactivateReason, setDeactivateReason] = useState('')
  const [savingDeactivate, setSavingDeactivate] = useState(false)

  useEffect(() => {
    api.getUsers().then(setUsers).catch((e) => setError(e.message))
  }, [])

  const filtered = useMemo(() => {
    let list = users
    if (search.trim()) {
      const q = search.trim().toLowerCase()
      list = list.filter(
        (u) =>
          u.id.toLowerCase().includes(q) ||
          (u.email ?? '').toLowerCase().includes(q) ||
          (u.displayName ?? '').toLowerCase().includes(q)
      )
    }
    const sorted = [...list].sort((a, b) => {
      const dir = sortDir === 'asc' ? 1 : -1
      if (sortKey === 'createdAt') {
        return (new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()) * dir
      }
      if (sortKey === 'habitCount') {
        return (a.habitCount - b.habitCount) * dir
      }
      const av = a.completionRatePercent ?? -1
      const bv = b.completionRatePercent ?? -1
      return (av - bv) * dir
    })
    return sorted
  }, [users, search, sortKey, sortDir])
  const activeCount = filtered.filter((u) => u.isActive).length
  const inactiveCount = filtered.length - activeCount

  const downloadCsv = () => {
    const header = ['id', 'email', 'authProvider', 'displayName', 'createdAt', 'isActive', 'habitCount', 'totalRecords', 'completionRatePercent']
    const rows = filtered.map((u) => [
      u.id,
      u.email ?? '',
      u.authProvider,
      u.displayName ?? '',
      new Date(u.createdAt).toISOString(),
      u.isActive ? 'true' : 'false',
      String(u.habitCount),
      String(u.totalRecords),
      u.completionRatePercent != null ? String(u.completionRatePercent) : '',
    ])
    const escapeCell = (v: string) => `"${v.replace(/"/g, '""')}"`
    const csv = [header, ...rows]
      .map((row) => row.map((cell) => escapeCell(cell)).join(','))
      .join('\n')
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `users-${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  const toggleUserActive = async (u: User) => {
    const next = !u.isActive
    const action = next ? '활성화' : '비활성화'
    if (!next) {
      setDeactivateTarget(u)
      setDeactivateReason('')
      return
    } else {
      if (!confirm(`${u.id} 계정을 ${action}할까요?`)) return
    }
    try {
      await api.setUserActive(u.id, next)
      setUsers((prev) =>
        prev.map((x) =>
          x.id === u.id
            ? {
                ...x,
                isActive: next,
                deactivatedAt: next ? null : new Date().toISOString(),
                deactivationReason: null,
                deactivatedBy: next ? null : 'admin',
              }
            : x,
        ),
      )
    } catch (e) {
      setError(e instanceof Error ? e.message : '상태 변경 실패')
    }
  }

  const submitDeactivate = async () => {
    if (!deactivateTarget) return
    const reason = deactivateReason.trim()
    if (!reason) {
      setError('비활성화 사유를 입력해야 합니다.')
      return
    }
    setSavingDeactivate(true)
    try {
      await api.setUserActive(deactivateTarget.id, false, reason)
      setUsers((prev) =>
        prev.map((x) =>
          x.id === deactivateTarget.id
            ? {
                ...x,
                isActive: false,
                deactivatedAt: new Date().toISOString(),
                deactivationReason: reason,
                deactivatedBy: 'admin',
              }
            : x,
        ),
      )
      setDeactivateTarget(null)
      setDeactivateReason('')
    } catch (e) {
      setError(e instanceof Error ? e.message : '상태 변경 실패')
    } finally {
      setSavingDeactivate(false)
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">회원 관리</h2>

      <div className="grid gap-3 sm:grid-cols-3">
        <div className="rounded-lg border border-border bg-card p-3">
          <p className="text-xs text-muted-foreground">조회 대상 회원</p>
          <p className="text-xl font-semibold text-card-foreground">{filtered.length}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-3">
          <p className="text-xs text-muted-foreground">활성 회원</p>
          <p className="text-xl font-semibold text-card-foreground">{activeCount}</p>
        </div>
        <div className="rounded-lg border border-border bg-card p-3">
          <p className="text-xs text-muted-foreground">비활성 회원</p>
          <p className="text-xl font-semibold text-card-foreground">{inactiveCount}</p>
        </div>
      </div>

      <div className="rounded-lg border border-border bg-card p-3">
        <div className="flex flex-wrap items-center gap-3">
          <input
            type="search"
            placeholder="ID·이메일·표시명 검색"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground w-48"
          />
          <span className="text-sm text-muted-foreground">정렬</span>
          <select
            value={sortKey}
            onChange={(e) => setSortKey(e.target.value as SortKey)}
            className="rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground"
          >
            <option value="createdAt">가입일</option>
            <option value="habitCount">습관 수</option>
            <option value="completionRatePercent">완료율</option>
          </select>
          <select
            value={sortDir}
            onChange={(e) => setSortDir(e.target.value as SortDir)}
            className="rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground"
          >
            <option value="desc">내림차순</option>
            <option value="asc">오름차순</option>
          </select>
          <button
            type="button"
            onClick={downloadCsv}
            className="rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground hover:bg-accent"
          >
            CSV 다운로드
          </button>
          <span className="text-sm text-muted-foreground">
            {filtered.length}명 / 전체 {users.length}명
          </span>
        </div>
      </div>

      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">ID</th>
              <th className="text-left p-3 font-medium">이메일</th>
              <th className="text-left p-3 font-medium">플랫폼</th>
              <th className="text-left p-3 font-medium">표시명</th>
              <th className="text-left p-3 font-medium">가입일</th>
              <th className="text-left p-3 font-medium">계정 상태</th>
              <th className="text-left p-3 font-medium">비활성화 사유</th>
              <th className="text-right p-3 font-medium">습관 수</th>
              <th className="text-right p-3 font-medium">총 기록</th>
              <th className="text-right p-3 font-medium">완료율</th>
              <th className="text-right p-3 font-medium">기능</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0">
                <td className="p-3">{u.id}</td>
                <td className="p-3">{u.email ?? '-'}</td>
                <td className="p-3">{u.authProvider}</td>
                <td className="p-3">{u.displayName ?? '-'}</td>
                <td className="p-3 text-muted-foreground">
                  {new Date(u.createdAt).toLocaleDateString('ko-KR')}
                </td>
                <td className="p-3">
                  <span className={u.isActive ? 'text-primary font-medium' : 'text-destructive font-medium'}>
                    {u.isActive ? '활성' : '비활성'}
                  </span>
                </td>
                <td className="p-3 text-muted-foreground">
                  {u.deactivationReason
                    ? `${u.deactivationReason}${u.deactivatedBy ? ` (${u.deactivatedBy})` : ''}`
                    : '-'}
                </td>
                <td className="p-3 text-right">{u.habitCount}</td>
                <td className="p-3 text-right">{u.totalRecords}</td>
                <td className="p-3 text-right">
                  {u.completionRatePercent != null ? `${u.completionRatePercent}%` : '-'}
                </td>
                <td className="p-3 text-right">
                  <button
                    type="button"
                    onClick={() => toggleUserActive(u)}
                    className={`rounded-md px-3 py-1.5 text-xs font-medium ${
                      u.isActive
                        ? 'border border-destructive/40 bg-destructive/10 text-destructive hover:bg-destructive/20'
                        : 'border border-primary/40 bg-primary/10 text-primary hover:bg-primary/20'
                    }`}
                  >
                    {u.isActive ? '비활성화' : '활성화'}
                  </button>
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

      {deactivateTarget && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          onClick={() => !savingDeactivate && setDeactivateTarget(null)}
        >
          <div
            className="w-full max-w-md rounded-lg border border-border bg-card p-5 text-card-foreground"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-base font-semibold">회원 비활성화</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              <span className="font-medium text-foreground">{deactivateTarget.id}</span> 계정을 비활성화합니다.
              사유를 입력해 주세요.
            </p>
            <textarea
              value={deactivateReason}
              onChange={(e) => setDeactivateReason(e.target.value)}
              maxLength={500}
              rows={4}
              className="mt-3 w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground"
              placeholder="비활성화 사유"
            />
            <div className="mt-1 text-right text-xs text-muted-foreground">
              {deactivateReason.length}/500
            </div>
            <div className="mt-4 flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setDeactivateTarget(null)}
                disabled={savingDeactivate}
                className="rounded-md border border-border px-3 py-2 text-sm"
              >
                취소
              </button>
              <button
                type="button"
                onClick={submitDeactivate}
                disabled={savingDeactivate || !deactivateReason.trim()}
                className="rounded-md bg-destructive px-3 py-2 text-sm text-destructive-foreground disabled:opacity-50"
              >
                {savingDeactivate ? '처리 중…' : '비활성화'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
