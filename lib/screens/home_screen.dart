import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../repositories/todo_repository.dart';
import 'add_edit_task_screen.dart';

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

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return const Color(0xFF4A6FA5); // Muted blue accent
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // User Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Greeting
            Text(
              'Halo, $_userName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to settings
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? _buildEmptyState()
              : _buildTodoList(),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambah tugas pertama',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        return _buildTodoCard(todo);
      },
    );
  }

  Widget _buildTodoCard(TodoModel todo) {
    final isOverdue = todo.deadline.isBefore(DateTime.now()) && !todo.isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => _toggleTodoComplete(todo.id),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: todo.isCompleted 
                        ? const Color(0xFF4A6FA5)
                        : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: todo.isCompleted 
                      ? const Color(0xFF4A6FA5)
                      : Colors.transparent,
                  ),
                  child: todo.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // Task Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: todo.isCompleted 
                          ? Colors.grey[500]
                          : Colors.black87,
                        decoration: todo.isCompleted 
                          ? TextDecoration.lineThrough
                          : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Deadline with icon
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: isOverdue 
                            ? Colors.red[400]
                            : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDeadline(todo.deadline),
                          style: TextStyle(
                            fontSize: 14,
                            color: isOverdue 
                              ? Colors.red[400]
                              : Colors.grey[600],
                            fontWeight: isOverdue 
                              ? FontWeight.w500
                              : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Priority indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPriorityColor(todo.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
