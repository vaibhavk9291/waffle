# Shrimant Street Food: Build Instructions for Anti Gravity (5 phases)

App: **Shrimant** (Shrimant Street Food), a billing, daily sales and expense app for a Chocolate Bowl and Waffle shop.
Stack: Flutter + Supabase (Auth, Postgres, Realtime). 4 individual logins created manually in Supabase. Business date = IST calendar date. Shop hours 12:00 PM to 11:30 PM.
Design: DESIGN.md is the single source of truth for the UI. Put it at `docs/DESIGN.md` and attach it to every phase.

## Project setup (do this once, before Phase 1)

Folder and asset layout the prompts assume:

```
shrimant/
  docs/DESIGN.md
  assets/branding/logo_shrimant.png      (transparent logo, from the crop)
  assets/branding/app_icon_1024.png      (square icon, dark plum background)
  assets/products/                       (one image per product, see list below)
  supabase/migrations/
  lib/core/ lib/features/
```

Product image slots (all optional, placeholders are used until you add them):
`choc_dark.png, choc_milk.png, choc_kitkat.png, choc_double.png, choc_white.png, choc_triple.png, choc_oreo.png, choc_biscoff.png, choc_strawberry.png, waffle_dark.png, waffle_milk.png, waffle_kitkat.png, waffle_double.png, waffle_white.png, waffle_triple.png, waffle_oreo.png, waffle_biscoff.png, waffle_icecream.png, waffle_pista.png, waffle_chocolate_ic.png, waffle_kesar_kulfi.png, waffle_strawberry_ic.png`

## Menu data (seed exactly this, prices in INR)

Section 1: **Chocolate Bowl**
| Product | Price |
|---|---|
| Dark Chocolate Bowl | 70 |
| Milk Chocolate Bowl | 80 |
| Kit Kat Bowl | 90 |
| Double Chocolate Bowl | 80 |
| White Chocolate Bowl | 100 |
| Triple Chocolate Bowl | 110 |
| Oreo Bowl | 90 |
| Biscoff Biscuit Bowl | 110 |
| Strawberry Chocolate Bowl (NEW badge) | 110 |

Section 2: **Waffle**
| Product | Price |
|---|---|
| Dark Waffle | 60 |
| Milk Waffle | 70 |
| Kitkat Waffle | 80 |
| Double Chocolate Waffle | 70 |
| White Waffle | 90 |
| Triple Chocolate Waffle | 100 |
| Oreo Waffle | 80 |
| Biscoff Waffle | 100 |
| Waffle with Ice Cream | 110 |

Waffle sub-group "Waffle with Ice Cream Flavors" (shown under the Waffle list)
| Product | Price |
|---|---|
| Waffle with Pista Ice Cream | 105 |
| Waffle with Chocolate Ice Cream | 110 |
| Waffle with Kesar Kulfi Ice Cream | 110 |
| Waffle with Strawberry Ice Cream | 110 |

---

## Phase 1: Supabase backend

```
You are a senior backend engineer. Set up the Supabase backend for "Shrimant", a billing, daily sales and expense app for a chocolate bowl and waffle shop.

Write supabase/migrations/001_init.sql that creates:

1. `sections`: id (uuid pk), name, sort_order. Seed: "Chocolate Bowl", "Waffle".
2. `products`: id (uuid pk), section_id (fk), sub_group (text, nullable, e.g. "Waffle with Ice Cream Flavors"), name, price (integer), sort_order, is_active (default true), is_new (default false), image_key (text, nullable). Seed all products from the menu data in the attached build-prompts file exactly, with the Strawberry Chocolate Bowl marked is_new = true.
3. `profiles`: id (uuid pk, references auth.users), display_name, role ('staff' or 'owner', default 'staff').
4. `bills`: id (uuid pk), bill_no (integer), business_date (date default (now() at time zone 'Asia/Kolkata')::date), subtotal (integer), discount (integer default 0), total (integer), payment_mode ('cash' or 'upi', default 'cash'), status ('paid' or 'void', default 'paid'), void_reason (nullable), created_by (uuid default auth.uid()), created_at (timestamptz default now()), voided_by, voided_at. Unique (business_date, bill_no). A trigger assigns bill_no as the next number for that business_date (safe under concurrent inserts; use an advisory lock or a counter table).
5. `bill_items`: id (uuid pk), bill_id (fk on delete cascade), product_id (fk), product_name (copied at insert), unit_price (copied at insert), qty (integer > 0), line_total (integer).
6. `expenses`: id (uuid pk), business_date (date default IST today), note (text, not null), amount (integer, > 0), created_by (uuid default auth.uid()), created_at, is_deleted (default false), deleted_by, deleted_at.
7. `shop_settings` (single row): shop_name (default "Shrimant Street Food"), address, phone, gstin (nullable), receipt_footer (default "Thank you! Visit again."), paper_width_mm (58 or 80, default 58).
8. Views:
   - `daily_totals` (business_date, bills_count, items_sold, gross_revenue, total_discount, expenses_total, net) computed from paid bills and non-deleted expenses.
   - `daily_product_summary` (business_date, section_name, product_id, product_name, units_sold, revenue) from bill_items of paid bills.
   - `daily_section_totals` (business_date, section_name, units_sold, revenue).
9. A function `create_bill(items jsonb, discount int, payment_mode text)` that inserts the bill and its items in one transaction, recomputes prices from the `products` table on the server (never trust client prices), and returns the bill with its items.
10. Row Level Security:
    - Authenticated users can select everything and call create_bill, insert into expenses.
    - Staff cannot update or delete bills or bill_items directly. Voiding a bill is done through a function `void_bill(bill_id, reason)` allowed for role = 'owner' only.
    - Expenses: staff can insert; only owner can soft-delete (is_deleted = true) through a function `delete_expense(id)`.
    - Only owner can update products, sections and shop_settings.
11. Enable Realtime on `bills`, `bill_items` and `expenses`.

Auth: email/password, public signup disabled, 4 users created manually. Include steps to insert their profiles and mark one as 'owner'.

Output: the full SQL, a dashboard checklist (disable signups, create 4 users, insert profiles, enable realtime), and 6 test queries (a bill with 3 items, discount handling, two bills on the same day get sequential numbers, void changes totals, expense changes net, staff cannot void).
```

