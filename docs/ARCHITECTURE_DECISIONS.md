# Delhi — Architecture Decisions

Decisions made during design session, March 13, 2026.

---

## 1. Local-First Architecture

**Decision**: The app is local-first. All transaction data lives in SQLite on the user's device. The phone is the source of truth, always.

**What this means**:
- SMS parsing, merchant resolution, categorisation, dashboard queries — all run locally in Flutter/Dart using `sqflite` or `drift`
- Zero network calls required for core functionality
- The app works fully offline, forever
- Templates are bundled into the APK — no server needed to parse SMS

**What this does NOT mean**:
- It doesn't mean local-only. Users can opt into cloud features when they want to.
- It doesn't mean the server doesn't exist. The server has specific, narrow roles (see below).

---

## 2. Two-Mode Architecture

**Decision**: One app, two modes. Default is fully local. Cloud is opt-in.

### Local Mode (default)
- Bundled template library for SMS parsing
- SQLite on-device for all data
- Zero API calls, zero server dependency
- Free forever

### Cloud Mode (opt-in)
- Everything in local mode, plus:
- LLM-powered template generation for unsupported banks
- Cloud backup + restore on new device
- Family dashboard (aggregated summaries only — raw data stays on device)
- Web dashboard access (future)

### Mode Switching
- Local → Cloud: user opts in, local data starts syncing to server
- Cloud → Local: stop syncing, delete server-side data. Local SQLite already has everything — no download needed.
- Switching is reversible in both directions.

### Data Flow
- Data flows one direction: device → server (when cloud is on). Never server → device.
- Exception: restore-from-cloud on a new device (distinct from mode toggle).
- Exception: template generation — sends one SMS body to server, receives a template back. Not transaction data.

---

## 3. Server Roles (Narrow)

The server is NOT a data store for transaction history. It has three specific jobs:

1. **Template Factory** — When the app encounters an unrecognised SMS, it can send that one SMS body to the server. Server calls Claude Haiku, generates a regex template, validates it, and returns the template. The server never sees the parsed transaction — just the raw SMS pattern.

2. **Template Library** — Hosts the shared template library. When a new template is generated for one user, all future users benefit. App can periodically pull new templates via app updates or a template sync endpoint.

3. **Family Aggregation** (future) — Receives aggregated spending summaries (not raw transactions) from family members who opt in. "Akshat spent ₹12,000 on Food this month" — not individual transactions.

---

## 4. Monetisation

**Decision**: Free at launch. Everything is free. Paid tier exists in the architecture but is not enforced.

### Free Tier (local-first)
- Full SMS parsing via bundled templates
- Full transaction history (no time cap — it's their local DB, costs nothing)
- Dashboard, categories, merchants, all local features
- P2P detection
- Spending insights
- LLM template generation for unsupported banks (free for now — revisit when user base grows)

### Paid Tier (future, cloud-powered)
- Cloud backup + restore
- Family dashboard
- Web dashboard
- Tax-ready export
- Other cloud-dependent features TBD

### Unit Economics
- Free users cost ₹0 to serve (no server, no DB, no API calls)
- Template generation cost: ~₹0.08 per user (one-time, amortised across users with same banks)
- Paid tier pricing TBD when there's a user base and data on what people value

---

## 5. Template Strategy

**Decision**: Ship with bundled templates for top Indian banks. LLM generation is the fallback, not the primary path.

### Bundled Templates
- Must cover top 8-10 banks at launch: HDFC, ICICI, SBI, Axis, Kotak, PNB, BOB, IndusInd, Yes Bank, IDFC
- Each bank: ~5-15 patterns (UPI debit/credit, NEFT, IMPS, card transaction, ATM withdrawal, etc.)
- Templates ship with the APK, updated via Play Store app updates
- Stored locally — loaded into memory on app start

### LLM Generation (bridge feature)
- When a user encounters an SMS no bundled template matches
- App shows: "We don't recognise this bank yet. Want to send this message to teach Delhi the pattern?"
- Single opt-in, single API call. User sees exactly what's being sent.
- Generated template is stored locally on device AND added to global library on server
- Free for now, potentially paid-tier in future

### Unrecognised SMS (no LLM, no opt-in)
- Queued as "untracked" locally
- User can request template generation later
- Or wait for an app update that adds their bank

---

## 6. Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| App | Flutter | Cross-platform potential, good plugin ecosystem for SMS/background work, Akshat has no native Android experience |
| Local DB | SQLite via `drift` or `sqflite` | On-device, zero server dependency, handles complex queries for dashboard |
| State management | Riverpod | Modern, testable, good for reactive UI |
| HTTP client | Dio | Only used for opt-in cloud features and template generation |
| Auth | Firebase Phone Auth | Only needed for cloud mode. Local mode needs no auth. |
| Server | FastAPI (existing) | Extended for multi-user, template generation, family sync |
| Server DB | PostgreSQL | Only stores: user accounts, templates, family aggregates. NOT transaction data. |
| LLM | Claude Haiku | Template generation only. ~₹0.08 per user. |
| Charts | fl_chart | Local dashboard visualisation |

---

## 7. Privacy Promise

> Delhi makes money from subscriptions, not from your data. By default, nothing leaves your phone. If you choose to use cloud features, you control exactly what is shared and can revoke access at any time.

- Default mode: zero network calls, zero data transmission
- Template generation: sends one SMS body with explicit user consent
- Cloud sync: opt-in, reversible, data deleted on opt-out
- Family sharing: aggregated summaries only, never raw transactions
- No ads. No loans. No third-party data sharing. Ever.

---

*Created: March 13, 2026*
