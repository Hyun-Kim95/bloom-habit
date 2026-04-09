import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  interpolate,
  messages,
  STORAGE_KEY,
  type AdminLang,
} from './messages'

type Ctx = {
  lang: AdminLang
  setLang: (l: AdminLang) => void
  t: (key: string, vars?: Record<string, string | number>) => string
  locale: string
}

const I18nContext = createContext<Ctx | null>(null)

function readInitialLang(): AdminLang {
  try {
    const v = localStorage.getItem(STORAGE_KEY)
    if (v === 'en' || v === 'ko') return v
  } catch {
    /* ignore */
  }
  return 'ko'
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<AdminLang>(readInitialLang)

  const setLang = useCallback((l: AdminLang) => {
    setLangState(l)
    try {
      localStorage.setItem(STORAGE_KEY, l)
    } catch {
      /* ignore */
    }
    document.documentElement.lang = l === 'en' ? 'en' : 'ko'
  }, [])

  useEffect(() => {
    document.documentElement.lang = lang === 'en' ? 'en' : 'ko'
  }, [lang])

  const locale = lang === 'en' ? 'en-US' : 'ko-KR'

  const t = useCallback(
    (key: string, vars?: Record<string, string | number>) => {
      const raw = messages[lang][key] ?? messages.ko[key] ?? key
      return vars ? interpolate(raw, vars) : raw
    },
    [lang],
  )

  const value = useMemo(
    () => ({ lang, setLang, t, locale }),
    [lang, setLang, t, locale],
  )

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>
}

export function useI18n(): Ctx {
  const c = useContext(I18nContext)
  if (!c) throw new Error('useI18n must be used within I18nProvider')
  return c
}
