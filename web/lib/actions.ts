"use server";

import { revalidatePath } from "next/cache";
import { api, ApiError } from "./api";
import { toDocument } from "./richtext";

/**
 * Server actions for every mutation.
 *
 * They run on the server, so the session cookie is already in scope and the API's CSRF
 * check is satisfied by the X-Requested-With header the client adds. Each returns a plain
 * result object rather than throwing, because the caller is a form and a thrown error
 * there becomes an error page rather than an inline message.
 */

export type ActionResult = { ok: true } | { ok: false; error: string };

async function run(fn: () => Promise<unknown>, paths: string[] = []): Promise<ActionResult> {
  try {
    await fn();
    paths.forEach((path) => revalidatePath(path));
    return { ok: true };
  } catch (error) {
    if (error instanceof ApiError) return { ok: false, error: error.message };
    return { ok: false, error: "Something went wrong. Try again." };
  }
}

export async function createPost(formData: FormData): Promise<ActionResult> {
  const title = String(formData.get("title") ?? "").trim();
  const bodyText = String(formData.get("body") ?? "").trim();
  const categoryId = Number(formData.get("category_id"));

  if (!title) return { ok: false, error: "Give your post a title." };
  if (!categoryId) return { ok: false, error: "Choose a category." };

  return run(
    () =>
      api.post("/api/v1/posts", {
        post: { title, category_id: categoryId, body: toDocument(bodyText) },
      }),
    ["/"],
  );
}

export async function createComment(postId: number, formData: FormData): Promise<ActionResult> {
  const bodyText = String(formData.get("body") ?? "").trim();
  const parentId = formData.get("parent_id");

  if (!bodyText) return { ok: false, error: "Write something first." };

  return run(
    () =>
      api.post(`/api/v1/posts/${postId}/comments`, {
        comment: {
          body: toDocument(bodyText),
          parent_id: parentId ? Number(parentId) : undefined,
        },
      }),
    [`/posts/${postId}`, "/"],
  );
}

export async function toggleReaction(
  reactableType: "Post" | "Comment",
  reactableId: number,
  path: string,
): Promise<ActionResult> {
  return run(
    () =>
      api.post("/api/v1/reactions/toggle", {
        reactable_type: reactableType,
        reactable_id: reactableId,
      }),
    [path],
  );
}

export async function rsvp(occurrenceId: number, state: string): Promise<ActionResult> {
  return run(() => api.post(`/api/v1/events/${occurrenceId}/rsvp`, { state }), ["/calendar", "/"]);
}

export async function saveLessonProgress(
  lessonId: number,
  seconds: number,
  completed: boolean,
): Promise<ActionResult> {
  return run(
    () =>
      api.put(`/api/v1/lessons/${lessonId}/progress`, {
        seconds_watched: Math.round(seconds),
        resume_at_seconds: Math.round(seconds),
        completed,
      }),
    ["/classroom"],
  );
}

export async function reportContent(
  subjectType: "Post" | "Comment",
  subjectId: number,
  reason: string,
  detail: string,
): Promise<ActionResult> {
  return run(() =>
    api.post("/api/v1/reports", {
      subject_type: subjectType,
      subject_id: subjectId,
      reason,
      detail,
    }),
  );
}

export async function moderateReport(reportId: number, actionTaken: string): Promise<ActionResult> {
  return run(
    () => api.post(`/api/v1/reports/${reportId}/resolve`, { action_taken: actionTaken }),
    ["/admin/moderation"],
  );
}

export async function pinPost(postId: number): Promise<ActionResult> {
  return run(() => api.post(`/api/v1/posts/${postId}/pin`), ["/"]);
}

export async function lockPost(postId: number): Promise<ActionResult> {
  return run(() => api.post(`/api/v1/posts/${postId}/lock`), ["/", `/posts/${postId}`]);
}

export async function deletePost(postId: number): Promise<ActionResult> {
  return run(() => api.delete(`/api/v1/posts/${postId}`), ["/"]);
}

export async function sendInvitations(formData: FormData): Promise<ActionResult> {
  const raw = String(formData.get("email_addresses") ?? "");
  const emails = raw
    .split(/[\s,;]+/)
    .map((value) => value.trim())
    .filter(Boolean);

  if (emails.length === 0) return { ok: false, error: "Add at least one email address." };

  return run(
    () =>
      api.post("/api/v1/invitations", {
        email_addresses: emails,
        role: String(formData.get("role") ?? "member"),
      }),
    ["/admin/members"],
  );
}

export async function reviewJoinRequest(id: number, decision: string): Promise<ActionResult> {
  return run(() => api.post(`/api/v1/join_requests/${id}/review`, { decision }), ["/admin/members"]);
}

export async function suspendMember(membershipId: number, reason: string): Promise<ActionResult> {
  return run(
    () => api.post(`/api/v1/members/${membershipId}/suspend`, { reason }),
    ["/members", "/admin/members"],
  );
}

export async function updateBranding(branding: Record<string, unknown>): Promise<ActionResult> {
  return run(() => api.patch("/api/v1/community", { community: { branding } }), ["/", "/admin"]);
}

export async function updateCommunity(formData: FormData): Promise<ActionResult> {
  return run(
    () =>
      api.patch("/api/v1/community", {
        community: {
          name: formData.get("name"),
          tagline: formData.get("tagline"),
          description: formData.get("description"),
          privacy: formData.get("privacy"),
        },
      }),
    ["/", "/admin", "/join"],
  );
}

export async function markNotificationsRead(): Promise<ActionResult> {
  return run(() => api.post("/api/v1/notifications/read_all"), ["/notifications", "/"]);
}
