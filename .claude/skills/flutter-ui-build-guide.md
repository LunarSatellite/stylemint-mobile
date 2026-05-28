# Flutter UI Implementation Guide

**How to ask Claude to build Flutter UI from Figma designs.**

## Quick Start

### 1. Find the feature in `figma-nodes.md`

Example: Want to build the cart screen? Find it:
```
| Cart | 9457-14057 |
```

### 2. Give Claude the feature name

```
/stylemint-mobile-frontend

Build the cart UI.
```

That's it. Claude will:
- Look up the node in figma-nodes.md
- Fetch the Figma design
- Analyze all screens, widgets, components
- Generate the entire presentation layer
- Wire it to the Riverpod provider
- Done ✅

## What You Don't Need to Do

❌ Don't provide Figma links — they're in figma-nodes.md
❌ Don't list screens — Claude analyzes the design
❌ Don't list widgets — Claude extracts them
❌ Don't specify providers — Claude infers from the feature

## Prompt Examples

### Minimal (best)
```
/stylemint-mobile-frontend

Build the checkout UI.
```

### More context (optional)
```
/stylemint-mobile-frontend

Build the product detail screen for the customer role.
```

### If you're adding a new design
```
/stylemint-mobile-frontend

Build the [feature name] UI from this Figma node: 9999-99999
```

## What Gets Built

For each feature, Claude builds:

```
lib/features/[feature_name]/presentation/
├── screens/
│   ├── [screen1]_screen.dart
│   ├── [screen2]_screen.dart
│   └── ...
├── widgets/
│   ├── [custom_widget1].dart
│   ├── [custom_widget2].dart
│   └── ...
└── providers/
    └── [feature_name]_provider.dart  # wired to Riverpod AsyncNotifier
```

All using:
- Design tokens from `lib/theme/design_tokens.dart`
- Shared components from `lib/shared/presentation/widgets/`
- Proper Feature-First Clean Architecture

## Before You Start

Make sure you've read:
1. `stylemint-mobile-frontend` SKILL — stack, architecture, conventions
2. `figma-nodes.md` — feature-to-node mapping
3. This guide ← you're reading it

## Adding New Features

1. Add the feature + node ID to `figma-nodes.md`
2. Ask Claude to build it:
   ```
   /stylemint-mobile-frontend
   
   Build the [feature name] UI.
   ```

That's all.
