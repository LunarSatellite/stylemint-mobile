# Design Extraction & Review Skill

## Purpose
Extract design specifications from Figma mockups and PDF design documents with full fidelity, avoiding missed details that cause rework.

---

## Part 1: Figma Design Extraction Protocol

### 1.1 Before Viewing the Figma File

**Prepare Context:**
- [ ] Understand the feature being designed (auth, checkout, product browsing, etc.)
- [ ] Know the design system being used (color palette, typography, spacing)
- [ ] Identify which states need to be implemented (default, hover, disabled, loading, error, success)
- [ ] List expected user interactions (taps, swipes, keyboard input, validation)

**Questions to Ask Yourself:**
- What is the primary user goal on this screen?
- What are all possible states (success, loading, error, empty, disabled)?
- What validations happen and what feedback is shown?
- Are there micro-interactions (animations, transitions, haptics)?
- How does this screen connect to the next one?

---

### 1.2 Examining Figma Components & Variants

**When you open a Figma file, systematically extract:**

#### A. Screen Layout & Hierarchy
- [ ] **Page structure** - is it a single screen or multiple variations?
- [ ] **Frame dimensions** - device size (mobile 375x812, tablet, etc.)
- [ ] **Safe areas** - notch, status bar, navigation bar space
- [ ] **Main content area** - how much vertical space available?
- [ ] **Scroll regions** - does content scroll, are headers sticky?

Example: "LoginScreen is 375x812. Status bar (24px) + AppBar (56px) = 80px reserved. Content scrolls below."

#### B. Visual Hierarchy & Spacing
For each section of the screen:
- [ ] **Component position** - top, centered, bottom, floating?
- [ ] **Spacing from edges** - measure margin from device edges
- [ ] **Spacing between elements** - distance between title, input, button
- [ ] **Grouping** - which elements are grouped visually?
- [ ] **Padding inside containers** - space between border and content

**Measurement technique:**
- Use Figma ruler/guides to identify spacing
- Common spacing: 4px grid (s4, s8, s12, s16, s24, s32, etc.)
- Measure: top margin, horizontal margins, gaps between elements

Example: "Phone icon is 80x120, centered, top margin 32px. Title below at 32px gap. Subtitle at 12px gap. Input field at 32px gap with 16px horizontal padding."

#### C. Typography Details
For each text element, measure:
- [ ] **Font family** - Poppins, Inter, Roboto, custom?
- [ ] **Font size** - 11px, 12px, 14px, 16px, 18px, 20px, etc.
- [ ] **Font weight** - 400 (regular), 500 (medium), 600 (semi-bold), 700 (bold)
- [ ] **Line height** - 1.0, 1.2, 1.3, 1.5, or px value (e.g., 21px)
- [ ] **Letter spacing** - 0, or specific pixel value
- [ ] **Text color** - exact hex or token name
- [ ] **Text transform** - uppercase, capitalize, none
- [ ] **Text alignment** - left, center, right
- [ ] **Number of lines** - single line vs multi-line vs truncated

**Figma extraction method:**
- Click text → check properties panel for font, size, weight, line height
- Right-click → inspect to see exact values
- Compare against design system in Figma library

Example: "Title: Poppins, 20px, 600 weight, 1.3 line height, white #FFF, center-aligned"

#### D. Colors & States
For every color on screen:
- [ ] **Background colors** - entire screen, cards, input fields, buttons
- [ ] **Text colors** - headings, body, hints, labels
- [ ] **Accent colors** - focus states, highlights, success/error
- [ ] **Border colors** - outlines, dividers, separators
- [ ] **Opacity/transparency** - full opaque or semi-transparent?

**For interactive elements, check all states:**
- [ ] **Default state** - how does it look normally?
- [ ] **Hover state** - what changes on hover (desktop)?
- [ ] **Focus state** - what shows when keyboard focused?
- [ ] **Active/pressed state** - what happens when clicked?
- [ ] **Disabled state** - appearance when disabled
- [ ] **Loading state** - spinner, progress, grayed out?
- [ ] **Error state** - red border, error text, error icon?
- [ ] **Success state** - green border, checkmark, success message?

**Figma extraction method:**
- Use Figma's "Inspect" panel to copy exact hex values
- Or use color picker tool to read colors
- Click component and view variants in design panel
- Check if component has different states documented

Example: "Button default: #2ECC71 green background, white text. Hover: darker shade. Disabled: gray #9F9FA9. Loading: shows spinner overlay."

#### E. Interactive Elements (Inputs, Buttons, Dropdowns)
For each interactive component:
- [ ] **Component type** - text field, button, dropdown, checkbox, etc.
- [ ] **Size** - width, height, padding
- [ ] **Border** - color, width, radius, style (solid, dashed)
- [ ] **Background** - color, opacity
- [ ] **Label** - text, font, size, color, position
- [ ] **Placeholder/hint text** - exact text shown, color, style
- [ ] **Icon** - which icon, size, color, position
- [ ] **Validation feedback** - error text location, color, size
- [ ] **Required indicator** - asterisk, color, position

