import { api, maybe } from "@/lib/api";
import type { Community, Me, Member } from "@/lib/types";
import { TopBar } from "@/components/Shell";

export default async function MembersPage() {
  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ members: Member[] }>("/api/v1/members")),
  ]);

  const members = data?.members ?? [];
  const staff = members.filter((member) => member.staff);
  const rest = members.filter((member) => !member.staff);

  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 900, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <div className="row row--between" style={{ marginBottom: "var(--space-5)" }}>
          <h1>Members</h1>
          <span className="u-meta">{community.member_count} active</span>
        </div>

        {staff.length > 0 && (
          <section style={{ marginBottom: "var(--space-6)" }}>
            <div className="u-label" style={{ marginBottom: "var(--space-3)" }}>Hosts and moderators</div>
            <MemberGrid members={staff} />
          </section>
        )}

        <section>
          <div className="u-label" style={{ marginBottom: "var(--space-3)" }}>Members</div>
          {rest.length === 0 ? (
            <div className="card empty"><p className="u-secondary">Nobody else has joined yet.</p></div>
          ) : (
            <MemberGrid members={rest} />
          )}
        </section>
      </div>
    </>
  );
}

function MemberGrid({ members }: { members: Member[] }) {
  return (
    <div className="grid" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(230px, 1fr))" }}>
      {members.map((member) => (
        <article key={member.id} className="card" style={{ gap: "var(--space-3)" }}>
          <div className="row">
            <span className="avatar avatar--lg" aria-hidden="true">{member.user.initials}</span>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: "var(--weight-semi)", fontSize: "var(--text-sm)" }}>
                {member.user.name}
              </div>
              <div className="u-meta">
                {member.joined_at
                  ? `Joined ${new Date(member.joined_at).toLocaleDateString(undefined, { month: "short", year: "numeric" })}`
                  : "Recently joined"}
              </div>
            </div>
          </div>
          <div className="row row--wrap" style={{ gap: "var(--space-2)" }}>
            {member.staff && <span className="badge badge--accent">{titleCase(member.role)}</span>}
            {member.plan_slug && <span className="badge">{titleCase(member.plan_slug)}</span>}
            {member.status === "past_due" && <span className="badge badge--warning">Past due</span>}
          </div>
        </article>
      ))}
    </div>
  );
}

function titleCase(value: string) {
  return value.replace(/[-_]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}
