import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/di.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  final notificationService = container.read(localNotificationServiceProvider);
  final notificationActionHandler = container.read(
    handleNotificationActionUseCaseProvider,
  );

  try {
    await container.read(cleanupExpiredHistoryUseCaseProvider).call();
  } catch (_) {
    // Cleanup failures should not block app startup.
  }

  try {
    await notificationService.init(
      onAction: ({required taskId, required actionId}) {
        return notificationActionHandler(taskId: taskId, actionId: actionId);
      },
    );
    await container.read(rescheduleAllUseCaseProvider).call();
  } catch (_) {
    // Keep app startup resilient when notification APIs are unavailable.
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OikerjainApp(),
    ),
  );
}
