# Whoop Dashboard Design Specification

Pixel-perfect design reference extracted from Whoop app screenshots.

---

## 1. Color System

### 1.1 Backgrounds

| Token | Hex | Usage |
|-------|-----|-------|
| `background.primary` | #000000 | OLED black main background |
| `background.card` | #1C1C1E | Card backgrounds |
| `background.cardAlt` | #2C2C2E | Info cards, lighter variant |

### 1.2 Text Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `text.primary` | #FFFFFF | Primary headings, values |
| `text.secondary` | #8E8E93 | Labels, descriptions |
| `text.tertiary` | #636366 | Placeholders, muted |
| `text.link` | #00D4AA | CTAs, links (teal) |

### 1.3 Semantic Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `recovery.ring` | #FFD700 | Yellow/gold recovery ring |
| `recovery.ringEnd` | #FFA500 | Orange gradient end |
| `strain.ring` | #00BFFF | Cyan/blue strain ring |
| `strain.ringEnd` | #0099CC | Darker blue gradient end |
| `sleep.accent` | #00D4AA | Teal for sleep metrics |
| `trend.positive` | #00D4AA | Green up arrows |
| `trend.negative` | #FF3B30 | Red down arrows |

### 1.4 Borders & Dividers

| Token | Hex | Usage |
|-------|-----|-------|
| `border.subtle` | #38383A | Card borders |
| `border.medium` | #48484A | Divider lines |

### 1.5 Sleep Stage Colors

| Stage | Hex | Description |
|-------|-----|-------------|
| `stage.awake` | #636366 | Gray |
| `stage.light` | #5B9BD5 | Blue |
| `stage.deep` | #7B68EE | Purple |
| `stage.rem` | #BA68C8 | Pink-purple |

---

## 2. Typography Scale

### 2.1 Font Sizes

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `hero` | 72pt | Bold | 1.0 | Main percentage (58%, 66%) |
| `largeValue` | 48pt | Semibold | 1.1 | Secondary values (12.8) |
| `mediumValue` | 28pt | Semibold | 1.2 | Metric tile values |
| `smallValue` | 20pt | Medium | 1.2 | Stats row values |
| `sectionHeader` | 13pt | Semibold | 1.3 | UPPERCASE headers |
| `tabLabel` | 13pt | Medium | 1.4 | Tab names |
| `body` | 15pt | Regular | 1.5 | Description text |
| `caption` | 13pt | Regular | 1.4 | Secondary labels |
| `footnote` | 11pt | Regular | 1.3 | Baseline comparisons |

### 2.2 Text Transformations

- Section headers: UPPERCASE with 1pt letter spacing
- Tab labels: Title case
- Metric labels: Sentence case
- Value units: Lowercase appended to value

---

## 3. Component Dimensions

### 3.1 Gauges

| Component | Dimension |
|-----------|-----------|
| Hero gauge (Overview) | 200pt diameter |
| Standard gauge | 180pt diameter |
| Small gauge (strain arc) | 100pt diameter |
| Gauge stroke width | 12pt |
| Dashed gauge stroke | 4pt dash, 8pt gap |

### 3.2 Cards & Containers

| Component | Dimension |
|-----------|-----------|
| Card corner radius | 12pt |
| Card padding | 16pt |
| Card border width | 1pt (when present) |
| Section spacing | 24pt |
| Inner element spacing | 16pt |

### 3.3 Charts

| Component | Dimension |
|-----------|-----------|
| Bar chart bar width | 24pt |
| Bar chart gap | 8pt |
| Bar chart height | 120pt |
| Line chart height | 100pt |
| Line stroke width | 2pt |
| Data point diameter | 6pt |

### 3.4 Rows & Lists

| Component | Dimension |
|-----------|-----------|
| Activity row height | 64pt |
| Stats row height | 56pt |
| Metric tile height | 100pt |
| Icon size (small) | 20pt |
| Icon size (medium) | 24pt |

---

## 4. Component Specifications

### 4.1 DualGaugeHero (Overview)

```
+------------------------------------------+
|                                          |
|         [Large Recovery Ring]            |
|            200pt diameter                |
|              "58%"                        |
|            RECOVERY                       |
|                                          |
|    [Small Strain Arc]                    |
|      100pt, bottom-right                 |
|        "12.8"                            |
|                                          |
|  HRV            |         SLEEP %        |
|  42ms           |          85%           |
+------------------------------------------+
```

### 4.2 BaselineInfoCard (Overview)

```
+------------------------------------------+
| [Gradient background: teal-to-transparent]
|                                          |
| (i) Your Personalized Baseline           |
|                                          |
| Your baseline is being established.      |
| Continue wearing your WHOOP to see       |
| personalized insights.                   |
|                                          |
| ████████░░░░░░░░░░  14/28 days           |
|                                          |
| WATCH THE VIDEO  →                       |
+------------------------------------------+
```

### 4.3 StatisticsSection

```
+------------------------------------------+
| VS. PREVIOUS 30 DAYS              CUSTOMIZE |
+------------------------------------------+
| [icon] HRV                    42ms   ↑   |
|        Baseline: 38ms                    |
+------------------------------------------+
| [icon] Sleep Performance       85%   →   |
|        Baseline: 82%                     |
+------------------------------------------+
| [icon] Calories              1,842   ↓   |
|        Baseline: 2,100                   |
+------------------------------------------+
```

