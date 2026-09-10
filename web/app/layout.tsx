import type { Metadata } from "next";
import { headers } from "next/headers";
import "../styles/tokens.css";
import "../styles/themes.css";
import "../styles/components.css";
import "./app.css";

export const metadata: Metadata = {
  title: process.env.APP_NAME || "Community Coach",
  description: "A community and group coaching platform you can host yourself.",
};

/**
 * The compiled brand tokens are fetched server-side and inlined.
 *
 * Source order is the whole mechanism: this <style> comes after themes.css, both resolve
 * at the same specificity, and the later one wins — which is how an owner's branding
 * overrides their chosen preset without a single !important anywhere in the codebase.
 */
async function brandingCss(): Promise<string> {
  const api = process.env.API_INTERNAL_URL || "http://localhost:3001";
  try {
    const headerStore = await headers();
    const response = await fetch(`${api}/api/v1/community/branding`, {
      headers: {
        "X-Community-Slug": process.env.COMMUNITY_SLUG || "momentum",
        "X-Forwarded-Host": headerStore.get("host") || "",
      },
      next: { revalidate: 60 },
    });
    if (!response.ok) return "";
    const payload = (await response.json()) as { css?: string };
    return payload.css ?? "";
  } catch {
    // The preset defaults in themes.css are a complete design on their own, so a branding
    // fetch failure degrades to the unbranded theme rather than an unstyled page.
    return "";
  }
}

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const css = await brandingCss();
  return (
    <html lang="en" data-theme={process.env.THEME_PRESET || "kiln"}>
      <head>{css ? <style dangerouslySetInnerHTML={{ __html: css }} /> : null}</head>
      <body>{children}</body>
    </html>
  );
}
