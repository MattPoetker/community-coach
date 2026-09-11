"use client";

import { useOptimistic, useTransition } from "react";
import { rsvp } from "@/lib/actions";

export function RsvpButton({
  occurrenceId,
  state,
  goingCount,
  locationUrl,
}: {
  occurrenceId: number;
  state: string | null;
  goingCount: number;
  locationUrl: string | null;
}) {
  const [optimistic, setOptimistic] = useOptimistic(
    { state, goingCount },
    (current, next: string) => ({
      state: next,
      goingCount:
        next === "going" && current.state !== "going"
          ? current.goingCount + 1
          : next !== "going" && current.state === "going"
            ? current.goingCount - 1
            : current.goingCount,
    }),
  );
  const [pending, startTransition] = useTransition();

  function set(next: string) {
    startTransition(async () => {
      setOptimistic(next);
      await rsvp(occurrenceId, next);
    });
  }

  if (optimistic.state === "going") {
    return (
      <div className="row" style={{ gap: "var(--space-2)" }}>
        <span className="badge badge--success">Going</span>
        {/* The joining link only exists once someone has said they are coming, so a
            public calendar cannot hand out the meeting URL. */}
        {locationUrl && (
          <a className="btn btn--primary" href={locationUrl} target="_blank" rel="noreferrer">
            Join call
          </a>
        )}
        <button className="btn btn--ghost" type="button" disabled={pending}
                onClick={() => set("declined")}>
          Cancel
        </button>
      </div>
    );
  }

  return (
    <div className="row" style={{ gap: "var(--space-2)" }}>
      <button className="btn btn--primary" type="button" disabled={pending}
              onClick={() => set("going")}>
        {pending ? "Saving…" : "Reserve a seat"}
      </button>
      <button className="btn btn--ghost" type="button" disabled={pending}
              onClick={() => set("maybe")}>
        Maybe
      </button>
    </div>
  );
}
