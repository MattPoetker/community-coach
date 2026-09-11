import { api, maybe } from "@/lib/api";
import type { Community, Me } from "@/lib/types";
import { TopBar } from "@/components/Shell";
import { AdminNav, StaffOnly } from "@/components/AdminNav";
import { CommunitySettingsForm } from "@/components/CommunitySettingsForm";
import { BrandingEditor } from "@/components/BrandingEditor";

export default async function AdminPage() {
  const [{ community }, me] = await Promise.all([
    api.get<{ community: Community }>("/api/v1/community"),
    maybe(() => api.get<Me>("/api/v1/members/me")),
  ]);

  if (!me?.membership?.staff) {
    return (
      <>
        <TopBar community={community} me={me} />
        <StaffOnly />
      </>
    );
  }

  return (
    <>
      <TopBar community={community} me={me} />
      <div className="admin-layout" style={{ maxWidth: 1000, margin: "0 auto", padding: "var(--space-5) var(--space-4)" }}>
        <aside><AdminNav active="/admin" /></aside>
        <main className="stack" style={{ gap: "var(--space-5)" }}>
          <div>
            <h1>Settings</h1>
            <p className="u-secondary" style={{ marginTop: "var(--space-2)" }}>
              What members and visitors see.
            </p>
          </div>
          <CommunitySettingsForm community={community} />
          <BrandingEditor branding={community.branding} />
        </main>
      </div>
    </>
  );
}
