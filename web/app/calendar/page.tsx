import { api, maybe } from "@/lib/api";
import type { Community, EventOccurrence, Me } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { dayParts, formatEventTime } from "@/lib/format";

export default async function CalendarPage() {
  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ events: EventOccurrence[] }>("/api/v1/events")),
  ]);

  const events = data?.events ?? [];

  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 900, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <h1 style={{ marginBottom: "var(--space-5)" }}>Calendar</h1>

        {events.length === 0 ? (
          <div className="card empty">
            <h3>Nothing scheduled</h3>
            <p className="u-secondary">Live calls will show up here once they are booked.</p>
          </div>
        ) : (
          <div className="stack">
            {events.map((event) => {
              const parts = dayParts(event.starts_at, event.timezone);
              return (
                <article key={event.id} className="card">
                  <div className="row">
                    <div className="event-date">
                      <div className="event-date__day">{parts.day}</div>
                      <div className="event-date__mon">{parts.month}</div>
                    </div>
                    <div>
                      <h3 style={{ fontSize: "var(--text-md)" }}>{event.title}</h3>
                      <div className="u-meta">
                        {formatEventTime(event.starts_at, event.timezone)}
                        {event.recurring && " · Recurring"} · {event.going_count} going
                      </div>
                    </div>
                    <div className="spacer" />
                    {event.my_rsvp === "going" ? (
                      <div className="row" style={{ gap: "var(--space-2)" }}>
                        <span className="badge badge--success">Going</span>
                        {event.location_url && (
                          <a className="btn btn--primary" href={event.location_url}>Join call</a>
                        )}
                      </div>
                    ) : (
                      <button className="btn btn--secondary" type="button">RSVP</button>
                    )}
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </>
  );
}
