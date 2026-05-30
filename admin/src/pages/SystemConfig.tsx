import { useEffect, useState } from 'react'
import { api } from '../api'
import { adminErrorMessage } from '../apiErrors'
import { useI18n } from '../i18n/I18nContext'

const KNOWN_KEYS = {
  app_jwt_expires_seconds: '앱 JWT 만료 시간 (초, 예: 604800=7일)',
} as const

type ConfigKey = keyof typeof KNOWN_KEYS

const DEFAULTS: Record<ConfigKey, string> = {
  app_jwt_expires_seconds: '604800',
}

export default function SystemConfig() {
  const { t } = useI18n()
  const [error, setError] = useState('')
  const [values, setValues] = useState<Record<ConfigKey, string>>({ ...DEFAULTS })
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    api
      .getConfig()
      .then((c) => {
        setValues((prev) => ({
          ...prev,
          app_jwt_expires_seconds: c.app_jwt_expires_seconds ?? DEFAULTS.app_jwt_expires_seconds,
        }))
      })
      .catch((e) => setError(adminErrorMessage(e, t('errors.generic'))))
  }, [])

  const save = async () => {
    setSaving(true)
    setError('')
    try {
      await api.patchConfig({
        app_jwt_expires_seconds: values.app_jwt_expires_seconds.trim() || '604800',
      })
    } catch (e) {
      setError(adminErrorMessage(e, t('errors.generic')))
    } finally {
      setSaving(false)
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">시스템 설정</h2>

      <div className="rounded-lg border border-border bg-card p-4 space-y-4">
        <div>
          <label className="block text-sm font-medium text-foreground">
            {KNOWN_KEYS.app_jwt_expires_seconds}
          </label>
          <input
            type="number"
            min={3600}
            value={values.app_jwt_expires_seconds}
            onChange={(e) =>
              setValues((prev) => ({
                ...prev,
                app_jwt_expires_seconds: e.target.value,
              }))
            }
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            placeholder="604800"
          />
          <p className="mt-1 text-xs text-muted-foreground">
            604800=7일, 86400=1일
          </p>
        </div>
        <button
          type="button"
          onClick={save}
          disabled={saving}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground"
        >
          {saving ? '저장 중...' : '저장'}
        </button>
      </div>

      <div className="rounded-lg border border-border bg-card p-4">
        <h3 className="text-sm font-medium text-foreground mb-2">앱 업데이트 (Android)</h3>
        <p className="text-sm text-muted-foreground">
          권장 업데이트 알림은 <strong>별도 설정 없이</strong> AAB를 Play에 올리고 게시하면 됩니다.
          어드민·서버에서 버전을 맞출 필요가 없습니다.
        </p>
        <p className="text-sm text-muted-foreground mt-2">
          강제 업데이트에 가깝게 쓰려면 Play Developer API로 priority(4~5)를 지정해야 합니다.
          Play Console 화면에 priority 항목이 없는 경우가 많습니다.
        </p>
        <p className="text-sm text-muted-foreground mt-2">
          자세한 내용:{' '}
          <code className="font-mono text-xs">docs/guides/play-in-app-update.md</code>
        </p>
      </div>

      <div className="rounded-lg border border-border bg-card p-4">
        <h3 className="text-sm font-medium text-foreground mb-2">설정값 관리 범위</h3>
        <p className="text-sm text-muted-foreground mb-2">
          JWT 만료는 다음 로그인부터 반영됩니다.
        </p>
        <ul className="text-sm text-muted-foreground space-y-1">
          {Object.entries(KNOWN_KEYS).map(([k, label]) => (
            <li key={k}>
              <span className="font-mono">{k}</span> — {label}
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
