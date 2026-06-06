import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the app session is currently unlocked. App sets this on successful auth.
final sessionUnlockedProvider = StateProvider<bool>((ref) => true);

final biometricProvider = StateNotifierProvider<BiometricNotifier, bool>((ref) => BiometricNotifier());

class BiometricNotifier extends StateNotifier<bool> {
  final LocalAuthentication _auth = LocalAuthentication();
  static const _key = 'biometric_enabled';

  BiometricNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (_) {
      state = false;
    }
    // mark initialization complete
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  final Completer<void> _initCompleter = Completer<void>();

  /// Wait until provider has loaded stored preference
  Future<void> ensureInitialized() => _initCompleter.future;

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  String? _lastAuthError;

  Future<bool> authenticate() async {
    _lastAuthError = null;
    try {
      final supported = await isDeviceSupported();
      if (!supported) {
        _lastAuthError = 'Biometrics not supported';
        return false;
      }
      final didAuth = await _auth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!didAuth) {
        _lastAuthError = 'User did not authenticate';
      }
      return didAuth;
    } catch (e) {
      _lastAuthError = e.toString();
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// Toggle biometric on/off.
  /// Returns null on success, or an error message on failure.
  Future<String?> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (!state) {
      // enabling -> ensure device supports biometrics and authenticate first
      final supported = await isDeviceSupported();
      if (!supported) return 'Device does not support biometrics';
      try {
        final ok = await authenticate();
        if (!ok) {
          // Provide more specific messages
          final supported = await isDeviceSupported();
          if (!supported) return 'Device does not support biometrics';
          final av = await availableBiometrics();
          if (av.isEmpty) return 'No biometrics enrolled on device';
          if (_lastAuthError != null && _lastAuthError!.isNotEmpty) return 'Authentication failed: ${_lastAuthError!}';
          return 'Authentication failed';
        }
        await prefs.setBool(_key, true);
        state = true;
        return null;
      } catch (e) {
        return 'Biometric error: $e';
      }
    } else {
      // disabling
      try {
        await prefs.setBool(_key, false);
        state = false;
        return null;
      } catch (e) {
        return 'Failed to disable biometrics: $e';
      }
    }
  }
}
