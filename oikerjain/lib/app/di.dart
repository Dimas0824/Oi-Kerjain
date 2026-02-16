import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../core/time/clock.dart';
import '../core/utils/id.dart';
import '../data/local/in_memory_task_store.dart';
import '../data/local/task_file_store.dart';
import '../data/local/task_store.dart';
import '../data/task_repository_impl.dart';
import '../domain/scheduler/reminder_scheduler.dart';
import '../domain/task_repository.dart';
import '../domain/usecase/cleanup_expired_history.dart';
import '../domain/usecase/compute_next_occurrence.dart';
import '../domain/usecase/delete_task.dart';
import '../domain/usecase/get_tasks.dart';
import '../domain/usecase/get_history_tasks.dart';
import '../domain/usecase/handle_notification_action.dart';
import '../domain/usecase/mark_done.dart';
import '../domain/usecase/reschedule_all.dart';
import '../domain/usecase/snooze_task.dart';
import '../domain/usecase/upsert_task.dart';
import '../feature/tasks/edit/edit_controller.dart';
import '../feature/tasks/edit/edit_state.dart';
import '../feature/tasks/history/history_controller.dart';
import '../feature/tasks/history/history_state.dart';
import '../feature/tasks/home/home_controller.dart';
import '../feature/tasks/home/home_state.dart';
import '../model/task.dart';
import '../system/notification/local_notification_service.dart';
import '../system/notification/notification_factory.dart';
import '../system/scheduler/reminder_scheduler_impl.dart';

final clockProvider = Provider<Clock>((ref) => const Clock());

final idGeneratorProvider = Provider<IdGenerator>((ref) => IdGenerator());

final inMemoryTaskStoreProvider = Provider<InMemoryTaskStore>(
  (ref) => InMemoryTaskStore(clock: ref.watch(clockProvider)),
);

final taskStoreProvider = Provider<TaskStore>((ref) => TaskFileStore());

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(
    ref.watch(taskStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

final notificationFactoryProvider = Provider<NotificationFactory>(
  (ref) => const NotificationFactory(),
);

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>(
      (ref) => FlutterLocalNotificationsPlugin(),
    );

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(
    plugin: ref.watch(flutterLocalNotificationsPluginProvider),
    notificationFactory: ref.watch(notificationFactoryProvider),
  ),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderSchedulerImpl(ref.watch(localNotificationServiceProvider)),
);

final getTasksUseCaseProvider = Provider<GetTasksUseCase>(
  (ref) => GetTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final getHistoryTasksUseCaseProvider = Provider<GetHistoryTasksUseCase>(
  (ref) => GetHistoryTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final cleanupExpiredHistoryUseCaseProvider = Provider<CleanupExpiredHistoryUseCase>(
  (ref) => CleanupExpiredHistoryUseCase(ref.watch(taskRepositoryProvider)),
);

final upsertTaskUseCaseProvider = Provider<UpsertTaskUseCase>(
  (ref) => UpsertTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>(
  (ref) => DeleteTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);

final markDoneUseCaseProvider = Provider<MarkDoneUseCase>(
  (ref) => MarkDoneUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);

final snoozeTaskUseCaseProvider = Provider<SnoozeTaskUseCase>(
  (ref) => SnoozeTaskUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);

final computeNextOccurrenceUseCaseProvider =
    Provider<ComputeNextOccurrenceUseCase>(
      (ref) => const ComputeNextOccurrenceUseCase(),
    );

final rescheduleAllUseCaseProvider = Provider<RescheduleAllUseCase>(
  (ref) => RescheduleAllUseCase(
    ref.watch(taskRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
    ref.watch(computeNextOccurrenceUseCaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final handleNotificationActionUseCaseProvider =
    Provider<HandleNotificationActionUseCase>(
      (ref) => HandleNotificationActionUseCase(
        ref.watch(taskRepositoryProvider),
        ref.watch(markDoneUseCaseProvider),
        ref.watch(snoozeTaskUseCaseProvider),
        ref.watch(upsertTaskUseCaseProvider),
        ref.watch(computeNextOccurrenceUseCaseProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final homeControllerProvider =
    legacy.StateNotifierProvider<HomeController, HomeState>(
      (ref) => HomeController(
        getTasks: ref.watch(getTasksUseCaseProvider),
        markDone: ref.watch(markDoneUseCaseProvider),
        deleteTask: ref.watch(deleteTaskUseCaseProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final historyControllerProvider =
    legacy.StateNotifierProvider<HistoryController, HistoryState>(
      (ref) => HistoryController(
        getHistoryTasks: ref.watch(getHistoryTasksUseCaseProvider),
        markDone: ref.watch(markDoneUseCaseProvider),
        deleteTask: ref.watch(deleteTaskUseCaseProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final editControllerProvider =
    legacy.StateNotifierProvider.autoDispose
        .family<EditController, EditState, Task?>(
          (ref, initialTask) => EditController(
            upsertTask: ref.watch(upsertTaskUseCaseProvider),
            idGenerator: ref.watch(idGeneratorProvider),
            clock: ref.watch(clockProvider),
            initialTask: initialTask,
          ),
        );
