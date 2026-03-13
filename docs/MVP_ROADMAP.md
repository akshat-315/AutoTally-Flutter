# Delhi — 1 Month MVP Roadmap (Local-First)

**Goal**: Ship a fully local, privacy-first expense tracker to the Play Store. Works offline, zero server dependency for core features.

**Timeline**: March 14 – April 13, 2026 (1 month, 1–2 hr/day minimum)

**Principle**: Local-first. Phone is the source of truth. Build the entire local engine before touching server code. Minimal UI until everything works.

**See**: `ARCHITECTURE_DECISIONS.md` for the full architectural rationale.

---

## Week 1 — Local Engine

No UI this week. Build the data layer that powers everything — SQLite schema, template engine ported to Dart, SMS reading, and the full parsing pipeline. This is the foundation every screen will sit on.

### Day 1–2: Flutter Project + SQLite Schema

**Flutter Setup**
- [ ] Install Flutter SDK + Android Studio, configure emulator + real device
- [ ] Create project (`delhi_app`)
- [ ] Add dependencies: `drift` (SQLite ORM), `riverpod`, `dio`, `fl_chart`, `shared_preferences`, `permission_handler`
- [ ] Project structure:
  ```
  lib/
  ├── core/
  │   ├── database/         (drift DB, tables, DAOs)
  │   ├── sms/              (reader, filter, parser)
  │   ├── templates/         (bundled templates, template engine)
  │   └── config/           (constants, enums)
  ├── features/
  │   ├── onboarding/
  │   ├── dashboard/
  │   ├── transactions/
  │   ├── merchants/
  │   └── settings/
  ├── models/
  └── main.dart
  ```

**Full SQLite Schema (design once)**

Build every table now. Include columns for features we'll build later — avoids schema migrations on user devices.

```
categories
  id (auto PK), name (unique), icon, description, is_default (bool),
  created_at

merchants
  id (auto PK), name, vpa, category_id (FK), display_name,
  primary_merchant_id (FK self — for future merge/variants),
  is_confirmed (bool), times_confirmed (int), source (text),
  is_p2p (bool), first_seen, last_seen, created_at

transactions
  id (auto PK), sms_id (unique — Android SMS ID for dedup),
  direction (debit/credit), amount (real), bank (text),
  merchant_id (FK), merchant_raw, account_last4, vpa, upi_ref,
  transaction_date, category_id (FK), category_source (text),
  raw_sms, sms_sender, sms_received_at,
  is_p2p (bool), is_subscription (bool — future flag),
  created_at

templates
  id (auto PK), sender_key, bank_name, direction,
  pattern (text), skeleton_hash (unique),
  version (int), is_active (bool), source (bundled/generated),
  created_at

app_config
  key (PK), value (text)
  -- stores: last_sms_id, onboarding_complete, cloud_mode, etc.
```

- [ ] Define all tables in `drift`
- [ ] Seed default categories on first launch (Food, Transport, Shopping, Bills, Entertainment, Health, Education, Transfers, Subscriptions, Other)
- [ ] Seed VPA dictionary as a local map (swiggy→Food, zomato→Food, uber→Transport, amazon→Shopping, etc.)
- [ ] Write basic CRUD DAOs for each table
- [ ] Test: app launches, DB created, seeds populated

**Deliverable**: App compiles, local DB with full schema, seeded with categories and VPA mappings.

---

### Day 3: Port Template Engine to Dart

The Python `template_engine.py` compiles YAML patterns with `{placeholders}` into regex. Port this logic to Dart.

- [ ] Port `compile_template()` — convert pattern strings like `"Rs.{amount} debited from {last4}"` into Dart `RegExp`
- [ ] Support all placeholders: `{amount}`, `{merchant}`, `{vpa}`, `{date}`, `{upi_ref}`, `{last4}`
- [ ] Flexible whitespace matching (same as Python version)
- [ ] Case-insensitive matching
- [ ] `ParsedSMS` model: `direction, amount, bank, accountLast4, merchantRaw, vpa, upiRef, transactionDate`
- [ ] Date parsing: support common Indian SMS date formats (`dd-mm-yy`, `dd/mm/yy`, `dd-MMM-yy`, `dd MMM YYYY`)
- [ ] Unit tests: compile a template, run against sample SMS, verify all fields extracted

**Deliverable**: Template engine works in Dart. Can parse any SMS that has a matching template.

---

### Day 4: Bundle Templates for Top Banks

