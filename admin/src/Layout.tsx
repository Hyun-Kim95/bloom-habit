import { useState } from 'react'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { clearAdminToken } from './api'

const nav = [
  { path: '/', label: '대시보드' },
  { path: '/users', label: '회원 관리' },
  { path: '/habit-templates', label: '습관 템플릿' },
  { path: '/habit-categories', label: '습관 카테고리' },
  { path: '/notices', label: '공지 관리' },
  { path: '/inquiries', label: '문의' },
  { path: '/legal', label: '약관·개인정보' },
  { path: '/system-config', label: 'AI 문구 / 설정' },
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

  return (
    <div className="min-h-screen bg-background text-foreground font-sans flex">
      <aside className="w-56 border-r border-border bg-card flex flex-col">
        <div className="p-4 border-b border-border">
          <h1 className="font-semibold text-card-foreground">Bloom Habit</h1>
          <p className="text-xs text-muted-foreground">관리자</p>
        </div>
        <nav className="p-2 flex-1">
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
        <div className="p-2 border-t border-border">
          <button
            type="button"
            onClick={toggleDark}
            className="w-full text-left px-3 py-2 rounded-md text-sm text-muted-foreground hover:bg-accent"
          >
            {dark ? '라이트' : '다크'} 모드
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <header className="border-b border-border px-4 py-3 flex items-center justify-end gap-2">
          <span className="text-sm text-muted-foreground">관리자</span>
          <button
            type="button"
            onClick={() => {
              clearAdminToken()
              navigate('/login', { replace: true })
            }}
            className="text-sm text-muted-foreground hover:text-foreground"
          >
            로그아웃
          </button>
        </header>
        <div className="p-6">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
