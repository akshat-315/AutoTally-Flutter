# AutoTally -- Complete Screen Design Brief

Target: Figma wireframing. Every screen described in enough detail to wireframe without guessing.

Global conventions used throughout:
- Indian number formatting: amounts always shown as "Rs 1,23,456" with rupee symbol
- Amount stored as integer paise, displayed by dividing by 100
- Debits shown in red text, credits in green text
- 10 default categories, each with an emoji icon and hex color: Food, Transport, Shopping, Bills, Entertainment, Health, Education, Transfers, Subscriptions, Other
- Merchant display: displayName if set, otherwise name. VPA shown as secondary text where relevant.
- Dark mode follows system setting, manual override in Settings. All screens must work in both themes.
- Bottom nav bar visible on all 5 main tabs. Hidden during onboarding, modals, and detail screens.
- All lists use lazy loading / pagination from local SQLite.
- Status bar: system default. No custom treatment.

---

## FLOW 1: ONBOARDING (First Launch)

Shown once. After completion, app_config `onboarding_complete` is set to true. User never sees this again.

---

### Screen 1.1: Welcome

**What the user sees:**
- Full-screen layout, vertically centered content
- App logo/icon at top (AutoTally wordmark or icon -- TBD by visual design)
- Headline: "Track every rupee. Privately."
- Subtext (2 lines max): "AutoTally reads your bank SMS to show where your money goes. Everything stays on your phone."
- Single primary button at bottom: "Get Started"
- Small text below button: "No sign-up needed. No data leaves your phone."

**Actions:**
- Tap "Get Started" --> navigate to Screen 1.2

**No empty/error states.** This is a static screen.

---

### Screen 1.2: SMS Permission

**What the user sees:**
- Illustration or icon representing SMS/messages (simple, not elaborate)
- Headline: "Allow SMS Access"
- Explanation text: "AutoTally needs to read your bank messages to find transactions. Your messages are never sent anywhere -- all processing happens on your phone."
- Primary button: "Allow SMS Access"
- Secondary text link below: "Why is this needed?" (expands an inline accordion or shows a bottom sheet with 3 bullet points: reads only financial SMS, all parsing is local, no network calls)

**Actions:**
- Tap "Allow SMS Access" --> triggers Android READ_SMS permission dialog (system dialog)
  - If GRANTED --> navigate to Screen 1.3
  - If DENIED --> show Screen 1.2a (Permission Denied state)
- Tap "Why is this needed?" --> expand/show explanation

**Error state -- Screen 1.2a: Permission Denied**
- Same layout but with different messaging
- Headline: "SMS Access Required"
- Text: "AutoTally can't work without reading your bank messages. No data leaves your phone -- this is the only permission the app needs."
- Primary button: "Try Again" --> re-trigger permission dialog
- If denied with "Don't ask again" (Android permanent denial): button text changes to "Open Settings", which deep-links to app permission settings. Below it, helper text: "Turn on SMS permission, then come back."
- Back arrow in top-left --> returns to Screen 1.1

---

### Screen 1.3: SMS Scan Progress

**What the user sees:**
- Centered content, no back button (process is running)
- Headline: "Scanning your messages..."
- Animated progress indicator (circular or linear progress bar)
- Live counter: "Processing 234 of 1,203 messages" (updates in real-time as SMS are filtered and parsed)
- Below counter: subtle secondary text that updates through phases:
  - Phase 1: "Finding financial messages..."
  - Phase 2: "Parsing transactions..."
  - Phase 3: "Identifying merchants..."

**Actions:**
- None. User waits. No cancel button -- scan completes in seconds on most devices.

**On completion:** auto-navigate to Screen 1.4

**Error state:**
- If zero financial SMS found (unlikely but possible -- new phone, non-Indian bank): navigate to Screen 1.4 with zero-state data.

---

### Screen 1.4: Scan Summary

**What the user sees:**
- Headline: "Here's what we found"
- Three stat cards in a vertical stack (or horizontal row if space permits):
  - Card 1: "[X] transactions" with a small icon
  - Card 2: "[Y] merchants" with a small icon
  - Card 3: "[Z] banks detected" with a small icon
