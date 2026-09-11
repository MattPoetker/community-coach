"use client";

import { useState, useTransition } from "react";
import { updateCommunity } from "@/lib/actions";
import type { Community } from "@/lib/types";

export function CommunitySettingsForm({ community }: { community: Community }) {
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  return (
    <form
      className="card stack"
      action={(formData) => {
        setMessage(null);
        setError(null);
        startTransition(async () => {
          const result = await updateCommunity(formData);
          if (result.ok) setMessage("Saved.");
          else setError(result.error);
        });
      }}
    >
      <div className="u-label">Community</div>
      {error && <p className="form-error" role="alert">{error}</p>}
      {message && <p className="u-meta" role="status">{message}</p>}

      <div className="field">
        <label htmlFor="name">Name</label>
        <input className="input" id="name" name="name" defaultValue={community.name} required />
      </div>

      <div className="field">
        <label htmlFor="tagline">Tagline</label>
        <input className="input" id="tagline" name="tagline" defaultValue={community.tagline ?? ""}
               placeholder="One line that says who this is for" maxLength={140} />
      </div>

      <div className="field">
        <label htmlFor="description">Description</label>
        <textarea className="textarea" id="description" name="description" rows={5}
                  defaultValue={community.description ?? ""}
                  placeholder="Shown on your public page. What members get, and who it is not for." />
      </div>

      <div className="field">
        <label htmlFor="privacy">Who can see this community</label>
        <select className="select" id="privacy" name="privacy" defaultValue={community.privacy}>
          <option value="public">Public — anyone can find and read the sales page</option>
          <option value="private">Private — the sales page is public, the content is not</option>
          <option value="secret">Secret — invisible unless you are a member</option>
        </select>
      </div>

      <div className="row" style={{ justifyContent: "flex-end" }}>
        <button className="btn btn--primary" type="submit" disabled={pending}>
          {pending ? "Saving…" : "Save changes"}
        </button>
      </div>
    </form>
  );
}
