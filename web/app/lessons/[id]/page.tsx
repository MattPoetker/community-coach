import Link from "next/link";
import { notFound } from "next/navigation";
import { api, maybe } from "@/lib/api";
import type { Community, Lesson, Me } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { LessonPlayer } from "@/components/LessonPlayer";
import { toParagraphs } from "@/lib/richtext";

type LessonResponse = { lesson: Lesson; body: unknown; playback_url: string | null };

export default async function LessonPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const [{ community }, me, data] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<LessonResponse>(`/api/v1/lessons/${id}`)),
  ]);

  // A 403 comes back as null here. That is the paywall doing its job, and it is worth
  // showing what unlocks the lesson rather than a bare error.
  if (!data) return <Locked community={community} me={me} />;

  const { lesson, body, playback_url: playbackUrl } = data;
  if (!lesson) notFound();

  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 900, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <Link className="u-meta" href="/classroom">← Back to the classroom</Link>

        <h1 style={{ fontSize: "var(--text-lg)", marginBlock: "var(--space-4) var(--space-4)" }}>
          {lesson.title}
        </h1>

        <LessonPlayer lessonId={lesson.id} playbackUrl={playbackUrl}
                      resumeAt={lesson.progress.resume_at_seconds}
                      completed={lesson.progress.state === "completed"} />

        <div className="card" style={{ marginTop: "var(--space-5)" }}>
          <div className="comment__body">
            {toParagraphs(body).map((paragraph, index) => <p key={index}>{paragraph}</p>)}
          </div>
        </div>
      </div>
    </>
  );
}

function Locked({ community, me }: { community: Community; me: Me | null }) {
  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 640, margin: "0 auto", padding: "var(--space-7) var(--space-4)" }}>
        <div className="card empty">
          <h2>This lesson is not open to you yet</h2>
          <p className="u-secondary">
            It is either part of a plan you are not on, or it unlocks later in the programme.
          </p>
          <Link className="btn btn--primary" href="/join">See the plans</Link>
        </div>
      </div>
    </>
  );
}
