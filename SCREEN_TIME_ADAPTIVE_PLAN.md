# Dokumentasi Implementasi Screen Time dan Rencana Algoritma Adaptif

Tanggal: 8 Mei 2026

## Tujuan

Dokumen ini merangkum pekerjaan yang sudah dilakukan untuk mengambil data penggunaan aplikasi dari Android, serta rencana lanjutan untuk membangun algoritma blokir adaptif pada fitur intervensi distraksi digital.

Fokus implementasi saat ini adalah fondasi data penggunaan aplikasi. Integrasi ke algoritma adaptif `AppBlockerService` belum diterapkan dan direncanakan sebagai tahap berikutnya.

## Ringkasan Implementasi yang Sudah Dilakukan

Pipeline screen time sudah dibuat dari Android native sampai Flutter UI. Data penggunaan aplikasi diambil dari `UsageStatsManager`, bukan dari tracking manual di background.

Implementasi mencakup:

1. Query data historis penggunaan aplikasi berdasarkan rentang waktu.
2. Query riwayat penggunaan harian untuk 7 hari terakhir.
3. Query sesi aplikasi yang sedang aktif menggunakan `UsageStatsManager.queryEvents`.
4. Bridge native ke Flutter melalui `MethodChannel` yang sudah ada.
5. Service Dart untuk membaca data screen time dan membuat polling sesi aktif setiap 10 detik.
6. Layar baru di menu Pengaturan untuk melihat data penggunaan aplikasi.

## File yang Ditambahkan atau Diubah

### Android Native

- `android/app/src/main/kotlin/com/example/todolist/UsageStatsHelper.kt`
  - File baru untuk membaca data dari `UsageStatsManager`.
  - Menyediakan query usage rentang waktu, riwayat harian, dan sesi aktif saat ini.

- `android/app/src/main/kotlin/com/example/todolist/MainActivity.kt`
  - Menambahkan 3 method channel baru:
    - `getAppUsageStats`
    - `getAppUsageHistory`
    - `getAppCurrentSession`
  - Setiap query dijalankan di `Dispatchers.IO` agar tidak memblokir UI thread.
  - Tetap melakukan pengecekan izin Usage Access sebelum query data.

- `android/app/build.gradle.kts`
  - Menambahkan dependency `kotlinx-coroutines-android` untuk menjalankan query native secara asynchronous.

### Flutter / Dart

- `lib/models/app_usage_stat.dart`
  - Model data penggunaan aplikasi.
  - Menyimpan `packageName`, `totalTimeMs`, dan `date`.
  - Menyediakan formatter durasi seperti `10m`, `1j 15m`, dan `30d`.

- `lib/services/permission_service.dart`
  - Menambahkan bridge Dart untuk:
    - `getAppUsageStats`
    - `getAppUsageHistory`
    - `getAppCurrentSession`
  - Menangani kondisi `PERMISSION_DENIED` secara aman.

- `lib/services/usage_stats_service.dart`
  - Service utama di sisi Flutter untuk mengolah data screen time.
  - Menyediakan:
    - `getTodayUsageForApps`
    - `getUsageHistory`
    - `getCurrentSessionForApp`
    - `watchCurrentSessions`
  - `watchCurrentSessions` memakai polling setiap 10 detik. Ini bukan streaming real-time murni dari OS, tetapi cukup untuk tampilan UI dan fondasi algoritma adaptif awal.

- `lib/screens/settings/screen_time_screen.dart`
  - Layar baru untuk melihat penggunaan aplikasi.
  - Menampilkan:
    - total penggunaan aplikasi distraksi hari ini
    - jumlah aplikasi yang dipantau
    - sesi aktif saat ini
    - daftar usage per aplikasi
    - riwayat 7 hari terakhir
  - Mendukung pull-to-refresh.
  - Menampilkan prompt jika izin Usage Access belum diberikan.

- `lib/screens/settings/settings_screen.dart`
  - Menambahkan menu `Penggunaan Aplikasi` di halaman Pengaturan.

## Alur Data Saat Ini

```text
Android UsageStatsManager
        |
        v
UsageStatsHelper.kt
        |
        v
MainActivity MethodChannel: app_blocker/permissions
        |
        v
PermissionService.dart
        |
        v
UsageStatsService.dart
        |
        v
ScreenTimeScreen.dart
```

