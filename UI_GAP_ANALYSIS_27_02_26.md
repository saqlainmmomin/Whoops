# UI Gap Analysis: Current App vs Design Reference

**Date**: 27 Feb 2026  
**Scope**: Comparing current Whoops app screenshots (`Whoops UI 27_02_26/`) against the design reference images (`Design Reference Guide/`) and `DESIGN_SPEC.md`.  
**Device**: Apple Watch Series 5 (hardware constraint noted)

> [!NOTE]
> This document identifies **every visual gap** between the current implementation and the reference design. The goal is pixel-perfect replication — no improvements, no design changes. Features not supported by Apple Watch Series 5 hardware are noted separately.

---

## Summary

| Category | Gaps Found |
|----------|-----------|
| 🔴 Critical (layout/structure wrong) | 10 |
| 🟡 Moderate (visual mismatch) | 12 |
| 🔵 Minor (small styling differences) | 8 |
| **Total** | **30** |

---

## Overview Tab

### Current UI
The current Overview tab shows:
- DualGaugeHero with "W" logo centered, Recovery % on left, Strain value on right
- HRV and Sleep values below the ring
- BaselineInfoCard with progress bar (0/28 days)
- Alarm row
- "TODAY'S ACTIVITIES" + "START ACTIVITY" header  
- Key Statistics section with HRV, Sleep Performance, Calories

### Reference Design (Overview 1, Overview 2, Overview 3)
The reference shows the same general layout but with significant differences in detail.

---

#### Gap O-1 🔴 DualGaugeHero — Missing Strain Arc on Ring

| | Detail |
|---|---|
| **Reference** | Overview 1 shows a **dual-arc ring**: a yellow/gold arc for Recovery AND a blue arc for Strain **overlaid on the same ring** |
| **Current** | The ring only shows a gray/dark track with no visible colored arcs (Recovery or Strain). This is likely because the user has 0% recovery and 0.0 strain, so no colored arc fills are drawn. However, the ring track styling itself also appears different |
| **Action** | Ensure the gauge renders both a yellow Recovery arc AND a blue Strain arc. When values are 0, the ring should still show the track outline matching the reference's dark gray track style |

---

#### Gap O-2 🔴 DualGaugeHero — Ring Size Too Small

| | Detail |
|---|---|
| **Reference** | The hero gauge in Overview 1 is very large, ~200pt diameter per spec, dominating the upper section |
| **Current** | The ring appears smaller relative to the screen (~140pt), with more whitespace around it |
| **Action** | Increase `heroGaugeDiameter` to 200pt as specified in `DESIGN_SPEC.md` §3.1 |

---

#### Gap O-3 🟡 DualGaugeHero — Missing Share Icon (Top Right)

| | Detail |
|---|---|
| **Reference** | Overview 1 shows a share/export icon (square with arrow) in the top-right area above the gauge |
| **Current** | No share icon is visible in the Overview hero area |
| **Action** | Add share icon near the gauge matching reference placement |

---

#### Gap O-4 🟡 BaselineInfoCard — Missing Whoop Band Image

| | Detail |
|---|---|
| **Reference** | Overview 1 shows the BaselineInfoCard with a **WHOOP band product image** on the right side and a checkmark badge ("✓4") |
| **Current** | The card shows only text + progress bar + "WATCH THE VIDEO →" link, no band image or checkmark badge |
| **Action** | Add the WHOOP band illustration and progress badge to match reference |

---

#### Gap O-5 🔴 Missing "Talk to your WHOOP Coach" Bar

| | Detail |
|---|---|
| **Reference** | Overview 1 shows a "Talk to your WHOOP Coach" bar with a W logo icon, positioned between the BaselineInfoCard and the Alarm row |
| **Current** | This component does not exist in the current UI |
| **Action** | Add the WHOOP Coach chat prompt bar component |

---

#### Gap O-6 🟡 Key Statistics — Missing "VS. PREVIOUS 30 DAYS" Right Label

