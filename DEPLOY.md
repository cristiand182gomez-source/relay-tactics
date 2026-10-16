# Portable Node deployment

This is the same Relay Tactics game and protocol as the Sites Worker. The React entry imports the existing UI; the Node server calls the existing rules and request handler. It creates no wallet, login, token, external database or background job.

## Run the portable version

Use Node 24.19.0 and pnpm 11.25.0. From the extracted project root:

```sh
pnpm install --frozen-lockfile
pnpm run build:standalone
pnpm test
node scripts/verify-standalone.mjs
pnpm run start:standalone
```

Open `http://localhost:10000`. The server binds `0.0.0.0`, uses `PORT` (default 10000) and saves SQLite at `SQLITE_PATH` (default `./data/rooms.sqlite`). The generated migration runs at startup before listening. One server process only; this adapter is not a distributed database.

Behind TLS termination, set `PUBLIC_ORIGIN=https://your-game.example` to the exact browser origin. Render's supplied `RENDER_EXTERNAL_URL` is used automatically when `PUBLIC_ORIGIN` is absent. Arbitrary forwarded-host headers do not change the allowed browser origin. CLI agents need no Origin header.

## Prepared Render configuration — not deployed

The included `Dockerfile` builds the client and runs the server as the non-root `node` user. The final image has no third-party Node runtime dependencies. `render.yaml` selects one **Free** web service, `/api/health`, and disables automatic deployments. No paid disk, paid database, registry credential or payment method is configured.

The public repository distributes the complete project in `relay-tactics-source.zip`. Its repository-root Dockerfile unpacks that ZIP before building. To deploy the extracted project directly, use the Dockerfile inside the ZIP instead. These are two packaging entry points for the same source.

An actual Render deployment has **not** been attempted. Docker is unavailable in the development environment, so the Docker image has **not** been built. The portable Node server, built browser assets and HTTP protocol were tested directly with Node 24.19.0. A successful local build does not establish public-host availability.

### Free-host limitations

According to [Render's official free-service documentation](https://render.com/docs/free):

- An idle service sleeps after 15 minutes; a new request can take about a minute to wake it. The sample bot checks readiness with GET requests before attempting its first action, with a 90-second limit. An authorization failure stops immediately.
- The filesystem is ephemeral. SQLite rooms and replays are lost on a restart, redeploy or sleep. An active game uses regular traffic, but Render can still restart the service. Save replay JSON after the match. The UI displays this limitation. The API's 24-hour maximum room age does not promise 24-hour retention on this host.
- Free quotas apply. Without a payment method, exceeding the included bandwidth suspends services; exceeding build minutes disables new builds. No payment method should be added for this task.
- Free Postgres expires after 30 days. It is not configured here because creating another database and its credentials would need separate authorization.

### Authorization still needed

No Render account or service has been created. The owner must authorize a Render account, its applicable terms, and GitHub deployment access restricted to this repository before deployment. Review the actual permission screen before confirming; do not grant access to all repositories. If a payment method or a paid plan is required, stop.

After an authorized deployment, independently verify the public HTML, API health, create/join/start/move flow, two independent clients, full replay reconstruction, and sample bot over the public HTTPS URL. Check the Taskmarket task still accepts submissions, then submit once and retain the receipt. A deployed game is neither an accepted submission nor a payment.

References: [Docker on Render](https://render.com/docs/docker), [Git provider access](https://render.com/docs/git-provider), [default environment variables](https://render.com/docs/environment-variables), [terms](https://render.com/terms).
