import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Define accent color - muted blue
  static const Color accentColor = Color(0xFF4A6FA5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _currentPage < 2
                    ? TextButton(
                        onPressed: () => _skipToEnd(),
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  OnboardingPage1(),
                  OnboardingPage2(),
                  OnboardingPage3(),
                ],
              ),
            ),
            // Page indicator and navigation
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? accentColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Navigation button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _currentPage < 2 ? _nextPage : _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < 2 ? 'Lanjutkan' : 'Berikan Izin Akses',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _requestPermission() {
    // TODO: Implement permission request logic
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meminta izin akses penggunaan...'),
      ),
    );
  }
}

// Page 1: Welcome & Focus Introduction
class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Hero icon - Focus target
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.center_focus_strong_outlined,
              size: 60,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 48),
          // Title
          const Text(
            'Tetap Fokus,\nRaih Tujuan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Subtitle
          const Text(
            'Bantu kamu fokus dengan memblokir distraksi dan mengingatkan tugas penting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          // Feature highlights with icons
          _buildFeatureItem(
            Icons.block_outlined,
            'Blokir Aplikasi Pengganggu',
            'Hindari distraksi dari media sosial dan game',
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            Icons.schedule_outlined,
            'Kelola Waktu Dengan Baik',
            'Atur prioritas dan deadline tugas',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Page 2: Distraction Blocking Features
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Hero icon - Shield protection
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 60,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 48),
          // Title
          const Text(
            'Lindungi Waktu\nProduktimu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Subtitle
          const Text(
            'Sistem cerdas yang mendeteksi dan mencegah akses ke aplikasi yang mengganggu produktivitas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          // Workflow steps
          _buildWorkflowStep(
            1,
            Icons.assignment_outlined,
            'Buat Daftar Tugas',
            'Tambahkan tugas dengan prioritas dan deadline',
          ),
          const SizedBox(height: 24),
          _buildWorkflowStep(
            2,
            Icons.block_outlined,
            'Aktifkan Perlindungan',
            'Sistem akan memblokir aplikasi pengganggu',
          ),
          const SizedBox(height: 24),
          _buildWorkflowStep(
            3,
            Icons.trending_up_outlined,
            'Tingkatkan Produktivitas',
            'Fokus pada tugas tanpa gangguan',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(int step, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        // Step number
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF4A6FA5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Page 3: Permission Request
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Hero icon - Security/Permission
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_outlined,
              size: 60,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 48),
          // Title
          const Text(
            'Izin Akses\nPenggunaan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Subtitle
          const Text(
            'Untuk memblokir aplikasi pengganggu, kami memerlukan izin akses penggunaan aplikasi di perangkat Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          // Permission info
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildPermissionItem(
                  Icons.visibility_outlined,
                  'Memantau Aplikasi Aktif',
                  'Mendeteksi aplikasi yang sedang digunakan',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.block_outlined,
                  'Mencegah Akses Aplikasi',
                  'Memblokir aplikasi yang mengganggu',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.lock_outline,
                  'Privasi Terjamin',
                  'Data tidak dibagikan ke pihak ketiga',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Disclaimer
          const Text(
            'Izin ini hanya digunakan untuk fitur pemblokiran aplikasi dan tidak akan mengakses data pribadi Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black45,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF4A6FA5),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
