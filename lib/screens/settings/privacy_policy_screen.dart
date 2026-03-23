import 'package:flutter/material.dart';
import '../../core/ui/app_size_tokens.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Latar belakang abu muda
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizeTokens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon ilustrasi besar di atas
            Center(
              child: Container(
                padding: EdgeInsets.all(AppSizeTokens.space24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.privacy_tip_outlined,
                  size: AppSizeTokens.icon64,
                  color: const Color(0xFF4A6FA5),
                ),
              ),
            ),
            SizedBox(height: AppSizeTokens.space32),

            // Teks pembuka
            const Text(
              'Komitmen Kami',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: AppSizeTokens.space12),
            const Text(
              'Aplikasi myTask berkomitmen tinggi untuk melindungi privasi dan keamanan data Anda. Kami merancang aplikasi ini agar Anda tetap produktif tanpa harus mengorbankan privasi.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSizeTokens.space32),

            // Poin-poin Kebijakan
            const Text(
              'Detail Kebijakan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: AppSizeTokens.space16),

            _buildPolicyItem(
              icon: Icons.save_outlined,
              title: 'Penyimpanan Lokal',
              description:
                  'Seluruh data tugas dan pengaturan Anda disimpan secara lokal dan aman di perangkat yang Anda gunakan.',
            ),
            _buildPolicyItem(
              icon: Icons.shield_outlined,
              title: 'Transparansi Izin Akses',
              description:
                  'Izin Akses Penggunaan (Usage Access) dan Aksesibilitas semata-mata digunakan agar fitur pemblokiran aplikasi dapat berjalan sesuai jadwal, BUKAN untuk melacak atau mengumpulkan riwayat aktivitas pribadi Anda.',
            ),
            _buildPolicyItem(
              icon: Icons.cloud_off_outlined,
              title: 'Tanpa Server Eksternal',
              description:
                  'Kami tidak mengunggah, menyinkronkan, atau mengirim data pribadi Anda ke server eksternal mana pun.',
            ),
            _buildPolicyItem(
              icon: Icons.block_outlined,
              title: 'Bebas Pelacakan Iklan',
              description:
                  'Data Anda adalah milik Anda. Kami tidak akan pernah membagikan atau menjual data Anda kepada pihak ketiga atau pengiklan.',
            ),
            _buildPolicyItem(
              icon: Icons.person_outline,
              title: 'Kendali Penuh Pengguna',
              description:
                  'Anda memegang kendali penuh. Anda bebas mencabut izin atau menghapus data aplikasi kapan saja.',
            ),

            SizedBox(height: AppSizeTokens.space32),
            // Penutup
            Container(
              padding: EdgeInsets.all(AppSizeTokens.space16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6FA5).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSizeTokens.radius12),
                border: Border.all(
                  color: const Color(0xFF4A6FA5).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF4A6FA5),
                    size: AppSizeTokens.icon20,
                  ),
                  SizedBox(width: AppSizeTokens.space12),
                  const Expanded(
                    child: Text(
                      'Jika Anda memiliki pertanyaan lebih lanjut mengenai kebijakan ini, jangan ragu untuk menghubungi tim pengembang kami.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizeTokens.space48),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizeTokens.space24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4A6FA5),
              size: AppSizeTokens.icon24,
            ),
          ),
          SizedBox(width: AppSizeTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: AppSizeTokens.space6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
