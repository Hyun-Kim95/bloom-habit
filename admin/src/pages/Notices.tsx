import { useEffect, useState } from 'react'
import DatePicker, { registerLocale } from 'react-datepicker'
import { ko } from 'date-fns/locale'
import 'react-datepicker/dist/react-datepicker.css'
import { api } from '../api'
import { adminErrorMessage } from '../apiErrors'
import { useI18n } from '../i18n/I18nContext'
import { displayNoticeBody, displayNoticeTitle } from '../i18n/dataDisplay'

registerLocale('ko', ko)

type Notice = {
  id: string
  title: string
  body: string
  titleEn?: string
  bodyEn?: string
  publishedAt?: string
  isNotice?: boolean
  isPublic?: boolean
  displayStartAt?: string
  displayEndAt?: string
}

function YesNoRadios(props: {
  legend: string
  name: string
  value: boolean
  onChange: (v: boolean) => void
  legendClass: string
}) {
  const { legend, name, value, onChange, legendClass } = props
  return (
    <fieldset>
      <legend className={legendClass}>{legend}</legend>
      <div className="mt-2 flex flex-wrap gap-6">
        <label className="flex items-center gap-2 text-sm text-foreground cursor-pointer">
          <input type="radio" name={name} checked={value} onChange={() => onChange(true)} />
          예
        </label>
        <label className="flex items-center gap-2 text-sm text-foreground cursor-pointer">
          <input type="radio" name={name} checked={!value} onChange={() => onChange(false)} />
          아니오
        </label>
      </div>
    </fieldset>
  )
}

function NoticeDatePickers(props: {
  startLabel: string
  endLabel: string
  start: Date | null
  end: Date | null
  onStartChange: (d: Date | null) => void
  onEndChange: (d: Date | null) => void
  labelClass: string
}) {
  const { startLabel, endLabel, start, end, onStartChange, onEndChange, labelClass } = props
  const inputClass =
    'w-full rounded-md border border-input bg-background px-3 py-2 text-sm text-foreground'
  return (
    <>
      <div>
        <label className={`block ${labelClass}`}>{startLabel}</label>
        <DatePicker
          selected={start}
          onChange={(d: Date | null) => onStartChange(d)}
          showTimeSelect
          timeIntervals={15}
          dateFormat="yyyy-MM-dd HH:mm"
          locale="ko"
          isClearable
          placeholderText="선택 안 함"
          className={`mt-1 ${inputClass}`}
          wrapperClassName="mt-1 block w-full"
        />
      </div>
      <div>
        <label className={`block ${labelClass}`}>{endLabel}</label>
        <DatePicker
          selected={end}
          onChange={(d: Date | null) => onEndChange(d)}
          showTimeSelect
          timeIntervals={15}
          dateFormat="yyyy-MM-dd HH:mm"
          locale="ko"
          isClearable
          placeholderText="선택 안 함"
          className={`mt-1 ${inputClass}`}
          wrapperClassName="mt-1 block w-full"
        />
      </div>
    </>
  )
}