**For input fields specifically:**
- [ ] **Label position** - above, inside (floating), outside
- [ ] **Placeholder text** - "Enter phone number", "mm/dd/yyyy", etc.
- [ ] **Helper text** - "Min 10 digits", "Password must contain...", location
- [ ] **Error message** - exact text, position, color
- [ ] **Input area padding** - horizontal and vertical padding inside field
- [ ] **Keyboard type** - text, number, email, phone, date, etc.
- [ ] **Max length** - character limit if any
- [ ] **Character counter** - shows current/max if visible

Example: "Phone field: label above, placeholder 'XXXXXXXXXX', 16px horizontal padding, 12px vertical padding, green border on focus (#2ECC71), error text in red below field."

#### F. Buttons
For each button:
- [ ] **Button type** - primary, secondary, outline, text-only, icon
- [ ] **Label text** - exact text in button
- [ ] **Button size** - width, height, padding
- [ ] **Border radius** - fully rounded (999px), slightly rounded (8px), sharp (0px)
- [ ] **Icon** - which icon, size, position relative to text
- [ ] **Loading state** - spinner replaces icon? Or shows beside text?
- [ ] **Disabled appearance** - grayed out? Different text color?
- [ ] **Active/pressed appearance** - darker? Inset shadow?

Example: "Submit button: 'Submit' label (or 'Sending...' when loading), primary green, fully rounded (999px), full width, 16px horizontal padding, 12px vertical padding, white text."

#### G. Modals, Dialogs, Sheets
If present:
- [ ] **Background** - overlay color, opacity, blur?
- [ ] **Position** - center, bottom sheet, full screen, modal?
- [ ] **Size** - width, height, max dimensions
- [ ] **Border radius** - corners rounded? How much?
- [ ] **Spacing from edges** - margin on all sides
- [ ] **Backdrop** - dismissible by tapping outside?
- [ ] **Close button** - X icon, location, size
- [ ] **Animation** - slide up, fade in, scale, etc.

#### H. Images & Icons
For each visual element:
- [ ] **Icon type** - Material icon, custom icon, SVG, image?
- [ ] **Size** - exact pixel dimensions
- [ ] **Color** - single color icon or multi-color?
- [ ] **Stroke weight** - for outlined icons, how thick are strokes?
- [ ] **Image aspect ratio** - 1:1, 16:9, custom
- [ ] **Placeholder** - shows skeleton, solid color, or nothing while loading?

#### I. Lists & Grids
If content is repeated:
- [ ] **Item layout** - single column, multiple columns, grid?
- [ ] **Item size** - height, aspect ratio
- [ ] **Spacing between items** - gap size
- [ ] **Item structure** - what's in each item? (thumbnail, title, subtitle, etc.)
- [ ] **Dividers** - shown between items? Color, thickness?
- [ ] **Empty state** - what shows when list is empty?
- [ ] **Loading state** - skeleton items? Spinner?
- [ ] **Scroll behavior** - infinite scroll, pagination, fixed height?

#### J. Form Validation & Error States
Document every validation scenario:
- [ ] **Email invalid** - "Please enter a valid email"
- [ ] **Phone too short** - "Please enter at least 10 digits"
- [ ] **Required field empty** - "This field is required"
- [ ] **Password weak** - "Password must contain uppercase, number, special character"
- [ ] **Where is error shown** - below field? As tooltip? As badge?
- [ ] **Error styling** - red border, red text, icon?

#### K. Navigation & Flow
- [ ] **Back button** - visible? Where? What does it do?
- [ ] **Next screen navigation** - button label, what triggers navigation?
- [ ] **Data passed between screens** - what parameters sent to next screen?
- [ ] **URL/route** - what's the path if using routing?

---

### 1.3 Figma Inspection Techniques

**Use Figma's built-in tools:**

1. **Select tool** (V)
   - Click element → properties panel shows all styling
   - Look for: fill color, stroke, shadow, border radius, size, position

2. **Inspect panel** (Cmd/Ctrl + Option/Alt + I)
   - Right-click element → "Inspect"
   - Shows exact values for copying
   - Useful for getting precise hex colors, dimensions

3. **Prototype view**
   - Click "Prototype" tab in design panel
   - See which elements are clickable
   - See navigation flows and interactions

4. **Developer handoff**
   - Click "Code" or export settings
   - Some Figma plugins export CSS/code snippets

5. **Comments & notes**
   - Designer may have left notes on specific elements
   - Check for interaction notes or special behaviors

6. **Component library**
   - If design uses Figma components, study the component structure
   - Understand component variants (size, state, color options)
   - See how components are composed

---

### 1.4 Document Figma Findings

**Template to use after examining Figma:**

