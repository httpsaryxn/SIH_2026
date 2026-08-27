---
name: Fresh Slate
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#3d4a3d'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#6d7b6c'
  outline-variant: '#bccbb9'
  surface-tint: '#006e2f'
  primary: '#006e2f'
  on-primary: '#ffffff'
  primary-container: '#22c55e'
  on-primary-container: '#004b1e'
  inverse-primary: '#4ae176'
  secondary: '#565e74'
  on-secondary: '#ffffff'
  secondary-container: '#dae2fd'
  on-secondary-container: '#5c647a'
  tertiary: '#005ac2'
  on-tertiary: '#ffffff'
  tertiary-container: '#82abff'
  on-tertiary-container: '#003d88'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6bff8f'
  primary-fixed-dim: '#4ae176'
  on-primary-fixed: '#002109'
  on-primary-fixed-variant: '#005321'
  secondary-fixed: '#dae2fd'
  secondary-fixed-dim: '#bec6e0'
  on-secondary-fixed: '#131b2e'
  on-secondary-fixed-variant: '#3f465c'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#adc6ff'
  on-tertiary-fixed: '#001a42'
  on-tertiary-fixed-variant: '#004395'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 40px
---

## Brand & Style

The brand identity for this design system is built upon three pillars: **Organization, Trust, and Freshness**. Designed specifically for small business owners in the food sector, the UI must feel as professional as a commercial kitchen while remaining as approachable as a local market.

We utilize a **Modern Corporate** style with a focus on high-clarity information density. The aesthetic draws from the geometric precision found in modern fitness and productivity apps, ensuring that complex food labeling data (ingredients, allergens, dates) is digestible at a glance. The visual mood is crisp and "daylight" bright, favoring high-quality whitespace and rhythmic structural alignment to instill a sense of operational efficiency.

## Colors

The palette is anchored by a vibrant **Fresh Green** (#22C55E), symbolizing health, growth, and compliance. This is balanced by a **Deep Slate Blue** (#0F172A) for primary text and navigation, providing a grounded, professional contrast. 

- **Primary (Green):** Used for "Success" states, primary action buttons, and active status indicators.
- **Secondary (Navy):** Used for headers, iconography, and high-emphasis interface elements.
- **Tertiary (Blue):** Employed for informational badges, links, and secondary interactive elements to signify professional utility.
- **Neutrals:** A range of cool grays (from #F8FAFC to #64748B) creates the structural framework, ensuring the interface feels airy and organized.

## Typography

This design system utilizes **Plus Jakarta Sans** for all roles, echoing the geometric, modern clarity of the reference inspiration. The typeface provides excellent legibility for long ingredient lists while maintaining a contemporary edge for marketing headlines.

**Scale & Rhythm:**
- **Headlines:** Use tight letter spacing (-0.01em to -0.02em) and heavy weights to create a strong visual hierarchy.
- **Labels:** Use semibold weights for uppercase metadata (e.g., "EXPIRY DATE") to ensure they are distinct from body copy.
- **Body:** Standardized on a 16px base for accessibility, ensuring that even dense nutritional information is easy to scan.

## Layout & Spacing

The design system employs a **Fluid-Fixed hybrid grid**. On mobile, it utilizes a 4-column layout with 20px margins. On desktop, it transitions to a 12-column grid capped at 1280px to maintain readability.

**Spacing Philosophy:**
We use a strictly 4px-based geometric progression. Elements are grouped into "containers" using 16px (md) or 24px (lg) padding to create a clear modular feel. Information-dense areas (like label editors) can drop to 8px (sm) gutters to maximize screen real estate, while "Management" dashboards should utilize 48px (xxl) vertical rhythm to prevent user fatigue.

## Elevation & Depth

To maintain a "fresh" and clean aesthetic, we avoid heavy shadows. Instead, we use **Tonal Layering** supplemented by **Soft Ambient Shadows**.

1.  **Level 0 (Surface):** The background color (#F8FAFC).
2.  **Level 1 (Card/Container):** Pure white (#FFFFFF) with a very subtle 1px border (#E2E8F0) and a soft, diffused shadow (0px 4px 12px rgba(0,0,0,0.03)).
3.  **Level 2 (Interactive/Floating):** Used for dropdowns and modals. These utilize a more pronounced shadow (0px 10px 25px rgba(0,0,0,0.08)) to lift them clearly above the workspace.

Glassmorphism is used sparingly for navigation bars (15px backdrop-blur) to maintain context while scrolling.

## Shapes

The shape language is **Rounded (Level 2)**, creating a friendly and approachable feel that mitigates the "stiffness" of industrial data.

- **Standard Elements:** Buttons and Input fields use a `0.5rem` (8px) corner radius.
- **Cards & Containers:** Larger layout blocks use `1rem` (16px) for a soft, modern containerized look.
- **Selection States:** Small indicators (chips/pills) use `rounded-full` to represent discrete pieces of data like food allergens.

## Components

**Buttons**
- **Primary:** Fresh Green background with White text. Bold weight.
- **Secondary:** Deep Slate outline with Deep Slate text.
- **Ghost:** No background, Blue tertiary text for low-priority actions.

**Inputs & Fields**
- Inputs should have a subtle #F1F5F9 background to distinguish them from the white card they sit on. 
- Focus states utilize a 2px Green ring with high-contrast label colors.

**Cards**
- Cards are the primary vehicle for food labels. They must feature a "Header" area for the product name and a "Grid" area for nutritional facts. Use high-contrast dividers (1px #F1F5F9).

**Status Chips**
- Use highly saturated background tints for status: `Organic` (Green tint), `Contains Nuts` (Amber tint), `Professional` (Blue tint).

**Lists**
- Ingredient lists should use `body-sm` with increased line-height (1.6) to prevent "wall of text" syndrome. Bullet points are replaced by subtle horizontal rules.