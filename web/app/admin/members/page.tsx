import { api, maybe } from "@/lib/api";
import type { Community, Invitation, JoinRequest, Me, Member } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { AdminNav, StaffOnly } from "@/components/AdminNav";
import { InviteForm } from "@/components/InviteForm";
import { JoinRequestActions } from "@/components/JoinRequestActions";
import { relativeTime } from "@/lib/format";

export default async function AdminMembersPage() {
  const [{ community }, me, members, invitations, joinRequests] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ members: Member[] }>("/api/v1/members")),
    maybe(() => api.get<{ invitations: Invitation[] }>("/api/v1/invitations")),
    maybe(() => api.get<{ join_requests: JoinRequest[] }>("/api/v1/join_requests")),
  ]);

  if (!me?.membership?.staff) {
    return (<><TopBar community={community} me={me} /><StaffOnly /></>);
  }

  const pending = joinRequests?.join_requests ?? [];

  return (
    <>
      <TopBar community={community} me={me} />
      <div className="admin-layout" style={{ maxWidth: 1000, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <aside><AdminNav active="/admin/members" /></aside>
        <main className="stack" style={{ gap: "var(--space-5)" }}>
          <h1>Members</h1>

          {pending.length > 0 && (
            <section className="card">
              <div className="u-label">Waiting to join ({pending.length})</div>
              <div className="stack">
                {pending.map((request) => (
                  <div key={request.id} className="row row--between row--wrap">
                    <div className="row">
                      <span className="avatar avatar--sm" aria-hidden="true">
                        {request.user.initials}
                      </span>
                      <div>
                        <div style={{ fontSize: "var(--text-sm)", fontWeight: "var(--weight-semi)" }}>
                          {request.user.name}
                        </div>
                        <div className="u-meta">Asked {relativeTime(request.created_at)}</div>
                      </div>
                    </div>
                    <JoinRequestActions id={request.id} />
                  </div>
                ))}
              </div>
            </section>
          )}

          <InviteForm />

          {(invitations?.invitations.length ?? 0) > 0 && (
            <section className="card">
              <div className="u-label">Invitations not yet accepted</div>
              <div className="table-scroll">
                <table className="table">
                  <thead>
                    <tr><th>Email</th><th>Role</th><th>Sent</th><th>Expires</th></tr>
                  </thead>
                  <tbody>
                    {invitations!.invitations.map((invitation) => (
                      <tr key={invitation.id}>
                        <td>{invitation.email_address}</td>
                        <td>{invitation.role}</td>
                        <td className="u-meta">{relativeTime(invitation.created_at)}</td>
                        <td className="u-meta">
                          {new Date(invitation.expires_at).toLocaleDateString()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          )}

          <section className="card">
            <div className="u-label">Everyone ({members?.members.length ?? 0})</div>
            <div className="table-scroll">
              <table className="table">
                <thead>
                  <tr><th>Member</th><th>Role</th><th>Plan</th><th>Status</th><th>Joined</th></tr>
                </thead>
                <tbody>
                  {(members?.members ?? []).map((member) => (
                    <tr key={member.id}>
                      <td>
                        <div className="row">
                          <span className="avatar avatar--sm" aria-hidden="true">
                            {member.user.initials}
                          </span>
                          {member.user.name}
                        </div>
                      </td>
                      <td>{member.role}</td>
                      <td>{member.plan_slug ?? "—"}</td>
                      <td>
                        <span className={statusClass(member.status)}>{member.status}</span>
                      </td>
                      <td className="u-meta">
                        {member.joined_at ? relativeTime(member.joined_at) : "—"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </main>
      </div>
    </>
  );
}

function statusClass(status: string) {
  if (status === "active") return "badge badge--success";
  if (status === "past_due") return "badge badge--warning";
  if (status === "suspended") return "badge badge--danger";
  return "badge";
}
