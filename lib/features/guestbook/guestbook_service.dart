import 'dart:async';

class GuestEntry {
  const GuestEntry({
    required this.name,
    required this.message,
    required this.at,
  });
  final String name;
  final String message;
  final DateTime at;
}

abstract class GuestbookService {
  Stream<List<GuestEntry>> watch(); // newest first
  Future<void> add(String name, String message);
}

/// Default — works immediately, no backend.
/// Seeded with a couple of sample notes.
///
/// Swap for FirestoreGuestbook (optional) by changing [guestbookService].
class InMemoryGuestbook implements GuestbookService {
  final _entries = <GuestEntry>[
    GuestEntry(
      name: 'Aanya',
      message: 'Love the aurora ✨',
      at: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    GuestEntry(
      name: 'Rahul',
      message: 'The Monte Carlo demo is sick',
      at: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    GuestEntry(
      name: 'Priya',
      message: 'That sorting viz is so satisfying to watch',
      at: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  final _ctrl = StreamController<List<GuestEntry>>.broadcast();

  InMemoryGuestbook() {
    Future.microtask(_emit);
  }

  void _emit() => _ctrl.add(List.unmodifiable(_entries));

  @override
  Stream<List<GuestEntry>> watch() async* {
    yield List.unmodifiable(_entries);
    yield* _ctrl.stream;
  }

  @override
  Future<void> add(String name, String message) async {
    _entries.insert(
      0,
      GuestEntry(name: name, message: message, at: DateTime.now()),
    );
    _emit();
  }
}

/// Global service instance.
/// Replace with FirestoreGuestbook() once firebase_core +
/// cloud_firestore are configured (see optional Phase 5c).
final GuestbookService guestbookService = InMemoryGuestbook();
