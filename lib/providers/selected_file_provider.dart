import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_node.dart';
import 'services_provider.dart';

/// The currently selected file for viewing.
final selectedFileProvider = StateProvider<FileNode?>((ref) => null);

/// The markdown content of the selected file.
final selectedFileContentProvider = FutureProvider.autoDispose<String?>((ref) async {
  final file = ref.watch(selectedFileProvider);
  if (file == null || file.isDirectory) return null;

  try {
    return await ref.read(fileServiceProvider).readFile(file.path);
  } catch (e) {
    return null;
  }
});
