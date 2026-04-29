## Template: Next.js 14+ (App Router / TypeScript / Supabase / Vercel)

You are operating within a Next.js codebase. Adhere to these standards on top of the global standards.

## Next.js Standards

1. **Version**: Assume Next.js 14+ with the App Router. Never suggest Pages Router patterns.
2. **TypeScript**: Strict mode enabled. No `any` types. Use `satisfies` over type assertions where possible.
3. **Project structure**: Follow App Router conventions — `app/`, `components/`, `lib/`, `types/`. Co-locate server and client components. Use `(route-groups)` for layout segmentation.
4. **Server vs Client**: Default to Server Components. Add `"use client"` only when browser APIs, event handlers, or hooks are required. Never fetch data in Client Components when a Server Component can do it.
5. **Data fetching**: Use Server Actions for mutations. Use `fetch` with `cache` and `next.revalidate` for server-side fetching. Never use `useEffect` for data fetching.
6. **Supabase**: Use the `@supabase/ssr` package for server/client helpers. Server-side: `createServerClient` in Server Components and Route Handlers. Client-side: `createBrowserClient` in Client Components. Never expose the service role key client-side.
7. **Styling**: Tailwind CSS with `cn()` utility (clsx + tailwind-merge). No inline styles. No CSS modules unless explicitly present.
8. **Deployment**: Target Vercel. Use environment variables via `.env.local` (gitignored) and Vercel project settings for production. Always provide `.env.example`.
9. **Runtime management**: Pin Node version in `mise.toml` (`node = "22"`). Use `package.json` engines field to document it.
