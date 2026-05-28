import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/utils/size_config.dart';

/// Passes [SizeConfig] and [ThemeData] to every widget — adapted from vpt-mydawa.
class BaseWidget extends StatelessWidget {
  const BaseWidget({super.key, required this.builder});

  final Widget Function(BuildContext context, SizeConfig config, ThemeData theme) builder;

  @override
  Widget build(BuildContext context) =>
      builder(context, SizeConfig(context), Theme.of(context));
}

/// Hook-based variant.
class HookBaseWidget extends HookWidget {
  const HookBaseWidget({super.key, required this.builder});

  final Widget Function(BuildContext context, SizeConfig config, ThemeData theme) builder;

  @override
  Widget build(BuildContext context) =>
      builder(context, SizeConfig(context), Theme.of(context));
}
