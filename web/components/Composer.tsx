"use client";

import { useRef, useState, useTransition } from "react";
import { createPost } from "@/lib/actions";
import type { Category } from "@/lib/types";

/**
 * Collapsed until focused. A full editor sitting open above the feed makes the feed feel
 * like a form; a single line makes it feel like a place where people are talking.
 */
export function Composer({ categories, initials }: { categories: Category[]; initials: string }) {
  const [open, setOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const formRef = useRef<HTMLFormElement>(null);

  function onSubmit(formData: FormData) {
    setError(null);
    startTransition(async () => {
      const result = await createPost(formData);
      if (result.ok) {
        formRef.current?.reset();
        setOpen(false);
      } else {
        setError(result.error);
      }
    });
  }

  if (!open) {
    return (
      <div className="card">
        <div className="row">
          <span className="avatar" aria-hidden="true">{initials}</span>
          <button className="input" type="button" onClick={() => setOpen(true)}
                  style={{ textAlign: "start", color: "var(--text-tertiary)", cursor: "text" }}>
            Share a win, or ask the room something…
          </button>
        </div>
      </div>
    );
  }

  return (
    <form className="card stack" ref={formRef} action={onSubmit}>
      {error && <p className="form-error" role="alert">{error}</p>}

      <div className="row">
        <span className="avatar" aria-hidden="true">{initials}</span>
        <input className="input" name="title" id="post-title" placeholder="Title"
               autoFocus required maxLength={200} />
      </div>

      <textarea className="textarea" name="body" id="post-body" rows={5}
                placeholder="What happened? Be specific — the room answers detail better than summary." />

      <div className="row row--between row--wrap">
        <select className="select" name="category_id" id="post-category" required
                style={{ width: "auto" }}>
          <option value="">Choose a category…</option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>{category.name}</option>
          ))}
        </select>

        <div className="row" style={{ gap: "var(--space-2)" }}>
          <button className="btn btn--ghost" type="button" onClick={() => setOpen(false)}
                  disabled={pending}>
            Cancel
          </button>
          <button className="btn btn--primary" type="submit" disabled={pending}>
            {pending ? "Posting…" : "Post"}
          </button>
        </div>
      </div>
    </form>
  );
}
