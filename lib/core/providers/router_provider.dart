// lib/core/providers/router_provider.dart
//
// Pont Riverpod vers `appRouter` (singleton go_router existant, P3.3) —
// ne le duplique pas, permet juste de le lire via `ref.watch(routerProvider)`
// (P3.7). `guards.dart`, le `refreshListenable` branché sur `authState` et
// tout le reste du routage restent inchangés.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/router/app_router.dart';

final routerProvider = Provider<GoRouter>((ref) => appRouter);
