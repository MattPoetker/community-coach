import { api, maybe } from "@/lib/api";
import type { Community, Me, Report } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { AdminNav, StaffOnly } from "@/components/AdminNav";
import { ReportActions } from "@/components/ReportActions";
import { relativeTime } from "@/lib/format";
import Link from "next/link";

export default async function ModerationPage() {
  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ reports: Report[] }>("/api/v1/reports")),
  ]);

  if (!me?.membership?.staff) {
    return (<><TopBar community={community} me={me} /><StaffOnly /></>);
  }

  const reports = data?.reports ?? [];

  return (
    <>
      <TopBar community={community} me={me} />
      <div className="admin-layout" style={{ maxWidth: 1000, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <aside><AdminNav active="/admin/moderation" /></aside>
        <main className="stack">
          <div>
            <h1>Moderation</h1>
            <p className="u-secondary" style={{ marginTop: "var(--space-2)" }}>
              {reports.length === 0
                ? "Nothing reported. The queue is empty."
                : `${reports.length} ${reports.length === 1 ? "report" : "reports"} waiting.`}
            </p>
          </div>

          {reports.map((report) => (
            <article key={report.id} className="card">
              <div className="row row--between row--wrap">
                <div className="row">
                  <span className="avatar avatar--sm" aria-hidden="true">
                    {report.reporter.initials}
                  </span>
                  <div>
                    <div style={{ fontSize: "var(--text-sm)" }}>
                      <strong>{report.reporter.name}</strong> reported a {report.subject_type.toLowerCase()}
                    </div>
                    <div className="u-meta">{relativeTime(report.created_at)}</div>
                  </div>
                </div>
                <span className="badge badge--warning">{report.reason.replace(/_/g, " ")}</span>
              </div>

              <div className="card card--sunken" style={{ gap: "var(--space-2)" }}>
                <div className="u-label">Reported content</div>
                <p className="post__body">{report.subject_title ?? "(no preview available)"}</p>
                {report.subject_type === "Post" && (
                  <Link className="u-meta" href={`/posts/${report.subject_id}`}>Open in context →</Link>
                )}
              </div>

              {report.detail && (
                <p className="post__body"><strong>They said:</strong> {report.detail}</p>
              )}

              <ReportActions reportId={report.id} />
            </article>
          ))}
        </main>
      </div>
    </>
  );
}
