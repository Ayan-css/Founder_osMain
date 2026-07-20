import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../isar_service.dart';
import '../collections/task_collection.dart';
import '../../workspace_service.dart';
import '../../notification_service.dart';
import '../../widget_service.dart';

class TaskRepository {
  final Isar _isar = IsarService.instance;
  final _uuid = const Uuid();
  final String? _workspaceId;

  TaskRepository(this._workspaceId);

  // ── READ ──
  Future<List<TaskItem>> getAll() async {
    return _isar.taskItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<TaskItem?> getById(String id) async {
    return _isar.taskItems.filter().idEqualTo(id).findFirst();
  }

  Future<List<TaskItem>> getPinnedTasks() async {
    return _isar.taskItems
        .filter()
        .isPinnedEqualTo(true)
        .not().syncStatusEqualTo('pendingDelete')
        .sortBySortOrder()
        .findAll();
  }

  Future<List<TaskItem>> getIncompleteTasks() async {
    return _isar.taskItems
        .filter()
        .isCompletedEqualTo(false)
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<int> getOpenTaskCount() async {
    return _isar.taskItems
        .filter()
        .isCompletedEqualTo(false)
        .not().syncStatusEqualTo('pendingDelete')
        .count();
  }

  // ── CREATE ──
  Future<TaskItem> create({
    required String title,
    String? description,
    String priority = 'Medium',
    DateTime? dueDate,
    bool isPinned = false,
  }) async {
    final task = TaskItem()
      ..id = _uuid.v4()
      ..title = title
      ..description = description
      ..priority = priority
      ..dueDate = dueDate
      ..isPinned = isPinned
      ..isCompleted = false
      ..workspaceId = _workspaceId
      ..syncStatus = 'pendingCreate'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.taskItems.put(task);
    });
    
    if (task.dueDate != null) {
      await NotificationService().scheduleTaskDeadline(task);
    }
    await WidgetService.syncWidgets();
    return task;
  }

  // ── UPDATE ──
  Future<void> update(TaskItem task) async {
    task.updatedAt = DateTime.now();
    if (task.syncStatus == 'synced') {
      task.syncStatus = 'pendingUpdate';
    }
    await _isar.writeTxn(() async {
      await _isar.taskItems.put(task);
    });
    
    if (task.isCompleted) {
      await NotificationService().cancelTaskDeadline(task.isarId);
    } else if (task.dueDate != null) {
      await NotificationService().scheduleTaskDeadline(task);
    }
    await WidgetService.syncWidgets();
  }

  Future<void> toggleComplete(String id) async {
    final task = await getById(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await update(task);
    }
  }

  Future<void> togglePin(String id) async {
    final task = await getById(id);
    if (task != null) {
      task.isPinned = !task.isPinned;
      await update(task);
    }
  }

  // ── DELETE ──
  Future<void> delete(String id) async {
    final task = await getById(id);
    if (task != null) {
      await NotificationService().cancelTaskDeadline(task.isarId);
      
      task.syncStatus = 'pendingDelete';
      task.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.taskItems.put(task);
      });
      await WidgetService.syncWidgets();
    }
  }

  // ── STREAM ──
  Stream<void> watchAll() {
    return _isar.taskItems.watchLazy();
  }

  Stream<List<TaskItem>> watchAllTasks() {
    return _isar.taskItems
        .filter()
        .not().syncStatusEqualTo('pendingDelete')
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<TaskItem>> watchPinnedTasksStream() {
    return _isar.taskItems
        .filter()
        .isPinnedEqualTo(true)
        .not().syncStatusEqualTo('pendingDelete')
        .sortBySortOrder()
        .watch(fireImmediately: true);
  }

  Stream<int> watchOpenTaskCount() {
    return _isar.taskItems
        .filter()
        .isCompletedEqualTo(false)
        .not().syncStatusEqualTo('pendingDelete')
        .watch(fireImmediately: true)
        .map((tasks) => tasks.length);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final wsId = ref.watch(currentWorkspaceIdProvider);
  return TaskRepository(wsId);
});

final allTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchAllTasks();
});

final pinnedTasksProvider = StreamProvider<List<TaskItem>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchPinnedTasksStream();
});

final openTaskCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchOpenTaskCount();
});
