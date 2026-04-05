import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import '../services/watcher_service.dart';
import '../services/bookmark_service.dart';

// ─── Services (singletons) ───

final fileServiceProvider = Provider<FileService>((ref) => FileService());
final watcherServiceProvider = Provider<WatcherService>((ref) => WatcherService());
final bookmarkServiceProvider = Provider<BookmarkService>((ref) => BookmarkService());
