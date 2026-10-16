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

## Render configuration and verified deployment

The included `Dockerfile` builds the client and runs the server as the non-root `node` user. The final image has no third-party Node runtime dependencies. `render.yaml` selects one **Free** web service, `/api/health`, and disables automatic deployments. No paid disk, paid database, registry credential or payment method is configured.

The public repository distributes the complete project in `relay-tactics-source.zip`. Its repository-root Dockerfile unpacks that ZIP before building. To deploy the extracted project directly, use the Dockerfile inside the ZIP instead. These are two packaging entry points for the same source.

The Docker image was built successfully by Render and the service reached Live on 16 October 2026. Public URL: https://relay-tactics-lira.onrender.com/. The public HTML and JSON health returned HTTP 200. Complete public 2/3/4-seat games and all replay states were verified. The sample bot ran as a separate Node process in a room with two browser tabs. See LIVE_CHECKS.json and live-replays.zip. Docker remains unavailable in the local development environment; the successful Docker build was executed on Render.

### Free-host limitations

According to [Render's official free-service documentation](https://render.com/docs/free):

- An idle service sleeps after 15 minutes; a new request can take about a minute to wake it. The sample bot checks readiness with GET requests before attempting its first action, with a 90-second limit. An authorization failure stops immediately.
- The filesystem is ephemeral. SQLite rooms and replays are lost on a restart, redeploy or sleep. An active game uses regular traffic, but Render can still restart the service. Save replay JSON after the match. The UI displays this limitation. The API's 24-hour maximum room age does not promise 24-hour retention on this host.
- Free quotas apply. Without a payment method, exceeding the included bandwidth suspends services; exceeding build minutes disables new builds. No payment method should be added for this task.
- Free Postgres expires after 30 days. It is not configured here because creating another database and its credentials would need separate authorization.

### Operator setup and redeployment

The deployed demo uses one Free web service, no persistent disk or external database, no registry credential, Auto-Deploy Off and health check `/api/health`. The GitHub app installation was limited to the single `relay-tactics` repository. Operator deployment requires the operator's own hosting account and Git-provider authorization; players and HTTP agents do not need these.

The source ZIP is immutable from the tested runtime commit. The repository-root Dockerfile validates its checksum, unpacks it and builds the client. Current deployment status is kept in the repository-root documentation. The archive contains historical preparation notes; those do not supersede the later verification here.

After a code change or redeployment, verify the public page, JSON API, a complete match and replay again. Marketplace submission, acceptance and payment are separate states.

References: [Docker on Render](https://render.com/docs/docker), [Git provider access](https://render.com/docs/git-provider), [default environment variables](https://render.com/docs/environment-variables), [terms](https://render.com/terms).
