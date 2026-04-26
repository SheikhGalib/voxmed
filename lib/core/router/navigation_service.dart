import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

String? _pendingLocation;

void navigateToAppRoute(String location) {
  _pendingLocation = location;
  _flushPendingNavigation();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => _flushPendingNavigation(),
  );
}

void _flushPendingNavigation() {
  final context = rootNavigatorKey.currentContext;
  final location = _pendingLocation;
  if (context == null || location == null) return;

  _pendingLocation = null;
  context.go(location);
}
