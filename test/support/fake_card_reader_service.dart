import 'dart:async';

import 'package:dtw_app/core/nfc/card_reader_service.dart';

/// In-memory [CardReaderService]. A test taps a card with [tap], or makes the
/// read fail with [fail]; [cancelCallCount] records cancellations.
class FakeCardReaderService implements CardReaderService {
  FakeCardReaderService({this.state = CardReaderAvailability.available});

  CardReaderAvailability state;
  int cancelCallCount = 0;
  int readCallCount = 0;
  Completer<String>? _pending;

  @override
  Future<CardReaderAvailability> availability() async => state;

  @override
  Future<String> readCardUid({
    Duration timeout = const Duration(seconds: 30),
  }) {
    readCallCount++;
    _pending = Completer<String>();
    return _pending!.future;
  }

  void tap(String uid) => _pending?.complete(uid);

  void fail(String message) =>
      _pending?.completeError(CardReadException(message));

  @override
  Future<void> cancel() async {
    cancelCallCount++;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const CardReadException('Dibatalkan.'));
    }
  }
}