## MethodChannel yang Ditambahkan

Channel yang digunakan tetap:

```text
app_blocker/permissions
```

Method baru:

### `getAppUsageStats`

Mengambil penggunaan aplikasi pada rentang waktu tertentu.

Input:

```text
packageNames: List<String>
startMs: int? optional
endMs: int? optional
```

Output:

```text
Map<String, int>
```

Format output:

```text
packageName -> totalTimeInForeground dalam milidetik
```

### `getAppUsageHistory`

Mengambil riwayat penggunaan aplikasi untuk beberapa hari terakhir.

Input:

```text
packageNames: List<String>
days: int default 7
```

Output:

```text
Map<String, Map<String, int>>
```

Format output:

```text
tanggal yyyy-MM-dd -> packageName -> totalTimeInForeground ms
```

### `getAppCurrentSession`

Mengambil durasi sesi aktif saat ini untuk satu package.

Input:

```text
packageName: String
```

Output:

```text
int
```

Format output:

```text
durasi sesi aktif saat ini dalam milidetik
```

## Permission Handling

Izin yang digunakan:

```text
android.permission.PACKAGE_USAGE_STATS
```

Karena izin ini adalah protected permission, aplikasi tidak bisa meminta izin melalui runtime permission biasa. Workflow yang digunakan:

1. App mengecek status izin melalui method native `isUsageStatsPermissionGranted`.
2. Jika belum diberikan, UI menampilkan pesan bahwa Usage Access dibutuhkan.
3. User diarahkan ke pengaturan Android melalui `Settings.ACTION_USAGE_ACCESS_SETTINGS`.
4. Saat app kembali ke foreground, data dimuat ulang.

## Verifikasi yang Sudah Dilakukan

Perintah yang sudah dijalankan:

```bash
flutter analyze
```

Hasil: sukses, tidak ada issue.

```bash
flutter test
```

Hasil: sukses, 117 test passed.

```bash
./android/gradlew.bat -p android :app:compileDebugKotlin --stacktrace --no-daemon
```

Hasil: sukses, Kotlin compile berhasil.

```bash
flutter build apk --debug
```

Hasil: sukses, APK debug berhasil dibuat di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Batasan Implementasi Saat Ini

1. Data real-time masih berbasis polling setiap 10 detik, bukan `EventChannel` native.
2. Algoritma adaptif belum dihubungkan ke `AppBlockerService`.
3. Overlay peringatan tanpa menutup aplikasi belum dibuat.
4. Threshold adaptif seperti 10 menit peringatan dan 1 jam blokir belum diterapkan.
5. Data saat ini dipakai untuk visualisasi dan fondasi logika, belum untuk pengambilan keputusan blokir.

## Rencana Algoritma Blokir Adaptif

Tujuan algoritma adaptif adalah membuat intervensi tidak langsung memblokir aplikasi, terutama ketika user hanya membuka aplikasi distraksi sebentar untuk relaksasi.

Contoh target perilaku:

- Jika user punya tugas urgensi tinggi dan membuka aplikasi distraksi sebentar, misalnya sekitar 10 menit, app hanya menampilkan overlay peringatan.
- Overlay peringatan tidak langsung menutup aplikasi.
- User tetap bisa melanjutkan membuka aplikasi.
- Jika durasi penggunaan terus naik sampai batas tertentu, misalnya 1 jam, aplikasi mulai diblokir secara hard-block.

## Input Data untuk Algoritma Adaptif

Algoritma adaptif sebaiknya memakai beberapa input berikut:

1. `TodoPriority`
   - Low
   - Medium
   - High

2. Status tugas aktif
   - Ada tugas belum selesai.
   - Deadline masuk window urgensi.
   - Tugas dengan prioritas tertinggi sedang aktif.

3. App target
   - Package name aplikasi.
   - Kategori aplikasi: sosial atau game.
   - Status block list.
   - Status whitelist.

4. Screen time historis
   - Total penggunaan hari ini.
   - Total penggunaan 7 hari terakhir.
   - Rata-rata penggunaan harian.

5. Sesi berjalan
   - Durasi app sedang aktif pada sesi saat ini.
   - Diambil dari `getAppCurrentSession`.

6. Riwayat intervensi
   - Berapa kali user sudah diberi warning.
   - Apakah user tetap lanjut setelah warning.
   - Kapan terakhir hard-block terjadi.

