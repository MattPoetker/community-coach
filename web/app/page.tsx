import { api, maybe } from "@/lib/api";
import type { Category, Community, EventOccurrence, Me, Post } from "@/lib/types";
import { TopBar, CategoryNav } from "@/components/Shell";
import { PostCard } from "@/components/PostCard";
import { Composer } from "@/components/Composer";
import { dayParts } from "@/lib/format";
import Link from "next/link";

export default async function FeedPage({
  searchParams,
}: {
  searchParams: Promise<{ category?: string }>;
}) {
  const { category } = await searchParams;

  const [{ community }, me, categories, feed, events] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ categories: Category[] }>("/api/v1/categories")),
    maybe(() => api.get<{ posts: Post[] }>("/api/v1/posts")),
    maybe(() => api.get<{ events: EventOccurrence[] }>("/api/v1/events")),
  ]);

  if (!me) return <JoinPrompt community={community} />;

  const posts = feed?.posts ?? [];
  const nextEvent = events?.events?.[0];

  return (
    <>
      <TopBar community={community} me={me} />
      <div className="shell">
        <aside className="shell__side">
          <nav className="nav" aria-label="Sections">
            <Link className="nav-item" href="/" aria-current="page">Community</Link>
            <Link className="nav-item" href="/classroom">Classroom</Link>
            <Link className="nav-item" href="/calendar">Calendar</Link>
            <Link className="nav-item" href="/members">Members</Link>
            {me.membership?.staff && <Link className="nav-item" href="/admin">Admin</Link>}
          </nav>
          <hr className="divider" style={{ margin: "var(--space-4) 0" }} />
          <CategoryNav categories={categories?.categories ?? []} activeSlug={category} />
        </aside>

        <main className="stack">
          <Composer categories={categories?.categories ?? []} initials={me.user.initials} />

          {posts.length === 0 ? (
            <div className="card empty">
              <h3>Nothing here yet</h3>
              <p className="u-secondary">Be the first to post. Ask the room a real question.</p>
            </div>
          ) : (
            posts.map((post) => <PostCard key={post.id} post={post} />)
          )}
        </main>

        <aside className="shell__rail stack">
          {nextEvent && (
            <div className="card">
              <div className="u-label">Next live call</div>
              <div className="row">
                <div className="event-date">
                  <div className="event-date__day">
                    {dayParts(nextEvent.starts_at, nextEvent.timezone).day}
                  </div>
                  <div className="event-date__mon">
                    {dayParts(nextEvent.starts_at, nextEvent.timezone).month}
                  </div>
                </div>
                <div>
                  <div style={{ fontWeight: "var(--weight-semi)", fontSize: "var(--text-sm)" }}>
                    {nextEvent.title}
                  </div>
                  <div className="u-meta">{nextEvent.going_count} going</div>
                </div>
              </div>
              <Link className="btn btn--primary btn--block" href="/calendar">
                {nextEvent.my_rsvp === "going" ? "You are going" : "Reserve a seat"}
              </Link>
            </div>
          )}

          <div className="card">
            <div className="u-label">Members</div>
            <div className="row row--between">
              <span style={{ fontSize: "var(--text-sm)" }}>Active members</span>
              <span className="u-num">{community.member_count}</span>
            </div>
          </div>
        </aside>
      </div>
    </>
  );
}

function JoinPrompt({ community }: { community: Community }) {
  return (
    <>
      <TopBar community={community} me={null} />
      <div className="auth-page">
        <h1>{community.name}</h1>
        <p className="u-secondary">{community.tagline}</p>
        <Link className="btn btn--primary btn--lg btn--block" href="/join">See what is inside</Link>
        <Link className="btn btn--secondary btn--block" href="/login">Sign in</Link>
      </div>
    </>
  );
}
