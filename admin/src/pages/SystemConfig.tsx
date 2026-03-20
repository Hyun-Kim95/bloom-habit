import { useEffect, useState } from 'react'
import { api } from '../api'

const KNOWN_KEYS = {
  app_jwt_expires_seconds: '앱 JWT 만료 시간 (초, 예: 604800=7일)',
} as const

export default function SystemConfig() {
  const [error, setError] = useState('')
  const [appJwtExpires, setAppJwtExpires] = useState('604800')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    api.getConfig().then((c) => {
      setAppJwtExpires(c.app_jwt_expires_seconds ?? '604800')
    }).catch((e) => setError(e.message))
  }, [])

  const save = async () => {
    setSaving(true)
    try {
      const body: Record<string, string> = {
        app_jwt_expires_seconds: appJwtExpires.trim() || '604800',
      }
      await api.patchConfig(body)
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패')
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
            value={appJwtExpires}
            onChange={(e) => setAppJwtExpires(e.target.value)}
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
        <h3 className="text-sm font-medium text-foreground mb-2">설정값 관리 범위</h3>
        <p className="text-sm text-muted-foreground mb-2">
          위 항목은 서버에서 즉시 반영됩니다. (JWT 만료: 다음 로그인부터)
        </p>
        <ul className="text-sm text-muted-foreground space-y-1">
          {Object.entries(KNOWN_KEYS).map(([k, label]) => (
            <li key={k}><span className="font-mono">{k}</span> — {label}</li>
          ))}
        </ul>
      </div>
    </div>
  )
}
