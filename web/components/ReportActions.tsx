"use client";

import { useState, useTransition } from "react";
import { moderateReport } from "@/lib/actions";

export function ReportActions({ reportId }: { reportId: number }) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function act(action: string) {
    setError(null);
    startTransition(async () => {
      const result = await moderateReport(reportId, action);
      if (!result.ok) setError(result.error);
    });
  }

  return (
    <div className="stack" style={{ gap: "var(--space-2)" }}>
      {error && <p className="form-error" role="alert">{error}</p>}
      <div className="row row--wrap" style={{ gap: "var(--space-2)" }}>
        <button className="btn btn--danger" type="button" disabled={pending}
                onClick={() => act("remove")}>
          Remove content
        </button>
        <button className="btn btn--secondary" type="button" disabled={pending}
                onClick={() => act("lock")}>
          Lock thread
        </button>
        <button className="btn btn--ghost" type="button" disabled={pending}
                onClick={() => act("dismiss")}>
          Dismiss — nothing wrong here
        </button>
      </div>
    </div>
  );
}
