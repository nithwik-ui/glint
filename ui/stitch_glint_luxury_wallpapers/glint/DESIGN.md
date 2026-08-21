---
name: Glint
colors:
  surface: '#fff7fe'
  surface-dim: '#e1d7e4'
  surface-bright: '#fff7fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fbf0fe'
  surface-container: '#f5eaf8'
  surface-container-high: '#f0e5f2'
  surface-container-highest: '#eadfed'
  on-surface: '#1f1a23'
  on-surface-variant: '#4d4354'
  inverse-surface: '#342e38'
  inverse-on-surface: '#f8edfb'
  outline: '#7e7385'
  outline-variant: '#cfc2d6'
  surface-tint: '#842bd2'
  primary: '#8127cf'
  on-primary: '#ffffff'
  primary-container: '#9c48ea'
  on-primary-container: '#fffbff'
  inverse-primary: '#ddb7ff'
  secondary: '#6f5092'
  on-secondary: '#ffffff'
  secondary-container: '#d9b5ff'
  on-secondary-container: '#614283'
  tertiary: '#7b5500'
  on-tertiary: '#ffffff'
  tertiary-container: '#9b6b00'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#f0dbff'
  primary-fixed-dim: '#ddb7ff'
  on-primary-fixed: '#2c0051'
  on-primary-fixed-variant: '#6900b3'
  secondary-fixed: '#efdbff'
  secondary-fixed-dim: '#dbb8ff'
  on-secondary-fixed: '#29074a'
  on-secondary-fixed-variant: '#573878'
  tertiary-fixed: '#ffdead'
  tertiary-fixed-dim: '#fabc4e'
  on-tertiary-fixed: '#281900'
  on-tertiary-fixed-variant: '#604100'
  background: '#fff7fe'
  on-background: '#1f1a23'
  surface-variant: '#eadfed'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.3'
    letterSpacing: -0.01em
  title-sm:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: -0.01em
  body-base:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
    letterSpacing: '0'
  caption-xs:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.02em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: 48px
  stack-sm: 8px
  stack-md: 24px
  stack-lg: 48px
  container-max: 1200px
---

## Brand & Style
The design system embodies a "Hyper-Minimal Luxury" aesthetic, blending the precision of high-end hardware interfaces with the ethereal quality of digital art. It is designed for a premium wallpaper application where the interface must recede to let the visual content lead, yet feel incredibly tactile and expensive when interacted with.

The style is a hybrid of **Minimalism** and **Glassmorphism**, characterized by:
- **Spatial Depth:** Using white-on-white layering to create a sense of physical stacks.
- **Ethereal Accents:** Soft purple glows that mimic light refracting through glass.
- **Precision Craft:** Extreme attention to negative space and typographic rhythm.
- **Fluidity:** Every transition should feel like a change in light or focus rather than a simple movement.

## Colors
The palette is intentionally restrained to maintain a "Gallery" feel.
- **Core Surfaces:** The background is pure white (#FFFFFF), while secondary surfaces and cards use a very subtle off-white (#FAFAFA) to define boundaries without heavy lines.
- **The Glint Effect:** The primary brand expression is a soft purple gradient. This is used sparingly for active states, call-to-action buttons, and subtle glowing underlays.
- **Functional Grays:** Text follows a strict hierarchy—deep charcoal for legibility and a muted medium gray for metadata and secondary info.
- **Transparency:** Glass elements use a white tint (rgba 255, 255, 255, 0.7) combined with a high-saturation background blur (30px - 40px).

## Typography
The typography utilizes **Inter** to achieve a neutral yet sophisticated look.
- **Weight Strategy:** Use Bold/Semi-Bold for headers to create a strong visual anchor. Body text remains at Regular (400) for maximum legibility.
- **Kerning:** Apply slight negative letter-spacing to large display type to give it a "tight," premium editorial feel, similar to high-fashion magazines.
- **Hierarchy:** Maintain large vertical gaps between sections to allow the type to breathe. Avoid center-aligning long-form text; keep it left-aligned to maintain the structured "Nothing OS" grid feel.

## Layout & Spacing
The layout follows a **Fluid Grid** model with generous safe areas. 
- **The Floating Grid:** Content should never feel "trapped." Cards and images should have significant outer margins, creating a floating effect within the viewport.
- **Pinterest Influence:** For image galleries, use a masonry or a balanced 2-column grid on mobile with 16px gutters.
- **Vertical Rhythm:** Use a 4px baseline. Components like buttons and inputs should have tall heights (56px or 64px) to feel substantial and "Apple-like."
- **Breakpoints:** 
  - Mobile: 0 - 599px (1 or 2 columns)
  - Tablet: 600 - 1023px (3 columns)
  - Desktop: 1024px+ (4-6 columns)

## Elevation & Depth
This design system avoids traditional black shadows. Depth is communicated through:
- **Luminous Shadows:** Use very large, soft blurs (60px+) with extremely low opacity (3-5%) mixed with a hint of the primary purple color. This creates a "glow" rather than a "shadow."
- **Glass Surfaces:** Navigation bars and action sheets use `backdrop-filter: blur(40px)` with a 1px semi-transparent white border. This mimics the "frosted glass" effect of macOS and Nothing OS.
- **Inner Glows:** Interactive elements like active cards use a subtle 1px inner stroke to simulate a light source hitting the edge of a physical object.
- **Stacking:** Use three primary z-index tiers: 0 (Base White), 100 (Floating Cards), 200 (Glass Navigation/Overlays).

## Shapes
The shape language is defined by "Squircle" aesthetics and extreme corner radii.
- **Main Containers:** All primary cards, image containers, and modally presented views must use a **32px** corner radius.
- **Small Elements:** Buttons and input fields use a **16px** to **24px** radius to maintain harmony with the larger containers.
- **Nested Corners:** When a component is nested inside a 32px card, its radius should be smaller (approx 12px) to maintain a concentric, organic look.
- **Pill Shapes:** Search bars and tag chips should use full pill-rounding for a friendly, touch-optimized feel.

## Components
- **Buttons:** Primary buttons use the accent gradient with white text. They should have a subtle "lift" on hover/touch. Ghost buttons use a 1px light gray stroke.
- **Image Cards:** High-quality imagery is the focus. Cards have no borders; they rely on the 32px radius and soft luminous shadows for definition.
- **Glass Navigation:** Bottom bars (for mobile) or Top bars (for web) must be floating, not pinned to the edge. They feature a high-blur glass effect and pill-shaped active states.
- **Input Fields:** Large, 60px height fields with #FAFAFA background and 24px radius. Focus state should trigger a subtle purple outer glow.
- **Chips/Filters:** Minimalist pill shapes with a white background and a 1px border. Active state switches to a solid purple fill or a vibrant purple text color.
- **Progressive Disclosure:** Use smooth "spring" animations for expanding cards or opening wallpaper previews to mimic the premium feel of high-end mobile operating systems.