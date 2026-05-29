import { useEffect, useMemo, useState } from 'react'
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { clearAdminToken } from './api'
import { useI18n } from './i18n/I18nContext'
import type { AdminLang } from './i18n/messages'

const navPaths = [
  { path: '/', key: 'layout.nav.dashboard' },
  { path: '/users', key: 'layout.nav.users' },
  { path: '/habit-templates', key: 'layout.nav.habitTemplates' },
  { path: '/notices', key: 'layout.nav.notices' },
  { path: '/inquiries', key: 'layout.nav.inquiries' },
  { path: '/legal', key: 'layout.nav.legal' },
  { path: '/system-config', key: 'layout.nav.systemConfig' },
] as const

const THEME_STORAGE_KEY = 'habit_fable_admin_theme'

const readStoredTheme = () => {
  if (typeof window === 'undefined') return 'light'
  return window.localStorage.getItem(THEME_STORAGE_KEY) === 'dark' ? 'dark' : 'light'
}

export default function Layout() {
  const [dark, setDark] = useState(() => readStoredTheme() === 'dark')
  const location = useLocation()
  const navigate = useNavigate()
  const { t, lang, setLang } = useI18n()

  const nav = useMemo(
    () => navPaths.map((item) => ({ ...item, label: t(item.key) })),
    [t],
  )

  useEffect(() => {
    if (typeof window === 'undefined') return
    document.documentElement.classList.toggle('dark', dark)
    window.localStorage.setItem(THEME_STORAGE_KEY, dark ? 'dark' : 'light')
  }, [dark])

  const toggleDark = () => {
    setDark((prev) => !prev)
  }

  const handleLogout = () => {
    clearAdminToken()
    navigate('/login', { replace: true })
  }

  const setLanguage = (next: AdminLang) => setLang(next)

  return (
    <div className="min-h-screen bg-background text-foreground font-sans flex">
      <aside className="fixed inset-y-0 left-0 z-20 flex w-56 flex-col border-r border-border bg-card">
        <div className="shrink-0 border-b border-border p-4">
          <h1 className="font-semibold text-card-foreground">{t('layout.brand')}</h1>
          <p className="text-xs text-muted-foreground">{t('layout.subtitle')}</p>
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
          <div className="flex gap-1 px-1">
            <button
              type="button"
              onClick={() => setLanguage('ko')}
              className={`flex-1 rounded-md px-2 py-1.5 text-xs font-medium ${
                lang === 'ko'
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent'
              }`}
            >
              {t('lang.ko')}
            </button>
            <button
              type="button"
              onClick={() => setLanguage('en')}
              className={`flex-1 rounded-md px-2 py-1.5 text-xs font-medium ${
                lang === 'en'
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent'
              }`}
            >
              {t('lang.en')}
            </button>
          </div>
          <button
            type="button"
            onClick={toggleDark}
            className="w-full rounded-md px-3 py-2 text-left text-sm text-muted-foreground hover:bg-accent"
          >
            {dark ? t('layout.themeLight') : t('layout.themeDark')}
            {t('layout.themeSuffix')}
          </button>
          <button
            type="button"
            onClick={handleLogout}
            className="w-full rounded-md px-3 py-2 text-left text-sm text-muted-foreground hover:bg-accent hover:text-foreground"
          >
            {t('layout.logout')}
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