```
Screen: [ScreenName]
Design File: [Link to Figma]
Last Updated: [Date]

LAYOUT
- Device: [375x812 mobile / 600x800 tablet / etc.]
- Safe area reserved: [status bar + nav bar heights]
- Main content area: [usable dimensions]
- Scroll behavior: [scrollable / fixed / with sticky header]

TYPOGRAPHY
Title (h1): [Poppins 20px 600 weight 1.3 line height white #FFF center]
Subtitle: [Poppins 14px 400 weight 1.5 line height gray #9F9FA9 center]
[... repeat for all text styles ...]

COLORS
Primary green: #2ECC71
Dark background: #18181B
Error red: #FF6467
[... all colors used ...]

SPACING (4px grid)
Margins: [16px horizontal, 24px vertical]
Gaps: [32px between major sections, 12px between title and subtitle]

COMPONENTS
- Phone Icon: 80x120px, blue #00A6F4, centered, 32px top margin
- Phone Input: unified field with country dropdown, green border on focus
- Submit Button: "Submit", full width, primary green, fully rounded

INTERACTIVE STATES
Phone Input:
  - Default: gray border #3F3F46
  - Focus: green border #2ECC71
  - Error: red border #FF6467, error text below
  - Disabled: gray background, not clickable

Submit Button:
  - Default: green #2ECC71
  - Disabled: gray #9F9FA9
  - Loading: shows "Sending..." + spinner
  - Pressed: darker shade

VALIDATION
- Phone must be 10+ digits
- Error text: "Please enter a valid phone number"
- Error shown: below input field in red

NAVIGATION
- Back button: not shown
- Next: navigate to /otp route with phone + otpId
```

---

## Part 2: PDF Design Specification Extraction

### 2.1 What to Extract from Design Spec PDFs

Design spec PDFs typically contain:
1. **Screen mockup** - visual screenshot
2. **Annotations** - measurements, spacing notes
3. **Component specifications** - detailed sizing, colors, typography
4. **Design tokens table** - organized color/typography/spacing values
5. **State variations** - different states of interactive elements
6. **Responsive behavior** - how layout changes on different screens
7. **Accessibility notes** - contrast ratios, focus states, alt text
8. **Animation specs** - transition durations, easing, etc.

### 2.2 PDF Extraction Checklist

When reviewing a design spec PDF:

#### Extract Color Specifications
- [ ] **Color name/token** - e.g., "primaryGreen", "bgAppBody"
- [ ] **Hex value** - exact hex code, e.g., "#2ECC71"
- [ ] **RGB value** - rgb(46, 204, 113) for web
- [ ] **Usage** - where is this color used? (background, text, border, etc.)
- [ ] **Variants** - any lighter/darker variants? (e.g., primaryGreenLight, primaryGreenDark)
- [ ] **Opacity** - is any transparency used? (e.g., 0.5 opacity, 80% alpha)

**Example extraction:**
```
Primary Green
  Token: primaryGreen
  Hex: #2ECC71
  RGB: rgb(46, 204, 113)
  Usage: Primary action buttons, focus states, success indicators
  Variants: 
    - primaryGreenLight: #0F4325
    - primaryGreenDark: #092A17
```

#### Extract Typography Specifications
For each text style defined:
- [ ] **Style name** - e.g., "h1", "body", "caption"
- [ ] **Font family** - Poppins, Inter, Roboto, etc.
- [ ] **Font size** - in pixels (e.g., 20px)
- [ ] **Font weight** - 400, 500, 600, 700
- [ ] **Line height** - as percentage (130%, 150%) or multiplier (1.3, 1.5)
- [ ] **Letter spacing** - if specified (usually 0 or specific px value)
- [ ] **Text color** - hex or token reference
- [ ] **Usage** - where is this used? (headings, body text, captions, etc.)
- [ ] **Examples** - sample text showing the style

**Example extraction:**
```
Heading 1 (h1)
  Font: Poppins
  Size: 20px
  Weight: 600 (Semi-bold)
  Line Height: 1.3 (130%)
  Color: #FFFFFF (textWhite)
  Usage: Main screen titles
  Example: "Enter your Phone No."

Body Text
  Font: Poppins
  Size: 14px
  Weight: 400 (Regular)
  Line Height: 1.5 (150%)
  Color: #D4D4D8 (textLight)
  Usage: Paragraph text, descriptions
  Example: "Sign in with your phone number. Password-less and easy"
```

#### Extract Spacing Specifications
- [ ] **Spacing unit** - 4px, 8px, or other base unit
- [ ] **Standard spacing values** - s4, s8, s12, s16, s24, s32, etc.
- [ ] **App-level padding** - horizontal and vertical padding on screens
- [ ] **Component padding** - internal padding in cards, buttons, inputs
- [ ] **Gap sizes** - space between adjacent elements
- [ ] **Margin specifications** - space around elements

