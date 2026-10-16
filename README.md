# Relay Tactics — public source

Current browser game: https://relay-tactics-lira.grassy-sage-5926.chatgpt.site

The complete source is in `relay-tactics-source.zip`. Extract it into an empty directory before running local commands. Archive SHA-256: `140c9540add399dc72f3b98a8b472bbfeb40ecd3b4bd2c0717017a00da0b87f8`.

**Prepared alternative:** standalone Node HTTP server, the same React UI and rules, and a Free Render deployment recipe. The repository-root Dockerfile unpacks and builds the source ZIP. No Render account or service has been created; its Docker image has not been built here. See [DEPLOY.md](DEPLOY.md) for the exact configuration, authorization needed and ephemeral-room limitation.

**Executed:** 29 automated tests, TypeScript, Sites production build, standalone client build, and built assets served over loopback HTTP. Independent HTTP clients completed 2/3/4-seat games and all replay states were reconstructed. The owner completed a mobile match on Sites. **Pending:** live external-bot access, standalone browser QA and public-host checks. The Sites edge returned 403 to the development HTTP client. No bounty submission, acceptance or payment is claimed.

---

# Relay Tactics

A small browser strategy game for humans and HTTP agents. Built for Taskmarket task [TSK-V6J8MSSD](https://taskmarket.dev/tasks/0x1fb989a3256eadc92fe09e863ca36bed7765e5bcb2f8d2c28183201e467c272d).

## Rules in one paragraph

Two to four players grow a network on a 5×5 grid from their numbered corner homes. On your turn, link one adjacent neutral tile for 1 energy (2 for a beacon), dash through two consecutive neutral tiles for 3 energy plus 1 per beacon, surge an adjacent enemy tile for 3 energy, or charge for 2 energy; every turn also grants 1 energy, capped at 6. All actions must touch your network connected to home, and homes cannot be removed. At the end of each round, connected beacons score: 2 for the center, 3 for the highlighted edge, and 1 for each other edge; the highlighted edge rotates North, East, South, West. Play 12 rounds with two players or 8 rounds with three or four; highest final score wins, with shared wins on a tie. Two- and three-player turns allow 20 seconds, four-player turns 15 seconds; overdue turns use the built-in bot when the room next receives a request, so the logical turn budget is at most 8 minutes.

## Play and agents

- Choose **Play against a bot** for an immediate two-player match, or create a room with 2–4 seats.
- Share the room link or six-character code. Other browsers and HTTP bots join the same lobby.
- The host can start with all human seats or fill empty seats with built-in bots.
- Select Link, Dash, or Surge and a highlighted tile. Dash needs a first and second tile. Charge needs no tile.
- The score panel shows energy and points. Inspect replay with the slider, or download the replay JSON.
- No wallet, account, external API key, installation, or paid service is needed by a player. Running the server locally does require Node and dependencies.

## Run locally

Use Node 24.19.0 for the portable server and verification suite (`node:sqlite` is used for persistence). The starter Worker supports Node `>=22.13` during builds. The dependency pin is `pnpm@11.25.0`; use Corepack or that exact pnpm version. Do not run multiple installers at once. The standalone Node server and a prepared free-host recipe are documented in [DEPLOY.md](DEPLOY.md).

```sh
corepack pnpm install --frozen-lockfile
npm test
npm run typecheck
npm run build
node --import ./scripts/sites-env.mjs ./node_modules/wrangler/bin/wrangler.js d1 execute DB --local --config dist/server/wrangler.json --persist-to .wrangler/state --file drizzle/0000_equal_bishop.sql
npm start
```

Apply the migration once to a new local database. Open the loopback URL Wrangler prints. `npm start -- --port 8787` selects a port. For subsequent starts, omit the install and migration. The built Worker uses the generated `dist/server/wrangler.json`; there is no root Wrangler configuration to create.

For HMR after initializing the local schema, use `npm run dev` and the URL it prints. The game does not call the optional starter authentication or connector helpers. If using the Sites plugin in managed Work, follow its preview workflow instead of starting a manual preview.

## Sample HTTP bot

Have a human create a room with an empty seat, then run:

```sh
node scripts/sample-bot.mjs http://127.0.0.1:8787 ABC234
```

The sample joins the lobby and prints its seat. The human host starts the match. An optional final numeric argument controls an already occupied seat; use that only for a seat whose player has agreed. The bot reads the same state humans see and sends one legal move with an optimistic version. It rereads on 409 and never retries an uncertain POST blindly. Full protocol: [API.md](API.md).

## Design and persistence

- React UI and Vinext Worker route: `app/`.
- Deterministic rules, legal moves, bot and replay verifier: `lib/game.mjs`.
- HTTP validation and optimistic persistence: `lib/service.mjs`.
- Shared rooms use Cloudflare D1, binding `DB`, with an atomic `UPDATE ... WHERE version = ?`. Independent Worker instances share the same durable room.
- Drizzle schema and the generated migration live in `db/` and `drizzle/`. No runtime table creation.
- The API advances bots and expired turns on a read/action. It requires no background cron or scheduled task.
- Room access expires after 24 hours. Database records are not automatically deleted; operators can apply their own retention policy.

## Verification and limits

```sh
npm test                 # engine, handlers, replay, bot and SQLite persistence
npm run typecheck
npm run build
npm run evaluate         # finite, deterministic policy comparison
```

The included `validation/` directory records executed checks. Tests cover the rules and in-process Request/Response handlers, real SQLite storage, and independent HTTP clients completing 2/3/4-seat matches through a Node server. Every replay state is reconstructed and checked. A separate short harness serves the actual built HTML/JS/CSS over loopback HTTP. These checks do not constitute a live Render test or browser QA of the standalone build.

The Sites version was opened and played by the owner on a mobile browser: one observed match finished all 12 rounds with 24 actions and a final score of 3–56. Its full replay was not independently downloaded. Ordinary programmatic HTTP requests from the development environment returned Cloudflare 403, so a public external-bot test on that deployment remains blocked. The portable version has not been deployed. No Taskmarket submission or payment is claimed.

The 12 policy matchups are a small heuristic comparison, not proof of balanced human play or absence of a dominant strategy. Every tested policy lost at least once, but seat 0 won 11 of 12 matchups: first-seat advantage remains a known balance limitation. Three/four-player strategic balance and real-user fun require play-testing.

This is casual cooperative room access: anyone with the code can control a seat. There are no secrets, stakes, wallets or financial actions. Local storage only remembers the chosen seat. Do not enter private information in callsigns. Rooms have no administrator moderation, rate limiting or private matchmaking; this build is a small bounty prototype, not a competitive service.

## Deploy

The existing Sites deployment is a Cloudflare Worker with a D1 binding named `DB`. Use the provided Sites workflow to build and publish it; the generated SQL migration must be applied by the hosting platform. The alternative standalone Node/SQLite build is prepared in [DEPLOY.md](DEPLOY.md); its free-host storage limitations are explicit. A public anonymous game URL and a public source repository are both required by the bounty. Verification should include anonymous access, separate clients sharing a match, replay and the sample bot against the deployed API. Marketplace receipts and wallet activity are tracked separately from the public game source.

## Attribution

Original rules, game engine, API, UI and tests were prepared by Codex for Lira Ventures with AI assistance. Infrastructure comes from the provided Vinext/Sites starter and its included licenses; external dependencies retain their own licenses. The original game files are MIT licensed; see [LICENSE](LICENSE).
