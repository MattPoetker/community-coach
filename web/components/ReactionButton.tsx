"use client";

import { useOptimistic, useTransition } from "react";
import { toggleReaction } from "@/lib/actions";

/**
 * Optimistic: a like is the highest-frequency interaction in the product and the one
 * people notice lag on. The count moves immediately and reconciles when the action
 * returns; a failure snaps it back rather than leaving a wrong number on screen.
 */
export function ReactionButton({
  type,
  id,
  count,
  reacted,
  path,
}: {
  type: "Post" | "Comment";
  id: number;
  count: number;
  reacted: boolean;
  path: string;
}) {
  const [state, setOptimistic] = useOptimistic(
    { count, reacted },
    (current) => ({
      count: current.reacted ? current.count - 1 : current.count + 1,
      reacted: !current.reacted,
    }),
  );
  const [, startTransition] = useTransition();

  return (
    <button
      className="post__action"
      type="button"
      aria-pressed={state.reacted}
      onClick={() =>
        startTransition(async () => {
          setOptimistic(null);
          await toggleReaction(type, id, path);
        })
      }
      style={state.reacted ? { color: "var(--text-accent)" } : undefined}
    >
      {state.reacted ? "▲" : "△"} {state.count}
    </button>
  );
}