| | Detail |
|---|---|
| **Reference** | Overview 2 shows "KEY STATISTICS" on the left and "CUSTOMIZE ✏️" on the right (this is present), but the statistics section itself does not show a "VS. PREVIOUS 30 DAYS" label like the dedicated tab stats sections |
| **Current** | Shows "KEY STATISTICS" and "CUSTOMIZE /" — close match, but the pen/edit icon style differs slightly |
| **Action** | Minor — verify icon style matches reference |

---

#### Gap O-7 🟡 Key Statistics Rows — Missing Baseline Values

| | Detail |
|---|---|
| **Reference** | Overview 2 shows each stat row with: icon + label on left, large value + trend arrow + **baseline value below** on right (e.g., HRV: 40, baseline: 35) |
| **Current** | Shows icon + label + value but no baseline comparison value below the main value, no trend arrows |
| **Action** | Add baseline values and trend arrows to statistics rows in Overview |

---

#### Gap O-8 🟡 Overview — Missing "Journal" Card

| | Detail |
|---|---|
| **Reference** | Overview 2 shows a "Fill out your Journal" card with a background image (person wearing WHOOP), a clipboard icon, description text, and a chevron `>` |
| **Current** | No journal card is visible in the current UI |
| **Action** | Add Journal promotion card below activities section |

---

#### Gap O-9 🟡 Key Statistics — Missing "HOURS OF SLEEP" Row

| | Detail |
|---|---|
| **Reference** | Overview 2 shows 4 statistics: HRV, SLEEP PERFORMANCE, CALORIES, HOURS OF SLEEP (partially visible) |
| **Current** | Shows only 3 statistics: HRV, SLEEP PERFORMANCE, CALORIES |
| **Action** | Add HOURS OF SLEEP as a 4th statistic row |

---

#### Gap O-10 🔵 Bottom Navigation Tab Bar

| | Detail |
|---|---|
| **Reference** | Overview 1 shows a bottom tab bar with: Home, Plan (W icon), Community (people icon), More (hamburger). Also has a floating "+" button |
| **Current** | Shows only: Home (house icon), Profile (dots). Much simpler navigation |
| **Action** | The reference app (WHOOP phone app) has a 4-tab navigation bar. Our Watch app has a simplified 2-tab bar. This is an expected hardware difference (Apple Watch has simpler navigation). **Mark as N/A for Watch** |

---

## Sleep Tab

### Current UI
- "SLEEP PERFORMANCE" as two-line header
- Large "0%" in teal color (no gauge)
- SHARE button
- Two comparison boxes: Hours of Sleep (--) and Sleep Needed (7:30)
- SLEEP STATISTICS with VS. PREVIOUS 30 DAYS
- Statistics: Time in Bed, Consistency, Restorative %, Sleep Debt
- Scrolled view shows: VS. LAST 7 DAYS, Sleep Performance chart, Hours vs Need chart, Time in Bed chart (all empty)

### Reference Design (Sleep 1, Sleep 2, Sleep 3, Sleep 4)
Features a dashed gauge, different layout for comparison boxes, tip cards, chat bar, and more detailed charts.

---

#### Gap S-1 🔴 Sleep Hero — Missing Dashed Gauge Ring

| | Detail |
|---|---|
| **Reference** | Sleep 1 shows the 66% value inside a **dashed circular gauge ring** made of small dashes/dots forming a broken circle |
| **Current** | Shows only plain text "0%" with no gauge ring around it at all |
| **Action** | Use the existing `DashedGauge` component (which already exists in the codebase at `Views/Components/DashedGauge.swift`) to wrap the sleep performance value |

---

#### Gap S-2 🟡 Sleep Hero — "SLEEP PERFORMANCE" Label Placement

| | Detail |
|---|---|
| **Reference** | Sleep 1 shows "SLEEP PERFORMANCE" as a **single block** of two lines centered above the percentage value, both inside/above the gauge area. The text is centered |
| **Current** | Shows "SLEEP" and "PERFORMANCE" as two separate lines, positioned outside of any gauge area. Layout appears correct structurally but visually the text is floating without the gauge context |
| **Action** | When the DashedGauge is added, ensure "SLEEP PERFORMANCE" label is positioned inside/above the gauge value area |

