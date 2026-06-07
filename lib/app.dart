import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/auth_provider.dart';

class WealthTrackerApp extends ConsumerStatefulWidget {
  const WealthTrackerApp({super.key});

  @override
  ConsumerState<WealthTrackerApp> createState() => _WealthTrackerAppState();
}

class _WealthTrackerAppState extends ConsumerState<WealthTrackerApp> with WidgetsBindingObserver {
  bool _authChecked = false;
  bool _authed = false;
  bool _authInProgress = false;
  DateTime? _lastAuthAttempt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticateOnStart();
  }

  Future<void> _authenticateOnStart() async {
    // ensure provider has loaded saved preference
    try {
      await ref.read(biometricProvider.notifier).ensureInitialized();
    } catch (_) {}
    final enabled = ref.read(biometricProvider);
    if (!enabled) {
      setState(() {
        _authed = true;
        _authChecked = true;
      });
      return;
    }
    // avoid overlapping attempts
    _authInProgress = true;
    _lastAuthAttempt = DateTime.now();
    final ok = await ref.read(biometricProvider.notifier).authenticate();
    _authInProgress = false;
    setState(() {
      _authed = ok;
      _authChecked = true;
    });
    // update global session state
    ref.read(sessionUnlockedProvider.notifier).state = ok;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Lock the app when backgrounded and require biometric on resume
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Mark locked; will re-authenticate on resume if biometrics enabled
      setState(() {
        _authed = false;
      });
      // also update global session state to indicate locked
      ref.read(sessionUnlockedProvider.notifier).state = false;
    } else if (state == AppLifecycleState.resumed) {
      // On resume, if biometrics enabled, try to authenticate immediately
      Future.microtask(() async {
        // don't attempt resume auth while initial auth is running or before we finished startup checks
        if (!_authChecked) return;
        // if already authenticated, no need to re-auth
        if (_authed) return;
        final enabled = ref.read(biometricProvider);
        if (!enabled) return;
        // throttle attempts and avoid overlapping auth prompts
        final now = DateTime.now();
        if (_authInProgress) return;
        if (_lastAuthAttempt != null && now.difference(_lastAuthAttempt!).inSeconds < 2) return;
        _authInProgress = true;
        _lastAuthAttempt = now;
        final ok = await ref.read(biometricProvider.notifier).authenticate();
        _authInProgress = false;
        if (ok) {
          setState(() => _authed = true);
          ref.read(sessionUnlockedProvider.notifier).state = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(darkModeProvider);

    if (!_authChecked) {
      return const MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    if (!_authed) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Finance Master')),
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Authenticate to unlock the app.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_authInProgress) return;
                  final now = DateTime.now();
                  if (_lastAuthAttempt != null && now.difference(_lastAuthAttempt!).inSeconds < 2) return;
                  _authInProgress = true;
                  _lastAuthAttempt = now;
                  final ok = await ref.read(biometricProvider.notifier).authenticate();
                  _authInProgress = false;
                  if (ok) {
                    // mark both local and global session unlocked
                    setState(() => _authed = true);
                    ref.read(sessionUnlockedProvider.notifier).state = true;
                  }
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ]),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Finance Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
