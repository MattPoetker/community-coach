/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Caddy fronts both apps on one origin in production, so the browser never needs CORS.
  // In development this rewrite reproduces that shape against the Rails dev server, which
  // is what keeps the session cookie working identically in both.
  async rewrites() {
    const api = process.env.API_INTERNAL_URL || "http://localhost:3001";
    return [
      { source: "/api/v1/:path*", destination: `${api}/api/v1/:path*` },
      { source: "/auth/:path*", destination: `${api}/auth/:path*` },
    ];
  },
};
export default nextConfig;
