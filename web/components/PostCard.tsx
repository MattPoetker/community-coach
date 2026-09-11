import Link from "next/link";
import type { Post } from "@/lib/types";
import { relativeTime } from "@/lib/format";
import { ReactionButton } from "./ReactionButton";

export function PostCard({ post }: { post: Post }) {
  return (
    <article className={`card post${post.pinned ? " post--pinned" : ""}`}>
      <div className="row">
        <span className="avatar" aria-hidden="true">{post.user.initials}</span>
        <div>
          <div style={{ fontWeight: "var(--weight-semi)", fontSize: "var(--text-sm)" }}>
            {post.user.name}
          </div>
          <div className="u-meta">
            {post.category.name}
            {post.pinned && " · Pinned"} · {relativeTime(post.last_activity_at)}
          </div>
        </div>
        <div className="spacer" />
        {post.kind === "announcement" && <span className="badge badge--accent">Announcement</span>}
        {post.locked && <span className="badge">Locked</span>}
      </div>

      <div>
        <h3 className="post__title">
          <Link href={`/posts/${post.id}`} style={{ color: "inherit", textDecoration: "none" }}>
            {post.title}
          </Link>
        </h3>
        <p className="post__body">{post.excerpt}</p>
      </div>

      <div className="post__footer">
        <ReactionButton type="Post" id={post.id} count={post.reactions_count}
                        reacted={post.reacted} path="/" />
        <Link className="post__action" href={`/posts/${post.id}`}>
          Reply · {post.comments_count}
        </Link>
      </div>
    </article>
  );
}
