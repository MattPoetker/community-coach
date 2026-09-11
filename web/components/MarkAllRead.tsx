"use client";

import { useTransition } from "react";
import { markNotificationsRead } from "@/lib/actions";

export function MarkAllRead({ count }: { count: number }) {
  const [pending, startTransition] = useTransition();

  return (
    <button className="btn btn--ghost" type="button" disabled={pending}
            onClick={() => startTransition(() => void markNotificationsRead())}>
      {pending ? "Marking…" : `Mark ${count} as read`}
    </button>
  );
}
