import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasReadPage3 = false; // Track if user has read page 3 completely

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
                children: [
                  OnboardingPage1(),
                  OnboardingPage2(),
                  OnboardingPage3(
                    onReadComplete: () {
                      setState(() {
                        _hasReadPage3 = true;
                      });
                    },
                  ),
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
                      onPressed: _currentPage < 2 
                          ? _nextPage 
                          : (_hasReadPage3 ? _requestPermission : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_currentPage == 2 && !_hasReadPage3) 
                            ? Colors.grey[400] 
                            : accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < 2 
                            ? 'Lanjutkan' 
                            : (_hasReadPage3 
                                ? 'Berikan Izin Akses' 
                                : 'Baca Hingga Selesai'),
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
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hero icon - Focus target
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.center_focus_strong_outlined,
                size: 50,
                color: Color(0xFF4A6FA5),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'Tetap Fokus,\nRaih Tujuan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            // Feature highlights with icons
            _buildFeatureItem(
              Icons.block_outlined,
              'Blokir Aplikasi Pengganggu',
              'Hindari distraksi dari media sosial',
            ),
            const SizedBox(height: 20),
            _buildFeatureItem(
              Icons.schedule_outlined,
              'Kelola Waktu Dengan Baik',
              'Atur prioritas dan deadline tugas',
            ),
            const SizedBox(height: 20),
          ],
        ),
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
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 5),
          // Hero icon - Shield protection
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 38,
              color: Color(0xFF4A6FA5),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'Lindungi Waktu\nProduktimu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Subtitle
          const Text(
            'Sistem yang bisa mendeteksi dan mencegah akses ke aplikasi yang mengganggu produktivitas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          // Workflow steps
          _buildWorkflowStep(
            1,
            Icons.assignment_outlined,
            'Buat Daftar Tugas',
            'Tambahkan tugas dengan prioritas dan deadline',
          ),
          const SizedBox(height: 14),
          _buildWorkflowStep(
            2,
            Icons.block_outlined,
            'Aktifkan Perlindungan',
            'Sistem akan memblokir aplikasi pengganggu',
          ),
          const SizedBox(height: 14),
          _buildWorkflowStep(
            3,
            Icons.trending_up_outlined,
            'Tingkatkan Produktivitas',
            'Fokus pada tugas tanpa gangguan',
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(int step, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        // Step number
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF4A6FA5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
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
class OnboardingPage3 extends StatefulWidget {
  final VoidCallback onReadComplete;
  
  const OnboardingPage3({
    super.key,
    required this.onReadComplete,
  });

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasReachedBottom && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.95; // 95% of the way down
      
      if (currentScroll >= threshold) {
        setState(() {
          _hasReachedBottom = true;
        });
        widget.onReadComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hero icon - Security/Permission
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_outlined,
                size: 50,
                color: Color(0xFF4A6FA5),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            const Text(
              'Izin Akses\nPenggunaan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 32),
            // Permission info
            Container(
              padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            // Additional privacy information to ensure scroll
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A6FA5).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: const Color(0xFF4A6FA5),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Informasi Tambahan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6FA5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Aplikasi ini menggunakan accessibility service untuk mendeteksi aplikasi yang sedang aktif\n\n'
                    '• Data penggunaan aplikasi disimpan secara lokal dan tidak dikirim ke server\n\n'
                    '• Anda dapat mengatur daftar aplikasi yang akan diblokir melalui pengaturan\n\n'
                    '• Fitur ini dapat dinonaktifkan kapan saja melalui pengaturan sistem Android',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // Extra space to ensure scroll
          ],
        ),
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
