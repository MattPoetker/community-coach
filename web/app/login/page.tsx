"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(formEvent: React.FormEvent<HTMLFormElement>) {
    formEvent.preventDefault();
    setPending(true);
    setError(null);

    const form = new FormData(formEvent.currentTarget);
    const response = await fetch("/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // The custom header a browser will not attach cross-site without a preflight —
        // one third of the CSRF defence for this cookie-authenticated API.
        "X-Requested-With": "CommunityCoach",
      },
      body: JSON.stringify({
        email_address: form.get("email_address"),
        password: form.get("password"),
      }),
    });

    if (response.ok) {
      router.push("/");
      router.refresh();
      return;
    }

    const payload = await response.json().catch(() => ({}));
    setError(payload?.error?.message ?? "Something went wrong. Try again.");
    setPending(false);
  }

  return (
    <form className="auth-page" onSubmit={onSubmit}>
      <h1>Sign in</h1>
      {error && <p className="form-error" role="alert">{error}</p>}

      <div className="field">
        <label htmlFor="email_address">Email</label>
        <input className="input" id="email_address" name="email_address" type="email"
               autoComplete="email" required />
      </div>

      <div className="field">
        <label htmlFor="password">Password</label>
        <input className="input" id="password" name="password" type="password"
               autoComplete="current-password" required />
      </div>

      <button className="btn btn--primary btn--lg btn--block" type="submit" disabled={pending}>
        {pending ? "Signing in…" : "Sign in"}
      </button>
      <a className="u-meta" href="/reset" style={{ textAlign: "center" }}>Forgot your password?</a>
    </form>
  );
}
