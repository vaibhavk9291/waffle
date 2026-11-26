# Shrimant Street Food UI Design System

Reference: the two Shrimant menu cards (deep purple, glossy chocolate, bright yellow accents) and the dark chocolate cupcake app (rounded product cards, circular "+" buttons, pill stat chips). Dark theme only. The logo (white to yellow gradient) is built for dark backgrounds, so the whole app is dark.

## 1. Mood
Rich, glossy, indulgent. Deep plum and chocolate backgrounds, yellow highlights, rounded cards with soft glow. Menu-board energy but clean and readable for fast one-handed use at a counter.

## 2. Color tokens

| Token | Hex | Use |
|---|---|---|
| bgTop | #3A1250 | Top of screen gradient (plum) |
| bgBottom | #150820 | Bottom of screen gradient (near black plum) |
| surface | #2A1238 | Cards |
| surfaceHigh | #3A1B4D | Raised cards, inputs, sheets |
| chocolate | #4A2519 | Chocolate-section accent surface |
| waffleGold | #C98A2B | Waffle-section accent |
| primary | #FFD21F | Main accent: buttons, active states, prices (menu-card yellow) |
| primaryDark | #F2B600 | Gradient end for yellow buttons |
| onPrimary | #2A0F3A | Text/icons on yellow |
| accentPurple | #7B2CBF | Secondary accent, chips, selected tab |
| textPrimary | #FFFFFF | Titles, prices on dark |
| textSecondary | #BFA9CC | Subtitles, captions |
| success | #3DDC84 | Live dot, positive values |
| danger | #FF5C7A | Expenses, negative values, destructive actions |
| hairline | #FFFFFF at 8% | Rare dividers |

Gradients:
- Screen background: vertical, bgTop to bgBottom.
- Primary button / hero card: diagonal, primary to primaryDark. Text on it is onPrimary.
- Chocolate Bowl section tile: diagonal #5A2D1D to #2E140E.
- Waffle section tile: diagonal #B8742A to #5A3410.

## 3. Typography
- Latin and numbers: **Plus Jakarta Sans** (google_fonts).
- Marathi text if ever shown: **Noto Sans Devanagari**.
- Display accent (screen titles only, sparingly): **Pacifico** or **Lobster**, echoing the brush-script menu titles ("Waffle Menu", "Chocolate Bowl Menu").

| Style | Size / Weight | Use |
|---|---|---|
| displayPrice | 34 / 800 | Hero revenue |
| title | 22 / 700 | Screen titles |
| sectionTitle | 18 / 700 | Section headers |
| cardTitle | 16 / 700 | Product names |
| body | 14 / 500 | General text |
| caption | 12 / 500, textSecondary | Labels, units |
| button | 16 / 700 | Buttons |

Prices use the ₹ symbol, no decimals, bold.

## 4. Shape, spacing, elevation
- Screen horizontal padding: 20. Spacing scale: 4, 8, 12, 16, 20, 24, 32.
- Card radius 24. Pill radius 28 (height 56). Thumbnail radius 20. Bottom sheet top radius 32.
- Circular icon button 44x44, surfaceHigh, radius 22.
- Shadows on dark: card glow color #000 at 35%, blur 24, offset (0, 10). Primary button glow: #FFD21F at 30%, blur 20, offset (0, 8).
- No hard borders. Optional 1px hairline only.
- Minimum tap target 48x48 everywhere.

## 5. Components

**Section tile (home)**: two large tiles side by side or stacked, radius 28, section gradient, white title, item count caption, large decorative icon or image at the right, chevron. Tapping opens that section's product list.

**Product row card**: surface card, radius 24, padding 12. Left: 72x72 rounded thumbnail on a tinted square. Middle: name (cardTitle), "₹70 each" caption in primary yellow, "Today: ₹X" caption in textSecondary. Right: stepper.

**Quantity stepper**: [ - ] count [ + ]. Minus is a 40px circle in surfaceHigh with white icon. Plus is a 40px yellow gradient circle with onPrimary icon. At 0, minus is disabled (30% opacity). Count 16 / 700.

**Hero summary card**: full width, radius 28, yellow gradient, onPrimary text. Shows "Today's Sales" caption, revenue in displayPrice, then a row of three mini stats: Items, Expenses, Net. Decorative translucent circle top right.

**Primary button**: yellow gradient, onPrimary bold text, pill, glow. **Secondary button**: surfaceHigh, white text, pill. **Destructive**: danger text on surfaceHigh.

**Bill / cart bar (billing)**: floating bar above the nav showing "N items | ₹Total" with a yellow "Checkout" pill, appears when the current bill has items.

**Bill sheet**: surfaceHigh bottom sheet, top radius 32, item rows (name, qty x price, line total), subtotal, optional discount (danger), grand total in bold yellow, buttons "Save bill" and "Print".

**Expense sheet**: bottom sheet with a note field, an amount field (numeric keypad, ₹ prefix), and a yellow "Add expense" pill. Expense rows show note, time, and amount in danger with a delete icon.

**Floating bottom navigation**: floating pill, surfaceHigh, radius 36, margins 40 / 16. Items: Home, Bills, History, Settings. Active item has a yellow circle with onPrimary icon; inactive are textSecondary outline icons.

**Live chip**: small pill, 8px dot (success = Live, grey = Offline) with pending count.

**Header**: logo (assets/branding/logo_shrimant.png, height 40) on the left or centered on Login, greeting caption plus display name, live chip and logout circular button on the right.

## 6. Screens

**Login**: gradient background, logo centered large, "Welcome back", two rounded input fields (surfaceHigh, radius 28, no border), yellow pill "Sign in".

**Home**: header, hero summary card, section title "Menu", the two section tiles (Chocolate Bowl, Waffle), then a "Today's expenses" row card with an "Add expense" pill. Space at the bottom for the floating nav and bill bar.

**Section product list**: back button, section title in the display font, a list of product row cards for that section only (Chocolate Bowl or Waffle), steppers add to the current bill and to today's sales. The bill bar stays visible.

**History**: pill date selector, 7-day revenue bar chart (yellow gradient bars, today highlighted), week and month chips, list of day cards. Tapping a day opens a summary sheet: per-section totals, per-product breakdown, expenses list, gross, expenses, net.

## 7. Motion
- Tap on + / -: scale 0.92 and back over 120 ms with light haptic.
- Count change: AnimatedSwitcher slide + fade 180 ms. Hero revenue: count-up 300 ms.
- Screen transitions: fade + slight upward slide 250 ms. Section tile to list: Hero transition on the tile.
- Loading: shimmer skeletons in plum tones.

## 8. Imagery
Product thumbnails on tinted rounded squares. Use assets/products/ with one image per product (file names in the build prompt). Until real photos exist, use a simple bowl or waffle icon on the tinted square. Keep the slots so photos can be dropped in without code changes.

## 9. Rules
- Dark theme only. Material 3 base with every component overridden by these tokens.
- No default Material blue or purple. No pure black backgrounds (use the plum gradient).
- All tokens live in core/theme (colors.dart, gradients.dart, text_styles.dart, theme.dart). No hardcoded colors or sizes in widgets.
