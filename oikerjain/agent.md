# AGENT_CONTEXT.md — Oi!Kerjain (Flutter, Offline-First, No DB)

## 1) Ringkasan Produk

Oi!Kerjain adalah aplikasi mobile ringan untuk membuat tugas (task) dan mengingatkan pengguna lewat **local scheduled notifications** (bukan push server). Aplikasi bersifat **offline-first** dan **tanpa database**: semua data disimpan lokal sebagai **JSON file** (atau key-value storage) di device.

Target: cepat, ringan, reliable untuk reminder (sebatas batasan OS), mudah dikembangkan dengan struktur yang maintainable.

Catatan istilah:

- “Push” di scope ini = **local notification terjadwal** (tanpa backend).
- Push dari server (FCM/APNs) termasuk out-of-scope MVP.

## 2) Scope & Batasan

### In-scope (MVP)

- CRUD task: tambah, edit, hapus, tandai selesai.
- Schedule reminder via local notifications (Android/iOS).
- Notifikasi dengan action:
  - **DONE** (tandai selesai)
  - **SNOOZE_10M** (tunda 10 menit)
- Repeat rule sederhana:
  - NONE, DAILY, WEEKLY (rolling: jadwalkan occurrence berikutnya saat notifikasi “triggered”/dibuka)
- Reschedule:
  - Android: reschedule setelah reboot (perlu handling khusus / plugin support).
  - iOS: scheduling biasanya persist, tetapi ada limit jumlah scheduled notifications.
- **Priority task setting**:
  - Task punya prioritas (LOW / MEDIUM / HIGH).
  - Prioritas mempengaruhi:
    - Urutan tampil di UI (sorting/filter).
    - Tingkat “importance” notifikasi (channel/importance di Android, presentasi di iOS).
    - Opsional: default snooze/repeat (bukan MVP, tapi disiapkan titik extend).

### Out-of-scope (MVP)

- Backend, sinkronisasi cloud, multi-device.
- Push server-driven (FCM/APNs).
- Login, analytics, kalender, NLP input.
- Database (SQLite/Drift/Isar/Hive sebagai DB).  
  Catatan: Hive sering dianggap DB embedded; jika “no DB” ketat, gunakan file JSON.

## 3) Tech Stack (Flutter)

- Flutter (Dart)
- State management: `riverpod` (disarankan) atau `provider` (lebih sederhana)
- Local notifications: `flutter_local_notifications`
- Timezone scheduling: `timezone` + `flutter_native_timezone` (atau plugin TZ lain yang kompatibel)
- Local storage (no DB):
  - **File JSON**: `path_provider` + `dart:io`
  - Alternatif sederhana untuk small data: `shared_preferences` (tidak ideal untuk list panjang)

## 4) Struktur Project (Feature-first, 1 package)

Tidak perlu modularisasi multi-package dari awal. Gunakan struktur folder yang maintainable.

`lib/`

- `app/`
  - `app.dart` (MaterialApp, theme)
  - `router.dart` (GoRouter / Navigator)
  - `di.dart` (provider wiring; Riverpod container)
- `core/`
  - `constants/notification_const.dart`
  - `time/clock.dart`
  - `utils/id.dart`
  - `utils/json_codec.dart`
- `model/`
  - `task.dart`
  - `repeat_rule.dart`
  - `task_priority.dart`
- `data/`
  - `local/`
    - `task_file_store.dart` (read/write JSON)
  - `task_repository_impl.dart`
- `domain/`
  - `task_repository.dart` (abstract)
  - `scheduler/reminder_scheduler.dart` (abstract)
  - `usecase/`
    - `get_tasks.dart`
    - `upsert_task.dart`
    - `delete_task.dart`
    - `mark_done.dart`
    - `snooze_task.dart`
    - `compute_next_occurrence.dart`
    - `reschedule_all.dart`
- `system/`
  - `notification/`
    - `local_notification_service.dart` (wrapper plugin)
    - `notification_factory.dart` (payload/actions)
  - `scheduler/`
    - `reminder_scheduler_impl.dart` (menggunakan LocalNotificationService)
- `feature/`
  - `tasks/`
    - `home/`
      - `home_page.dart`
      - `home_view_model.dart` / `home_controller.dart`
      - `home_state.dart`
    - `edit/`
      - `edit_page.dart`
      - `edit_view_model.dart`
      - `edit_state.dart`
    - `components/` (TaskTile, PriorityChip, EmptyState, dsb.)

`test/`

- domain unit tests (compute next occurrence, sorting)

`integration_test/` (opsional)

- smoke test scheduling basic

## 5) Data Model & Penyimpanan

### Task (minimal)

- `id: String` (UUID)
- `title: String`
- `dueAtEpochMillis: int`
- `repeatRule: RepeatRule` (none/daily/weekly)
- `priority: TaskPriority` (low/medium/high) default medium
- `isDone: bool`
- `updatedAtEpochMillis: int`

