import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/di.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final container = ProviderContainer();

  final notificationService = container.read(localNotificationServiceProvider);
  final pushNotificationService = container.read(
    pushNotificationServiceProvider,
  );
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
    await pushNotificationService.init();
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
