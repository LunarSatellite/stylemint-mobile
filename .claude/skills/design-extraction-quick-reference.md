# Design Extraction Quick Reference

**Use this checklist for EVERY screen implementation. Print it out or bookmark it.**

---

## 5-Minute Pre-Implementation Checklist

Before you code a single widget, complete this in 5 minutes:

### Step 1: Open Figma File (2 min)
```
1. Open Figma design file
2. Identify the screen you're implementing
3. Check if there are multiple states shown (default, loading, error, success)
4. Look for components used (buttons, inputs, cards)
5. Check for design notes or annotations in comments
```

**Questions to answer:**
- [ ] What is the main user goal on this screen?
- [ ] What are the 3-5 most important visual elements?
- [ ] Are there loading, error, or success states shown?

### Step 2: Check Design Spec PDF (2 min)
```
1. Open the design spec PDF for this screen
2. Search for sections: Colors, Typography, Spacing, Components
3. Look for a table or list of design tokens
4. Find the specific screen/component you're building
```

**Key things to copy/document:**
- [ ] All color hex values (#2ECC71, #FF6467, etc.)
- [ ] All font sizes and weights (20px 600, 14px 400, etc.)
- [ ] All spacing values used on screen (margins, padding, gaps)
- [ ] All validation rules and error messages

### Step 3: Extract Core Design Data (1 min)
Create a simple text file with:

```
SCREEN: [Name]
COLORS USED: primaryGreen, bgAppBody, textWhite, textMuted, colorError
TYPOGRAPHY: h1 (20px 600), body (14px 400), small (12px 400)
SPACING: margins 16px, gaps 32px, padding 12-16px
MAIN COMPONENTS: Button, Input, Icon, Text
STATES: default, loading, error, success
ERROR MESSAGES: "Please enter a valid X", "X is required"
```

---

## Implementation Workflow

### Before Coding

**Figma Inspection Checklist:**
- [ ] Select each element and note exact color (use Inspect panel, copy hex)
- [ ] Check Typography for each text element (font, size, weight, line height)
- [ ] Measure spacing (margins between elements, padding inside containers)
- [ ] Document all interactive states (hover, focus, disabled, loading)
- [ ] Note all validation messages exactly as written

**Design System Check:**
- [ ] Are all colors already in DesignTokens?
- [ ] Are all text styles (h1, body, small) already defined?
- [ ] Are all spacing values (s16, s32) already defined?
- [ ] Do reusable components (Sm*) exist for what you need?

**If any are missing:**
- [ ] Add colors to DesignTokens
- [ ] Add typography styles to DesignTokens
- [ ] Add spacing values to DesignTokens
- [ ] Create reusable Sm* component (don't hardcode)

---

## Coding Checklist

### Colors
- [ ] **Every color uses DesignTokens**
  ```dart
  ❌ color: Color(0xFF2ECC71)  // WRONG - hardcoded
  ✅ color: DesignTokens.primaryGreen  // CORRECT
  ```
- [ ] **Verify hex values match**
  - Copy from Figma Inspect panel
  - Compare with DesignTokens constant
  - If different, ask why before changing

### Typography
- [ ] **Every text uses a style**
  ```dart
  ❌ Text('Title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
  ✅ Text('Title', style: DesignTokens.h1)
  ```
- [ ] **Font, size, weight, line height match design**
  - h1: Poppins 20px 600 weight 1.3 line height
  - body: Poppins 14px 400 weight 1.5 line height
  - small: Poppins 12px 400 weight 1.3 line height

### Spacing
- [ ] **All spacing uses DesignTokens constants**
  ```dart
  ❌ SizedBox(height: 24)  // Magic number
  ✅ SizedBox(height: DesignTokens.s24)  // Token
  ```
- [ ] **Values are on 4px grid**
  - Allowed: s4, s8, s12, s16, s20, s24, s28, s32, s36, s40, s48
  - Not allowed: 5, 10, 15, 18, 22, 25, etc.

### Components
- [ ] **Buttons styled with SmPrimaryButton**
  ```dart
  SmPrimaryButton(
    label: 'Submit',  // Match Figma text exactly
    onPressed: _handleSubmit,
  )
  ```

- [ ] **Input fields use SmPhoneNumberField, SmTextField, etc.**
  ```dart
  SmPhoneNumberField(
    controller: _controller,
    labelText: 'Phone Number',  // Match Figma label
    enabled: !isLoading,
  )
  ```

- [ ] **All custom components prefixed with Sm***, stored in `lib/shared/presentation/widgets/`

### States
- [ ] **Loading state implemented**
  ```dart
  if (isLoading) {
    // Show spinner, disable button, show "Sending..."
  } else {
    // Normal state
  }
  ```

- [ ] **Error state implemented**
  ```dart
  if (hasError) {
    SmSnackbar.error(context, 'Exact error message from design spec');
  }
  ```

- [ ] **Success state implemented**
  ```dart
  if (isSuccess) {
    // Navigate to next screen or show success message
  }
  ```

- [ ] **Disabled state implemented**
  ```dart
  button.disabled = isLoading;
  input.enabled = !isLoading;
  ```

### Validation
- [ ] **Validation messages match design spec exactly**
  ```dart
  ❌ "Invalid input"  // Generic message
  ✅ "Please enter a valid phone number"  // From design spec
  ```

- [ ] **Error shown in correct location**
  - Below input field? Inside field? As toast?
  - Show both text and visual indicator (red border, icon)

---

## Visual Verification Checklist

After implementation, before submitting:

### Screenshot Comparison
1. **Take screenshot of your implementation**
2. **Open Figma design side-by-side**
3. **Compare systematically:**

| Element | Design | Implementation | Match? |
|---------|--------|-----------------|--------|
| Color of button | #2ECC71 | (check in DevTools) | ✓/✗ |
| Font size of title | 20px | (inspect in DevTools) | ✓/✗ |
| Margin from top | 32px | (measure spacing) | ✓/✗ |
| Button text | "Submit" | (same as Figma) | ✓/✗ |
| Border color focused | #2ECC71 | (test focus state) | ✓/✗ |

### Red Flags (Things Often Wrong)
- ❌ Green looks different shade (hex mismatch)
- ❌ Text size off by 1-2px (wrong font size in code)
- ❌ Spacing too loose/tight (wrong margin or padding)
- ❌ Button not full width (has unwanted margins)
- ❌ Text not centered (wrong alignment)
- ❌ Border radius too sharp/round (wrong cardRadius)
- ❌ Input field padding wrong (wrong horizontal/vertical padding)

**If you see ANY of these, fix it before submitting.**

---

## State Management Checklist

For screens with async operations (API calls, form submission):

### StateNotifier Setup
```dart
✅ CORRECT:
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState());  // Starts with isLoading: false
  
  Future<void> doSomething() async {
    state = state.copyWith(isLoading: true, error: null);
    // API call...
    state = state.copyWith(isLoading: false, data: result);
  }
}

❌ WRONG:
class MyNotifier extends AsyncNotifier<MyState> {  // AsyncNotifier shows loading on initial
  // ...
}
```

### Watch Provider in Widget
```dart
✅ CORRECT:
final myState = ref.watch(myProvider);
final isLoading = myState.isLoading;
final hasError = myState.hasError;
final data = myState.data;

if (isLoading) { ... }
else if (hasError) { ... }
else { ... }

❌ WRONG:
final asyncValue = ref.watch(myProvider);
if (asyncValue is AsyncLoading) { ... }  // Shows loading on initial load
```

### Read Notifier for Actions
```dart
✅ CORRECT:
ref.read(myProvider.notifier).doSomething();

❌ WRONG:
ref.watch(myProvider.notifier).doSomething();  // watch is for state, not actions
```

---

## Error Message Checklist

Every error message must come from the design spec:

### Find in Design Spec:
```
1. Open design spec PDF
2. Search for "error" or "validation"
3. Find table or section listing all error messages
4. Copy exact text (including capitalization)
```

### Code Implementation:
```dart
✅ CORRECT - matches design spec exactly:
if (phone.length < 10) {
  SmSnackbar.error(context, 'Please enter a valid phone number');
}

❌ WRONG - different message:
if (phone.length < 10) {
  SmSnackbar.error(context, 'Invalid phone');  // Not in spec
}

❌ WRONG - grammatical variation:
if (phone.length < 10) {
  SmSnackbar.error(context, 'Please enter a valid phone number.');  // Extra period
}
```

---

## Post-Implementation Checklist

After you think you're done:

### 1. Visual Check (2 min)
- [ ] Colors match design exactly
- [ ] Typography matches (size, weight, color)
- [ ] Spacing matches (margins, padding, gaps)
- [ ] All interactive elements styled correctly
- [ ] Loading state shows while waiting
- [ ] Error state shows on failure
- [ ] Success state navigates or confirms

### 2. Functional Check (2 min)
- [ ] Happy path works end-to-end
- [ ] Validation shows errors
- [ ] Error messages match spec
- [ ] Loading prevents double-submission
- [ ] Navigation works correctly
- [ ] Back button works (if shown)

### 3. Code Quality Check (2 min)
- [ ] No hardcoded colors (all use DesignTokens)
- [ ] No magic spacing numbers (all use DesignTokens)
- [ ] All text styles use DesignTokens
- [ ] Reusable components are Sm* widgets
- [ ] Clean Architecture followed
- [ ] No console errors

### 4. Ready to Submit?
Ask yourself:
- [ ] Would a designer approve this visually?
- [ ] Does it work end-to-end with no errors?
- [ ] Is the code maintainable and follows patterns?

If yes to all → submit for review  
If no to any → fix and re-check

---

## Common Mistakes & Quick Fixes

| Mistake | How to Fix |
|---------|-----------|
| Color slightly different | Copy hex from Figma Inspect, update DesignTokens |
| Text too large/small | Check DesignTokens has correct fontSize, verify in code |
| Spacing too loose | Measure in Figma, use correct s* value |
| Button not full width | Add `SizedBox(width: double.infinity, child: button)` |
| Text not centered | Add `textAlign: TextAlign.center` or use Center widget |
| Loading state shows initially | Use StateNotifier not AsyncNotifier |
| Error message wrong | Copy exact text from design spec PDF |
| Input field looks wrong | Verify label, placeholder, hint, padding match design |
| Missing state | Check design spec for all states: default, loading, error, success |

---

## When to Stop and Ask Questions

❓ **Stop and ask if:**
- Design spec doesn't show a state (e.g., what shows while loading?)
- Error message not in design spec (what should it say?)
- Component doesn't exist (should you create it or use something else?)
- Spacing value not on 4px grid (should it be 16px or 20px?)
- Color hex in Figma doesn't match DesignTokens (is DesignTokens wrong or design wrong?)

✅ **Don't guess — clarify first before coding**

---

## Skill Reference

For deep dives on design extraction:
- **Full Figma extraction guide** → See `/design-extraction-and-review.md` Part 1
- **PDF spec extraction** → See `/design-extraction-and-review.md` Part 2
- **Design token organization** → See `/design-extraction-and-review.md` Part 3
- **Implementation verification** → See `/design-extraction-and-review.md` Part 4
- **Design review checklist** → See `/design-extraction-and-review.md` Part 5
- **Common mistakes** → See `/design-extraction-and-review.md` Part 6

---

## The Golden Rule

> **If it looks different from Figma, it's wrong — even if the code "works"**

Always verify visually against the original design before submitting.