- If any unsupported banks detected, a subtle note below: "[N] messages from unsupported banks (you can request support later)"
- Primary button: "Review Top Merchants" (if uncategorized merchants exist)
- OR if all merchants were auto-categorized (unlikely): "Go to Dashboard"

**Actions:**
- Tap primary button --> navigate to Screen 1.5

**Empty state (zero transactions found):**
- Headline: "No transactions found"
- Text: "We couldn't find any bank transaction messages. This might mean your bank isn't supported yet, or your financial SMS have been deleted."
- Text: "AutoTally will track new transactions as they arrive."
- Button: "Go to Dashboard" --> navigate to Dashboard (empty state)

---

### Screen 1.5: Merchant Categorization (Onboarding)

**What the user sees:**
- Top bar: "Categorize Your Merchants" (title), step indicator "X of Y" showing progress
- Subtitle: "These are your most frequent merchants. Categorize them so your dashboard makes sense."
- Scrollable list of top 15-20 merchants, sorted by transaction count (descending). Each list item:
  - Left: Category emoji icon (if already auto-categorized from VPA dictionary) or a grey placeholder circle (if uncategorized)
  - Merchant name (bold), VPA below it in secondary text (if available)
  - Right side: transaction count as badge (e.g., "47 txns"), and a category chip/pill showing current category or "Uncategorized"
  - Tap the category chip --> opens Category Picker modal (see Modal M1)
  - If the merchant is P2P-detected (phone number VPA), show a subtle "P2P" label
- Bottom area:
  - Primary button: "Done" (enabled always -- user can skip categorization)
  - Text link below: "Skip -- I'll do this later"
- If there are more uncategorized merchants beyond the top 15-20, a note above the button: "[N] more merchants can be categorized in the Review tab"

**Actions:**
- Tap category chip on any merchant --> opens Category Picker modal (M1). On selection, chip updates immediately.
- Tap "Done" or "Skip" --> set onboarding_complete in app_config, navigate to main app (Dashboard tab)

**Empty state:** If no uncategorized merchants (all auto-categorized), skip this screen entirely and go to Dashboard.

---

## FLOW 2: MAIN APP -- BOTTOM NAVIGATION

5 tabs: Dashboard, Transactions, Review, Merchants, Settings

Bottom nav bar: 5 icons with labels underneath.
- Dashboard: grid/chart icon
- Transactions: list icon
- Review: inbox icon + badge count (sum of: uncategorized P2P txns + incomplete txns + uncategorized merchants)
- Merchants: store/shop icon
- Settings: gear icon

Badge on Review tab: red circle with white number. Disappears when count is 0.

Active tab: filled icon + accent color label. Inactive: outline icon + muted label.

---

## FLOW 2.1: DASHBOARD TAB

### Screen 2.1.1: Dashboard (Main)

**What the user sees:**

