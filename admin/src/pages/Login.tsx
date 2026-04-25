import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { adminLogin, setAdminToken } from '../api'
import { useI18n } from '../i18n/I18nContext'
import type { AdminLang } from '../i18n/messages'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { t, lang, setLang } = useI18n()

  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { accessToken } = await adminLogin(email, password)
      setAdminToken(accessToken)
      navigate('/', { replace: true })
    } catch (err) {
      setError(err instanceof Error ? err.message : t('login.error'))
    } finally {
      setLoading(false)
    }
  }

  const setLanguage = (next: AdminLang) => setLang(next)

  return (
    <div className="min-h-screen bg-background text-foreground font-sans flex items-center justify-center p-4">
      <div className="w-full max-w-sm rounded-lg border border-border bg-card p-6 shadow-sm">
        <div className="flex justify-end gap-1 mb-4">
          <button
            type="button"
            onClick={() => setLanguage('ko')}
            className={`rounded-md px-2 py-1 text-xs font-medium ${
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
            className={`rounded-md px-2 py-1 text-xs font-medium ${
              lang === 'en'
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:bg-accent'
            }`}
          >
            {t('lang.en')}
          </button>
        </div>
        <h1 className="text-xl font-semibold text-card-foreground">{t('login.title')}</h1>
        <p className="text-sm text-muted-foreground mt-1">{t('login.subtitle')}</p>
        <form onSubmit={submit} className="mt-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-foreground">{t('login.email')}</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground">{t('login.password')}</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
              required
            />
          </div>
          {error && <p className="text-sm text-destructive">{error}</p>}
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-md bg-primary px-3 py-2 text-primary-foreground font-medium disabled:opacity-50"
          >
            {loading ? t('login.loading') : t('login.submit')}
          </button>
        </form>
      </div>
    </div>
  )
}
