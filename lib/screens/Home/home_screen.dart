import 'package:flutter/material.dart';
import '../../models/todo_model.dart';
import '../../repositories/todo_repository.dart';
import '../add_edit_task_screen.dart';
import 'widgets/widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const LoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4A6FA5),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  ModernAppBar(userName: _userName),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        DashboardOverviewCard(todos: _todos),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  _todos.isEmpty 
                    ? const SliverFillRemaining(child: EmptyState())
                    : TodoList(
                        todos: _todos,
                        onToggleComplete: _toggleTodoComplete,
                        onDeleted: _loadData,
                      ),
                ],
              ),
            ),
      floatingActionButton: AnimatedFab(
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
      ),
    );
  }
}