## Tahap Intervensi yang Direncanakan

Algoritma adaptif dapat memakai level intervensi bertahap:

### Level 0: Allow

Kondisi:

- Tidak ada tugas mendesak.
- App masuk whitelist.
- Durasi sesi masih sangat pendek.

Aksi:

- Tidak ada overlay.
- App tetap dibuka normal.

### Level 1: Soft Warning

Kondisi contoh:

- Ada tugas urgensi tinggi.
- User membuka app distraksi.
- Durasi sesi masih di bawah 10 menit.

Aksi:

- Tampilkan overlay peringatan ringan.
- Jangan tutup aplikasi.
- User bisa memilih lanjut.

Contoh pesan:

```text
Kamu punya tugas prioritas tinggi. Ambil jeda sebentar boleh, tapi jangan terlalu lama.
```

### Level 2: Strong Warning

Kondisi contoh:

- Durasi sesi sudah melewati 10 menit.
- Total penggunaan app hari ini mulai tinggi.
- User tetap lanjut setelah soft warning.

Aksi:

- Tampilkan overlay lebih tegas.
- Tetap tidak langsung menutup aplikasi.
- Bisa tampilkan pilihan `Kembali ke Tugas` dan `Lanjut 5 Menit`.

### Level 3: Temporary Hard Block

Kondisi contoh:

- Durasi sesi sudah mendekati 30-45 menit.
- Tugas urgensi tinggi belum selesai.
- User sudah melewati beberapa warning.

Aksi:

- App mulai diblokir sementara.
- Overlay hard-block tampil.
- User diarahkan kembali ke aplikasi todo.

### Level 4: Full Hard Block

Kondisi contoh:

- Durasi penggunaan mencapai 1 jam.
- Masih ada tugas urgensi tinggi.
- App termasuk daftar aplikasi yang diblokir.

Aksi:

- Hard-block penuh seperti perilaku `AppBlockerAccessibilityService` saat ini.
- User tidak bisa lanjut membuka aplikasi sampai kondisi urgency berubah atau tugas selesai.

## Draft Threshold Awal

Threshold awal bisa dibuat sederhana dulu:

| Prioritas Tugas | Soft Warning | Strong Warning | Temporary Block | Hard Block |
|---|---:|---:|---:|---:|
| High | 5 menit | 10 menit | 30 menit | 60 menit |
| Medium | 10 menit | 20 menit | 45 menit | 90 menit |
| Low | 15 menit | 30 menit | 60 menit | 120 menit |

Untuk permintaan awal user, fokus utama adalah prioritas tinggi:

```text
0-10 menit: overlay peringatan tanpa menutup aplikasi
10-30 menit: peringatan lebih tegas
30-60 menit: mulai intervensi kuat
>= 60 menit: aplikasi diblokir
```

## Rancangan Policy Function

Tahap berikutnya dapat menambahkan fungsi policy baru, misalnya:

```text
AdaptiveInterventionDecision evaluateAdaptiveBlock({
  packageName,
  activeTask,
  priority,
  currentSessionMs,
  todayUsageMs,
  warningCount,
  isWhitelisted,
  isBlockedByUser,
})
```

Output:

```text
allow
softWarning
strongWarning
temporaryBlock
hardBlock
```

Dengan field tambahan:

```text
reason
message
nextAllowedDelayMs
remainingGraceMs
```

## Rencana File untuk Tahap Adaptif

Tahap berikutnya dapat menambahkan atau mengubah file berikut:

### Dart

- `lib/models/adaptive_intervention_decision.dart`
  - Model hasil keputusan adaptif.

- `lib/services/adaptive_intervention_policy.dart`
  - Logic threshold dan scoring adaptif.

- `lib/services/app_blocker_service.dart`
  - Menggunakan `UsageStatsService` dan policy adaptif saat menentukan apakah app harus diblokir.

- `lib/screens/settings/intervention_rules_settings_screen.dart`
  - Opsional: menambahkan konfigurasi threshold adaptif.

### Android Native

- `AppBlockerAccessibilityService.kt`
  - Saat mendeteksi app distraksi aktif, native service dapat membaca keputusan dari SharedPreferences atau menerima policy state yang disinkronkan dari Flutter.

- `InterventionOverlayManager.kt`
  - Menambahkan mode overlay baru: warning-only overlay.
  - Warning-only overlay tidak langsung menutup aplikasi.

