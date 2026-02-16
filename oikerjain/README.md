# Oi!Kerjain (Technical README)

Dokumen ini ditujukan untuk developer/kontributor.

Jika kamu mencari dokumentasi untuk pengguna akhir + galeri aplikasi, lihat README root repository: `../README.md`.

## 1. Project Overview

Oi!Kerjain adalah aplikasi task scheduler harian berbasis Flutter dengan fokus:
- task management lokal (tanpa backend),
- reminder berbasis local notification,
- pemisahan task aktif vs riwayat yang konsisten terhadap boundary hari lokal user.

## 2. Current Functional Scope

- CRUD task (`add`, `edit`, `delete`, `mark done/undo`).
- Filtering di tab aktif: kategori + search query.
- Bottom navigation 3 slot: `Aktif`, `Tambah`, `Riwayat`.
- Riwayat:
  - weekly filter default (Senin-Minggu),
  - custom date range picker (custom neumorphic sheet),
  - grouping berdasarkan `createdAt`.
- Retention riwayat 14 hari berbasis `completedAt`.
- Local notifications dengan quick actions:
  - `DONE`,
  - `SNOOZE 10M`.

## 3. Tech Stack

- Flutter (Material 3)
- Dart SDK `^3.9.2`
- `flutter_riverpod` (state + DI)
- `flutter_local_notifications`
- `timezone` + `flutter_timezone`
- `path_provider`
- `uuid`

## 4. High-Level Architecture

Project dipecah per layer:

- `lib/app`
  - bootstrap app, router, provider graph (`di.dart`)
- `lib/feature/tasks`
  - presentation layer (page/widget/controller/state)
- `lib/domain`
  - use cases + abstraction contracts (`TaskRepository`, `ReminderScheduler`)
- `lib/data`
  - repository implementation + local persistence
- `lib/system`
  - wrapper integrasi platform (notification + scheduler)
- `lib/model`
  - entity dan enum domain
- `lib/core`
  - constants, clock abstraction, utils

### Main Runtime Flow

1. UI memanggil controller (`HomeController`, `HistoryController`, `EditController`).
2. Controller memanggil use case pada layer domain.
3. Use case mengakses repository/scheduler abstraction.
4. `TaskRepositoryImpl` membaca/menulis task via `TaskStore` (`TaskFileStore`).
5. Perubahan task menyinkronkan reminder melalui `ReminderSchedulerImpl`.

## 5. Data Model & Rules

Entity utama: `Task` (`lib/model/task.dart`) dengan field penting:
- `createdAtEpochMillis`
- `dueAtEpochMillis`
- `isDone`
- `completedAtEpochMillis`
- `updatedAtEpochMillis`
- `priority`, `category`, `repeatRule`

Business rules utama:
- Task selesai hari ini tetap di tab aktif sampai hari berganti.
- Task masuk riwayat jika `completedAt < todayStart`.
- Filtering riwayat selalu berdasarkan `createdAt` range.
- Retention riwayat 14 hari berdasarkan `completedAt`.

## 6. Notifications

- Service: `lib/system/notification/local_notification_service.dart`
- Channel:
  - `id`: `oikerjain_reminders`
  - action IDs: `DONE`, `SNOOZE_10M`
- Startup (`lib/main.dart`):
  1. cleanup history expired,
  2. init notification plugin + timezone,
  3. reschedule reminder untuk task aktif.

## 7. Local Storage

- Persistence: JSON file via `TaskFileStore`.
- Lokasi file: application documents directory, nama file `tasks.json`.
- Atomic write strategy: tulis ke `.tmp`, hapus file lama, rename temp file.

## 8. Project Structure

```text
lib/
  app/
    app.dart
    di.dart
    router.dart
  core/
    constants/
    time/
    utils/
  data/
    local/
      task_store.dart
      task_file_store.dart
    task_repository_impl.dart
  domain/
    scheduler/
    usecase/
    task_repository.dart
  feature/
    tasks/
      components/
      home/
      edit/
      history/
  model/
  system/
    notification/
    scheduler/
```

## 9. Setup & Run

```bash
flutter pub get
flutter run
```

## 10. Testing

Run all tests:

```bash
flutter test
```

Run targeted suites:

```bash
flutter test test/widget_test.dart
flutter test test/data/task_repository_impl_test.dart
flutter test test/feature/tasks/history/history_controller_test.dart
```

Test coverage saat ini mencakup:
- repository behavior dan retention,
- use case domain (mark done, recurrence, reschedule),
- widget behavior utama (active/history navigation, swipe actions, history filter flow).

## 11. Engineering Notes

- Gunakan `Clock` abstraction (`lib/core/time/clock.dart`) untuk logic berbasis waktu agar testable.
- Hindari menaruh business rule di widget; letakkan di controller/use case/repository.
- Pertahankan kontrak penyimpanan lokal existing (jangan ubah schema tanpa migration plan).

## 12. Next Suggested Improvements

- Tambah `CONTRIBUTING.md` (branching, commit convention, checklist PR).
- Tambah CI untuk `flutter analyze` + `flutter test`.
- Tambah snapshot/golden test untuk UI neuromorphic yang kritikal.
