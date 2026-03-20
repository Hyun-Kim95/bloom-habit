import { useState } from 'react'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { clearAdminToken } from './api'

const nav = [
  { path: '/', label: '대시보드' },
  { path: '/users', label: '회원 관리' },
  { path: '/habit-templates', label: '습관 템플릿' },
  { path: '/notices', label: '공지 관리' },
  { path: '/inquiries', label: '문의' },
  { path: '/legal', label: '약관·개인정보' },
]

export default function Layout() {
  const [dark, setDark] = useState(false)
  const location = useLocation()
  const navigate = useNavigate()

  const toggleDark = () => {
    const next = !dark
    setDark(next)
    document.documentElement.classList.toggle('dark', next)
  }

  const handleLogout = () => {
    clearAdminToken()
    navigate('/login', { replace: true })
  }

  return (
    <div className="min-h-screen bg-background text-foreground font-sans flex">
      <aside className="fixed inset-y-0 left-0 z-20 flex w-56 flex-col border-r border-border bg-card">
        <div className="shrink-0 border-b border-border p-4">
          <h1 className="font-semibold text-card-foreground">Bloom Habit</h1>
          <p className="text-xs text-muted-foreground">관리자</p>
        </div>
        <nav className="min-h-0 flex-1 overflow-y-auto p-2">
          {nav.map(({ path, label }) => (
            <Link
              key={path}
              to={path}
              className={`block px-3 py-2 rounded-md text-sm ${
                location.pathname === path
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              }`}
            >
              {label}
            </Link>
          ))}
        </nav>
        <div className="shrink-0 space-y-1 border-t border-border p-2">
          <button
            type="button"
            onClick={toggleDark}
            className="w-full rounded-md px-3 py-2 text-left text-sm text-muted-foreground hover:bg-accent"
          >
            {dark ? '라이트' : '다크'} 모드
          </button>
          <button
            type="button"
            onClick={handleLogout}
            className="w-full rounded-md px-3 py-2 text-left text-sm text-muted-foreground hover:bg-accent hover:text-foreground"
          >
            로그아웃
          </button>
        </div>
      </aside>

      <main className="ml-56 flex min-h-screen flex-1 flex-col">
        <div className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
