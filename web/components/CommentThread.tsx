"use client";

import { useRef, useState, useTransition } from "react";
import { createComment } from "@/lib/actions";
import { ReactionButton } from "./ReactionButton";
import { relativeTime } from "@/lib/format";
import { toParagraphs } from "@/lib/richtext";
import type { Comment } from "@/lib/types";

export function CommentThread({
  postId,
  comments,
  locked,
}: {
  postId: number;
  comments: Comment[];
  locked: boolean;
}) {
  const [replyTo, setReplyTo] = useState<number | null>(null);

  return (
    <div className="stack">
      {!locked && <CommentForm postId={postId} />}
      {locked && (
        <p className="u-meta">This thread is locked. Nobody can add a reply.</p>
      )}

      {comments.length === 0 ? (
        <p className="u-secondary" style={{ fontSize: "var(--text-sm)" }}>
          No replies yet. Be the one who answers.
        </p>
      ) : (
        comments.map((comment) => (
          <div key={comment.id} style={{ marginInlineStart: `calc(var(--space-5) * ${comment.depth})` }}>
            <article className="comment">
              <div className="row">
                <span className="avatar avatar--sm" aria-hidden="true">{comment.user.initials}</span>
                <span style={{ fontWeight: "var(--weight-semi)", fontSize: "var(--text-sm)" }}>
                  {comment.user.name}
                </span>
                <span className="u-meta">{relativeTime(comment.created_at)}</span>
                {comment.edited_at && <span className="u-meta">· edited</span>}
              </div>

              {comment.deleted ? (
                <p className="u-meta" style={{ fontStyle: "italic" }}>This reply was removed.</p>
              ) : (
                <div className="comment__body">
                  {toParagraphs(comment.body).map((paragraph, index) => (
                    <p key={index}>{paragraph}</p>
                  ))}
                </div>
              )}

              {!comment.deleted && (
                <div className="row" style={{ gap: "var(--space-4)" }}>
                  <ReactionButton type="Comment" id={comment.id} count={comment.reactions_count}
                                  reacted={false} path={`/posts/${postId}`} />
                  {!locked && (
                    <button className="post__action" type="button"
                            onClick={() => setReplyTo(replyTo === comment.id ? null : comment.id)}>
                      Reply
                    </button>
                  )}
                </div>
              )}
            </article>

            {replyTo === comment.id && (
              <div style={{ marginInlineStart: "var(--space-5)", marginBlock: "var(--space-2)" }}>
                <CommentForm postId={postId} parentId={comment.id}
                             onDone={() => setReplyTo(null)} autoFocus />
              </div>
            )}
          </div>
        ))
      )}
    </div>
  );
}

function CommentForm({
  postId,
  parentId,
  onDone,
  autoFocus,
}: {
  postId: number;
  parentId?: number;
  onDone?: () => void;
  autoFocus?: boolean;
}) {
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const formRef = useRef<HTMLFormElement>(null);

  return (
    <form
      ref={formRef}
      action={(formData) => {
        setError(null);
        startTransition(async () => {
          const result = await createComment(postId, formData);
          if (result.ok) {
            formRef.current?.reset();
            onDone?.();
          } else {
            setError(result.error);
          }
        });
      }}
      className="stack"
      style={{ gap: "var(--space-2)" }}
    >
      {error && <p className="form-error" role="alert">{error}</p>}
      {parentId && <input type="hidden" name="parent_id" value={parentId} />}

      <textarea className="textarea" name="body" rows={3} autoFocus={autoFocus}
                id={parentId ? `reply-${parentId}` : `comment-${postId}`}
                placeholder={parentId ? "Write a reply…" : "Add to the discussion…"} />

      <div className="row" style={{ justifyContent: "flex-end", gap: "var(--space-2)" }}>
        {onDone && (
          <button className="btn btn--ghost" type="button" onClick={onDone} disabled={pending}>
            Cancel
          </button>
        )}
        <button className="btn btn--primary" type="submit" disabled={pending}>
          {pending ? "Posting…" : parentId ? "Reply" : "Comment"}
        </button>
      </div>
    </form>
  );
}
