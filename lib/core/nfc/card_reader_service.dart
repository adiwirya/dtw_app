import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_reader_service.g.dart';

enum CardReaderAvailability { available, disabled, unsupported }

/// Why [CardReaderService.readCardUid] gave up without a UID.
class CardReadException implements Exception {
  const CardReadException(this.message);

  final String message;

  @override
  String toString() => 'CardReadException: $message';
}

/// Reads an NFC card's UID for tap-login. Abstracted behind an interface so
/// tests can substitute a fake — the real implementation needs NFC hardware,
/// see `test/support/fake_card_reader_service.dart`.
abstract class CardReaderService {
  Future<CardReaderAvailability> availability();

  /// Waits for a card and returns its UID as upper-case hex with no
  /// separators (e.g. `04A1B2C3D4E5F6`). Throws [CardReadException] on
  /// timeout, cancellation or a read failure.
  Future<String> readCardUid({
    Duration timeout = const Duration(seconds: 30),
  });

  /// Stops an in-flight [readCardUid]. Safe to call when idle.
  Future<void> cancel();
}

/// [CardReaderService] backed by `package:flutter_nfc_kit`, the same package
/// `pos-mobile` uses for its tap-card login. Android only — iOS is reported
/// as [CardReaderAvailability.unsupported] (this app's NFC hardware is the
/// Android POS/handheld devices).
class FlutterNfcKitCardReaderService implements CardReaderService {
  @override
  Future<CardReaderAvailability> availability() async {
    if (!Platform.isAndroid) return CardReaderAvailability.unsupported;
    try {
      return switch (await FlutterNfcKit.nfcAvailability) {
        NFCAvailability.available => CardReaderAvailability.available,
        NFCAvailability.disabled => CardReaderAvailability.disabled,
        NFCAvailability.not_supported => CardReaderAvailability.unsupported,
      };
    } on PlatformException {
      return CardReaderAvailability.unsupported;
    }
  }

  @override
  Future<String> readCardUid({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final tag = await FlutterNfcKit.poll(timeout: timeout);
      return tag.id.toUpperCase();
    } on PlatformException catch (error) {
      throw CardReadException(
        error.code == '408'
            ? 'Waktu habis. Tempelkan kartu lagi.'
            : 'Kartu gagal dibaca. Coba lagi.',
      );
    } finally {
      await cancel();
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await FlutterNfcKit.finish();
    } on PlatformException {
      // Nothing was in flight.
    }
  }
}

@Riverpod(keepAlive: true)
CardReaderService cardReaderService(Ref ref) =>
    FlutterNfcKitCardReaderService();
