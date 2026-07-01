import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase App Check static contract', () {
    final libFiles = _dartFilesIn(Directory('lib'));

    test('debug App Check providers are guarded and have release providers', () {
      final offenders = <String>[];

      for (final file in libFiles) {
        final source = file.readAsStringSync();
        final usesAndroidDebug =
            source.contains('AndroidDebugProvider') ||
            source.contains('AndroidProvider.debug');
        final usesAppleDebug =
            source.contains('AppleDebugProvider') ||
            source.contains('AppleProvider.debug');

        if (usesAndroidDebug) {
          if (!_hasDebugOrLocalGuard(source) ||
              !_hasAndroidReleaseProvider(source)) {
            offenders.add(_relativePath(file));
          }
        }

        if (usesAppleDebug) {
          if (!_hasDebugOrLocalGuard(source) ||
              !_hasAppleReleaseProvider(source)) {
            offenders.add(_relativePath(file));
          }
        }
      }

      expect(offenders, isEmpty);
    });

    test('Firebase emulators are guarded for local/debug only', () {
      final offenders = <String>[];

      for (final file in libFiles) {
        final source = file.readAsStringSync();
        final usesEmulator =
            source.contains('useFirestoreEmulator') ||
            source.contains('useAuthEmulator') ||
            source.contains('useStorageEmulator');

        if (usesEmulator && !_hasDebugOrLocalGuard(source)) {
          offenders.add(_relativePath(file));
        }
      }

      expect(offenders, isEmpty);
    });

    test('no App Check debug token or Firebase localhost is hardcoded in lib', () {
      final offenders = <String>[];

      for (final file in libFiles) {
        final source = file.readAsStringSync();
        final hasDebugToken = source.contains('debugToken');
        final hasFirebaseLocalhost =
            source.contains('localhost') &&
            (source.contains('Firebase') ||
                source.contains('Firestore') ||
                source.contains('Storage') ||
                source.contains('Auth') ||
                source.contains('Emulator'));

        if (hasDebugToken ||
            (hasFirebaseLocalhost && !_hasDebugOrLocalGuard(source))) {
          offenders.add(_relativePath(file));
        }
      }

      expect(offenders, isEmpty);
    });

    test('Firebase initializeApp is not duplicated in lib', () {
      var initializeAppCount = 0;

      for (final file in libFiles) {
        final source = file.readAsStringSync();
        initializeAppCount += 'Firebase.initializeApp'.allMatches(source).length;
      }

      expect(initializeAppCount, 1);
    });
  });
}

List<File> _dartFilesIn(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

bool _hasDebugOrLocalGuard(String source) {
  return source.contains('kDebugMode') ||
      source.contains('assert(') ||
      source.contains('bool.fromEnvironment') ||
      source.contains('String.fromEnvironment');
}

bool _hasAndroidReleaseProvider(String source) {
  return source.contains('AndroidPlayIntegrityProvider') ||
      source.contains('AndroidProvider.playIntegrity');
}

bool _hasAppleReleaseProvider(String source) {
  return source.contains('AppleDeviceCheckProvider') ||
      source.contains('AppleAppAttestProvider') ||
      source.contains('AppleAppAttestWithDeviceCheckFallbackProvider') ||
      source.contains('AppleProvider.deviceCheck') ||
      source.contains('AppleProvider.appAttest');
}

String _relativePath(File file) {
  return file.path.replaceAll('\\', '/');
}
