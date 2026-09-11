import { notFound } from "next/navigation";
import Link from "next/link";
import { api, maybe } from "@/lib/api";
import type { Comment, Community, Me, Post } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { CommentThread } from "@/components/CommentThread";
import { ReactionButton } from "@/components/ReactionButton";
import { PostAdminMenu } from "@/components/PostAdminMenu";
import { relativeTime } from "@/lib/format";
import { toParagraphs } from "@/lib/richtext";

export default async function PostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const [{ community }, me, postData, commentData] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
    maybe(() => api.get<{ post: Post }>(`/api/v1/posts/${id}`)),
    maybe(() => api.get<{ comments: Comment[] }>(`/api/v1/posts/${id}/comments`)),
  ]);

  if (!postData) notFound();
  const post = postData.post;

  return (
    <>
      <TopBar community={community} me={me} />
      <div style={{ maxWidth: 780, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <Link className="u-meta" href="/">← Back to the feed</Link>

        <article className="card" style={{ marginTop: "var(--space-4)" }}>
          <div className="row">
            <span className="avatar" aria-hidden="true">{post.user.initials}</span>
            <div>
              <div style={{ fontWeight: "var(--weight-semi)", fontSize: "var(--text-sm)" }}>
                {post.user.name}
              </div>
              <div className="u-meta">
                {post.category.name} · {relativeTime(post.last_activity_at)}
                {post.edited_at && " · edited"}
              </div>
            </div>
            <div className="spacer" />
            {post.pinned && <span className="badge badge--accent">Pinned</span>}
            {post.locked && <span className="badge">Locked</span>}
            {me?.membership?.staff && <PostAdminMenu post={post} />}
          </div>

          <h1 style={{ fontSize: "var(--text-lg)" }}>{post.title}</h1>

          <div className="comment__body">
            {toParagraphs(post.body).map((paragraph, index) => (
              <p key={index}>{paragraph}</p>
            ))}
          </div>

          <div className="post__footer">
            <ReactionButton type="Post" id={post.id} count={post.reactions_count}
                            reacted={post.reacted} path={`/posts/${post.id}`} />
            <span className="u-meta">
              {post.comments_count === 1 ? "1 reply" : `${post.comments_count} replies`}
            </span>
          </div>
        </article>

        <section className="card" style={{ marginTop: "var(--space-4)" }}>
          <h2 style={{ fontSize: "var(--text-md)" }}>
            {post.comments_count === 1 ? "1 reply" : `${post.comments_count} replies`}
          </h2>
          <hr className="divider" />
          <CommentThread postId={post.id} comments={commentData?.comments ?? []}
                         locked={post.locked} />
        </section>
      </div>
    </>
  );
}