---

#### Gap S-3 🟡 Sleep Comparison Boxes — Layout Mismatch

| | Detail |
|---|---|
| **Reference** | Sleep 1 shows two large boxes side-by-side: "5:51" HOURS OF SLEEP (white text, rounded outlined box) and "8:52" SLEEP NEEDED (teal text, teal outlined box). The values are VERY large (~48pt), labels below in capsule-outlined badges |
| **Current** | Shows two boxes but they're smaller. "Hours of Sleep" shows "--" (no data), "Sleep Needed" shows "7:30" in teal. The label text is inside the boxes, not in outlined capsule badges below |
| **Action** | Increase value font size. Change label presentation to match outlined capsule badge style below the value |

---

#### Gap S-4 🔴 Missing Tip Card ("Try to get more sleep")

| | Detail |
|---|---|
| **Reference** | Sleep 1 shows a tip section: "Try to get more sleep" as a bold title, followed by descriptive text about sleep importance |
| **Current** | No tip card/section is visible in the Sleep tab |
| **Action** | Add TipCard component to Sleep tab layout |

---

#### Gap S-5 🔴 Missing "Chat to learn about Sleep" Bar

| | Detail |
|---|---|
| **Reference** | Sleep 1 shows a "Chat to learn about Sleep" bar with W logo, positioned below the tip text |
| **Current** | Not present |
| **Action** | Add WHOOP Coach chat prompt bar to Sleep tab |

---

#### Gap S-6 🟡 Missing "SLEEP ACTIVITIES" Section Header

| | Detail |
|---|---|
| **Reference** | Sleep 2 shows "SLEEP ACTIVITIES" as a section header above the sleep activity row |
| **Current** | No sleep activities section is visible in the current Sleep tab screenshots |
| **Action** | Add SLEEP ACTIVITIES section with activity rows |

---

#### Gap S-7 🟡 Sleep Activity Row — Shows Time as Duration Badge

| | Detail |
|---|---|
| **Reference** | Sleep 1/2 show activity row: moon icon + "5:51" in a light blue rounded badge, "SLEEP" label, and time range "4:47 AM / [Sun] 10:12 PM" with a blue vertical bar |
| **Current** | Not visible in current screenshots |
| **Action** | Implement sleep activity row matching reference layout |

---

#### Gap S-8 🟡 Statistics Rows — Missing Trend Arrows and Baseline Values

| | Detail |
|---|---|
| **Reference** | Sleep 2 shows statistics rows with: icon + label + value + trend arrow (colored ▲▼) + baseline value below |
| **Current** | Shows icon + label + value, but baseline values show as 0 and no trend arrows visible (likely because data is 0) |
| **Action** | Verify that trend arrows and baselines render correctly when data is populated. Currently appears correct structurally |

---

#### Gap S-9 🟡 "What is Sleep Performance?" Card — Missing Background Image

| | Detail |
|---|---|
| **Reference** | Sleep 2/3 shows the "What is Sleep Performance?" card with a **background screenshot/image** of the sleep performance graph, and a gradient border (teal to purple). Also shows a moon icon on the left |
| **Current** | The card text "What is Sleep Performance?" is visible but cut off at the bottom. Cannot confirm if it has the background image or gradient border from the screenshots |
| **Action** | Ensure the WhatIsInfoCard includes the background image and gradient border matching reference |

---

#### Gap S-10 🟡 Chart Cards — Icon + Title + Chevron Header Format

| | Detail |
|---|---|
| **Reference** | Sleep 3 shows chart cards with: icon + "SLEEP PERFORMANCE" title + chevron `>` on right, all as a tappable header. Same pattern for "HOURS VS. NEED" and "TIME IN BED" |
| **Current** | Shows "Sleep Performance", "Hours vs Need", "Time in Bed" as plain text labels without icons or chevrons |
| **Action** | Add icon + uppercase title + chevron header to all chart cards |