### Storage (no DB)

Gunakan file JSON:

- file: `tasks.json` di app documents directory (`path_provider`)
- atomic write:
  - tulis ke `tasks.tmp`, flush, rename ke `tasks.json`
- load:
  - jika corrupt → fallback empty list (opsional backup)

Alasan: menghindari DB, tetap scalable untuk puluhan–ratusan task.

## 6) Scheduling & Notification Rules

### Konsep utama

- Jadwal notifikasi menggunakan `flutter_local_notifications` dengan timezone-aware scheduling.
- Payload notifikasi membawa `taskId` + action metadata.

### Scheduler abstraction

- `ReminderScheduler` (domain)
  - `schedule(Task task)`
  - `cancel(String taskId)`
  - `rescheduleAll(List<Task> tasks)`

Implementasi:

- `ReminderSchedulerImpl` → panggil `LocalNotificationService.zonedSchedule(...)`

### Action handling (DONE / SNOOZE)

`flutter_local_notifications` mendukung callback ketika user menekan action (Android). Implementasi umum:

- `onDidReceiveNotificationResponse` (callback)
  - parse payload/actionId
  - panggil usecase (`MarkDone` / `SnoozeTask`)
  - simpan + reschedule/cancel
Catatan:
- iOS action support ada, tapi konfigurasi category/actions perlu setup tambahan.
- Background isolate: beberapa kasus butuh handler top-level/static function. Pastikan wiring sesuai dokumentasi plugin.

### Repeat (rolling)

Saat notifikasi “fired” dan user berinteraksi (atau saat app dibuka dan mendeteksi overdue):

- kalau `repeatRule != none` dan task belum done:
  - compute next dueAt
  - update task
  - schedule ulang untuk dueAt baru

Batasan:

- OS limit scheduled notifs (iOS) → jadwalkan hanya yang perlu.
- Android reboot: scheduled notification by plugin bisa hilang tergantung implementasi. Untuk reliability, saat app start lakukan `rescheduleAll()`.

## 7) Priority Behavior

### UI sorting/filter

Default sorting:

- `priority desc`, lalu `dueAt asc`, lalu `updatedAt desc`

### Notification importance (guideline)

Android:

- Disarankan channel per priority untuk beda importance (LOW/MED/HIGH).
- MVP bisa 1 channel saja, prioritas hanya untuk UI; channel-per-priority bisa phase 2.

iOS:

- priority lebih ke presentation config (sound, badge) dan category.

Rekomendasi MVP:

- Priority mempengaruhi UI + label notif (mis. “[HIGH] Judul”).
- Channel-per-priority sebagai peningkatan setelah MVP.

## 8) Permission & Platform Setup Checklist

Android:

- `POST_NOTIFICATIONS` (Android 13+): request runtime.
- Notification channels (buat saat init).
- Exact timing tidak dijamin 100% karena doze/battery; plugin pakai scheduling OS.

iOS:

- Request notification permission.
- Setup iOS categories/actions bila memakai action buttons.

App init:

- `LocalNotificationService.init()`
- `rescheduleAll()` saat start untuk recovery.

## 9) State Management & DI

Rekomendasi:

- `flutter_riverpod`:
  - provider untuk repository
  - provider untuk scheduler
  - provider untuk usecases
  - state notifier / notifier untuk UI state

Aturan:

- UI tidak akses file atau plugin langsung.
- UI hanya memanggil controller/viewmodel yang memanggil usecase.

## 10) Testing Strategy

Unit test (Dart, cepat):

- `ComputeNextOccurrence` (repeat daily/weekly, timezone-agnostic via epoch)
- Sorting by priority + dueAt
- Repository read/write JSON (mock path dengan temp directory)

Integration/smoke:

- scheduling 1 menit ke depan (manual test) di emulator/device.

## 11) Definition of Done (MVP)

- Task tersimpan di `tasks.json` dan survive app restart.
- Notifikasi muncul sesuai jadwal (dengan batasan OS).
- Action DONE mengubah status dan membatalkan schedule.
- Action SNOOZE menjadwalkan ulang 10 menit.
- Repeat (daily/weekly) rolling berjalan.
- Priority tersimpan dan mempengaruhi UI sorting/filter.
- UI tidak mengakses storage/plugin secara langsung.

## 12) Pitfalls yang harus dihindari

- Simpan list task besar di `shared_preferences` (rawan lambat/limit).
- Generate banyak occurrences untuk repeat (jangan).
- Mengandalkan notifikasi tetap ada setelah reboot tanpa reschedule recovery.
- Mengabaikan timezone (pakai epoch + tz scheduling).
- Action handler tidak ter-setup untuk background isolate (Android) → action tidak bekerja.

## 13) Roadmap setelah MVP

- Settings: default snooze, default priority, notification channels per priority.
- Templates task.
- Smart snooze.
- Optional cloud sync (butuh backend; out-of-scope saat ini).
- Analytics (task completion rate, dsb.).