- [ ] Collect sample SMS from top banks: HDFC, ICICI, SBI, Axis, Kotak (minimum for launch)
- [ ] Write templates for each bank's SMS patterns:
  - UPI debit / credit
  - NEFT / IMPS
  - Card transaction
  - ATM withdrawal (if distinct pattern)
  - Auto-debit / mandate (if distinct)
- [ ] Store as a bundled Dart map or JSON asset file, keyed by sender ID (e.g. `HDFCBK`, `ICICIB`)
- [ ] Load into `templates` table on first launch (source = `bundled`)
- [ ] Test: feed real SMS from each bank through the parser, verify correct extraction

**Deliverable**: 5 banks fully supported with bundled templates. This covers the majority of Indian users.

---

### Day 5: SMS Reading + Filtering + Parsing Pipeline

- [ ] Add SMS reading plugin (`sms_advanced` or `flutter_sms_inbox`)
- [ ] Request `READ_SMS` permission
- [ ] Read full inbox → get list of `{id, address, body, date}`
- [ ] Pre-filter: keep only messages from alphanumeric senders containing financial keywords (`Rs`, `INR`, `debited`, `credited`, `UPI`, `txn`, `withdrawn`, `deposited`, `transferred`)
- [ ] For each filtered SMS:
  1. Match sender against template sender_keys
  2. Try all templates for that sender → find first match
  3. If matched → return `ParsedSMS`
  4. If no match → queue as untracked
- [ ] Test on real device: read SMS, filter, parse, print results to console

**Deliverable**: Full local pipeline works — SMS in, parsed transactions out. No UI needed to verify, just console output.

---

### Day 6–7: Merchant Resolution + Transaction Storage

Port the tiered merchant resolution from Python (`merchant_ops.py`) to Dart.

**Merchant Resolution**
- [ ] Tier 1: VPA exact match → return existing merchant, inherit category
- [ ] Tier 2: Exact normalised name match → return existing merchant
- [ ] Tier 3: Fuzzy name match against confirmed merchants (use `fuzzywuzzy` Dart package or simple token-based similarity) → copy category to new merchant, do NOT link
- [ ] Tier 4: No match → create new merchant (source = `pending`)
- [ ] P2P detection: phone-number VPAs (`^\d{10,12}@`) → `is_p2p = true`
- [ ] VPA dictionary auto-categorisation: check VPA against seed dictionary → assign category + source = `vpa_dict`

**Transaction Storage**
- [ ] Dedup by `sms_id` — skip if already exists
- [ ] Create transaction with all parsed fields + resolved merchant + inherited category
- [ ] Set `category_source`: `merchant` / `vpa_dict` / `fuzzy` / null (uncategorised)

**Full Pipeline Test**
- [ ] Read SMS → filter → parse → resolve merchants → store transactions → query back
- [ ] Verify: transactions in DB, merchants created, categories assigned where possible
- [ ] Print summary: "Processed X SMS, Y transactions, Z merchants, W uncategorised"

**Deliverable**: The entire local engine works end-to-end. Week 1 complete. Every subsequent week is just UI on top of this.

---

## Week 2 — Onboarding + Core Screens

Get the user from install to a working dashboard. Minimal UI — functional, not pretty.

### Day 8–9: Onboarding Flow

The moment the user goes from "empty app" to "all my spending is here."

**Permission + SMS Scan**
- [ ] Welcome screen: one-liner about what Delhi does
- [ ] Permission request with rationale: "Delhi reads bank SMS to track your spending. Messages stay on your device."
- [ ] On grant: scan inbox, filter financial SMS
- [ ] Show: "Found X financial messages from Y banks"

**Processing**
- [ ] Progress screen: "Processing your messages... 234/1,203"
- [ ] Parse all matched SMS → resolve merchants → store transactions
- [ ] Collect untracked SMS (no template match) → store separately with sender info
- [ ] Show summary: "Tracked X transactions across Y banks. Z messages from unsupported banks."

**Merchant Review**
- [ ] List all uncategorised merchants, sorted by transaction count
- [ ] Each item: merchant name, VPA, count, category dropdown
- [ ] "Skip for now" option (can categorise later)
- [ ] On done → navigate to dashboard

**Deliverable**: User goes from install to a populated dashboard in under 2 minutes.

---

### Day 10–11: Dashboard

- [ ] Monthly summary cards: Total Debited, Total Credited, Net Flow, Transaction Count
- [ ] Spending by category: bar chart (`fl_chart`)
- [ ] Top merchants: list sorted by spending amount
- [ ] Month selector: tap to switch between months
- [ ] Pull-to-refresh (re-query local DB)
- [ ] All data from local SQLite — drift queries with SUM/GROUP BY