---

#### Gap S-11 🔴 Chart Day Labels — Single Letter vs Two-Line Format

| | Detail |
|---|---|
| **Reference** | Sleep 3/4, Strain 3/4, Recovery 3/4 all show day labels as **two lines**: day name + date number (e.g., "Tue\n12", "Mon\n18"). The "today" column has a darker background highlight |
| **Current** | The chart area appears empty (no data), so labels are not fully visible, but chart code likely uses single-letter labels ("M", "T", "W") based on previous audit |
| **Action** | Change chart x-axis labels from single-letter to two-line "DayName\nDate" format. Add "today" column background highlight |

---

#### Gap S-12 🔵 Sleep Performance Bar Color

| | Detail |
|---|---|
| **Reference** | Sleep 3 shows sleep performance bars in a **light blue/teal** color |
| **Current** | Not visible (no data), but should match teal color per reference |
| **Action** | Verify bar color matches reference teal when data is available |

---

## Recovery Tab

### Current UI
- "RECOVERY" header with (i) info button
- Large circular gauge with "0%" inside (gray ring track)
- SHARE button
- MessageCard: "Low Recovery" with yellow accent bar
- RECOVERY STATISTICS VS. PREVIOUS 30 DAYS
- Statistics: HRV (0ms), RESTING HEART RATE (0 bpm), RESPIRATORY RATE (N/A), SLEEP PERFORMANCE (0%)
- Scrolled view: "What is Recovery?" card, VS. LAST 7 DAYS section, Recovery/HRV/RHR charts (empty)

### Reference Design (Recovery 1, Recovery 2, Recovery 3, Recovery 4)
Features a much larger gauge with yellow fill, different MessageCard style, chat bar, and detailed charts.

---

#### Gap R-1 🔴 Recovery Gauge — Size and Fill Style

| | Detail |
|---|---|
| **Reference** | Recovery 1 shows a **very large** gauge (~full screen width) with a thick yellow/gold arc fill showing 57%. The "RECOVERY" label and "57%" value are inside the gauge. The arc has a gradient from gold to orange |
| **Current** | Gauge is noticeably smaller and shows 0% with just a dark ring track. The "RECOVERY" label is above the gauge externally, not inside it |
| **Action** | Increase gauge size. Move "RECOVERY" label inside the gauge above the percentage value. Ensure gradient fill matches reference |

---

#### Gap R-2 🟡 Recovery Gauge — "RECOVERY" Label Position

| | Detail |
|---|---|
| **Reference** | "RECOVERY" is printed **inside** the gauge circle, above the percentage value |
| **Current** | "RECOVERY" is printed **above** the gauge, outside the circle area |
| **Action** | Move the "RECOVERY" label inside the gauge |

---

#### Gap R-3 🔴 Recovery — Missing "Chat to learn about Recovery" Bar

| | Detail |
|---|---|
| **Reference** | Recovery 1 shows a "Chat to learn about Recovery" bar with W logo below the message text |
| **Current** | Not present |
| **Action** | Add WHOOP Coach chat prompt bar to Recovery tab |

---

#### Gap R-4 🟡 MessageCard — Style Differences

| | Detail |
|---|---|
| **Reference** | Recovery 1: "Solid Recovery" title in normal-sized bold text (~18-20pt), followed by descriptive body text. No card background boundary visible (the text appears directly on the dark background without a card container) |
| **Current** | "Low Recovery" shown inside a card with visible accent bar on the left. The title appears correct but the card container style with accent bar may differ from the reference's border-less text style |
| **Action** | Compare more carefully. The reference does show the MessageCard without a visible card background — just the accent bar on the left and text. Current implementation appears to match this pattern. **Likely OK** |

---

#### Gap R-5 🟡 Recovery Statistics — Missing RHR Row (uses different label)

