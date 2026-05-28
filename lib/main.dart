import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/format_date.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezone();

  runApp(
    const ProviderScope(
      child: StyleMintApp(),
    ),
  );
}