### 4.4 DashedGauge (Sleep)

```
+------------------------------------------+
|                                          |
|     .  .  .  .  .  .  .  .  .            |
|   .                           .          |
|  .          66%                .         |
|  .    SLEEP PERFORMANCE        .         |
|   .                           .          |
|     .  .  .  .  .  .  .  .  .            |
|                                          |
|                          [SHARE]         |
+------------------------------------------+
```

### 4.5 SleepComparisonBoxes (Sleep)

```
+------------------+  +------------------+
|  5:51            |  |  8:52            |
|  HOURS OF SLEEP  |  |  SLEEP NEEDED    |
+------------------+  +------------------+
 (white bg)            (teal accent)
```

### 4.6 TipCard (Sleep/Recovery/Strain)

```
+------------------------------------------+
| [lightbulb icon]                         |
| Try to get more sleep                    |
|                                          |
| Going to bed earlier can improve your    |
| recovery score and daily performance.    |
+------------------------------------------+
```

### 4.7 MessageCard (Recovery/Strain)

```
+------------------------------------------+
| Solid Recovery                           |
|                                          |
| Your body is well-recovered. You can     |
| handle higher strain activities today.   |
+------------------------------------------+
```

### 4.8 WhatIsInfoCard

```
+------------------------------------------+
| What is Recovery?                    >   |
+------------------------------------------+
 (gradient border, teal accent)
```

### 4.9 VerticalBarChart

```
+------------------------------------------+
|  85%  72%  91%  88%  76%  82%  89%       |
|  ██   ██   ██   ██   ██   ██   ██        |
|  ██   ██   ██   ██   ██   ██   ██        |
|  ██   ▓▓   ██   ██   ▓▓   ██   ██        |
|  ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓        |
|  M    T    W    T    F    S    S         |
+------------------------------------------+
```

### 4.10 StrainActivityRow

```
+------------------------------------------+
| [●12.3] Running          7:30AM - 8:15AM |
| (blue)                                   |
+------------------------------------------+
```

---

## 5. Layout Specifications

### 5.1 Overview Tab Layout

1. DualGaugeHero (top, centered)
2. BaselineInfoCard (if < 28 days of data)
3. AlarmBedtimeRow
4. Activities Section (header + rows)
5. Journal Card
6. KeyStatisticsSection

### 5.2 Sleep Tab Layout

1. DashedGauge with SHARE button
2. SleepComparisonBoxes (2-up horizontal)
3. TipCard
4. Sleep Activities
5. StatisticsSection (VS. PREVIOUS 30 DAYS)
6. WhatIsInfoCard
7. StatisticsSection (VS. LAST 7 DAYS)
8. VerticalBarChart (Sleep Performance)
9. DualLineChart (Hours vs Need)
10. VerticalBarChart (Time in Bed)

### 5.3 Recovery Tab Layout

1. CircularProgressGauge (yellow, 57%)
2. MessageCard ("Solid Recovery")
3. StatisticsSection (VS. PREVIOUS 30 DAYS)
4. WhatIsInfoCard
5. StatisticsSection (VS. LAST 7 DAYS header only)
6. VerticalBarChart (Recovery 7-day)
7. Line Chart (HRV Trend)
8. Line Chart (RHR Trend)
9. Line Chart (Respiratory Rate)

### 5.4 Strain Tab Layout

1. StrainGauge (blue, 12.8 / 0-21)
2. MessageCard ("Balanced Strain")
3. Strain Activities (StrainActivityRow)
4. StatisticsSection (VS. PREVIOUS 30 DAYS)
5. WhatIsInfoCard
6. StatisticsSection (VS. LAST 7 DAYS header only)
7. VerticalBarChart (Strain 7-day)
8. Line Chart (Average HR)
9. VerticalBarChart (Calories)

---

## 6. Interaction States

### 6.1 Tap States

- Cards: Scale to 0.98 on press
- Buttons: Opacity to 0.7 on press
- Rows: Background highlight #2C2C2E

### 6.2 Transitions

- Tab switch: Cross-dissolve, 0.2s
- Card expand: Spring animation, 0.3s
- Chart data change: Ease-out, 0.25s

---

## 7. Accessibility

### 7.1 Text Scaling

- Supports Dynamic Type up to xxxLarge
- Minimum touch target: 44pt x 44pt

### 7.2 VoiceOver Labels

- Gauges: "[Metric]: [value] percent, [sublabel]"
- Charts: "[Chart type] showing [metric] over [time period]"
- Rows: "[Activity type], [time], [value]"

---

## 8. Color Gradients

### 8.1 Recovery Ring Gradient

```swift
AngularGradient(
    colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
    center: .center,
    startAngle: .degrees(135),
    endAngle: .degrees(135 + 270 * progress)
)
```

### 8.2 Strain Ring Gradient

```swift
AngularGradient(
    colors: [Color(hex: "#00BFFF"), Color(hex: "#0099CC")],
    center: .center,
    startAngle: .degrees(135),
    endAngle: .degrees(135 + 270 * progress)
)
```

### 8.3 Info Card Gradient

```swift
LinearGradient(
    colors: [Color(hex: "#00D4AA").opacity(0.2), Color.clear],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```