| | Detail |
|---|---|
| **Reference** | Recovery 2 shows: HRV, **RHR** (abbreviated), RESPIRATORY RATE, SLEEP PERFORMANCE |
| **Current** | Shows: HRV, **RESTING HEART RATE** (full name), RESPIRATORY RATE, SLEEP PERFORMANCE |
| **Action** | Change "RESTING HEART RATE" label to "RHR" to match reference abbreviation |

---

#### Gap R-6 🟡 "What is Recovery?" Card — Background Image and Gradient Border

| | Detail |
|---|---|
| **Reference** | Recovery 2 shows the "What is Recovery?" card with a **background image** (person smiling), the recovery icon, description text, chevron `>`, and a gradient border (teal → purple / pink → purple) |
| **Current** | Shows simplified text-only version. Card says "Discover the science behind Recovery and how it measures health and fitness." with chevron `>`. No background image or gradient border visible from the screenshot |
| **Action** | Add background image and gradient border to the WhatIsInfoCard in Recovery tab |

---

#### Gap R-7 🔴 Recovery Gauge Start Angle

| | Detail |
|---|---|
| **Reference** | Recovery 1: The yellow arc starts from approximately the **10 o'clock** position (~135°) and sweeps clockwise |
| **Current** | The gauge ring appears to start from the 12 o'clock position (-90°) |
| **Action** | Change gauge start angle from -90° to 135° per `DESIGN_SPEC.md` §8.1 |

---

#### Gap R-8 🟡 Recovery Chart Cards — Missing Icon + Chevron Headers

| | Detail |
|---|---|
| **Reference** | Recovery 3/4 shows chart cards with: icon (bell/recovery icon) + "RECOVERY" title + chevron `>`, "HEART RATE VARIABILITY" + icon + chevron, "RESTING HEART RATE" + icon + chevron, "RESPIRATORY RATE" + icon + chevron |
| **Current** | Shows plain text "Recovery", "Heart Rate Variability", "Resting Heart Rate" without icons or chevrons |
| **Action** | Add icon + uppercase title + chevron header to chart cards |

---

#### Gap R-9 🔴 Recovery Bar Chart — Color-Coded Bars Based on Score

| | Detail |
|---|---|
| **Reference** | Recovery 3 shows bar chart with **color-coded bars**: low scores in white, high scores (58%, 57%) in **yellow/gold**. This is specific to recovery — the bars change color based on the recovery zone |
| **Current** | Chart is empty (no data), but likely renders all bars in a single color |
| **Action** | Implement color-coded bars for Recovery chart: white/gray for low (<33%), yellow for moderate (33-67%), green for high (67+%), matching the reference |

---

#### Gap R-10 🔵 Chart "Today" Column Highlight

| | Detail |
|---|---|
| **Reference** | Recovery 3/4 and all chart views show a subtle **gray/dark background column** on the rightmost (today) data point |
| **Current** | Not visible (no data), but likely not implemented |
| **Action** | Add "today" column background highlight to all chart cards |

---

## Strain Tab

### Current UI
- "STRAIN" header with (i) info button
- Circular gauge with "0.0" in cyan/blue
- SHARE button
- MessageCard: "Light Strain" with description
- STRAIN STATISTICS VS. PREVIOUS 30 DAYS
- Statistics: AVERAGE HR (0 bpm), CALORIES (0)
- "What is Strain?" card (partially visible)

### Reference Design (Strain 1, Strain 2, Strain 3, Strain 4)
Features a large gauge with blue gradient fill, "STRAIN" label inside gauge, activities, chat bar, and detailed charts.

---

#### Gap ST-1 🔴 Strain Gauge — Size and Fill

| | Detail |
|---|---|
| **Reference** | Strain 1: Very large gauge with a thick blue/cyan gradient arc showing 12.8. The arc shows a gradient from light blue to darker blue as it sweeps. "STRAIN" label and "12.8" value both inside the gauge |
| **Current** | Gauge shows "0.0" with a gray ring track. The gap between the unfilled/empty track and a filled version isn't apparent at 0 but the overall gauge size appears smaller than reference |
| **Action** | Increase gauge size to match reference. Ensure blue gradient arc renders properly when strain > 0 |

