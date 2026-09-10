export type User = { id: number; name: string; initials: string };
export type Category = { id: number; name: string; slug: string; position: number };

export type Post = {
  id: number;
  title: string;
  excerpt: string;
  kind: "discussion" | "poll" | "announcement";
  pinned: boolean;
  locked: boolean;
  comments_count: number;
  reactions_count: number;
  reacted: boolean;
  last_activity_at: string;
  user: User;
  category: Category;
};

export type Course = {
  id: number;
  title: string;
  slug: string;
  description: string | null;
  lesson_count: number;
  locked: boolean;
  progress: { completed: number; total: number; percent: number };
};

export type Lesson = {
  id: number;
  title: string;
  slug: string;
  position: number;
  has_video: boolean;
  access: { granted: boolean; reason: string | null; message: string | null } | null;
  progress: { state: "unseen" | "started" | "completed"; resume_at_seconds: number };
};

export type EventOccurrence = {
  id: number;
  title: string;
  description: string | null;
  starts_at: string;
  ends_at: string;
  timezone: string;
  location_kind: string;
  location_url: string | null;
  recurring: boolean;
  going_count: number;
  my_rsvp: "going" | "maybe" | "declined" | null;
  host: User;
};

export type Plan = {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  price: string;
  interval: string;
  trial_days: number;
  features: string[];
  free: boolean;
};

export type Community = {
  id: number;
  slug: string;
  name: string;
  tagline: string | null;
  description: string | null;
  branding: Record<string, unknown>;
  member_count: number;
  viewer: { member: boolean; role?: string; staff?: boolean; plan_slug?: string | null };
};

export type Me = {
  user: User;
  membership: { id: number; role: string; status: string; staff: boolean } | null;
  unread_notifications: number;
};
