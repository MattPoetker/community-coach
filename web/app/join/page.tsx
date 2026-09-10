import { api } from "@/lib/api";
import type { Community, Plan } from "@/lib/types";

/**
 * The public sales page. Follows the layout the category has settled on — a wide editorial
 * column carrying the offer beside a narrow sticky card carrying the decision — because
 * visitors arriving from an ad or a creator's link already know how to read it.
 */
export default async function JoinPage() {
  const { community, plans, stats } = await api.get<{
    community: Community;
    plans: Plan[];
    stats: { members: number; online: number; admins: number };
  }>("/api/v1/community");

  const headline = plans.find((plan) => !plan.free) ?? plans[0];

  return (
    <>
      <header className="public-header">
        <div className="identity__mark identity__mark--sm">
          {community.name.split(" ").slice(0, 2).map((w) => w[0]).join("")}
        </div>
        <strong style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-md)" }}>
          {community.name}
        </strong>
        <div className="spacer" />
        <a className="btn btn--ghost" href="/login">Log in</a>
      </header>

      <main className="hz-section" style={{ padding: "var(--space-6) var(--space-4)" }}>
        <div className="landing">
          <div className="stack">
            <div className="card">
              <h1 style={{ fontSize: "var(--text-xl)" }}>{community.name}</h1>
              {community.tagline && <p className="u-secondary">{community.tagline}</p>}

              <div className="hero-media" role="img" aria-label={`${community.name} introduction`}>
                <div className="hero-media__play" aria-hidden="true">▶</div>
                <div className="hero-media__caption">{community.tagline}</div>
              </div>

              <div className="meta-bar">
                <span className="meta-bar__item">
                  <span className="meta-bar__icon" aria-hidden="true">◎</span>
                  <strong>{stats.members.toLocaleString()}</strong> members
                </span>
                {headline && (
                  <span className="meta-bar__item">
                    <span className="meta-bar__icon" aria-hidden="true">◇</span>
                    <strong>{headline.price}</strong>/{headline.interval}
                  </span>
                )}
              </div>

              <hr className="divider" />

              {community.description && (
                <div className="prose">
                  <p>{community.description}</p>
                </div>
              )}
            </div>
          </div>

          <aside className="landing__aside">
            <div className="card join-card">
              <div className="join-card__cover">{community.name}</div>
              <div className="join-card__body">
                <div>
                  <div style={{
                    fontFamily: "var(--font-display)",
                    fontWeight: "var(--weight-display)",
                    fontSize: "var(--text-md)",
                  }}>
                    {community.name}
                  </div>
                  <div className="join-card__url">{community.slug}</div>
                </div>
                {community.tagline && (
                  <p style={{ fontSize: "var(--text-sm)", color: "var(--text-secondary)" }}>
                    {community.tagline}
                  </p>
                )}
              </div>

              <div className="stat-trio">
                <div className="stat">
                  <span className="stat__value">{stats.members.toLocaleString()}</span>
                  <span className="stat__label">Members</span>
                </div>
                <div className="stat">
                  <span className="stat__value stat__value--live">
                    <span className="stat__dot" aria-hidden="true" />
                    {stats.online}
                  </span>
                  <span className="stat__label">Online</span>
                </div>
                <div className="stat">
                  <span className="stat__value">{stats.admins}</span>
                  <span className="stat__label">Admins</span>
                </div>
              </div>

              <div className="join-card__foot">
                <a className="btn btn--primary btn--lg btn--block" href="/signup">
                  {headline ? `Join · ${headline.price}/${headline.interval}` : "Join"}
                </a>
                {headline && headline.trial_days > 0 && (
                  <p className="u-meta" style={{ textAlign: "center" }}>
                    {headline.trial_days} days free · cancel any time
                  </p>
                )}
              </div>
            </div>

            {plans.length > 1 && (
              <div className="card">
                <div className="u-label">Plans</div>
                {plans.map((plan) => (
                  <div key={plan.id} className="row row--between" style={{ padding: "var(--space-2) 0" }}>
                    <span style={{ fontSize: "var(--text-sm)" }}>{plan.name}</span>
                    <span className="u-num" style={{ fontWeight: "var(--weight-semi)" }}>{plan.price}</span>
                  </div>
                ))}
              </div>
            )}
          </aside>
        </div>
      </main>
    </>
  );
}
