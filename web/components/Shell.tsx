import Link from "next/link";
import type { Community, Category, Me } from "@/lib/types";

const SECTIONS = [
  { href: "/", label: "Community" },
  { href: "/classroom", label: "Classroom" },
  { href: "/calendar", label: "Calendar" },
  { href: "/members", label: "Members" },
];

export function TopBar({ community, me }: { community: Community; me: Me | null }) {
  return (
    <header className="topbar">
      <div className="identity">
        <div className="identity__mark identity__mark--sm">{initials(community.name)}</div>
        <span className="identity__name">{community.name}</span>
      </div>
      <nav className="topbar__nav">
        {SECTIONS.map((section) => (
          <Link key={section.href} className="topbar__link" href={section.href}>
            {section.label}
          </Link>
        ))}
      </nav>
      <div className="spacer" />
      {me ? (
        <div className="row" style={{ gap: "var(--space-3)" }}>
          <Link className="bell" href="/notifications" aria-label={
            me.unread_notifications > 0
              ? `${me.unread_notifications} unread notifications`
              : "Notifications"
          }>
            <span aria-hidden="true" style={{ fontSize: "var(--text-md)" }}>◔</span>
            {me.unread_notifications > 0 && (
              <span className="bell__dot">{me.unread_notifications > 9 ? "9+" : me.unread_notifications}</span>
            )}
          </Link>
          <span className="avatar avatar--sm" title={me.user.name}>{me.user.initials}</span>
        </div>
      ) : (
        <Link className="btn btn--primary" href="/login">Sign in</Link>
      )}
    </header>
  );
}

export function CategoryNav({
  categories,
  activeSlug,
}: {
  categories: Category[];
  activeSlug?: string;
}) {
  if (categories.length === 0) return null;
  return (
    <>
      <div className="u-label" style={{ marginBottom: "var(--space-2)" }}>Categories</div>
      <nav className="nav" aria-label="Categories">
        {categories.map((category) => (
          <Link
            key={category.id}
            className="nav-item"
            href={`/?category=${category.slug}`}
            aria-current={activeSlug === category.slug ? "page" : undefined}
          >
            {category.name}
          </Link>
        ))}
      </nav>
    </>
  );
}

function initials(name: string) {
  return name.split(" ").slice(0, 2).map((word) => word[0]).join("").toUpperCase();
}
