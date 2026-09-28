import 'package:flutter/material.dart';

/// Closes the on-screen keyboard when the user taps outside a text field or
/// starts dragging a scrollable, anywhere in the app.
///
/// Before this existed, dismissal was a per-screen opt-in: a handful of
/// screens set `keyboardDismissBehavior: onDrag` or wrapped themselves in a
/// `GestureDetector` that unfocused, and every other screen left the keyboard
/// up with no way down but the system back gesture. Wiring it once above the
/// router makes the behaviour uniform instead of depending on whether whoever
/// built a given screen remembered.
///
/// Two gestures dismiss, matching what the platform keyboards already train
/// people to expect:
///
///  * **Tap outside.** The [GestureDetector] sits above the router with
///    [HitTestBehavior.translucent], so it sees taps that nothing else
///    claimed. Gesture-arena resolution is what keeps this safe: a tap landing
///    on a button, a link or another [TextField] is won by that widget's own
///    recognizer and never reaches here, so tapping from one field straight
///    into another still moves focus rather than closing the keyboard.
///
///  * **Drag a scrollable.** [ScrollStartNotification] with non-null
///    `dragDetails` is a drag the user's finger started — programmatic scrolls
///    (an autoscroll, a page animation, scroll-into-view when a field gains
///    focus) carry null details and are ignored. That last exclusion matters:
///    focusing a field near the bottom of a form scrolls it into view, and
///    reacting to that would close the keyboard the tap had just opened.
///
/// Both paths are guarded on the keyboard actually being up
/// ([MediaQueryData.viewInsets]), so with no keyboard on screen this widget
/// changes nothing about focus — a tap on empty space leaves the focused
/// widget alone rather than silently dropping focus.
class DismissKeyboardOnInteraction extends StatelessWidget {
  const DismissKeyboardOnInteraction({required this.child, super.key});

  final Widget child;

  /// Drops focus, which is what lowers the keyboard.
  static void _dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    // Read during build, not from inside the callbacks: this registers the
    // inherited-widget dependency in the one place that is unambiguously
    // correct, and rebuilds this widget whenever the keyboard opens or closes.
    //
    // Reading the inset rather than "is something focused" is deliberate: a
    // focused button or a focus-traversal position is not a keyboard, and a
    // tap on the background should leave it alone.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return NotificationListener<ScrollStartNotification>(
      // false: the notification keeps bubbling. Scrollables and any listener
      // above this one still see their own scroll starts — this only observes.
      onNotification: (notification) {
        if (keyboardVisible && notification.dragDetails != null) _dismiss();
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: keyboardVisible ? _dismiss : null,
        child: child,
      ),
    );
  }
}