---

## Phase 2: Flutter foundation, theme, login, home with two sections

```
You are a senior Flutter engineer. Create the Flutter app "Shrimant" (a billing, sales and expense app for a chocolate bowl and waffle shop).

Stack: Flutter (latest stable), supabase_flutter, flutter_riverpod, go_router, google_fonts, intl, shimmer. Feature-first folders: core/ (theme, config, utils, widgets), features/auth, features/menu, features/billing, features/expenses, features/history, features/settings.

IMPORTANT: docs/DESIGN.md is the single source of truth for the UI. Reproduce it exactly: plum gradient background, yellow accent, glossy rounded cards, circular steppers, the yellow hero card, the floating pill nav. Dark theme only. All colors, gradients, text styles, radii and shadows go in core/theme as tokens and widgets use only those tokens. No hardcoded values.

Backend (already built in Phase 1): tables sections, products, profiles, bills, bill_items, expenses, shop_settings; views daily_totals, daily_product_summary, daily_section_totals; functions create_bill, void_bill, delete_expense.

Build:
1. Supabase init with environment config via --dart-define (SUPABASE_URL, SUPABASE_ANON_KEY), no hardcoded keys, persisted session, and a `.env.example`.
2. Login screen per DESIGN.md using assets/branding/logo_shrimant.png. Auto redirect when signed in. Load the profile (display_name, role).
3. Home screen:
   - Header: logo, greeting with display name, live chip placeholder, logout circular button.
   - Hero card: today's gross revenue, bills count, items sold, expenses, net (from daily_totals).
   - Section title "Menu" and TWO large section tiles: "Chocolate Bowl" and "Waffle" (gradients and layout from DESIGN.md, item counts from the products table).
   - "Today's expenses" row card with an "Add expense" button (wired in Phase 3, show a stub for now).
4. Section product list screen: tapping a tile opens only that section's products. Waffle shows its "Waffle with Ice Cream Flavors" sub-group under a sub-header. Each product is a product row card with thumbnail (from assets/products using image_key, placeholder icon if missing), name, "₹X each", NEW badge where is_new, and the stepper. A "+" tap adds the item to the CURRENT BILL (in-memory cart held in a Riverpod provider that survives navigation between the two sections). A "-" removes one. Haptic feedback and the tap animation from DESIGN.md.
5. A floating bill bar above the nav showing "N items | ₹Total" and a "Checkout" button (checkout is built in Phase 3, show a stub).
6. Floating bottom nav: Home | Bills | History | Settings (Bills, History, Settings are placeholders for now).

Rules: small reusable widgets, loading and error states, ₹ formatting with no decimals, tap targets at least 48x48, products and prices always read from Supabase (never hardcoded in Dart).

Output complete code for every file, pubspec.yaml (assets, fonts), and run instructions.
```

---

## Phase 3: Billing, expenses, realtime

