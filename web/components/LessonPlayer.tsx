"use client";

import { useEffect, useRef, useState } from "react";
import { saveLessonProgress } from "@/lib/actions";

/**
 * Progress is saved on a timer and again when the tab goes away, rather than on every
 * timeupdate event — that fires several times a second and would generate a write storm
 * for no extra fidelity. The PUT is idempotent, so a dropped save costs nothing.
 */
const SAVE_INTERVAL_MS = 15_000;

export function LessonPlayer({
  lessonId,
  playbackUrl,
  resumeAt,
  completed,
}: {
  lessonId: number;
  playbackUrl: string | null;
  resumeAt: number;
  completed: boolean;
}) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const lastSaved = useRef(0);
  const [done, setDone] = useState(completed);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    if (resumeAt > 0) video.currentTime = resumeAt;

    function save(markComplete = false) {
      const seconds = video?.currentTime ?? 0;
      if (!markComplete && Math.abs(seconds - lastSaved.current) < 5) return;
      lastSaved.current = seconds;
      void saveLessonProgress(lessonId, seconds, markComplete);
    }

    const timer = setInterval(() => save(), SAVE_INTERVAL_MS);
    const onHide = () => document.visibilityState === "hidden" && save();
    const onEnded = () => {
      setDone(true);
      save(true);
    };

    document.addEventListener("visibilitychange", onHide);
    video.addEventListener("ended", onEnded);

    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", onHide);
      video.removeEventListener("ended", onEnded);
      save();
    };
  }, [lessonId, resumeAt]);

  if (!playbackUrl) {
    return (
      <div className="player player--locked">
        <strong style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-md)" }}>
          No video in this lesson
        </strong>
        <span style={{ fontSize: "var(--text-sm)", opacity: 0.85 }}>
          The written material is below.
        </span>
      </div>
    );
  }

  return (
    <div className="stack" style={{ gap: "var(--space-3)" }}>
      <div className="player">
        <video ref={videoRef} controls playsInline preload="metadata" src={playbackUrl} />
      </div>
      <div className="row row--between">
        <span className="u-meta">{done ? "Completed" : "In progress"}</span>
        <button
          className={done ? "btn btn--secondary" : "btn btn--primary"}
          type="button"
          onClick={() => {
            setDone(true);
            void saveLessonProgress(lessonId, videoRef.current?.currentTime ?? 0, true);
          }}
        >
          {done ? "Marked complete" : "Mark complete"}
        </button>
      </div>
    </div>
  );
}
