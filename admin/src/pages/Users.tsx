import { useEffect, useState } from 'react'
import { api } from '../api'

type User = { id: string; email: string | null; displayName: string | null }

export default function Users() {
  const [users, setUsers] = useState<User[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    api.getUsers().then(setUsers).catch((e) => setError(e.message))
  }, [])

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">회원 관리</h2>
      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <table className="w-full text-sm text-card-foreground">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">ID</th>
              <th className="text-left p-3 font-medium">이메일</th>
              <th className="text-left p-3 font-medium">표시명</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b border-border last:border-0">
                <td className="p-3">{u.id}</td>
                <td className="p-3">{u.email ?? '-'}</td>
                <td className="p-3">{u.displayName ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <p className="p-4 text-muted-foreground">등록된 회원이 없습니다.</p>
        )}
      </div>
    </div>
  )
}
