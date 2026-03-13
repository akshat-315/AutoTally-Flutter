# AutoTally

Privacy-first, SMS-based expense tracker for Android. Built for Indian users.

Reads bank/UPI transaction SMS, parses them into structured transactions using regex templates, categorises by merchant, and shows a spending dashboard — all locally on-device.

## Core Principles

- **Local-first**: All data lives in SQLite on the user's phone. Phone is the source of truth.
- **Zero network calls** for core functionality. App works fully offline, forever.
- **Privacy promise**: No ads, no loans, no data leaves your phone unless you explicitly opt in.
- **Two-mode architecture**: Default is fully local (free). Cloud features are opt-in (future paid tier).
- **Server has 3 narrow roles** (future): template factory (LLM), shared template library, family aggregation (summaries only, never raw data).

## Tech Stack

- Flutter (Dart) for Android
- SQLite on-device for all data storage
- Regex-based template engine for SMS parsing (ported from Python server)

## Reference Docs

All in '/docs/\*'

- `AutoTally_Design_Document.docx` — full product design (cloud features, family dashboard, monetisation, all system flows)
- `ARCHITECTURE_DECISIONS.md` — why local-first, two-mode architecture, server roles, monetisation strategy
- `MVP_ROADMAP.md` — 1-month build plan with daily milestones

## Origin

This app started as a Termux + FastAPI self-hosted tool. The server code in `../AutoTally/server/` has the working SMS parser, template engine, merchant resolution, and dashboard logic — all in Python. These are being ported to Dart for the local-first app.

---

## Rules

- Do not write any comments anywhere in the codebase.
- Before writing any code, confirm with me - tell me the logic and whys and hows properly.
