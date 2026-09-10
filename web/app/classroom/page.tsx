import { api, maybe } from "@/lib/api";
import type { Community, Course, Me } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import Link from "next/link";

export default async function ClassroomPage() {
  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ courses: Course[] }>("/api/v1/courses")),
  ]);

  const courses = data?.courses ?? [];

  return (
    <>
      <TopBar community={community} me={me} />
      <div className="hz-shell" style={{ maxWidth: 1100, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <h1 style={{ marginBottom: "var(--space-5)" }}>Classroom</h1>

        {courses.length === 0 ? (
          <div className="card empty">
            <h3>No courses yet</h3>
            <p className="u-secondary">Published courses will appear here.</p>
          </div>
        ) : (
          <div className="grid" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))" }}>
            {courses.map((course) => (
              <article key={course.id} className="card card--flush">
                <div className="course-cover">{course.title}</div>
                <div className="stack" style={{ padding: "var(--card-padding)", gap: "var(--space-2)" }}>
                  <div className="row row--between">
                    <span className="u-meta">{course.lesson_count} lessons</span>
                    {course.locked ? (
                      <span className="badge">Locked</span>
                    ) : course.progress.percent === 100 ? (
                      <span className="badge badge--success">Complete</span>
                    ) : course.progress.percent > 0 ? (
                      <span className="badge badge--accent">In progress</span>
                    ) : null}
                  </div>
                  <div className="progress">
                    <div className="progress__bar" style={{ width: `${course.progress.percent}%` }} />
                  </div>
                  {course.description && <p className="post__body">{course.description}</p>}
                  <Link className="btn btn--secondary btn--block" href={`/classroom/${course.slug}`}>
                    {course.locked ? "See what unlocks it" : "Open course"}
                  </Link>
                </div>
              </article>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
