# HTTP/JSON API, rules v1.0.0

Base URL is the public game origin, or the loopback URL printed by the local server. All routes return JSON and `Cache-Control: no-store`. POST bodies require `Content-Type: application/json`, are limited to 4096 bytes, and must be objects. Browser writes must have the same origin; command-line HTTP clients can omit Origin. No authentication, key, cookie, wallet or token is required. Room code possession permits controlling a seat; this is intended for casual play with trusted participants.

## Create

`POST /api/rooms`

```json
{"name":"Human","capacity":2}
```

Returns `201 {"player":0,"game":{...}}`. Capacity is 2, 3 or 4; defaults to 2. Name is optional, trimmed, limited to 20 characters, and stripped of ASCII control characters. The server assigns a six-character `game.code` and version 1. Random room codes are identifiers, not authorization secrets.

## Join a lobby

`POST /api/rooms/ABC234/join`

```json
{"name":"HTTP agent"}
```

Returns `200 {"player":1,"game":{...}}`, with the assigned seat index. Keep that index. Joins after the start or when full return 409. Concurrent joins cannot claim the same seat. Built-in bot fill happens only when the host starts.

## Read state

`GET /api/rooms/ABC234`

Returns `200 {"game":{...}}` with:

| Field | Meaning |
| --- | --- |
| code, version | Room identifier and current optimistic write version |
| status | `lobby`, `playing`, or `finished` |
| capacity, players | Seat count; players contain id, name, kind, color, energy, score |
| board | 25 row-major cells; -1 neutral, 0–3 owning seat |
| linked | Connected cells for each player; disconnected cells remain owned but cannot score or extend |
| round, rounds, turn | Current round, final round, seat to act |
| turnSeconds, deadline | Turn limit and deadline in Unix milliseconds; deadline null outside play |
| serverNow | Server Unix milliseconds; use for countdown clock offset |
| activeBeacon | Highlighted edge cell, or null in the lobby |
| legalMoves | Every legal action for the current turn, including server-calculated cost |
| winners | Empty during play; winning seat indexes after the final round, including all tied winners |
| history, initial | Ordered actions with post-action states, and initial started state |

Board coordinates: index 0 is A1 (top left), 4 is E1, 20 is A5, 24 is E5. Homes are `[0,24,4,20]` in seat order. Edge beacons are North 2, East 14, South 22, West 10; center is 12. Adjacency is orthogonal.

Built-in bots and expired turns advance lazily before the response and are persisted atomically. A read can therefore change the version. If a read competes with another update, it can return 409; reread. Live clients normally poll around once every 1–2 seconds. Inactivity does not create a scheduled job: a later read resolves any elapsed deadlines.

## Start

`POST /api/rooms/ABC234/start`

```json
{"player":0,"expectedVersion":2,"fillBots":true}
```

Only seat 0 can start. Empty seats become built-in bots unless `fillBots` is false; then every seat must already be occupied. Read the lobby version just before starting. Returns `200 {"game":{...}}`.

## Make a move

`POST /api/rooms/ABC234/moves`

```json
{"player":0,"expectedVersion":3,"move":{"kind":"link","tile":1}}
```

Use an entry from the current `game.legalMoves`. You may omit cost: the server computes it. Supported move shapes:

```json
{"kind":"charge"}
{"kind":"link","tile":1}
{"kind":"dash","path":[1,2]}
{"kind":"surge","tile":7}
```

Charge adds 2 energy up to the cap of 6. Link must reach an empty adjacent cell from a home-connected cell. Dash must cross two consecutive empty cells, starting adjacent to the connected network. Surge removes one adjacent enemy cell, leaving it neutral; active home cells cannot be surged. Disconnected branches may reconnect later. Only beacons connected to home at the end of a round score.

Returns `200 {"game":{...}}`. Built-in bots may already have taken their following turns before that response. Their moves appear in history. A 409 means refresh the state; do not resend the same move/version blindly. If the network outcome of a POST is unknown, GET the room and inspect version/history before considering another action.

## Replay

`GET /api/rooms/ABC234/replay`

Returns `{code,rulesVersion,initial,events,game}`. Each event has `n`, `player`, `move`, `cause` (`human`, `bot` or `timeout`), timestamp `at`, `gains` (only on round scoring), and a full post-action `state`. The rules module exports `replay(initial, events, game)` to reconstruct moves and reject a differing recorded state. The browser exposes a move-by-move slider. Before the host starts, initial is null and events is empty.

## Health and errors

`GET /api/health` returns `{ "ok": true, "game": "Relay Tactics", "rulesVersion": "1.0.0" }`. This reports the route, not a database connectivity test.

Errors have `{ "error": "..." }` with HTTP status 400 (invalid input), 403 (host/origin), 404 (room/endpoint), 405 (create method), 409 (stale state, turn, full room or race), 410 (room older than 24 hours), 413 (body too large), 415 (content type), 422 (illegal move), or 503 (storage/allocation unavailable). Unexpected internal errors do not expose database details.

See `scripts/sample-bot.mjs` for a complete runnable client. The game, sample bot and replay verifier have no third-party model dependency.