**Example extraction:**
```
Spacing System (4px grid)
  Base unit: 4px
  
  Standard values:
    s4: 4px
    s8: 8px
    s12: 12px
    s16: 16px
    s24: 24px
    s32: 32px
  
  App padding:
    Horizontal: 16px (left/right on all screens)
    Vertical: 24px (top/bottom when needed)
  
  Component padding:
    Card: 16px all sides
    Button: 12px vertical, 32px horizontal
    Input: 12px vertical, 16px horizontal
  
  Gaps:
    Between sections: 32px
    Between title and subtitle: 12px
    Between input and button: 32px
```

#### Extract Component Specifications
For each component (button, input, card, etc.):
- [ ] **Component name** - Button, TextField, Card, etc.
- [ ] **Variants** - primary, secondary, outline, disabled, etc.
- [ ] **Size** - width, height, or size variants (small, medium, large)
- [ ] **Padding** - internal spacing
- [ ] **Border** - color, width, radius, style
- [ ] **Background** - color, gradient, opacity
- [ ] **Text styling** - font, size, color, weight
- [ ] **Icon** - if present, which icon, size, color, position
- [ ] **States** - default, hover, focus, active, disabled, loading, error
- [ ] **Interaction** - what happens on click, hover, focus, etc.

**Example extraction:**
```
Primary Button
  Variant: primary
  Width: full width or content-based?
  Height: 48px (or s12 vertical padding)
  Padding: 16px horizontal, 12px vertical (32px h, 12px v)
  
  Default state:
    Background: #2ECC71 (primaryGreen)
    Text color: #06190E (buttonPrimaryText - dark text)
    Border: none
    Border radius: 999px (fully rounded)
  
  Disabled state:
    Background: #9F9FA9 (textMuted - gray)
    Text color: #9F9FA9
    Opacity: 0.6
  
  Loading state:
    Background: #2ECC71
    Text: "Sending..." or loading label
    Icon: spinner (24px, white)
    Position: icon left of text, or replaces icon
  
  Hover state (if applicable):
    Background: darker shade
    Elevation: 4px shadow
```

#### Extract State Variations
Document all states for interactive elements:
- [ ] **How many states are shown in the PDF?**
- [ ] **Visual differences** - color changes, opacity, styling
- [ ] **When states change** - on user interaction or system state?
- [ ] **Feedback timing** - instant or delayed feedback?
- [ ] **Loading indicator** - what shows while loading? (spinner, skeleton, progress)
- [ ] **Error indication** - how are errors shown? (red border, error text, icon)
- [ ] **Success confirmation** - how is success indicated? (green check, message)

**Example extraction:**
```
Phone Input Field States

Default:
  Border: 1px solid #3F3F46 (borderDefault)
  Background: #18181B (bgAppBody)
  Text color: #D4D4D8 (textLight)
  Label: "Phone Number" in #D4D4D8

Focus:
  Border: 2px solid #2ECC71 (primaryGreen)
  Background: #18181B
  Shadow: slight glow effect

Error:
  Border: 2px solid #FF6467 (colorError - red)
  Background: #18181B
  Error text below: "Please enter a valid phone number" in red
  Text color: #FF6467

Disabled:
  Border: 1px solid #3F3F46
  Background: #27272A (bgAppBodyLight - darker)
  Text color: #9F9FA9 (muted)
  Opacity: 0.6
  Not clickable
```

#### Extract Accessibility Specifications
- [ ] **Contrast ratios** - text vs background contrast for readability
- [ ] **Minimum tap target size** - usually 44x44px minimum
- [ ] **Focus indicators** - visual indication when keyboard-focused
- [ ] **Alt text** - for images, icons
- [ ] **Semantic HTML** - label associations, ARIA roles
- [ ] **Color alone** - not used to convey meaning (use icon + color)

### 2.3 PDF Reading Technique

**Best approach for reading design spec PDFs:**

1. **First pass: Overview**
   - Read the title and introduction
   - Understand what screen/feature this spec covers
   - Note the document date and version
   - Check if there are any special notes or dependencies

2. **Second pass: Component extraction**
   - Go through each section systematically
   - Take notes on exact values (colors, sizes, fonts)
   - Screenshot or copy any tables/lists
   - Note any patterns or repeating values

3. **Third pass: Detail verification**
   - Compare values against the visual mockup
   - Verify colors match their descriptions
   - Check spacing measurements against the mockup
   - Verify font sizes appear correct visually

4. **Fourth pass: Organize into structure**
   - Create a organized document with:
     - Colors section (all color tokens)
     - Typography section (all text styles)
     - Spacing section (spacing values)
     - Components section (each component detailed)
     - States section (all interactive states)

---

## Part 3: Design Token Organization System

### 3.1 Token Structure

Organize all extracted design tokens into this hierarchy:

