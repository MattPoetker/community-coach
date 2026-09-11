"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import { deletePost, lockPost, pinPost } from "@/lib/actions";
import type { Post } from "@/lib/types";

/** Moderator controls. Deliberately plain buttons: a hidden menu makes moderation slower,
 *  and the people who see these are the ones who need them most often. */
export function PostAdminMenu({ post }: { post: Post }) {
  const [pending, startTransition] = useTransition();
  const router = useRouter();

  return (
    <div className="row" style={{ gap: "var(--space-2)" }}>
      <button className="btn btn--ghost" type="button" disabled={pending}
              onClick={() => startTransition(() => void pinPost(post.id))}>
        {post.pinned ? "Unpin" : "Pin"}
      </button>
      <button className="btn btn--ghost" type="button" disabled={pending}
              onClick={() => startTransition(() => void lockPost(post.id))}>
        {post.locked ? "Unlock" : "Lock"}
      </button>
      <button className="btn btn--ghost" type="button" disabled={pending}
              style={{ color: "var(--danger-text)" }}
              onClick={() =>
                startTransition(async () => {
                  await deletePost(post.id);
                  router.push("/");
                })
              }>
        Remove
      </button>
    </div>
  );
}