```
Continue the Flutter app "Shrimant". Phase 2 is complete. Follow DESIGN.md for every new UI element.

1. Checkout: tapping "Checkout" opens the bill sheet: item rows (name, qty x price, line total), subtotal, optional discount (rupees, numeric), payment mode toggle (Cash | UPI), grand total, buttons "Save bill" and "Save & print" (print wiring comes in Phase 4, stub for now). "Save bill" calls the create_bill function, shows a success state with the bill number, clears the cart, and revenue updates. Prices are recalculated by the server.
2. Bills screen: today's bills list (bill no, time, items count, total, payment mode, status). Tap to view details. Void is owner-only (Phase 5), staff see a read-only view.
3. Expenses: "Add expense" opens the expense sheet from DESIGN.md with a Note field (required, e.g. "Milk packets", "Chocolate stock", "Gas"), an Amount field (numeric, ₹ prefix, required, greater than 0) and a yellow "Add expense" button. Saved expenses insert into `expenses`. Show today's expenses list on Home (note, time, who added it, amount in danger color). The hero card Net = gross revenue minus expenses, and updates immediately.
4. Realtime: subscribe to bills, bill_items and expenses. When any of the 4 users' devices saves a bill or expense, every open device updates the hero card, bills list and expenses list within about a second without refresh. Show the Live / Offline chip in the header.
5. Offline safety: if offline when saving a bill or expense, store it in a persisted local queue, show a "pending sync" count on the chip, and sync in order when the connection returns. A queued bill must not be lost or duplicated (use a client-generated idempotency key).
6. Date rollover: if the app stays open past midnight IST, switch to the new business date automatically.
7. Validation and safety: block checkout on an empty cart, block a discount larger than the subtotal, confirm before clearing a non-empty cart.

Provide updated code for changed files only, plus a manual test plan for 3 devices.
```

---

## Phase 4: Printing, history and reports

```
Continue the Flutter app "Shrimant". Phases 2 and 3 are complete. Follow DESIGN.md.

1. Receipt printing (print billing):
   - Support Bluetooth thermal printers (58mm and 80mm ESC/POS) using print_bluetooth_thermal and esc_pos_utils_plus (or the most maintained equivalents). Settings screen: scan, pick and save the default printer, paper width, and a "Test print" button.
   - Receipt layout: shop name (from shop_settings), address, phone, optional GSTIN, bill number, date and time, cashier name, item lines (name, qty x price, line total), subtotal, discount, grand total, payment mode, footer text. Plain text; the Devanagari logo is not printed.
   - "Save & print" on checkout prints right after saving. A "Reprint" button on every bill in the Bills screen.
   - Fallback when no Bluetooth printer is connected: generate a PDF receipt with the `printing` package so it can be shared or printed over the system print dialog.
   - Handle Bluetooth permissions for Android 12 and above. If printing fails, the bill is still saved and the user sees a clear retry option.
2. History screen: pill date selector, 7-day net revenue bar chart (yellow gradient bars, today highlighted), week and month summary chips, and day cards (date, bills, revenue, expenses, net) for the last 30 days. Tapping a day opens the summary sheet with: per-section totals (Chocolate Bowl, Waffle), per-product breakdown (units and revenue), expenses list, then gross, expenses and net.
3. Share: "Share today's report" sends a plain-text daily report (date, per-section totals, per-product units and revenue, discounts, expenses with notes, gross, net) via the system share sheet, for example to WhatsApp.
4. Polish: empty states, plum-toned shimmer skeletons, pull to refresh, consistent animations, tablet-safe layout, large-text accessibility.

Output changed code, printer setup notes (including a note on which Bluetooth printers were considered), and a test checklist.
```

---

## Phase 5: Owner layer, branding, release

```
Continue the Flutter app "Shrimant". Phases 2 to 4 are complete. Follow DESIGN.md.

1. Owner-only hidden layer: visible only to users whose profile role = 'owner'. It is not shown in the nav; owners open it by long-pressing the logo in the Home header, then it asks for a 4-digit owner PIN (stored hashed locally, set on first use). Inside:
   - Void a bill (reason required, uses void_bill).
   - Delete an expense (uses delete_expense, soft delete, keeps an audit trail).
   - Edit product names, prices, active/inactive and the NEW badge; reorder products. Price changes apply to new bills only, old bills keep their stored prices.
   - Edit shop_settings (name, address, phone, GSTIN, footer, paper width).
   - Full report export for a date range as CSV (bills, items, expenses).
   - An audit list of voids and deleted expenses (who and when).
2. Branding: use assets/branding/logo_shrimant.png on Login and Home. Create the app icon from assets/branding/app_icon_1024.png with flutter_launcher_icons (Android adaptive icon, background #2B0F3A). Create the splash with flutter_native_splash using the plum gradient background and the centered logo. App display name "Shrimant".
3. Release: Android release signing steps, building an APK for the shop phones, a Supabase production checklist (backups, RLS verification, key handling, confirm signups are disabled, confirm the service_role key is never in the app), and a final QA checklist covering billing totals, printing, realtime on 3 devices, offline queue, expenses and the owner layer.

Output changed code, release steps and the QA checklist.
```
