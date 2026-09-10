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
        <span className="avatar avatar--sm" title={me.user.name}>{me.user.initials}</span>
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
