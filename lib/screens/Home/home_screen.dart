import 'package:flutter/material.dart';
import '../../models/todo_model.dart';
import '../../repositories/todo_repository.dart';
import '../add_edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodoRepository _todoRepository = TodoRepository();
  List<TodoModel> _todos = [];
  String _userName = 'Pengguna';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final todos = await _todoRepository.getTodos();
    final userName = await _todoRepository.getUserName();
    
    setState(() {
      _todos = todos;
      _userName = userName ?? 'Pengguna';
      _isLoading = false;
    });
  }

  Future<void> _toggleTodoComplete(String todoId) async {
    await _todoRepository.toggleTodoComplete(todoId);
    await _loadData();
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, TodoModel todo) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Tugas',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${todo.title}"?',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _todoRepository.deleteTodo(todo.id);
                Navigator.of(context).pop(true);
                await _loadData();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${todo.title} dihapus'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return const Color(0xFF4A6FA5);
      case TodoPriority.medium:
        return Colors.grey[600]!;
      case TodoPriority.low:
        return Colors.grey[400]!;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) {
      return 'Terlambat ${difference.abs()} hari';
    } else if (difference == 0) {
      return 'Hari ini';
    } else if (difference == 1) {
      return 'Besok';
    } else {
      return '$difference hari lagi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4A6FA5),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  _buildModernAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildDashboardOverview(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  _todos.isEmpty 
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : _buildModernTodoList(),
                ],
              ),
            ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6FA5).withValues(alpha: 0.3),
                    blurRadius: 15 * value,
                    offset: Offset(0, 4 * value),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditTaskScreen(),
                    ),
                  );
                  
                  if (result == true) {
                    await _loadData();
                  }
                },
                backgroundColor: const Color(0xFF4A6FA5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai produktif dengan menambahkan\ntugas pertama Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF4A6FA5),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Tap tombol + untuk menambah tugas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: true,
          expandedHeight: 160,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildShimmerContainer(48, 48, isCircle: true),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShimmerContainer(80, 14),
                              const SizedBox(height: 4),
                              _buildShimmerContainer(120, 20),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildShimmerContainer(150, 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(140, 18),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildShimmerStatCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildShimmerStatCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildShimmerStatCard()),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerTaskCard(),
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerContainer(double width, double height, {bool isCircle = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return AnimatedOpacity(
          opacity: value,
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: isCircle ? null : BorderRadius.circular(8),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerStatCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildShimmerContainer(24, 24, isCircle: true),
          const SizedBox(height: 8),
          _buildShimmerContainer(30, 18),
          const SizedBox(height: 4),
          _buildShimmerContainer(50, 12),
        ],
      ),
    );
  }

  Widget _buildShimmerTaskCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildShimmerContainer(28, 28, isCircle: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerContainer(200, 16),
                const SizedBox(height: 12),
                _buildShimmerContainer(120, 32),
              ],
            ),
          ),
          _buildShimmerContainer(6, 50),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour < 17) {
      greeting = 'Selamat Siang';
    } else {
      greeting = 'Selamat Malam';
    }

    final dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                       'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    final dateString = '${dayNames[now.weekday % 7]}, ${now.day} ${monthNames[now.month - 1]}';
    
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      expandedHeight: 160,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.settings_outlined,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dateString,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview() {
    final completedTasks = _todos.where((todo) => todo.isCompleted).length;
    final totalTasks = _todos.length;
    final todayTasks = _todos.where((todo) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadline = DateTime(todo.deadline.year, todo.deadline.month, todo.deadline.day);
      return deadline.isAtSameMomentAs(today);
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Tugas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalTasks.toString(),
                  Icons.assignment_outlined,
                  Colors.grey[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Selesai',
                  completedTasks.toString(),
                  Icons.check_circle_outline,
                  const Color(0xFF4A6FA5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Hari Ini',
                  todayTasks.toString(),
                  Icons.today_outlined,
                  Colors.grey[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTodoList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final todo = _todos[index];
            return _buildModernTodoCard(todo, index);
          },
          childCount: _todos.length,
        ),
      ),
    );
  }

  Widget _buildModernTodoCard(TodoModel todo, int index) {
    final isOverdue = todo.deadline.isBefore(DateTime.now()) && !todo.isCompleted;
    final now = DateTime.now();
    final isToday = todo.deadline.year == now.year && 
                   todo.deadline.month == now.month && 
                   todo.deadline.day == now.day;
    
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context, todo);
        } else if (direction == DismissDirection.startToEnd) {
          await _toggleTodoComplete(todo.id);
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF4A6FA5),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Complete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTaskScreen(todo: todo),
                ),
              );
              
              if (result == true) {
                await _loadData();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleTodoComplete(todo.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: todo.isCompleted 
                            ? const Color(0xFF4A6FA5)
                            : Colors.grey[300]!,
                          width: 2,
                        ),
                        color: todo.isCompleted 
                          ? const Color(0xFF4A6FA5)
                          : Colors.transparent,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: todo.isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                              key: ValueKey('checked'),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('unchecked'),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: todo.isCompleted 
                              ? Colors.grey[500]
                              : Colors.black87,
                            decoration: todo.isCompleted 
                              ? TextDecoration.lineThrough
                              : null,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOverdue 
                                  ? Colors.red[50]
                                  : isToday 
                                    ? Colors.orange[50]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_outlined,
                                    size: 16,
                                    color: isOverdue 
                                      ? Colors.red[600]
                                      : isToday 
                                        ? Colors.orange[600]
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDeadline(todo.deadline),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isOverdue 
                                        ? Colors.red[600]
                                        : isToday 
                                          ? Colors.orange[600]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(todo.priority),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
