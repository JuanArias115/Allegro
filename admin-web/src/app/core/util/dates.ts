export const BOGOTA_TZ = 'America/Bogota';

/** Formatea un Date a 'yyyy-MM-dd' (fecha calendario, sin zona). */
export function toIsoDate(d: Date): string {
  const y = d.getFullYear();
  const m = `${d.getMonth() + 1}`.padStart(2, '0');
  const day = `${d.getDate()}`.padStart(2, '0');
  return `${y}-${m}-${day}`;
}

/** Rango [from, to) del mes que contiene `ref` (to = primer día del mes siguiente). */
export function monthRange(ref = new Date()): { from: string; to: string } {
  const from = new Date(ref.getFullYear(), ref.getMonth(), 1);
  const to = new Date(ref.getFullYear(), ref.getMonth() + 1, 1);
  return { from: toIsoDate(from), to: toIsoDate(to) };
}

/** Rango [from, to) de un mes dado (year, monthIndex 0-11). */
export function monthRangeOf(year: number, monthIndex: number): { from: string; to: string } {
  return {
    from: toIsoDate(new Date(year, monthIndex, 1)),
    to: toIsoDate(new Date(year, monthIndex + 1, 1)),
  };
}

/** Noches entre dos fechas ISO 'yyyy-MM-dd'. */
export function nightsBetween(checkIn: string, checkOut: string): number {
  const a = new Date(checkIn + 'T00:00:00');
  const b = new Date(checkOut + 'T00:00:00');
  return Math.max(0, Math.round((b.getTime() - a.getTime()) / 86_400_000));
}
