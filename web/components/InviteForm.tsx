"use client";

import { useRef, useState, useTransition } from "react";
import { sendInvitations } from "@/lib/actions";

export function InviteForm() {
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form
      ref={formRef}
      className="card stack"
      action={(formData) => {
        setMessage(null);
        setError(null);
        startTransition(async () => {
          const result = await sendInvitations(formData);
          if (result.ok) {
            setMessage("Invitations sent.");
            formRef.current?.reset();
          } else {
            setError(result.error);
          }
        });
      }}
    >
      <div className="u-label">Invite people</div>
      {error && <p className="form-error" role="alert">{error}</p>}
      {message && <p className="u-meta" role="status">{message}</p>}

      <div className="field">
        <label htmlFor="email_addresses">Email addresses</label>
        <textarea className="textarea" id="email_addresses" name="email_addresses" rows={3}
                  placeholder="one@example.com, two@example.com" />
        <span className="u-meta">
          Separate with commas, spaces or new lines. People already in the community are skipped.
        </span>
      </div>

      <div className="row row--between row--wrap">
        <select className="select" id="invite-role" name="role" defaultValue="member"
                style={{ width: "auto" }}>
          <option value="member">Member</option>
          <option value="moderator">Moderator</option>
          <option value="admin">Admin</option>
        </select>
        <button className="btn btn--primary" type="submit" disabled={pending}>
          {pending ? "Sending…" : "Send invitations"}
        </button>
      </div>
    </form>
  );
}
