import Link from "next/link";
import { notFound } from "next/navigation";
import { api, maybe } from "@/lib/api";
import type { Community, Course, Lesson, Me } from "@/lib/types";
import { TopBar } from "@/components/Shell";

type CourseResponse = {
  course: Course;
  modules: { id: number; title: string; position: number; lessons: Lesson[] }[];
};

export default async function CoursePage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;

  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<CourseResponse>(`/api/v1/courses/${slug}`)),
  ]);

  if (!data) return <Locked community={community} me={me} />;
  if (!data.course) notFound();

  const { course, modules } = data;
  const nextLesson = modules
    .flatMap((module) => module.lessons)
    .find((lesson) => lesson.access?.granted && lesson.progress.state !== "completed");

  return (
    <>
      <TopBar community={community} me={me} />
      <div className="lesson-layout" style={{ maxWidth: 1000, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <aside className="stack">
          <Link className="u-meta" href="/classroom">← All courses</Link>
          <div className="card">
            <div className="u-label">Your progress</div>
            <div className="row row--between">
              <span style={{ fontSize: "var(--text-sm)" }}>
                {course.progress.completed} of {course.progress.total}
              </span>
              <span className="u-num">{course.progress.percent}%</span>
            </div>
            <div className="progress">
              <div className="progress__bar" style={{ width: `${course.progress.percent}%` }} />
            </div>
            {nextLesson && (
              <Link className="btn btn--primary btn--block" href={`/lessons/${nextLesson.id}`}>
                {course.progress.completed > 0 ? "Continue" : "Start the course"}
              </Link>
            )}
          </div>
        </aside>

        <main className="stack">
          <div>
            <h1>{course.title}</h1>
            {course.description && (
              <p className="u-secondary" style={{ marginTop: "var(--space-2)" }}>
                {course.description}
              </p>
            )}
          </div>

          {modules.map((module) => (
            <section key={module.id} className="card">
              <h2 style={{ fontSize: "var(--text-md)" }}>{module.title}</h2>
              <hr className="divider" />
              <div>
                {module.lessons.map((lesson) => (
                  <LessonRow key={lesson.id} lesson={lesson} />
                ))}
              </div>
            </section>
          ))}
        </main>
      </div>
    </>
  );
}

function LessonRow({ lesson }: { lesson: Lesson }) {
  const granted = lesson.access?.granted ?? false;
  const done = lesson.progress.state === "completed";

  const inner = (
    <>
      <span className="lesson-row__mark" aria-hidden="true">{done ? "✓" : ""}</span>
      <div style={{ fontSize: "var(--text-sm)", fontWeight: done ? undefined : "var(--weight-semi)" }}>
        {lesson.title}
      </div>
      <div className="spacer" />
      {granted ? (
        lesson.progress.state === "started" && <span className="badge badge--accent">Resume</span>
      ) : (
        // The API tells us *why* it is shut, so the row says that rather than "locked".
        <span className="u-meta">{lesson.access?.message ?? "Locked"}</span>
      )}
    </>
  );

  const className = `lesson-row${done ? " lesson-row--done" : ""}${granted ? "" : " lesson-row--locked"}`;

  return granted ? (
    <Link className={className} href={`/lessons/${lesson.id}`}>{inner}</Link>
  ) : (
    <div className={className}>{inner}</div>
  );
}

function Locked({ community, me }: { community: Community; me: Me | null }) {
  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 620, margin: "0 auto", padding: "var(--space-7) var(--space-4)" }}>
        <div className="card empty">
          <h2>This course is not open to you yet</h2>
          <p className="u-secondary">It is part of a plan you are not on.</p>
          <Link className="btn btn--primary" href="/join">See the plans</Link>
        </div>
      </div>
    </>
  );
}
