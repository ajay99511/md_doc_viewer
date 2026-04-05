import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';

/// Service for watching directory changes in real-time.
class WatcherService {
  final Map<String, StreamSubscription<WatchEvent>> _subscriptions = {};
  final _changeController = StreamController<String>.broadcast();

  /// Stream of changed directory paths.
  Stream<String> get changes => _changeController.stream;

  /// Start watching a directory.
  void watch(String directoryPath) {
    if (_subscriptions.containsKey(directoryPath)) return;

    try {
      final dir = Directory(directoryPath);
      if (!dir.existsSync()) return;

      final watcher = DirectoryWatcher(directoryPath);
      final subscription = watcher.events.listen((event) {
        final parentDir = Directory(event.path).parent.path;
        _changeController.add(parentDir);
      });
      _subscriptions[directoryPath] = subscription;
    } catch (e) {
      // Permission denied or directory doesn't exist
    }
  }

  /// Stop watching a directory.
  void unwatch(String directoryPath) {
    _subscriptions.remove(directoryPath)?.cancel();
  }

  /// Watch multiple directories.
  void watchAll(Iterable<String> directoryPaths) {
    for (final path in directoryPaths) {
      watch(path);
    }
  }

  /// Unwatch multiple directories.
  void unwatchAll(Iterable<String> directoryPaths) {
    for (final path in directoryPaths) {
      unwatch(path);
    }
  }

  /// Stop watching all directories.
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _changeController.close();
  }
}
