import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/utils/json_codec.dart';
import '../../model/task.dart';
import 'task_store.dart';

class TaskFileStore implements TaskStore {
  TaskFileStore({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  @override
  Future<List<Task>> readAll() async {
    try {
      final file = await _tasksFile();
      if (!await file.exists()) {
        return <Task>[];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return <Task>[];
      }

      final decoded = JsonCodecUtil.decode(raw);
      if (decoded is! List<dynamic>) {
        return <Task>[];
      }

      final tasks = <Task>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final taskMap = Map<String, dynamic>.from(item);
        try {
          tasks.add(Task.fromJson(taskMap));
        } on FormatException {
          // Skip malformed entry and keep the rest readable.
        }
      }
      return tasks;
    } on FileSystemException {
      return <Task>[];
    } on FormatException {
      return <Task>[];
    }
  }

  @override
  Future<void> writeAll(List<Task> tasks) async {
    final file = await _tasksFile();
    final tempFile = File('${file.path}.tmp');
    final encoded = JsonCodecUtil.encode(
      tasks.map((task) => task.toJson()).toList(),
    );

    await tempFile.writeAsString(encoded, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tempFile.rename(file.path);
  }

  Future<File> _tasksFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/tasks.json');
  }
}
