# Relay Tactics — public source

Play: https://relay-tactics-lira.grassy-sage-5926.chatgpt.site

The complete source is in `relay-tactics-source.zip` in this repository. Extract it into an empty directory, then run the commands below from that directory. No account or wallet is needed to play. The source includes the game engine, API, browser UI, bot, SQL migration, tests and pinned dependencies.

Source archive SHA-256: `69782f61fc4e0ff1992e33152d05e2fb26954d7b9fd3899afe48025345be11cd`.

Verification: 23 automated tests, TypeScript and the production build passed. Hosting confirms a public deployment and the live `rooms` database table. A direct external HTTP check was denied by the hosting edge (403/1010) before reaching the API; a completed remote match, anonymous agent access and mobile interaction remain unverified. Do not treat publication as an accepted bounty submission or guaranteed payment.

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

Use Node 24 for the verification suite (`node:sqlite` is used in persistence tests). The app supports the starter's Node `>=22.13` runtime. The dependency pin is `pnpm@11.25.0`; use Corepack or that exact pnpm version. Do not run multiple installers at once.

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

The included `validation/` directory records executed checks. Tests use in-process HTTP Request/Response objects and a real SQLite database with a D1-compatible adapter. They do not constitute a live Cloudflare deployment test. Visual/browser QA and public anonymous access have not been verified yet.

The 12 policy matchups are a small heuristic comparison, not proof of balanced human play or absence of a dominant strategy. Every tested policy lost at least once, but seat 0 won 11 of 12 matchups: first-seat advantage remains a known balance limitation. Three/four-player strategic balance and real-user fun require play-testing.

This is casual cooperative room access: anyone with the code can control a seat. There are no secrets, stakes, wallets or financial actions. Local storage only remembers the chosen seat. Do not enter private information in callsigns. Rooms have no administrator moderation, rate limiting or private matchmaking; this build is a small bounty prototype, not a competitive service.

## Deploy

The app is a Cloudflare Worker with a D1 binding named `DB`. Use the provided Sites workflow to build and publish it; the generated SQL migration must be applied by the hosting platform. A public anonymous game URL and a public source repository are both required by the bounty. Verification should include anonymous access, separate clients sharing a match, replay and the sample bot against the deployed API. Marketplace receipts and wallet activity are tracked separately from the public game source.

## Attribution

Original rules, game engine, API, UI and tests were prepared by Codex for Lira Ventures with AI assistance. Infrastructure comes from the provided Vinext/Sites starter and its included licenses; external dependencies retain their own licenses. The original game files are MIT licensed; see [LICENSE](LICENSE).
