import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App'
import { I18nProvider } from './i18n/I18nContext'

const THEME_STORAGE_KEY = 'habit_fable_admin_theme'
const rootElement = document.documentElement
const storedTheme = window.localStorage.getItem(THEME_STORAGE_KEY)
rootElement.classList.toggle('dark', storedTheme === 'dark')

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <I18nProvider>
      <App />
    </I18nProvider>
  </StrictMode>,
)
