import Link from "next/link";
import { api, maybe } from "@/lib/api";
import type { Community, Me, Notification } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { MarkAllRead } from "@/components/MarkAllRead";
import { relativeTime } from "@/lib/format";

export default async function NotificationsPage() {
  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ notifications: Notification[]; unread_count: number }>("/api/v1/notifications")),
  ]);

  const notifications = data?.notifications ?? [];

  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 680, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <div className="row row--between" style={{ marginBottom: "var(--space-5)" }}>
          <h1>Notifications</h1>
          {(data?.unread_count ?? 0) > 0 && <MarkAllRead count={data!.unread_count} />}
        </div>

        {notifications.length === 0 ? (
          <div className="card empty">
            <h3>Nothing waiting</h3>
            <p className="u-secondary">Replies, mentions and reminders land here.</p>
          </div>
        ) : (
          <div className="card" style={{ gap: 0 }}>
            {notifications.map((notification) => (
              <NotificationRow key={notification.id} notification={notification} />
            ))}
          </div>
        )}

        <p className="u-meta" style={{ marginTop: "var(--space-4)", textAlign: "center" }}>
          <Link href="/settings/notifications">Choose what you hear about</Link>
        </p>
      </div>
    </>
  );
}

function NotificationRow({ notification }: { notification: Notification }) {
  const href =
    notification.subject_type === "Post" ? `/posts/${notification.subject_id}` : "/notifications";

  return (
    <Link href={href} className={`notification${notification.read ? "" : " notification--unread"}`}>
      <span className="avatar avatar--sm" aria-hidden="true">
        {notification.actor?.initials ?? "··"}
      </span>
      <div style={{ minWidth: 0 }}>
        <div className="notification__text">{describe(notification)}</div>
        <div className="u-meta">{relativeTime(notification.created_at)}</div>
      </div>
    </Link>
  );
}

/** Written from the member's side of the screen: what happened, not which record changed. */
function describe(notification: Notification): string {
  const who = notification.actor?.name ?? "Someone";
  const others = notification.group_count > 1 ? ` and ${notification.group_count - 1} others` : "";
  const title = String(notification.data.post_title ?? notification.data.title ?? "your post");

  switch (notification.kind) {
    case "reply": return `${who}${others} replied to ${title}`;
    case "mention": return `${who} mentioned you`;
    case "reaction": return `${who}${others} liked ${title}`;
    case "new_post": return `${who} posted: ${title}`;
    case "event_reminder": return `${title} is starting soon`;
    case "lesson_published": return `New lesson: ${title}`;
    default: return `${who} did something in the community`;
  }
}