**Deliverable**: User sees where their money goes.

---

### Day 12: Transaction List

- [ ] Paginated list (lazy loading from local DB)
- [ ] Each row: merchant name, amount (red/green), category badge, date
- [ ] Filter by: direction, category, date range
- [ ] Search by merchant name
- [ ] Tap → detail view with category override dropdown
- [ ] Category override: update transaction's `category_id`, set `category_source = user_override`

**Deliverable**: User can browse and recategorise transactions.

---

### Day 13–14: Real-Time SMS Tracking

- [ ] Background SMS listener (platform channel or plugin) — fires on new SMS
- [ ] Pre-filter → template match → parse → merchant resolution → store
- [ ] Local notification: "Spent ₹450 at Swiggy — Food"
- [ ] If no template match → store as untracked, show badge in settings
- [ ] WorkManager fallback: periodic scan every 15 min (catches missed SMS)
- [ ] Test: send yourself a bank SMS format, verify it appears in transaction list

**Deliverable**: New spending tracked in real-time. Week 2 complete — the app is usable.

---

## Week 3 — Complete Feature Set

Build out every remaining screen and feature. Still minimal UI.

### Day 15–16: Merchants + Categories Screens

**Merchants**
- [ ] Searchable merchant list: name, VPA, category, transaction count
- [ ] Tap → change category, view transactions for this merchant
- [ ] P2P merchants shown with distinct label
- [ ] Uncategorised queue accessible (badge with count)

**Categories**
- [ ] List with spending totals per category
- [ ] Add / edit / delete custom categories
- [ ] Tap category → filtered transaction list
- [ ] Prevent deletion of categories with transactions (or prompt to reassign)

**Deliverable**: Full merchant and category management.

---

### Day 17: Settings + Template Info

- [ ] Supported banks list (from bundled templates) — user can see what's covered
- [ ] Untracked SMS list: messages from unsupported banks
  - Show sender, count of untracked messages
  - "Request support" — placeholder for now (future: LLM generation)
- [ ] App info, privacy policy link
- [ ] "Cloud features coming soon" placeholder toggle

**Deliverable**: Settings complete. User knows what's supported and what isn't.

---

### Day 18–19: Self-Learning + Smart Categorisation

- [ ] When user overrides a merchant's category 3+ times → prompt: "Update default for [merchant]?"
- [ ] If confirmed → update `merchant.category_id`, set `is_confirmed = true`
- [ ] "Categorise similar" — when overriding a transaction, offer to apply same category to all uncategorised transactions from same merchant
- [ ] Show `category_source` subtly on transaction detail (auto, merchant default, user override)
- [ ] Dashboard: separate P2P transfers from merchant spending in summary

**Deliverable**: App gets smarter with use.

---

### Day 20–21: Add More Banks + Template Testing

- [ ] Add templates for next tier of banks: PNB, BOB, IndusInd, Yes Bank, IDFC
- [ ] Add templates for wallets/payment apps: Paytm, PhonePe, GPay (if they send SMS)
- [ ] Systematic testing: collect 5+ sample SMS per bank, verify parsing accuracy
- [ ] Fix edge cases: amount formats (1,00,000 vs 100000), date formats, multi-line SMS
- [ ] Target: 10+ banks covered, major UPI apps covered

**Deliverable**: Broad bank coverage. Most Indian users will find their bank supported.

---

## Week 4 — Polish + Play Store

Make it real. Handle edge cases. Ship it.

### Day 22–23: Error Handling + Edge Cases

- [ ] Empty states: no transactions yet, no merchants, category with no spending
- [ ] Permission denied: explain why SMS access is needed, offer to retry
- [ ] Permission revoked mid-use: detect and prompt gracefully
- [ ] Corrupted/weird SMS: parser shouldn't crash on malformed messages
- [ ] Loading states / skeleton screens for initial DB queries
- [ ] First launch vs returning user (check `onboarding_complete` in app_config)
- [ ] Test on Android 10, 12, 13, 14 (API 29+)

**Deliverable**: App doesn't crash or show blank screens in any scenario.

---

### Day 24–25: Minimal Design Pass

Not a full redesign — just make it look intentional.

