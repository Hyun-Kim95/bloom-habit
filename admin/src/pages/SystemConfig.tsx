import { useEffect, useState } from 'react'
import { api } from '../api'

const KNOWN_KEYS = {
  ai_prompt_template: 'AI 프롬프트 ({{habitName}} 사용 가능)',
  ai_fallback_messages: 'AI Fallback 문구 (JSON 배열, 한 줄에 하나)',
  ai_daily_limit: '일일 AI 코멘트 호출 상한 (회원당, 숫자)',
  app_jwt_expires_seconds: '앱 JWT 만료 시간 (초, 예: 604800=7일)',
} as const

const DEFAULT_PROMPT =
  '사용자가 오늘 "{{habitName}}" 습관을 완료했습니다. 한 문장으로 짧고 따뜻한 격려 한마디만 한국어로 답해 주세요. 이모지 없이.'

export default function SystemConfig() {
  const [config, setConfig] = useState<Record<string, string>>({})
  const [error, setError] = useState('')
  const [aiPromptTemplate, setAiPromptTemplate] = useState(DEFAULT_PROMPT)
  const [aiFallback, setAiFallback] = useState('')
  const [aiDailyLimit, setAiDailyLimit] = useState('30')
  const [appJwtExpires, setAppJwtExpires] = useState('604800')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    api.getConfig().then((c) => {
      setConfig(c)
      setAiPromptTemplate(c.ai_prompt_template?.trim() || DEFAULT_PROMPT)
      try {
        const arr = JSON.parse(c.ai_fallback_messages ?? '[]') as string[]
        setAiFallback(Array.isArray(arr) ? arr.join('\n') : '')
      } catch {
        setAiFallback('')
      }
      setAiDailyLimit(c.ai_daily_limit ?? '30')
      setAppJwtExpires(c.app_jwt_expires_seconds ?? '604800')
    }).catch((e) => setError(e.message))
  }, [])

  const save = async () => {
    setSaving(true)
    try {
      const lines = aiFallback.split('\n').map((s) => s.trim()).filter(Boolean)
      const body: Record<string, string> = {
        ai_prompt_template: aiPromptTemplate.trim() || DEFAULT_PROMPT,
        ai_fallback_messages: JSON.stringify(lines),
        ai_daily_limit: aiDailyLimit.trim() || '30',
        app_jwt_expires_seconds: appJwtExpires.trim() || '604800',
      }
      await api.patchConfig(body)
      setConfig((prev) => ({ ...prev, ...body }))
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
            {KNOWN_KEYS.ai_prompt_template}
          </label>
          <textarea
            value={aiPromptTemplate}
            onChange={(e) => setAiPromptTemplate(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground font-mono text-sm"
            rows={4}
            placeholder={DEFAULT_PROMPT}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">
            {KNOWN_KEYS.ai_fallback_messages}
          </label>
          <textarea
            value={aiFallback}
            onChange={(e) => setAiFallback(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground font-mono text-sm"
            rows={6}
            placeholder="오늘도 수고했어요!&#10;꾸준함이 쌓여가고 있어요."
          />
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-foreground">
              {KNOWN_KEYS.ai_daily_limit}
            </label>
            <input
              type="number"
              min={1}
              max={999}
              value={aiDailyLimit}
              onChange={(e) => setAiDailyLimit(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            />
          </div>
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
          위 항목은 서버에서 즉시 반영됩니다. (JWT 만료: 다음 로그인부터, AI 상한: 즉시)
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
