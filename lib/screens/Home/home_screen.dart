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
  final BulkSelectionManager _selectionManager = BulkSelectionManager();
  List<TodoModel> _todos = [];
  String _userName = 'Pengguna';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _selectionManager.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _selectionManager.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final todos = await _todoRepository.getTodos();
    final userName = await _todoRepository.getUserName();

    if (!mounted) return;
    
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

  Future<void> _duplicateTodo(TodoModel todo) async {
    final newTodo = TodoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${todo.title} (Copy)',
      description: todo.description,
      priority: todo.priority,
      deadline: todo.deadline,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    
    await _todoRepository.addTodo(newTodo);
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task duplicated successfully'),
          backgroundColor: Color(0xFF4A6FA5),
        ),
      );
    }
  }

  void _showBulkActions() {
    final selectedTodos = _selectionManager.getSelectedTodos(_todos);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BulkActionsBottomSheet(
        selectedCount: _selectionManager.selectedCount,
        selectedTodos: selectedTodos,
        onMarkAllCompleted: () async {
          for (final todo in selectedTodos) {
            if (!todo.isCompleted) {
              await _todoRepository.toggleTodoComplete(todo.id);
            }
          }
          _selectionManager.exitSelectionMode();
          await _loadData();
        },
        onMarkAllIncomplete: () async {
          for (final todo in selectedTodos) {
            if (todo.isCompleted) {
              await _todoRepository.toggleTodoComplete(todo.id);
            }
          }
          _selectionManager.exitSelectionMode();
          await _loadData();
        },
        onDeleteAll: () async {
          for (final todo in selectedTodos) {
            await _todoRepository.deleteTodo(todo.id);
          }
          _selectionManager.exitSelectionMode();
          await _loadData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedTodos.length} task${selectedTodos.length > 1 ? 's' : ''} deleted'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onCancel: () {
          _selectionManager.exitSelectionMode();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectionManager.isSelectionMode 
        ? SelectionModeAppBar(
            selectedCount: _selectionManager.selectedCount,
            onCancel: () => _selectionManager.exitSelectionMode(),
            onSelectAll: () => _selectionManager.selectAll(_todos),
            onBulkActions: _showBulkActions,
          )
        : null,
      body: _isLoading
          ? const LoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF4A6FA5),
              backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  if (!_selectionManager.isSelectionMode)
                    ModernAppBar(userName: _userName),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (!_selectionManager.isSelectionMode) ...[
                          DashboardOverviewCard(todos: _todos),
                          const SizedBox(height: 8),
                        ] else ...[
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                  _todos.isEmpty 
                    ? const SliverFillRemaining(child: EmptyState())
                    : TodoList(
                        todos: _todos,
                        onToggleComplete: _toggleTodoComplete,
                        onDeleted: _loadData,
                        selectionManager: _selectionManager,
                        onDuplicate: _duplicateTodo,
                      ),
                ],
              ),
            ),
      floatingActionButton: !_selectionManager.isSelectionMode
        ? AnimatedFab(
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
          )
        : null,
    );
  }
}