export default function Notices() {
  const { t, lang } = useI18n()
  const [list, setList] = useState<Notice[]>([])
  const [error, setError] = useState('')
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [titleEn, setTitleEn] = useState('')
  const [bodyEn, setBodyEn] = useState('')
  const [loading, setLoading] = useState(false)
  const [isNotice, setIsNotice] = useState(true)
  const [isPublic, setIsPublic] = useState(true)
  const [displayStartAt, setDisplayStartAt] = useState<Date | null>(null)
  const [displayEndAt, setDisplayEndAt] = useState<Date | null>(null)
  const [editing, setEditing] = useState<Notice | null>(null)
  const [editTitle, setEditTitle] = useState('')
  const [editBody, setEditBody] = useState('')
  const [editTitleEn, setEditTitleEn] = useState('')
  const [editBodyEn, setEditBodyEn] = useState('')
  const [editSaving, setEditSaving] = useState(false)
  const [editIsNotice, setEditIsNotice] = useState(true)
  const [editIsPublic, setEditIsPublic] = useState(false)
  const [editDisplayStartAt, setEditDisplayStartAt] = useState<Date | null>(null)
  const [editDisplayEndAt, setEditDisplayEndAt] = useState<Date | null>(null)

  const load = () =>
    api.getNotices().then(setList).catch((e) => setError(adminErrorMessage(e, t('errors.generic'))))

  useEffect(() => {
    load()
  }, [])

  const create = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) return
    setLoading(true)
    try {
      await api.createNotice({
        title: title.trim(),
        body: body.trim(),
        titleEn: titleEn.trim() || undefined,
        bodyEn: bodyEn.trim() || undefined,
        isNotice,
        isPublic,
        displayStartAt: displayStartAt ? displayStartAt.toISOString() : undefined,
        displayEndAt: displayEndAt ? displayEndAt.toISOString() : undefined,
      })
      setTitle('')
      setBody('')
      setTitleEn('')
      setBodyEn('')
      setIsNotice(true)
      setIsPublic(true)
      setDisplayStartAt(null)
      setDisplayEndAt(null)
      load()
    } catch (e) {
      setError(adminErrorMessage(e, t('notices.createFail')))
    } finally {
      setLoading(false)
    }
  }

  const startEdit = (n: Notice) => {
    setEditing(n)
    setEditTitle(n.title)
    setEditBody(n.body)
    setEditTitleEn(n.titleEn ?? '')
    setEditBodyEn(n.bodyEn ?? '')
    setEditIsNotice(n.isNotice ?? true)
    setEditIsPublic(n.isPublic ?? false)
    setEditDisplayStartAt(n.displayStartAt ? new Date(n.displayStartAt) : null)
    setEditDisplayEndAt(n.displayEndAt ? new Date(n.displayEndAt) : null)
  }

  const saveEdit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editing) return
    setEditSaving(true)
    try {
      await api.updateNotice(editing.id, {
        title: editTitle.trim(),
        body: editBody.trim(),
        titleEn: editTitleEn.trim(),
        bodyEn: editBodyEn.trim(),
        isNotice: editIsNotice,
        isPublic: editIsPublic,
        displayStartAt: editDisplayStartAt ? editDisplayStartAt.toISOString() : null,
        displayEndAt: editDisplayEndAt ? editDisplayEndAt.toISOString() : null,
      })
      setEditing(null)
      load()
    } catch (e) {
      setError(adminErrorMessage(e, t('notices.updateFail')))
    } finally {
      setEditSaving(false)
    }
  }

  const remove = async (id: string) => {
    if (!confirm(t('notices.confirmDelete'))) return
    try {
      await api.deleteNotice(id)
      load()
    } catch (e) {
      setError(adminErrorMessage(e, t('notices.deleteFail')))
    }
  }

  if (error && list.length === 0) return <p className="text-destructive">{error}</p>

  const legendCreate = 'block text-sm font-medium text-foreground'
  const legendEdit = 'block text-xs text-muted-foreground'

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-semibold text-foreground">{t('notices.title')}</h2>

      {error && list.length > 0 && <p className="text-sm text-destructive">{error}</p>}

      <form onSubmit={create} className="space-y-3 rounded-lg border border-border bg-card p-4">
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.titleLabel')}</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.titleEn')}</label>
          <input
            value={titleEn}
            onChange={(e) => setTitleEn(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.body')}</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            rows={3}
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-foreground">{t('notices.bodyEn')}</label>
          <textarea
            value={bodyEn}
            onChange={(e) => setBodyEn(e.target.value)}
            className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            rows={3}
          />
        </div>
        <YesNoRadios
          legend="상단고정"
          name="notice-create-isNotice"
          value={isNotice}
          onChange={setIsNotice}
          legendClass={legendCreate}
        />
        <YesNoRadios
          legend="공개여부"
          name="notice-create-isPublic"
          value={isPublic}
          onChange={setIsPublic}
          legendClass={legendCreate}
        />
        <NoticeDatePickers
          startLabel="개시 시작"
          endLabel="개시 종료"
          start={displayStartAt}
          end={displayEndAt}
          onStartChange={setDisplayStartAt}
          onEndChange={setDisplayEndAt}
          labelClass="text-sm font-medium text-foreground"
        />
        <button
          type="submit"
          disabled={loading}
          className="rounded-md bg-primary px-4 py-2 text-primary-foreground"
        >
          {t('notices.add')}
        </button>
      </form>

      {editing && (
        <form
          onSubmit={saveEdit}
          className="space-y-3 rounded-lg border border-border bg-card p-4"
        >
          <h3 className="text-sm font-medium text-foreground">{t('notices.editTitle')}</h3>
          <div>
            <label className={legendEdit}>{t('notices.titleLabel')}</label>
            <input
              value={editTitle}
              onChange={(e) => setEditTitle(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            />
          </div>
          <div>
            <label className={legendEdit}>{t('notices.titleEn')}</label>
            <input
              value={editTitleEn}
              onChange={(e) => setEditTitleEn(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
            />
          </div>
          <div>
            <label className={legendEdit}>{t('notices.body')}</label>
            <textarea
              value={editBody}
              onChange={(e) => setEditBody(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
              rows={3}
            />
          </div>
          <div>
            <label className={legendEdit}>{t('notices.bodyEn')}</label>
            <textarea
              value={editBodyEn}
              onChange={(e) => setEditBodyEn(e.target.value)}
              className="mt-1 w-full rounded-md border border-input bg-background px-3 py-2 text-foreground"
              rows={3}
            />
          </div>
          <YesNoRadios
            legend="상단고정"
            name="notice-edit-isNotice"
            value={editIsNotice}
            onChange={setEditIsNotice}
            legendClass={legendEdit}
          />
          <YesNoRadios
            legend="공개여부"
            name="notice-edit-isPublic"
            value={editIsPublic}
            onChange={setEditIsPublic}
            legendClass={legendEdit}
          />
          <NoticeDatePickers
            startLabel="개시 시작"
            endLabel="개시 종료"
            start={editDisplayStartAt}
            end={editDisplayEndAt}
            onStartChange={setEditDisplayStartAt}
            onEndChange={setEditDisplayEndAt}
            labelClass="text-xs text-muted-foreground"
          />
          <div className="flex gap-2">
            <button
              type="submit"
              disabled={editSaving}
              className="rounded-md bg-primary px-4 py-2 text-primary-foreground text-sm"
            >
              {t('common.save')}
            </button>
            <button
              type="button"
              onClick={() => setEditing(null)}
              className="rounded-md border border-border px-4 py-2 text-sm"
            >
              {t('common.cancel')}
            </button>
          </div>
        </form>
      )}

      <div className="space-y-2">
        {list.map((n) => (
          <div
            key={n.id}
            className="rounded-lg border border-border bg-card p-4 flex justify-between items-start"
          >
            <div>
              <h3 className="font-medium text-foreground">{displayNoticeTitle(n, lang)}</h3>
              <p className="text-xs text-muted-foreground mt-1">
                상단고정:{n.isNotice ? '예' : '아니오'} / 공개:{n.isPublic ? '예' : '아니오'}
              </p>
              <p className="text-sm text-muted-foreground mt-1 whitespace-pre-wrap">
                {displayNoticeBody(n, lang)}
              </p>
            </div>
            <div className="flex flex-wrap gap-2 shrink-0">
              <button
                type="button"
                onClick={() => startEdit(n)}
                className="rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground hover:bg-accent"
              >
                {t('common.edit')}
              </button>
              <button
                type="button"
                onClick={() => remove(n.id)}
                className="rounded-md border border-destructive px-3 py-2 text-sm text-destructive hover:bg-destructive/10"
              >
                {t('common.delete')}
              </button>
            </div>
          </div>
        ))}
        {list.length === 0 && <p className="text-muted-foreground">{t('notices.empty')}</p>}
      </div>
    </div>
  )
}

