import 'package:flutter/material.dart';

import 'onboarding_permission_page.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPermissionPage(
      headerIcon: Icons.accessibility_new_outlined,
      title: 'Izin\nAksesibilitas',
      subtitle:
          'Untuk memblokir aplikasi pengganggu secara real-time, aktifkan '
          'layanan aksesibilitas myTask di perangkat Anda.',
      items: const [
        PermissionItem(
          icon: Icons.visibility_outlined,
          title: 'Mendeteksi Aplikasi Aktif',
          subtitle: 'Membaca perubahan aplikasi yang sedang dibuka',
        ),
        PermissionItem(
          icon: Icons.block_outlined,
          title: 'Intervensi Langsung',
          subtitle: 'Menampilkan layar blokir saat distraksi dibuka',
        ),
        PermissionItem(
          icon: Icons.lock_outline,
          title: 'Tetap Aman',
          subtitle: 'Layanan hanya dipakai untuk fitur fokus',
        ),
      ],
      disclaimer:
          'Layanan aksesibilitas tidak dipakai untuk membaca isi chat atau '
          'data pribadi Anda.',
    );
  }
}