- [ ] App icon + splash screen (Delhi/AutoTally logo)
- [ ] Consistent color scheme (Material 3 theme — pick one accent color and let M3 derive the rest)
- [ ] Dark mode (Material 3 makes this nearly free)
- [ ] Typography: consistent text styles across screens
- [ ] Smooth page transitions (default Flutter hero/fade animations)
- [ ] Amount formatting: Indian numbering (₹1,23,456), always show ₹ symbol
- [ ] Test on 2-3 screen sizes

**Deliverable**: Clean, consistent, minimal app. Not flashy — just polished.

---

### Day 26–27: Privacy Policy + Play Store Prep

**Privacy Policy** (required — Google is strict about SMS access apps)
- [ ] What's collected: nothing by default. All data stays on device.
- [ ] SMS access: used solely to parse bank transaction messages. Raw SMS stored only on device.
- [ ] Cloud mode (future): opt-in, user-controlled, reversible. Data stored on Indian servers.
- [ ] No third-party sharing. No ads. No tracking.
- [ ] Account deletion: clear all local data from settings.
- [ ] Host on public URL (GitHub Pages)

**Play Store**
- [ ] Google Play Developer account ($25 one-time)
- [ ] SMS permission declaration — core functionality use case:
  > "Delhi reads bank/financial SMS to automatically parse and categorise spending transactions. All parsing happens on-device. No SMS content is transmitted to any server. This is the app's core and only functionality."
- [ ] Store listing: name, short description, full description, screenshots (4+), feature graphic
- [ ] Signed App Bundle (AAB)
- [ ] Content rating questionnaire
- [ ] Target API level

**Deliverable**: Everything ready for submission.

---

### Day 28: Submit + Buffer

- [ ] Submit to Play Store
- [ ] First review: 1–3 days typically
- [ ] Buffer for: review feedback, last-minute bugs, SMS declaration revision if needed

**Deliverable**: App submitted. Sprint complete.

---

## Daily Summary

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 1–2 | Flutter project + full SQLite schema + seeds | DB ready with all tables |
| 3 | Port template engine to Dart | Can parse SMS locally |
| 4 | Bundle templates for top 5 banks | HDFC, ICICI, SBI, Axis, Kotak covered |
| 5 | SMS reading + filtering + parsing pipeline | SMS → parsed transactions pipeline works |
| 6–7 | Merchant resolution + transaction storage | Full local engine end-to-end |
| 8–9 | Onboarding flow (scan → parse → review) | Install to dashboard in 2 minutes |
| 10–11 | Dashboard screen | Spending summary visible |
| 12 | Transaction list + filters | Browse and recategorise |
| 13–14 | Real-time SMS tracking + background worker | New SMS auto-tracked |
| 15–16 | Merchants + categories screens | Full data management |
| 17 | Settings + template info | Supported banks visible |
| 18–19 | Self-learning + smart categorisation | App learns from user |
| 20–21 | More bank templates + testing | 10+ banks covered |
| 22–23 | Error handling + edge cases | Production-ready stability |
| 24–25 | Design pass (colors, dark mode, polish) | Looks intentional |
| 26–27 | Privacy policy + Play Store prep | Ready to submit |
| 28 | Submit to Play Store | Shipped |

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Google rejects SMS permission | Blocker | Local-first strengthens the case — "no data leaves device." Write declaration early (Day 1). |
| Flutter SMS plugin unreliable | High | Test on Day 5, not Day 20. Fallback: Kotlin platform channel. |
| Template coverage gaps | Medium | Launch with top 5 banks minimum. Users with unsupported banks see "request support" flow. |
| Drift/SQLite performance on large inboxes | Low | SQLite handles millions of rows. Add indices on transaction_date, merchant_id, category_id. |
| SMS format changes by banks | Low (post-launch) | App update pushes new templates. Future: LLM generation for instant fixes. |

---

## What's in this MVP

- Fully local SMS parsing — zero server dependency
- Bundled templates for 10+ Indian banks
- Full onboarding (scan inbox → parse → merchant review)
- Real-time SMS tracking (listener + WorkManager fallback)
- Spending dashboard (summary, by-category, by-merchant)
- Transaction list with filters and category override
- Merchant management with categorisation
- Category CRUD
- P2P detection
- Self-learning category suggestions
- Untracked SMS queue (for unsupported banks)
- Dark mode
- Privacy policy + Play Store listing

## What's deferred (next roadmap)

- Cloud mode (server, auth, sync)
- LLM template generation
- Family dashboard
- Subscription detection
- Tax export
- Web dashboard
- Budget alerts
- Spending insights / behavioral patterns (the "spending fingerprint" idea)
- Proper UI redesign

---

*Created: March 13, 2026*
