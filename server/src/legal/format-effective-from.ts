/**
 * PostgreSQL `date` (TypeORM) may hydrate as `string` ("YYYY-MM-DD") or `Date`.
 * Never call `.toISOString()` on a plain string — use this for API DTOs.
 */
export function formatLegalEffectiveFrom(value: unknown): string | null {
  if (value == null || value === '') return null;
  if (typeof value === 'string') {
    const s = value.trim();
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
    if (/^\d{4}-\d{2}-\d{2}T/.test(s)) return s.slice(0, 10);
    const t = Date.parse(s);
    if (!Number.isNaN(t)) return new Date(t).toISOString().slice(0, 10);
    return null;
  }
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return null;
    return value.toISOString().slice(0, 10);
  }
  return null;
}
