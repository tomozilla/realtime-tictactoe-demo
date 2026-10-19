# realtime-tictactoe-demo

English | [日本語](README.ja.md)

A small learning demo: a tic-tac-toe page you play across several browser tabs, to try Supabase Realtime **Broadcast (tell everyone what just happened)** and **Presence (who is here right now)**.

> **A personal learning project.** It is not an official sample of any company, and it is not a sound implementation of a multiplayer game or meant for production.
>
> Summary: a single-file tic-tac-toe page to try Supabase Realtime Broadcast + Presence with several browser tabs, including a "late joiner asks for the current state" fix. Demo only: the channel is public and game rules are checked only in the browser.

This is the code for two Japanese articles on Qiita:
- How-to: *Introduction to Supabase Realtime: sharing game state and "who is here right now" with Broadcast and Presence* (`index.html` in the root)
- Web app: *I built a live order board where everyone sees the same thing at the same time: you can tell who is watching and who is working on which card* (`app/` and `sql/app/`)

The page/UI texts and code comments are English. Sample data (and the stored status values of the order board) stay Japanese on purpose, with English glosses in comments; Japanese-commented copies of the code (with Japanese UI) are in [`ja/`](ja/).

## Files

| File | Role |
|---|---|
| `index.html` | The tic-tac-toe itself (HTML and JavaScript in one file; supabase-js is loaded from a CDN (`esm.sh`)) |
| `config.example.js` | Config template. Copy it to `config.js` (`config.js` is already in `.gitignore`) |
| `app/index.html`, `app/config.example.js` | The live order board (see below) |
| `sql/app/` | SQL for the order board: `01_orders.sql` (table), `02_reset_seed.sql` (reset), `99_cleanup.sql` (cleanup) |
| `ja/` | Copies of the same files with Japanese comments and Japanese UI text |

## Live order board (`app/`)

A small screen with three columns (received / cooking / done). When someone moves an order card, everyone's screen changes right away. It also shows "who is viewing now" and "who is looking at which card" (one HTML file, no build step). The "current state" lives in the database; Realtime only carries change notifications (Postgres Changes) and the roster (Presence).

```bash
# 1. Run sql/app/01_orders.sql in the SQL Editor (table, demo policies, Realtime publication, 4 sample rows)
cd app
cp config.example.js config.js     # fill in the URL and the publishable key (config.js is in .gitignore)
python3 -m http.server 8765 --bind 127.0.0.1
# open http://127.0.0.1:8765/index.html?name=Alice  and  ?name=Bob  -- use a different name in each tab
```

- When the connection drops, the screen turns gray and says the data may be out of date, reconnects automatically, and reloads everything from the database. With `?debug=1` you can drop the connection on purpose with `window.__rt.disconnect()`.
- What I checked (October 2026): in three tabs (Alice, Bob, Carol joining late) I confirmed updates showing up, adding orders, the roster, the "is looking" badge, and recovery after a disconnect. From Bob's click to Alice's screen changing took 369-745 ms over 5 runs (same computer, including the database write).
- Cost: Free allows 2 million Realtime messages per month and 200 concurrent connections (from the docs). I did not check the exact rules for how messages are counted.
- **Security (this is a demo setup)**: the policies let anyone read, add and update orders without logging in (`sql/app/01_orders.sql`). In a real app, restrict it to logged-in users and narrow the columns and rows that can be updated. `updated_by` is a name sent by the page, so it can be faked.
- Cleanup: `sql/app/99_cleanup.sql`. To start over: `sql/app/02_reset_seed.sql`.

## Prerequisites

- A Supabase project (checked on a Free plan demo project). **No tables or SQL are needed** for the tic-tac-toe (it only uses Realtime).
- A browser and `python3` (only to serve the files locally).
- **A publishable (anon) key**: found under Project Settings -> API Keys. It is meant to be public, but keep it out of screenshots and articles. **Never put a service_role / secret key in here.**

## Usage

```bash
cp config.example.js config.js     # open it and fill in the URL and the publishable key
python3 -m http.server 8765 --bind 127.0.0.1
```

Open several tabs in the browser.

- `http://127.0.0.1:8765/index.html?name=Alice&mark=X`
- `http://127.0.0.1:8765/index.html?name=Bob&mark=O`
- `http://127.0.0.1:8765/index.html?name=Carol` (spectator)
- For a tab that joins midway, add `&resync=1`: on joining it broadcasts "tell me the current board"

When Alice clicks a cell it shows up on Bob's board too, and the "Online: N" roster updates. If `config.js` is missing, the page shows a hint.

In a clean copy (only `config.js` created) I opened two tabs, Alice and Bob, and confirmed the join roster and that one move was reflected (October 2026).

## How it works (the short version)

- Everyone joins `supabase.channel('game-room-1')`
- Making a move -> `room.send({ type: 'broadcast', event: 'move', ... })`
- Joining/leaving -> the roster is updated on the `presence` `sync` event
- Broadcast **does not remember the past**. Someone who joins midway sees an empty board, so on joining they broadcast `state-request`, and a player answers with `state` containing the current board

## Cost

From the docs' pricing table (as of October 2026):

| | Free | Pro |
|---|---|---|
| Realtime messages | 2 million / month | 5 million included, then $2.50 per million |
| Concurrent connections (peak) | 200 | 500 included, then $10 per 1,000 |

Tic-tac-toe fit comfortably in the Free limits. **Something like streaming mouse movements to everyone would, I think, approach the limits quickly** (I did not try it). Behavior on a paid plan is not verified.

## Warnings (this is a demo setup)

- **The channel is public (anyone can join).** Someone who knows how it works can join and send fake messages. I did not try the "private channel for logged-in users only" setup.
- **Win/draw detection happens only in the browser.** Cheating cannot be stopped. If money or points are involved, decide the result on the server.
- supabase-js is loaded from the CDN with `@2` (major version only). For production, it is safer to pin the version and serve it yourself.

## Not verified

- Connecting from another device or another network (I only checked with tabs on one computer)
- Speed and stability with more people
- Setting up a private channel
- After translating the comments and UI texts to English, I only syntax-checked the scripts (`node --check`). I did not re-run the pages against a live backend after the translation; the checks above were done on the original Japanese version.

## License

MIT (see `LICENSE`)