```
DesignTokens
├── COLORS
│   ├── Brand Colors (primaryGreen, primaryGreenLight, primaryGreenDark)
│   ├── Backgrounds (bgAppFoundation, bgAppBody, bgAppBodyLight)
│   ├── Text Colors (textWhite, textLight, textMuted)
│   ├── Semantic (colorSuccess, colorError, colorWarning, colorInfo)
│   ├── Borders & Dividers (borderDefault, dotSeparator)
│   └── State Colors (status*, chip*, tag*)
│
├── TYPOGRAPHY
│   ├── Font Family (fontFamily: 'Poppins')
│   ├── Heading Styles (h1, h2, h3 with size, weight, lineHeight)
│   ├── Body Text (body with size, weight, lineHeight)
│   ├── Caption/Small (small, tiny with size, weight, lineHeight)
│   └── Utility Styles (mono, code if needed)
│
├── SPACING
│   ├── Scale (s4, s6, s8, s12, s16, s20, s24, s28, s32, s36, s40, s48)
│   ├── App-level (appHorizontalPadding, appVerticalPadding)
│   ├── Component-level (cardPadding, buttonPadding, inputPadding)
│   └── Gaps (gapSmall, gapMedium, gapLarge)
│
├── SIZING
│   ├── Border radius (cardRadius, buttonRadius, chipRadius, inputRadius)
│   ├── Icon sizes (iconSmall, iconMedium, iconLarge, iconXLarge)
│   ├── Avatar sizes (avatarSmall, avatarMedium, avatarLarge)
│   └── Component sizes (buttonHeight, inputHeight)
│
└── COMPONENT STYLES
    ├── Button styles (primaryButtonStyle, secondaryButtonStyle, etc.)
    ├── Input styles (inputDecoration, inputHint)
    ├── Card styles (cardDecoration, cardShadow)
    ├── Chip styles (chipDecoration, chipActive, chipDefault)
    └── Shadow/Elevation (shadow4, shadow8, shadow12)
```

### 3.2 Documentation Template

For each token, document:

```dart
/// [Category] - [Purpose]
/// 
/// Usage: Where this token is used
/// Related tokens: Other tokens used with this one
/// States: If applicable, which states use this token
static const Color tokenName = Color(0xFFHEXVALUE);

// Example for a color token:
/// Primary brand green used for main actions
/// 
/// Usage: Primary buttons, focus states, success indicators, primary text
/// Related tokens: primaryGreenDark (#092A17), primaryGreenLight (#0F4325)
/// States: Default state, hover state (darker), focus state
static const Color primaryGreen = Color(0xFF2ECC71);
```

### 3.3 Token Naming Convention

Follow consistent naming:

**Colors:**
```
[category][name][variant]

primary + Green = primaryGreen
primary + Green + Dark = primaryGreenDark
bg + App + Body = bgAppBody
text + White / Light / Muted
color + Success / Error / Warning / Info
border + Default
```

**Typography:**
```
[style name] = h1, h2, h3, body, small, tiny, mono

TextStyle h1 = { fontSize, fontWeight, height, fontFamily }
```

**Spacing:**
```
s[number] = s4, s8, s12, s16, s24, s32
app + [direction] + Padding = appHorizontalPadding, appVerticalPadding
```

**Sizing:**
```
[component] + [dimension] = cardRadius, buttonRadius, iconMedium, avatarLarge
```

---

## Part 4: Implementation Verification Checklist

### 4.1 UI Accuracy Verification

After implementing a screen, verify against the original design:

