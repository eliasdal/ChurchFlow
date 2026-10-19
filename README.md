# ChurchFlow — Worship Planning Starter

A responsive, Netlify-ready first build for ChurchFlow. It includes a dashboard, service-plan and setlist workflows, team screen, settings screen, and a built-in library of the provided PDF chord charts. The UI runs in local demo mode immediately; demo changes are saved in this browser's localStorage.

## Included
- `index.html`, `styles.css`, `src/main.js`: website UI and interactions.
- `charts.json` and `charts/`: built-in chart index and PDF files.
- `supabase/schema.sql`: starting point for a multi-tenant Supabase database with row-level security.
- `config.js.example`: example public Supabase configuration.
- `netlify.toml`, `_redirects`: Netlify static-site configuration.

## Run locally
Because the app uses browser ES modules, run a local static server from this folder (for example `python3 -m http.server 8080`) and open `http://localhost:8080`. Opening `index.html` directly as a `file://` URL may block the chart manifest request.

## Deploy to Netlify
1. Unzip this folder.
2. Drag the folder contents into Netlify's manual deploy area, or connect the folder/repository to Netlify.
3. The app should load in local demo mode. Demo data is browser-local, not shared with other accounts.

## Connect Supabase (required for real shared accounts)
1. Create a Supabase project.
2. In Supabase SQL Editor, review and run `supabase/schema.sql`.
3. Edit `config.js` and fill in your project URL and public anon/publishable key.
4. Configure Supabase Auth email confirmation and redirect URLs for your Netlify site.
5. Implement and test a trusted first-church provisioning flow before enabling public multi-church signups. The schema intentionally does not let anonymous users create membership rows.
6. Keep the Supabase service-role key server-side only. Never put it in `config.js` or frontend code.

**Important status:** This ZIP is a working frontend/demo foundation, not yet a complete production SaaS. The service planner and chart viewer work locally, but real sign-in, invitations, cloud syncing, tenant provisioning, and enforcement of per-user module permissions still need integration and security testing against your Supabase project. Do not use real church/member data until those steps are completed.

## Chart library
The included PDFs are copied from the provided ZIP into `charts/` and indexed in `charts.json`. A song can have multiple available keys. The browser's built-in PDF viewer provides print/download controls where supported.
