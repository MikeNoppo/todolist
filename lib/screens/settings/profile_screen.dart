import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_size_tokens.dart';
import '../../repositories/todo_repository.dart';
import '../../services/app_logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _tag = 'ProfileScreen';

  final TodoRepository _todoRepository = TodoRepository();
  final TextEditingController _nameController = TextEditingController();
  String _selectedAvatar = 'person_outline';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _avatarOptions = [
    {'icon': Icons.person_outline, 'name': 'person_outline'},
    {'icon': Icons.face, 'name': 'face'},
    {'icon': Icons.mood, 'name': 'mood'},
    {'icon': Icons.emoji_emotions, 'name': 'emoji_emotions'},
    {'icon': Icons.sentiment_satisfied, 'name': 'sentiment_satisfied'},
    {'icon': Icons.psychology_outlined, 'name': 'psychology_outlined'},
    {'icon': Icons.star_outline, 'name': 'star_outline'},
    {'icon': Icons.favorite_outline, 'name': 'favorite_outline'},
    {'icon': Icons.emoji_nature, 'name': 'emoji_nature'},
    {'icon': Icons.pets, 'name': 'pets'},
    {'icon': Icons.explore_outlined, 'name': 'explore_outlined'},
    {'icon': Icons.lightbulb_outline, 'name': 'lightbulb_outline'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userName = await _todoRepository.getUserName();
      final userAvatar = await _todoRepository.getUserAvatar();
      final fallbackAvatar = _avatarOptions.first['name'] as String;
      final selectedAvatar = _isValidAvatarName(userAvatar)
          ? userAvatar!
          : fallbackAvatar;

      if (!mounted) return;

      setState(() {
        _nameController.text = userName ?? '';
        _selectedAvatar = selectedAvatar;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load profile.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      AppLogger.warn(_tag, 'Save profile blocked: empty name');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _todoRepository.saveUserName(_nameController.text.trim());
      await _todoRepository.saveUserAvatar(_selectedAvatar);

      if (!mounted) return;

      AppLogger.info(_tag, 'Profile saved successfully');

      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Color(0xFF4A6FA5),
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to save profile.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan profil'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          'Profil & Avatar',
          style: TextStyle(
            fontSize: AppSizeTokens.text20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: AppSizeTokens.icon16,
                    height: AppSizeTokens.icon16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4A6FA5),
                    ),
                  )
                : Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: AppSizeTokens.text16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A6FA5),
                    ),
                  ),
          ),
          SizedBox(width: AppSizeTokens.space16),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A6FA5)),
            )
          : ListView(
              padding: EdgeInsets.all(AppSizeTokens.cardPadding),
              children: [
                Center(
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6FA5).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _avatarOptions.firstWhere(
                        (avatar) => avatar['name'] == _selectedAvatar,
                        orElse: () => _avatarOptions[0],
                      )['icon'],
                      color: const Color(0xFF4A6FA5),
                      size: 60.w,
                    ),
                  ),
                ),

                SizedBox(height: AppSizeTokens.space32),

                _buildSectionHeader('Nama Pengguna'),
                SizedBox(height: AppSizeTokens.space12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama Anda',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.edit_outlined,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizeTokens.radius16,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.all(AppSizeTokens.cardPadding),
                    ),
                    style: TextStyle(
                      fontSize: AppSizeTokens.text16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: AppSizeTokens.space32),

                _buildSectionHeader('Pilih Avatar'),
                SizedBox(height: AppSizeTokens.space12),
                Container(
                  padding: EdgeInsets.all(AppSizeTokens.cardPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizeTokens.radius16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minTileWidth = 64.w;
                      final crossAxisSpacing = AppSizeTokens.space12;
                      var crossAxisCount =
                          ((constraints.maxWidth + crossAxisSpacing) /
                                  (minTileWidth + crossAxisSpacing))
                              .floor();
                      crossAxisCount = crossAxisCount.clamp(3, 5);

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: crossAxisSpacing,
                          mainAxisSpacing: AppSizeTokens.space12,
                          mainAxisExtent: 64.w,
                        ),
                        itemCount: _avatarOptions.length,
                        itemBuilder: (context, index) {
                          final avatar = _avatarOptions[index];
                          final isSelected = avatar['name'] == _selectedAvatar;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatar = avatar['name'];
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF4A6FA5,
                                      ).withValues(alpha: 0.1)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(
                                  AppSizeTokens.radius12,
                                ),
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF4A6FA5),
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                avatar['icon'],
                                color: isSelected
                                    ? const Color(0xFF4A6FA5)
                                    : Colors.grey[600],
                                size: 32.sp,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppSizeTokens.text14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5.sp,
      ),
    );
  }

  bool _isValidAvatarName(String? avatarName) {
    if (avatarName == null || avatarName.isEmpty) {
      return false;
    }

    return _avatarOptions.any((avatar) => avatar['name'] == avatarName);
  }
}
