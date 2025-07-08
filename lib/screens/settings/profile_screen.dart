import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/todo_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      // In a real app, you'd also load the selected avatar from preferences
      
      setState(() {
        _nameController.text = userName ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
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
      // In a real app, you'd also save the selected avatar to preferences
      
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Color(0xFF4A6FA5),
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan profil'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
        ),
        title: const Text(
          'Profil & Avatar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4A6FA5),
                    ),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A6FA5),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6FA5)))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Current Avatar Preview
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FA5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _avatarOptions.firstWhere(
                      (avatar) => avatar['name'] == _selectedAvatar,
                      orElse: () => _avatarOptions[0],
                    )['icon'],
                    color: const Color(0xFF4A6FA5),
                    size: 60,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Name Input
              _buildSectionHeader('Nama Pengguna'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Avatar Selection
              _buildSectionHeader('Pilih Avatar'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
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
                            ? const Color(0xFF4A6FA5).withOpacity(0.1)
                            : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
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
                          size: 32,
                        ),
                      ),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }
}
