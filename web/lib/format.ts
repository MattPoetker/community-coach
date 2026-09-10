/** Relative time, written the way a person would say it rather than "0 minutes ago". */
export function relativeTime(iso: string): string {
  const then = new Date(iso).getTime();
  const seconds = Math.round((Date.now() - then) / 1000);

  if (seconds < 60) return "just now";
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.round(hours / 24);
  if (days < 7) return `${days}d`;
  return new Date(iso).toLocaleDateString(undefined, { day: "numeric", month: "short" });
}

export function formatEventTime(iso: string, timezone: string): string {
  return new Intl.DateTimeFormat(undefined, {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: timezone,
    timeZoneName: "short",
  }).format(new Date(iso));
}

export function dayParts(iso: string, timezone: string) {
  const date = new Date(iso);
  return {
    day: new Intl.DateTimeFormat(undefined, { day: "numeric", timeZone: timezone }).format(date),
    month: new Intl.DateTimeFormat(undefined, { month: "short", timeZone: timezone }).format(date),
  };
}