## Strategi Integrasi dengan AppBlockerService

Strategi paling aman adalah membuat adaptif sebagai layer di atas logic lama, bukan mengganti hard-block langsung.

Urutan evaluasi yang disarankan:

1. Jika app whitelist, selalu allow.
2. Jika intervention global off, allow.
3. Jika tidak ada tugas aktif dalam window urgensi, allow.
4. Jika app tidak masuk block list user, allow.
5. Ambil data usage:
   - `currentSessionMs`
   - `todayUsageMs`
   - `weeklyAverageMs`
6. Evaluasi policy adaptif.
7. Jalankan aksi sesuai level:
   - allow
   - warning overlay
   - strong warning overlay
   - temporary block
   - hard block

## Catatan tentang Real-time Streaming

Android `UsageStatsManager` tidak menyediakan stream real-time langsung seperti event listener biasa. Pilihan realistis:

1. Polling dari Flutter setiap 10 detik.
   - Sudah diterapkan.
   - Cukup untuk UI dan adaptif tahap awal.

2. EventChannel native.
   - Bisa dibuat nanti jika perlu update lebih cepat.
   - Tetap perlu sumber event dari native, kemungkinan dari AccessibilityService atau polling native.

3. Accessibility event foreground tracking.
   - Sudah ada di `AppBlockerAccessibilityService`.
   - Cocok untuk mendeteksi app sedang dibuka.
   - Bisa digabung dengan UsageStats untuk keputusan adaptif.

Rekomendasi: gunakan kombinasi AccessibilityService untuk deteksi foreground dan UsageStatsManager untuk durasi historis. Ini lebih stabil daripada mencoba membuat background tracker manual.

## Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| UsageStats kosong walau izin aktif | Tampilkan fallback 0 dan jangan hard-block berdasarkan data kosong saja |
| OEM membatasi UsageStats | Tetap gunakan AccessibilityService untuk enforcement utama |
| Polling terlalu sering | Default 10 detik, bisa dinaikkan jika boros resource |
| User merasa terlalu cepat diblokir | Gunakan grace period dan warning bertahap |
| Algoritma terlalu rumit | Mulai dari threshold statis sebelum scoring adaptif |

## Roadmap Implementasi Berikutnya

### Tahap 1: Warning-only Overlay

- Tambahkan tipe overlay `warningOnly`.
- Overlay tidak memanggil tombol home/back otomatis.
- User bisa lanjut menggunakan app.
- Simpan timestamp warning terakhir.

### Tahap 2: Policy Adaptif Statis

- Tambahkan threshold hardcoded untuk high/medium/low.
- Pakai `currentSessionMs` dan `todayUsageMs`.
- Output keputusan: allow, warning, block.

### Tahap 3: Integrasi ke AppBlockerService

- `AppBlockerService.shouldBlockApp` tetap ada untuk kompatibilitas.
- Tambahkan method baru seperti `evaluateInterventionForApp`.
- Method baru mengembalikan level intervensi, bukan boolean saja.

### Tahap 4: Sinkronisasi Native

- Simpan keputusan adaptif ke SharedPreferences agar native service bisa membaca cepat.
- Atau tambahkan method channel khusus sinkronisasi policy dari Flutter ke native.

### Tahap 5: Settings Threshold

- Tambahkan UI untuk mengatur batas warning dan hard-block.
- Default tetap konservatif agar user tidak langsung terblokir.

### Tahap 6: Evaluasi dan Logging

- Tambahkan debug info:
  - package name
  - priority
  - session duration
  - today usage
  - decision level
  - reason
- Tampilkan di halaman debug agar mudah diuji untuk kebutuhan tugas akhir.

## Kesimpulan

Fondasi data screen time sudah siap. Aplikasi sekarang bisa membaca data penggunaan aplikasi dari Android secara native, mengirimkannya ke Flutter, menampilkannya di layar Penggunaan Aplikasi, dan melakukan polling sesi aktif.

Tahap berikutnya adalah mengubah keputusan blokir dari boolean sederhana menjadi keputusan bertingkat. Dengan begitu, aplikasi bisa memberikan ruang relaksasi singkat kepada user, tetapi tetap melakukan hard-block ketika penggunaan aplikasi distraksi melewati batas yang tidak sehat saat ada tugas berurgensi tinggi.