#### Colors
- [ ] Primary brand color (green) - exact hex match?
- [ ] Background colors - dark body (#18181B), foundation (#09090B)?
- [ ] Text colors - white, light, muted match design?
- [ ] Border colors - gray (#3F3F46) when not focused?
- [ ] Error red - #FF6467 appears when validation fails?
- [ ] All color values use DesignTokens, not hardcoded hex?

#### Typography
- [ ] Font family - all text uses Poppins?
- [ ] Font sizes - measure with inspector (h1=20px, body=14px, etc.)?
- [ ] Font weights - 600 for headings, 400 for body?
- [ ] Line heights - 1.3 for headings, 1.5 for body?
- [ ] Text alignment - centered, left-aligned as designed?
- [ ] Text colors - white for headings, muted for hints?
- [ ] All text uses DesignTokens.h1, DesignTokens.body, etc.?

#### Spacing
- [ ] Top margin - 16px or 32px from top as designed?
- [ ] Horizontal margins - 16px left/right padding?
- [ ] Gaps between elements - measure with inspector?
- [ ] Button size - full width, correct padding?
- [ ] Input padding - 12px vertical, 16px horizontal?
- [ ] All spacing uses DesignTokens constants (s4, s16, etc.)?

#### Components
- [ ] Button styling - green (#2ECC71), fully rounded, white text?
- [ ] Input field - gray border by default, green on focus?
- [ ] Input has correct label, placeholder, helper text?
- [ ] Dropdown styling - matches input field style?
- [ ] All components use Sm* widgets (SmTextField, SmButton)?

#### Icons
- [ ] Icon type - Material icon, custom icon, or image?
- [ ] Icon size - 24px, 32px, 48px as designed?
- [ ] Icon color - matches design (blue #00A6F4, green, etc.)?
- [ ] Icon position - left of text, centered, right?

#### Layout
- [ ] Safe area respected - content doesn't overlap status bar?
- [ ] Scroll behavior - scrolls when content exceeds viewport?
- [ ] Sticky headers - if designed, sticky on scroll?
- [ ] Responsive - works on mobile 375px and tablet 600px+?

#### States
- [ ] Default state - matches design mockup
- [ ] Focus state - green border appears when focused
- [ ] Error state - red border, error text shown
- [ ] Disabled state - grayed out, not clickable
- [ ] Loading state - "Sending..." text, spinner shown
- [ ] Success state - green check, success message shown

### 4.2 Interaction Verification

- [ ] **Input validation** - error appears for invalid input?
- [ ] **Button feedback** - button shows loading state during API call?
- [ ] **Error handling** - error message displays on API failure?
- [ ] **Navigation** - navigates to next screen on success?
- [ ] **Data flow** - correct data passed to next screen?
- [ ] **User feedback** - snackbars/toasts show for important events?
- [ ] **Keyboard** - soft keyboard appears for text inputs?
- [ ] **Accessibility** - focus indicators visible when tabbing?

### 4.3 API Integration Verification

- [ ] **Endpoints correct** - POST to correct API path?
- [ ] **Request format** - sends correct parameters/payload?
- [ ] **Headers** - includes required headers (Content-Type, etc.)?
- [ ] **Response parsing** - correctly parses API response?
- [ ] **Error handling** - displays correct error message for each error?
- [ ] **Token handling** - stores and uses auth token correctly?
- [ ] **Loading state** - shows loading indicator during request?
- [ ] **Timeout handling** - gracefully handles network timeout?

### 4.4 Visual Regression Check

**Side-by-side comparison:**

1. **Take screenshot of implementation**
2. **Compare with Figma design**
3. **Look for differences in:**
   - Colors - are they exactly the same?
   - Spacing - are gaps and margins identical?
   - Typography - are font sizes and weights correct?
   - Alignment - is content aligned the same way?
   - Rounded corners - do border radii match?
   - Shadows - if present, do shadows match?

**Red flags (things that are often different):**
- ❌ Colors slightly off (different shade of green, gray too light/dark)
- ❌ Spacing too loose or too tight (margins/padding wrong size)
- ❌ Font size too large/small (off by 1-2px)
- ❌ Text not centered/aligned same way
- ❌ Button not full width (has wrong margins)
- ❌ Border radius too sharp or too rounded
- ❌ Input field padding different from design
- ❌ Icon size or position off

---

## Part 5: Design Review Checklist

### 5.1 Pre-Implementation Review

Before starting to code, review the design and answer:

#### Understanding
- [ ] **Screen purpose** - what is the main goal of this screen?
- [ ] **User flow** - how did user get here? Where do they go next?
- [ ] **Data model** - what data is displayed on this screen?
- [ ] **API endpoints** - which endpoints does this screen call?
- [ ] **Success criteria** - how do you know the screen is correct?

#### Design Completeness
- [ ] **All states defined** - default, loading, error, success, disabled?
- [ ] **All variations shown** - empty state, with data state, error state?
- [ ] **Typography specified** - all text styles clearly defined?
- [ ] **Colors specified** - all colors have hex values?
- [ ] **Spacing specified** - all margins and gaps defined?
- [ ] **Interactions specified** - what happens on user actions?
- [ ] **Animations specified** - transitions, micro-interactions documented?
- [ ] **Accessibility considered** - focus states, contrast, alt text?

#### Design System Alignment
- [ ] **Uses defined tokens** - only uses colors/typography from system?
- [ ] **Follows spacing grid** - all spacing is multiple of 4px?
- [ ] **Uses existing components** - reuses Sm* widgets?
- [ ] **Consistent with other screens** - visual style matches existing screens?
- [ ] **Responsive design** - works on mobile and tablet sizes?

#### Missing Information
- [ ] **Any ambiguous specs** - anything unclear in the design?
- [ ] **Any edge cases** - what if text is very long? Very short?
- [ ] **Any missing states** - loading while typing? Error while correcting?
- [ ] **Any missing interactions** - what happens on back button? On app pause?
- [ ] **Any open questions** - write them down before implementation

### 5.2 During Implementation Review

As you implement, check:

#### Code Quality
- [ ] **Follows Clean Architecture** - proper separation of data/domain/presentation?
- [ ] **Uses proper state management** - StateNotifier, AsyncNotifier used correctly?
- [ ] **Error handling** - Either<Failure, T> used for all async operations?
- [ ] **No hardcoded values** - all styling uses DesignTokens?
- [ ] **Reusable components** - complex widgets extracted to separate files?
- [ ] **Widget composition** - not too many nested Widgets, easy to read?

#### Design Implementation
- [ ] **Colors accurate** - compare hex values with DesignTokens?
- [ ] **Typography correct** - font size, weight, line height match design?
- [ ] **Spacing consistent** - margins and padding use spacing scale?
- [ ] **Components match** - input fields, buttons styled correctly?
- [ ] **States working** - loading, error, success states implemented?

#### Accessibility
- [ ] **Contrast ratio** - text readable on background? (4.5:1 minimum)
- [ ] **Touch targets** - interactive elements at least 44x44px?
- [ ] **Focus visible** - keyboard focus clearly visible?
- [ ] **Semantic structure** - proper heading hierarchy, labels for inputs?
- [ ] **Alt text** - images and icons have descriptions?

### 5.3 Post-Implementation Review

After implementation, verify:

#### Visual Verification
- [ ] **Screenshots match design** - take side-by-side screenshots?
- [ ] **Colors exact** - use color picker to verify hex values?
- [ ] **Spacing accurate** - measure with inspector, compare with design?
- [ ] **Typography correct** - inspector shows correct size/weight?
- [ ] **All states visible** - loading, error, success states visible?
- [ ] **Responsive** - test on different device sizes?

#### Functional Verification
- [ ] **Validations work** - error messages show for invalid input?
- [ ] **API calls work** - data successfully sent and received?
- [ ] **Navigation works** - routes to correct next screen?
- [ ] **Error handling works** - graceful error display?
- [ ] **Loading states work** - loading indicator shows during requests?

#### Edge Case Verification
- [ ] **Empty state** - what if no data? Handled gracefully?
- [ ] **Long text** - what if text is very long? Truncates correctly?
- [ ] **Network error** - app doesn't crash on network failure?
- [ ] **Large values** - can app handle very large numbers/text?
- [ ] **Special characters** - handles emojis, unicode correctly?

#### Performance
- [ ] **Smooth scrolling** - no jank or frame drops?
- [ ] **Responsive input** - text input responds immediately?
- [ ] **Fast API response** - loading state doesn't show too long?
- [ ] **Memory usage** - no memory leaks on navigation?

### 5.4 Design Review Approval Checklist

Before considering a screen "done":

**Visual Sign-off**
- [ ] **Screenshots approved** - designer reviewed side-by-side screenshots?
- [ ] **Colors approved** - exact hex values match design?
- [ ] **Typography approved** - font sizes and weights correct?
- [ ] **Spacing approved** - layout matches design spacing?
- [ ] **Components approved** - input fields, buttons styled as designed?

**Functional Sign-off**
- [ ] **Happy path works** - successful flow from start to end?
- [ ] **Error paths work** - error handling displays correctly?
- [ ] **Edge cases handled** - empty, long text, special chars, etc.?
- [ ] **Performance acceptable** - no jank, loads quickly?
- [ ] **Accessibility meets standards** - contrast, focus, semantic HTML?

**Technical Sign-off**
- [ ] **Code quality** - follows architecture, no hardcoded values?
- [ ] **Tests pass** - unit tests, widget tests pass?
- [ ] **No console errors** - clean debug output, no warnings?
- [ ] **PR reviewed** - code review feedback addressed?
- [ ] **Documentation complete** - comments, docstrings added?

---

## Part 6: Common Mistakes & How to Avoid Them

### Mistake #1: Missing Padding/Margins
**Problem:** Input field or button has wrong internal padding
**How it happens:** Designer shows component with padding, but spec doesn't explicitly state padding value
**How to avoid:** 
- Measure in Figma: select component → check inspector for padding
- Document padding in notes: "Button has 12px vertical, 32px horizontal padding"
- Use exact values in code: `EdgeInsets.symmetric(h: 32, v: 12)`

### Mistake #2: Color Mismatch
**Problem:** Green looks different than designed
**How it happens:** Designer specifies hex, but different monitor/browser renders differently
**How to avoid:**
- Copy hex directly from Figma color panel, not by visual inspection
- Use Figma's color picker (press Shift+C) to get exact hex
- Test on multiple devices to see rendering differences
- Compare hex values in design tokens: if code says #2ECC71, verify design uses same hex

### Mistake #3: Font Size Off by a Few Pixels
**Problem:** Text looks too large or too small
**How it happens:** Measuring font size by eye instead of reading exact value
**How to avoid:**
- Use Figma inspector (right-click → Inspect) to see exact font size
- Document: "h1 is 20px, not 18px or 22px"
- Use Chrome DevTools to verify rendered size matches expected
- Compare against design tokens: h1Size should be 20

### Mistake #4: Spacing Not on 4px Grid
**Problem:** Gaps between elements look uneven
**How it happens:** Using arbitrary spacing instead of defined scale
**How to avoid:**
- Design system uses 4px grid: s4, s8, s12, s16, s24, s32
- Measure all spacing in design: is it 16px or 20px?
- Use only scale values: `SizedBox(height: DesignTokens.s16)` not `height: 18`
- If design shows 18px, ask designer - it should probably be 16 or 20

### Mistake #5: Using Different Components
**Problem:** Input field looks different from design (using TextField instead of SmTextField)
**How it happens:** Not aware of available reusable components
**How to avoid:**
- Know what Sm* components exist: SmTextField, SmButton, SmPhoneNumberField, etc.
- Check component library before implementing: "do we have this widget?"
- If not available, create it as reusable component (not inline)
- Example: "use SmPhoneNumberField, not custom Row with Dropdown + TextField"

### Mistake #6: Not Checking All States
**Problem:** Loading state not implemented, app shows wrong state
**How it happens:** Only implementing happy path, forgetting loading/error states
**How to avoid:**
- Document all states before coding: default, loading, error, success, disabled
- Design spec should show each state - ask designer if not shown
- Implement all states: `if (isLoading) { ... } else if (hasError) { ... } else { ... }`
- Test each state by triggering it manually

### Mistake #7: Incorrect Validation Messages
**Problem:** Error message doesn't match design or is unclear
**How it happens:** Writing error messages from memory instead of reading design spec
**How to avoid:**
- Design spec documents exact error messages: "Phone must be 10+ digits"
- Use exact text from design: don't rephrase or summarize
- String literals should match exactly: `"Please enter a valid phone number"`
- Test all validation scenarios before submitting

### Mistake #8: Ignoring Accessibility
**Problem:** App doesn't work with keyboard or screen reader
**How it happens:** Focusing only on visual design, forgetting accessibility
**How to avoid:**
- Semantic HTML/Flutter: use Semantics, proper widget types
- Focus indicators: ensure keyboard focus is visible
- Contrast: text should have 4.5:1 contrast ratio minimum
- Alt text: images should have descriptions
- Labels: inputs should have associated labels

---

## Part 7: Figma-to-Code Checklist Template

Use this checklist for EVERY screen you implement from Figma:

```
Screen: [Name]
Figma Link: [URL]
Design Spec PDF: [URL or file name]
Implementation Date: [Date]

DESIGN EXTRACTION COMPLETE
- [ ] Layout dimensions and safe areas documented
- [ ] All typography specs extracted (font, size, weight, line height)
- [ ] All colors documented with hex values and usage
- [ ] All spacing values documented (margins, padding, gaps)
- [ ] All component specifications documented
- [ ] All interactive states documented
- [ ] Validation rules and error messages documented
- [ ] Navigation flow and data passed documented

DESIGN TOKENS CREATED/UPDATED
- [ ] All colors added to DesignTokens
- [ ] All typography styles added to DesignTokens
- [ ] All spacing values added to DesignTokens
- [ ] All component styles added to DesignTokens (if applicable)

IMPLEMENTATION COMPLETE
- [ ] All UI components created/refactored
- [ ] All styling uses DesignTokens (no hardcoded colors/sizes)
- [ ] All reusable components are Sm* widgets
- [ ] Clean Architecture properly implemented (data/domain/presentation)
- [ ] State management working (StateNotifier, loading/error/success states)
- [ ] API integration connected
- [ ] All validations implemented
- [ ] All error messages match design spec exactly
- [ ] All interactive states implemented (default, loading, error, disabled)

VISUAL VERIFICATION
- [ ] Colors match design (hex-for-hex comparison)
- [ ] Typography matches design (size, weight, color)
- [ ] Spacing matches design (measure with inspector)
- [ ] Components styled correctly
- [ ] All states visible and working
- [ ] Layout responsive on mobile and tablet
- [ ] Smooth scrolling, no jank

FUNCTIONAL VERIFICATION
- [ ] Happy path works end-to-end
- [ ] Validation shows errors correctly
- [ ] Loading state shows during API calls
- [ ] Error state shows on API failure
- [ ] Success state navigates to next screen
- [ ] Data correctly passed to next screen
- [ ] Back button works (if shown)

DESIGN REVIEW SIGN-OFF
- [ ] Designer approved screenshots
- [ ] All feedback addressed
- [ ] Final side-by-side comparison approved
- [ ] Ready for QA/testing

READY FOR MERGE
- [ ] Code review approved
- [ ] Tests passing
- [ ] No console errors
- [ ] Documentation complete
```

---

## Summary

This skill provides a systematic approach to:
1. **Extract designs precisely** from Figma (layout, typography, colors, spacing, components, states)
2. **Extract specifications accurately** from design PDFs (organized tokens, component specs)
3. **Organize tokens** in a centralized system (DesignTokens class)
4. **Verify implementations** against original designs (colors, typography, spacing, components, states)
5. **Review designs** before and after implementation (completeness, accuracy, quality)

Use this skill as a reference guide for every design-to-code project. When in doubt, follow the checklists to ensure nothing is missed.
