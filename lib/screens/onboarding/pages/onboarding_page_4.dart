import 'package:flutter/material.dart';

import 'onboarding_permission_page.dart';

class OnboardingPage4 extends StatelessWidget {
  const OnboardingPage4({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPermissionPage(
      headerIcon: Icons.query_stats_outlined,
      title: 'Izin Statistik\nPenggunaan',
      subtitle:
          'Agar myTask bisa menilai penggunaan aplikasi dan menjalankan aturan '
          'blokir, aktifkan akses statistik penggunaan.',
      items: const [
        PermissionItem(
          icon: Icons.timeline_outlined,
          title: 'Memantau Pola Penggunaan',
          subtitle: 'Melihat aplikasi aktif dan durasi penggunaan',
        ),
        PermissionItem(
          icon: Icons.rule_outlined,
          title: 'Menjalankan Aturan Blokir',
          subtitle: 'Menentukan kapan intervensi harus muncul',
        ),
        PermissionItem(
          icon: Icons.lock_outline,
          title: 'Privasi Tetap Terkontrol',
          subtitle: 'Data penggunaan tetap berada di perangkat',
        ),
      ],
      disclaimer:
          'Data statistik penggunaan tidak dikirim ke server eksternal.',
    );
  }
}
