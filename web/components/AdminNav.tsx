import Link from "next/link";

const LINKS = [
  { href: "/admin", label: "Settings" },
  { href: "/admin/moderation", label: "Moderation" },
  { href: "/admin/members", label: "Members" },
];

export function AdminNav({ active }: { active: string }) {
  return (
    <nav className="nav" aria-label="Admin sections">
      {LINKS.map((link) => (
        <Link key={link.href} className="nav-item" href={link.href}
              aria-current={active === link.href ? "page" : undefined}>
          {link.label}
        </Link>
      ))}
    </nav>
  );
}

export function StaffOnly() {
  return (
    <div style={{ maxWidth: 560, margin: "0 auto", padding: "var(--space-7) var(--space-4)" }}>
      <div className="card empty">
        <h2>Admins only</h2>
        <p className="u-secondary">You need to be a host or moderator to see this.</p>
        <Link className="btn btn--secondary" href="/">Back to the community</Link>
      </div>
    </div>
  );
}
