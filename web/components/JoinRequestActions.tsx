"use client";

import { useTransition } from "react";
import { reviewJoinRequest } from "@/lib/actions";

export function JoinRequestActions({ id }: { id: number }) {
  const [pending, startTransition] = useTransition();

  return (
    <div className="row" style={{ gap: "var(--space-2)" }}>
      <button className="btn btn--primary" type="button" disabled={pending}
              onClick={() => startTransition(() => void reviewJoinRequest(id, "approve"))}>
        Approve
      </button>
      <button className="btn btn--ghost" type="button" disabled={pending}
              onClick={() => startTransition(() => void reviewJoinRequest(id, "reject"))}>
        Decline
      </button>
    </div>
  );
}