---

#### Gap ST-2 🔴 Strain Gauge — "STRAIN" Label Inside Gauge

| | Detail |
|---|---|
| **Reference** | "STRAIN" text is positioned **inside** the gauge circle, above the numeric value |
| **Current** | "STRAIN" is positioned **above** the gauge, outside the circle area |
| **Action** | Move "STRAIN" label inside the gauge above the value |

---

#### Gap ST-3 🔴 Strain — Missing "Chat to learn about Strain" Bar

| | Detail |
|---|---|
| **Reference** | Strain 1: "Chat to learn about Strain" bar with W logo below the MessageCard |
| **Current** | Not present |
| **Action** | Add WHOOP Coach chat prompt bar to Strain tab |

---

#### Gap ST-4 🟡 Strain Activities — Missing Activity Row Details

| | Detail |
|---|---|
| **Reference** | Strain 1/2: Shows "STRAIN ACTIVITIES" header and activity row: blue badge with "11.8" + activity icon, "FUNCTIONAL FITNESS" label, time range "5:25 PM / 4:22 PM", blue vertical bar on right edge |
| **Current** | No activities are visible (likely because no activity data exists for 0.0 strain) |
| **Action** | Verify activity row renders correctly when data is present. Ensure time range and blue vertical bar are shown per reference |

---

#### Gap ST-5 🟡 Strain Chart Cards — Icon + Chevron Headers

| | Detail |
|---|---|
| **Reference** | Strain 3: Chart card shows: strain icon + "STRAIN" title + chevron `>` |
| **Current** | Not visible in current screenshots since the view doesn't scroll far enough |
| **Action** | Add icon + uppercase title + chevron header to strain chart cards |

---

#### Gap ST-6 🔵 Strain Bar Color

| | Detail |
|---|---|
| **Reference** | Strain 3 shows bars in **bright blue/cyan** color |
| **Current** | Not visible (no data) |
| **Action** | Verify strain bar chart uses cyan/blue colors per reference when data is available |

---

## Cross-Tab / Global Gaps

#### Gap G-1 🔵 Tab Bar Label Font Size

| | Detail |
|---|---|
| **Reference** | Tab labels (OVERVIEW, SLEEP, RECOVERY, STRAIN) appear to be ~13pt |
| **Current** | Tab labels appear to be ~11pt (per code review from previous audit) |
| **Action** | Increase tab label font from 11pt to 13pt to match `DESIGN_SPEC.md` `tabLabel` = 13pt |

---

#### Gap G-2 🔵 Tab Bar Background

