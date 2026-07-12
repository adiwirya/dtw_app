import 'package:flutter/material.dart';

/// A neutral stub page used by the routing skeleton until the real screen for a
/// given frame is implemented by a later work item.
///
/// Later items should replace the route `builder:` in `app_router.dart` with
/// the concrete screen — the route name/path stays the same, so nothing else
/// needs to change.
// TODO(open-question): replace each PlaceholderScreen usage with the real
// feature screen as items 02–12 land.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  /// Human-readable name of the frame this placeholder stands in for.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