**Top section -- Month Navigation**
- Current month and year displayed prominently: "March 2026"
- Left arrow and right arrow flanking the month text for prev/next month navigation
- Tap on the month text itself opens Month Picker modal (M2)
- Swipe left/right on the entire dashboard content area also changes months
- If viewing current month, right arrow is disabled/hidden (can't go to future)

**Summary Cards Row**
- Horizontal row of 2-3 cards (scrollable if needed, but ideally all visible):
  - Card 1: "Spent" -- total debits for the month in red, large font. Excludes P2P.
  - Card 2: "Received" -- total credits for the month in green. Excludes P2P.
  - Card 3 (optional): "P2P" -- total P2P transfers (both directions combined or separated). This separates real spending from transfers.
- Below cards: transaction count for the month: "142 transactions"

**Category Breakdown**
- Section header: "Spending by Category"
- Horizontal bar chart (or donut chart -- designer's choice, but bar chart is more readable for 10 categories). Each bar:
  - Category emoji + name label
  - Bar length proportional to spend
  - Amount in Rs at the end of the bar
  - Sorted by amount descending
- Only show categories with non-zero spend. Max ~6-7 visible, rest behind "Show All" which expands the list or navigates to a full category breakdown screen (2.1.2)
- Tap any category bar --> navigates to Category Detail screen (2.1.2)

**Top Merchants**
- Section header: "Top Merchants"
- List of top 5 merchants by spend this month. Each row:
  - Category emoji (from merchant's assigned category)
  - Merchant display name
  - Total spend amount (in Rs, red)
  - Transaction count in parentheses: "(12 txns)"
- "See All" link at bottom --> navigates to Merchants tab with current month filter

**Actions:**
- Swipe left/right or tap arrows: change month
- Tap month text: open Month Picker (M2)
- Tap any category bar: navigate to Category Detail (2.1.2)
- Tap any merchant row: navigate to Merchant Detail (2.4.2)
- Pull-to-refresh: re-query local DB (should be near-instant)
- Bottom nav: switch tabs

**Empty state (no transactions for selected month):**
- Summary cards show Rs 0 for all values
- In place of charts/lists: centered illustration + text: "No transactions this month"
- If it's the current month and onboarding just completed with zero txns: "New transactions will appear here as they arrive"

**Empty state (very first launch, zero transactions total):**
- Same as above but text says: "No transactions yet. AutoTally will track your spending as new bank SMS arrive."

---

### Screen 2.1.2: Category Detail

**What the user sees:**
- Top app bar with back arrow, title: "[Category Emoji] [Category Name]"
- Month nav (same as dashboard: arrows + tap for picker). Carries forward whatever month was selected on dashboard.
- Total spend in this category for selected month (large, red for debits)
- Transaction count: "23 transactions"
- Transaction list for this category in selected month, sorted by date descending. Each row follows the standard Transaction Row format (see Component C1 below).
- If transactions span multiple days, date headers group them: "Today", "Yesterday", "March 15", etc.

**Actions:**
- Tap any transaction --> Transaction Detail (2.2.2)
- Change month via nav
- Back arrow --> Dashboard

**Empty state:** "No [Category Name] spending this month."

---

## FLOW 2.2: TRANSACTIONS TAB

### Screen 2.2.1: Transaction List

**What the user sees:**

**Top area -- Search and Filters**
- Search bar at top: placeholder "Search merchants..."
- Filter row below search bar: horizontal scrollable chips
  - "All" (default, selected)
  - "Debits"
  - "Credits"
  - Each of the 10 categories as filter chips (emoji + name, truncated if long)
  - "Uncategorized" chip
  - "P2P" chip
- Active filter chip is filled/highlighted. Multiple category chips can be active simultaneously (OR logic). Debit/Credit are mutually exclusive with each other but combinable with categories.

**Month Navigation**
- Same month nav bar as dashboard (arrows + tap for picker)

**Transaction List**
- Grouped by date: "Today", "Yesterday", "15 Mar", "14 Mar", etc.
- Each row: standard Transaction Row (Component C1)
- Infinite scroll / lazy loading

**Actions:**
- Type in search bar: filters transaction list by merchant name in real-time (local DB query)
- Tap filter chip: toggle filter, list updates immediately
- Tap any transaction row --> Transaction Detail (2.2.2)
- Change month: updates list
- Bottom nav: switch tabs

**Empty state (for current filters):**
- If filters active: "No transactions match your filters." with a "Clear Filters" button
- If no filters and month is empty: "No transactions this month."
- If total zero transactions: "No transactions yet. They'll appear here as AutoTally reads your bank SMS."

---

### Screen 2.2.2: Transaction Detail

**What the user sees:**
- Full-screen detail view (not a modal -- pushed onto navigation stack)
- Top app bar: back arrow, title "Transaction"

**Amount section (prominent)**
- Large amount: "Rs 1,234" in red (debit) or green (credit)
- Direction label below: "Debit" or "Credit"

**Details section (card or grouped list)**
- Merchant: merchant display name (tappable --> Merchant Detail 2.4.2). If no merchant (incomplete): "Unknown Merchant" in muted text with an "Assign" button.
- Category: emoji + category name, shown as a tappable chip. Tap --> Category Picker modal (M1). Below the chip, subtle text showing category source: "Auto (VPA match)" / "Auto (merchant default)" / "You set this" / "Uncategorized"
- Date & Time: "15 Mar 2026, 2:34 PM"
- Bank: "HDFC Bank"
- Account: "xx1234" (last 4 digits)
- VPA: "swiggy@okaxis" (if available, otherwise row hidden)
- UPI Ref: "412345678901" (if available, otherwise row hidden)
- P2P flag: if is_p2p is true, show "P2P Transfer" label with distinct styling

**Raw SMS section (collapsible)**
- Collapsed by default, header: "Original SMS"
- Tap to expand: shows the raw SMS text in a monospace or muted text block
- SMS sender shown above the body: "From: HDFCBK"

**Actions:**
- Tap category chip --> Category Picker modal (M1). On selection: update transaction's category_id, set category_source to "user_override". If user has overridden this merchant's category 3+ times, show a prompt: "Always use [Category] for [Merchant]?" with Yes/No. If Yes, update merchant's default category.
- Tap merchant name --> Merchant Detail (2.4.2)
- Tap "Assign" on unknown merchant --> Merchant Assignment modal (M5)
- Back arrow --> Transaction List

---

## FLOW 2.3: REVIEW TAB (Unified Inbox)

### Screen 2.3.1: Review Inbox

**What the user sees:**

**Top app bar:** "Review" title, total count: "12 items need attention"

**Three sections, shown as a segmented control or tab bar at the top of the content area:**
- "P2P" with count badge (e.g., "5")
- "Incomplete" with count badge (e.g., "3")
- "Merchants" with count badge (e.g., "4")

User taps a segment to switch between the three lists. Default: whichever section has the highest count, or P2P if tied.

---

**Section A: P2P Transactions**

Explanation banner at top (dismissable, shown once): "These are transfers to people (not shops). Assign a category so they count in your totals."

List of transactions where is_p2p = true AND category_id is null. Each row:
- Merchant name (often a phone number or person name)
- VPA (e.g., "9876543210@ybl")
- Amount and direction
- Date
- Category chip: "Uncategorized" (tappable --> Category Picker M1)
- Swipe right to quick-categorize as "Transfers" (most common action for P2P)

**Actions:**
- Tap category chip on any row --> Category Picker (M1). On selection, transaction gets categorized and the row animates out of the list. Badge count decrements.
- Swipe right --> auto-assign "Transfers" category, row animates out
- Tap the row itself --> Transaction Detail (2.2.2)
- Long-press merchant name --> option: "Always categorize [Merchant] as..." which sets the merchant's default category for all future transactions

**Empty state:** Checkmark illustration. "All P2P transactions categorized."

---

**Section B: Incomplete Transactions**

Explanation banner (dismissable, shown once): "These transactions were found in your SMS but are missing merchant details. Help AutoTally fill in the gaps."

List of transactions where merchant_id is null (SMS parsed, but template didn't extract merchant info). Each row:
- "Unknown Merchant" label (muted)
- Bank name
- Amount, direction, date
- Partial info if available (account last 4, any raw text from SMS)
- Action button: "Assign Merchant"

**Actions:**
- Tap "Assign Merchant" --> Merchant Assignment modal (M5). User can search existing merchants, create a new one, or pick a category directly without a merchant. On completion, row animates out.
- Tap the row --> Transaction Detail (2.2.2) with the "Assign" button prominent
- Can also swipe to reveal a "Skip" option (marks it as reviewed, removes from inbox but doesn't assign anything. Transaction stays uncategorized.)

**Empty state:** Checkmark illustration. "No incomplete transactions."

---

**Section C: Uncategorized Merchants**

Explanation banner (dismissable, shown once): "These merchants don't have a category yet. Categorize them so your spending breakdown is accurate."

List of merchants where category_id is null AND is_p2p = false, sorted by transaction count descending. Each row:
- Merchant display name
- VPA (secondary text)
- Transaction count and total spend: "12 txns, Rs 4,560"
- Category chip: "Uncategorized" (tappable)

**Actions:**
- Tap category chip --> Category Picker (M1). On selection, merchant's category updates. All transactions from this merchant that don't have a user_override get the new category. Row animates out.
- Tap the row --> Merchant Detail (2.4.2)

**Empty state:** Checkmark illustration. "All merchants categorized."

---

**Overall empty state (all three sections at zero):**
- All three segment badges show 0
- Full-screen centered: checkmark illustration
- "You're all caught up!"
- Subtitle: "New items will appear here when AutoTally needs your help."

---

## FLOW 2.4: MERCHANTS TAB

### Screen 2.4.1: Merchant List

**What the user sees:**

**Top area:**
- Search bar: "Search merchants..."
- Filter chips below: "All", "Categorized", "Uncategorized", "P2P"

**Merchant List**
- Sorted alphabetically by default. Each row:
  - Left: category emoji (or grey circle if uncategorized)
  - Merchant display name (bold)
  - VPA below name (secondary text, if available)
  - Right side: total spend amount across all time, and small text "X txns"
  - If P2P: "P2P" chip/badge next to name
- Alphabetical section headers (A, B, C...) with sticky headers for scrolling

**Actions:**
- Tap search: filter list in real-time by merchant name or VPA
- Tap filter chip: filter list
- Tap any merchant row --> Merchant Detail (2.4.2)
- Bottom nav: switch tabs

**Empty state:** "No merchants yet. They'll appear as AutoTally processes your bank SMS."

---

### Screen 2.4.2: Merchant Detail

**What the user sees:**
- Top app bar: back arrow, merchant display name as title, overflow menu (three dots)

**Merchant Info Card**
- Merchant display name (large)
- VPA (if available)
- Category: emoji + name as tappable chip
- P2P toggle: "This is a person, not a shop" -- switch/toggle. When toggled ON, merchant.is_p2p = true, future transactions go to Review queue.
- First seen / Last seen dates
- Total transaction count

**Edit section**
- "Display Name" field: editable inline. Tap to edit, shows the current displayName (or name if no displayName). Save on blur or checkmark.

**Transaction History for this Merchant**
- Section header: "Transactions" with month filter (defaults to all time, can filter by month)
- List of all transactions for this merchant, standard Transaction Row format (C1), sorted by date descending
- Infinite scroll

**Actions:**
- Tap category chip --> Category Picker (M1). Updates merchant's default category. Prompt: "Apply to all [N] transactions from [Merchant]?" with "Yes, update all" / "Only new ones" options.
- Toggle P2P switch: updates merchant.is_p2p. If toggling ON: "Future transactions from [Merchant] will need manual categorization."
- Edit display name: updates merchant.displayName
- Tap any transaction --> Transaction Detail (2.2.2)
- Overflow menu: "View all aliases" (future), "Merge with another merchant" (future, greyed out/hidden for MVP)
- Back arrow --> Merchant List

**Empty state for transactions:** Should not occur -- a merchant only exists if it has at least one transaction.

---

## FLOW 2.5: SETTINGS TAB

### Screen 2.5.1: Settings

**What the user sees:**

Scrollable list of settings groups with section headers:

**Section: App**
- "Theme" -- tap to cycle or show options: "System Default" / "Light" / "Dark". Current selection shown as secondary text.
- "Default Transaction View" -- "Monthly" / "All Time" (controls default filter on Transactions tab)

**Section: Data**
- "Supported Banks" -- tap to see list (Screen 2.5.2). Secondary text: "12 banks"
- "Unsupported Messages" -- tap to see untracked SMS list (Screen 2.5.3). Badge with count if > 0: "[N] messages"
- "Re-scan SMS" -- re-runs the full SMS scan pipeline. Shows confirmation dialog first: "This will re-process all your SMS. Existing transactions won't be duplicated." Useful if user granted permission late or templates were updated.
- "Categories" -- tap to manage categories (Screen 2.5.4)

**Section: Cloud (Future)**
- "Cloud Sync" -- greyed out with "Coming Soon" label. Not tappable.
- "Family Dashboard" -- greyed out with "Coming Soon" label.

**Section: About**
- "Privacy Policy" -- opens privacy policy URL in in-app browser
- "How It Works" -- brief explainer (bottom sheet or new screen) covering: reads bank SMS, parses locally, never sends data
- "App Version" -- "1.0.0" (not tappable)
- "Clear All Data" -- destructive action. Tap shows confirmation dialog: "This will permanently delete all your transaction data, merchants, and categories. This cannot be undone." Two buttons: "Cancel" / "Delete Everything" (red). On confirm: wipe all tables, reset app_config, navigate to onboarding (Screen 1.1).

**Actions:**
- Each row is tappable where described
- No pull-to-refresh on this screen

---

### Screen 2.5.2: Supported Banks

**What the user sees:**
- Top app bar: back arrow, "Supported Banks"
- List of banks with bundled templates. Each row:
  - Bank name (e.g., "HDFC Bank")
  - Number of patterns: "8 patterns"
  - Sender IDs: "HDFCBK, HDFCBN" (secondary text)
- Sorted alphabetically

**Actions:**
- Back arrow --> Settings
- This is a read-only informational screen

---

### Screen 2.5.3: Unsupported Messages

**What the user sees:**
- Top app bar: back arrow, "Unsupported Messages"
- Explanation text at top: "These financial messages couldn't be matched to any supported bank template."
- List grouped by sender. Each group:
  - Sender ID (e.g., "UNIONB") as section header
  - Count of unmatched messages: "14 messages"
  - Tap to expand: shows a few sample SMS bodies (first 3), truncated
- Bottom: "Request Support" button (placeholder for MVP -- shows a toast: "Bank support requests coming soon. Check back after an app update.")

**Actions:**
- Tap sender group: expand to show sample messages
- Tap "Request Support": show toast/snackbar
- Back arrow --> Settings

**Empty state:** "All your bank messages are supported."

---

### Screen 2.5.4: Category Management

**What the user sees:**
- Top app bar: back arrow, "Categories", "+" button (add new)
- List of all categories. Each row:
  - Left: emoji icon on a colored circle (using the category's hex color)
  - Category name
  - Right: transaction count and total spend: "56 txns, Rs 23,400"
  - Default categories have a subtle "Default" label
- Rows are reorderable via drag handles (or this can be deferred for MVP)

**Actions:**
- Tap any category --> Category Edit modal (M3)
- Tap "+" --> Category Create modal (M3, but in create mode)
- Back arrow --> Settings

---

## FLOW 3: MODALS AND OVERLAYS

---

### Modal M1: Category Picker

**Trigger:** Tap on any category chip throughout the app (transaction detail, merchant detail, review tab items, onboarding)

**What the user sees:**
- Bottom sheet, slides up from bottom
- Title: "Choose Category"
- Grid or list of all categories. Each item:
  - Emoji icon on colored circle
  - Category name below/beside icon
  - If one is currently selected, it has a checkmark overlay
- Grid layout preferred (2 or 3 columns) since there are only 10 default categories -- all visible without scrolling
- If user has created custom categories, those appear after defaults
- Bottom: "Manage Categories" text link --> navigates to Category Management (2.5.4), dismissing the picker

**Actions:**
- Tap a category: selects it, bottom sheet dismisses, calling screen updates
- Tap outside the sheet or swipe down: dismiss without selection (no change)
- Tap "Manage Categories": navigate to 2.5.4

---

### Modal M2: Month Picker

**Trigger:** Tap on the month/year text in the month navigation bar (Dashboard, Transactions, Category Detail)

**What the user sees:**
- Bottom sheet or dialog
- Year shown at top with left/right arrows to change year
- Grid of 12 months (Jan-Dec), 3 columns x 4 rows
- Current selection highlighted with accent color fill
- Months in the future are disabled/greyed out
- Months with zero transactions show in normal text. Months with transactions could optionally have a subtle dot indicator (nice-to-have, not required).

**Actions:**
- Tap a month: selects it, picker dismisses, calling screen updates to that month
- Tap year arrows: change year, months re-render
- Tap outside or swipe down: dismiss without change

---

### Modal M3: Category Create / Edit

**Trigger:** Tap "+" on Category Management, or tap an existing category row

**What the user sees:**
- Bottom sheet or full dialog
- Title: "New Category" (create) or "Edit Category" (edit)
- Fields:
  - Name: text input, required
  - Icon: emoji picker or a curated grid of ~30-40 relevant emojis (food, transport, money, health, etc.). Current selection shown prominently.
  - Color: row of 10-12 color swatches. Tap to select. Current selection has a checkmark.
  - Description: optional text input (single line)
- Bottom buttons: "Cancel" / "Save"
- In edit mode for default categories: name field may be editable but show a warning "This is a default category"
- In edit mode: "Delete Category" button (red text, at very bottom). Tap shows confirmation. If category has transactions: "This category has [N] transactions. Reassign them to:" followed by a category picker dropdown, then "Delete & Reassign" button. If no transactions: simple "Delete" confirmation.

**Actions:**
- Fill fields, tap Save: creates or updates category, dismisses modal
- Tap Cancel: dismiss without saving
- Tap Delete: show confirmation/reassignment flow as described

---

### Modal M4: Confirmation Dialog

**Trigger:** Various destructive or important actions (Clear All Data, Delete Category, Apply category to all merchant transactions)

**What the user sees:**
- Standard Material dialog, centered on screen with dimmed background
- Title: action-specific
- Body text: explains what will happen
- Two buttons: "Cancel" (text button) / Action button (filled, red if destructive)

**Actions:**
- Tap action button: execute the action, dismiss
- Tap Cancel or outside: dismiss, no action

---

### Modal M5: Merchant Assignment

**Trigger:** "Assign Merchant" on incomplete transactions (Review tab, Transaction Detail)

**What the user sees:**
- Bottom sheet, taller than category picker (takes ~70% of screen)
- Title: "Assign Merchant"
- Search bar at top: "Search existing merchants..."
- Below search: list of existing merchants matching search query. Each row:
  - Merchant name, VPA, category emoji
  - Tap to select --> assigns this merchant to the transaction, inherits category, sheet dismisses
- Below the list (or when search has no results): "Create New Merchant" button
  - Tap opens inline form within the same sheet:
    - Name: text input (required)
    - Category: category chip (tap opens M1 as a nested picker)
    - "Save & Assign" button
- Also available: "Just assign a category" text link at the bottom -- skips merchant assignment entirely, opens Category Picker (M1). Transaction gets a category but no merchant.

**Actions:**
- Search and tap existing merchant: assign and dismiss
- Create new: fill form, save, assign, dismiss
- "Just assign a category": open category picker, assign category only
- Dismiss: swipe down or tap outside, no changes

---

### Modal M6: Merchant Category Update Prompt

**Trigger:** When user changes a transaction's category on Transaction Detail, and they have now overridden this merchant's transactions 3+ times to the same new category.

**What the user sees:**
- Dialog (not bottom sheet -- this is a decision prompt)
- Title: "Update [Merchant Name]?"
- Body: "You've categorized [Merchant] as [New Category] multiple times. Want to make this the default?"
- "Yes, update default" button: sets merchant.category_id to new category, marks merchant as confirmed
- "No, just this one" button: keeps the override on the single transaction only
- Secondary text: "This will apply to future transactions from this merchant."

**Actions:**
- "Yes": update merchant default, dismiss
- "No": dismiss, transaction override stays but merchant default unchanged

---

## FLOW 4: NOTIFICATION

### Notification N1: New Transaction Detected

**Trigger:** Background SMS listener detects and successfully parses a new bank SMS.

**What the user sees:**
- Standard Android notification
- App icon: AutoTally icon
- Title: "Spent Rs 450 at Swiggy" (debit) or "Received Rs 15,000 from SALARY" (credit)
- Body: "Food -- HDFC Bank xx1234" (category -- bank account)
- If uncategorized: Body shows "Uncategorized -- HDFC Bank xx1234"
- If P2P: Title "Sent Rs 2,000 to 9876543210" Body "P2P -- needs categorization"
- If incomplete (no merchant): Title "Spent Rs 3,400" Body "Unknown merchant -- tap to assign"

**Actions:**
- Tap notification: opens app to Transaction Detail (2.2.2) for that specific transaction
- If P2P or incomplete: tap opens the transaction in context within Review tab

**Notification for unmatched SMS (no template):**
- Not shown. Unmatched SMS are silently queued. User discovers them in Settings > Unsupported Messages. No notification noise for things the app can't act on.

---

## COMPONENT DEFINITIONS (Reusable)

### Component C1: Transaction Row

Used in: Transaction List, Category Detail, Merchant Detail transaction history, Review tab items

**Layout:**
- Left: category emoji on small colored circle (using category hex color). If uncategorized: grey circle with "?"
- Center (takes remaining space):
  - Line 1: Merchant display name (bold, single line, truncate with ellipsis). If no merchant: "Unknown Merchant" in muted italic.
  - Line 2: Category name + date, separated by a dot. E.g., "Food . 15 Mar". If uncategorized: "Uncategorized . 15 Mar"
- Right:
  - Amount: "Rs 1,234" in red (debit) or "+ Rs 15,000" in green (credit)
  - Credits prefixed with "+"

**Tap behavior:** Always navigates to Transaction Detail (2.2.2)

---

### Component C2: Month Navigation Bar

Used in: Dashboard, Transactions tab, Category Detail

**Layout:**
- Centered text: "March 2026" (month name + year)
- Left arrow icon button (tappable for previous month)
- Right arrow icon button (tappable for next month, disabled if current month)
- Tap on the text itself: opens Month Picker (M2)
- Swipe gesture on the parent content area also triggers month change

---

### Component C3: Filter Chip Row

Used in: Transactions tab, Merchant list

**Layout:**
- Horizontal scrollable row of chips
- First chip is always "All" (resets other filters)
- Active chips: filled background with accent color, white text
- Inactive chips: outline/ghost style
- Chips don't wrap -- single row, horizontally scrollable

---

## SCREEN MAP SUMMARY

```
ONBOARDING
  1.1  Welcome
  1.2  SMS Permission
  1.2a   Permission Denied (error variant of 1.2)
  1.3  SMS Scan Progress
  1.4  Scan Summary
  1.5  Merchant Categorization

MAIN APP (Bottom Nav)
  Tab 1: Dashboard
    2.1.1  Dashboard (month summary, category chart, top merchants)
    2.1.2  Category Detail (transactions in one category)
  Tab 2: Transactions
    2.2.1  Transaction List (search, filters, month nav)
    2.2.2  Transaction Detail (full detail, edit category, view raw SMS)
  Tab 3: Review
    2.3.1  Review Inbox (3 segments: P2P, Incomplete, Merchants)
  Tab 4: Merchants
    2.4.1  Merchant List (search, filters)
    2.4.2  Merchant Detail (info, edit, transactions)
  Tab 5: Settings
    2.5.1  Settings (all options)
    2.5.2  Supported Banks (read-only list)
    2.5.3  Unsupported Messages (grouped by sender)
    2.5.4  Category Management (CRUD)

MODALS
  M1  Category Picker (bottom sheet, grid)
  M2  Month Picker (bottom sheet, year + month grid)
  M3  Category Create/Edit (bottom sheet, form)
  M4  Confirmation Dialog (centered dialog)
  M5  Merchant Assignment (bottom sheet, search + create)
  M6  Merchant Category Update Prompt (dialog)

NOTIFICATION
  N1  New Transaction Detected

REUSABLE COMPONENTS
  C1  Transaction Row
  C2  Month Navigation Bar
  C3  Filter Chip Row
```

Total unique screens: 16
Total modals/overlays: 6
Total reusable components: 3
