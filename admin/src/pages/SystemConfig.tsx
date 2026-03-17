import { useEffect, useState } from 'react'
import { api } from '../api'

export default function SystemConfig() {
  const [config, setConfig] = useState<Record<string, string>>({})
  const [error, setError] = useState('')
  const [aiFallback, setAiFallback] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    api.getConfig().then((c) => {
      setConfig(c)
      try {
        const arr = JSON.parse(c.ai_fallback_messages ?? '[]') as string[]
        setAiFallback(Array.isArray(arr) ? arr.join('\n') : '')
      } catch {
        setAiFallback('')
      }
    }).catch((e) => setError(e.message))
  }, [])

  const save = async () => {
    setSaving(true)
    try {
      const lines = aiFallback.split('\n').map((s) => s.trim()).filter(Boolean)
      await api.patchConfig({ ai_fallback_messages: JSON.stringify(lines) })
      setConfig((prev) => ({ ...prev, ai_fallback_messages: JSON.stringify(lines) }))
    } catch (e) {
      setError(e instanceof Error ? e.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  if (error) return <p className="text-destructive">{error}</p>

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">AI 문구 / 시스템 설정</h2>

      <div className="rounded-lg border border-border bg-card p-4 space-y-4">
        <div>
          <label className="block text-sm font-medium text-foreground">
            AI Fallback 문구 (한 줄에 하나)
          </label>
          <textarea
            value={aiFallback}
            onChange={(e) => setAiFallback(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground font-mono text-sm"
            rows={6}
            placeholder="오늘도 수고했어요!&#10;꾸준함이 쌓여가고 있어요."
          />
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
        <h3 className="text-sm font-medium text-foreground mb-2">현재 설정 키</h3>
        <ul className="text-sm text-muted-foreground space-y-1">
          {Object.keys(config).map((k) => (
            <li key={k}>{k}</li>
          ))}
        </ul>
      </div>
    </div>
  )
}