| | Detail |
|---|---|
| **Reference** | Tab bar background appears to be pure OLED black (#000000) |
| **Current** | Uses `Theme.Colors.surface` (#0A0A0B) — very slightly lighter |
| **Action** | Change tab bar background to `primary` (#000000) |

---

#### Gap G-3 🔵 Active Tab Indicator Line

| | Detail |
|---|---|
| **Reference** | Active tab has a short **underline bar** below the text, appearing blue/underline |
| **Current** | Active tab has a green/teal underline bar |
| **Action** | Verify the underline color — reference shows it as a subtle indicator. The current teal color may be correct for the active tab styling. **Likely OK** |

---

#### Gap G-4 🔵 Gauge Value Font Size

| | Detail |
|---|---|
| **Reference** | Recovery and Strain gauge values appear at approximately 72pt (hero size) per `DESIGN_SPEC.md` |
| **Current** | Code uses 64pt for gauge values (per previous audit) |
| **Action** | Increase gauge value font to 72pt per `hero` typography spec |

---

#### Gap G-5 🔵 Share Button Placement

| | Detail |
|---|---|
| **Reference** | All tabs show "SHARE" button **inside** the gauge area (within the circle) |
| **Current** | SHARE button appears below the gauge, outside the circle boundary |
| **Action** | Move SHARE button to be inside/overlapping the lower portion of the gauge circle |

---

#### Gap G-6 🔵 (i) Info Button Style

| | Detail |
|---|---|
| **Reference** | Shows (i) info button as a circle with "i" in the top-right area of the gauge section |
| **Current** | Similar placement — appears correct |
| **Action** | **Likely OK** — verify sizing matches |

---

## Features Not Supported by Apple Watch Series 5

The following features from the reference design are specific to the WHOOP phone app and either cannot or should not be replicated on Apple Watch Series 5:

| Feature | Reason |
|---------|--------|
| Bottom tab bar (Home / Plan / Community / More) | Watch uses simplified navigation (Home + Profile) |
| Floating "+" FAB button | Watch does not typically use floating action buttons |
| "Talk to your WHOOP Coach" / "Chat to learn about X" bars | May require network-heavy AI features not suitable for Watch |
| Journal card with background photo | Watch display too small for rich card backgrounds |
| Profile photo (top-left avatar) | Watch app shows generic icon, not user avatar |
| WHOOP band product image in BaselineInfoCard | Watch display too small for detailed product images |
| Sleep activity detail view (Overview 3) | This is a drill-down detail screen on the phone app |

> [!IMPORTANT]
> The chat/coach bars appear in **all four** reference tabs (Overview, Sleep, Recovery, Strain). If the decision is made to include them, they should be added consistently across all tabs. If excluded for Watch, they should be excluded everywhere.

---

## Priority Summary

### 🔴 Critical — Must Fix (10 items)

| # | Gap ID | Description |
|---|--------|-------------|
| 1 | S-1 | Sleep tab: Use DashedGauge instead of plain text |
| 2 | O-1 | Overview DualGaugeHero: Add colored Recovery + Strain arcs |
| 3 | O-2 | Overview DualGaugeHero: Increase ring diameter to 200pt |
| 4 | R-1 | Recovery gauge: Increase size and fix gradient fill |
| 5 | ST-1 | Strain gauge: Increase size and fix gradient fill |
| 6 | R-2/ST-2 | Recovery + Strain: Move label text inside gauge |
| 7 | O-5 | Missing "Talk to your WHOOP Coach" bar (if applicable) |
| 8 | R-3/ST-3/S-5 | Missing "Chat to learn about X" bars (if applicable) |
| 9 | R-7 | Recovery gauge start angle: -90° → 135° |
| 10 | S-11 | Chart day labels: single-letter → two-line format |

### 🟡 Moderate — Should Fix (12 items)

| # | Gap ID | Description |
|---|--------|-------------|
| 1 | O-3 | Missing share icon on Overview hero |
| 2 | O-4 | BaselineInfoCard: Missing WHOOP band image |
| 3 | O-7 | Key Statistics: Missing baseline values + trend arrows |
| 4 | O-8 | Missing Journal card |
| 5 | O-9 | Missing HOURS OF SLEEP statistic row |
| 6 | S-2 | Sleep Performance label placement |
| 7 | S-3 | Sleep comparison boxes layout |
| 8 | S-9/R-6 | WhatIsInfoCard: Missing background image + gradient |
| 9 | S-10/R-8/ST-5 | Chart cards: Missing icon + chevron headers |
| 10 | R-5 | Recovery: "RESTING HEART RATE" → "RHR" |
| 11 | R-9 | Recovery bar chart: Color-coded bars by score zone |
| 12 | S-4 | Missing TipCard on Sleep tab |

### 🔵 Minor — Nice to Fix (8 items)

| # | Gap ID | Description |
|---|--------|-------------|
| 1 | G-1 | Tab label font: 11pt → 13pt |
| 2 | G-2 | Tab bar background: surface → primary |
| 3 | G-4 | Gauge value font: 64pt → 72pt |
| 4 | G-5 | SHARE button placement inside gauge |
| 5 | R-10/S-11 | Chart "today" column highlight |
| 6 | S-12 | Sleep bar color verification |
| 7 | ST-6 | Strain bar color verification |
| 8 | O-10 | Bottom nav bar (Watch N/A) |
