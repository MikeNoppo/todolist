import 'package:flutter/material.dart';
import '../../models/todo_model.dart';
import '../../repositories/todo_repository.dart';
import '../../services/app_logger.dart';
import '../add_edit_task_screen.dart';
import 'widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _tag = 'HomeScreen';

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

    try {
      final todos = await _todoRepository.getTodos();
      final userName = await _todoRepository.getUserName();

      AppLogger.debug(
        _tag,
        'Loaded home data: todos=${todos.length}, hasUserName=${(userName ?? '').isNotEmpty}',
      );

      if (!mounted) return;

      setState(() {
        _todos = todos;
        _userName = userName ?? 'Pengguna';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to load home data.',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat data tugas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleTodoComplete(String todoId) async {
    try {
      await _todoRepository.toggleTodoComplete(todoId);
      AppLogger.info(_tag, 'Toggled task completion: id=$todoId');
      await _loadData();
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to toggle task completion: id=$todoId',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status tugas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _duplicateTodo(TodoModel todo) async {
    try {
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
      AppLogger.info(_tag, 'Duplicated task: sourceId=${todo.id}');
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task duplicated successfully'),
          backgroundColor: Color(0xFF4A6FA5),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to duplicate task: sourceId=${todo.id}',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menduplikasi tugas'),
          backgroundColor: Colors.red,
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
          try {
            int updatedCount = 0;
            for (final todo in selectedTodos) {
              if (!todo.isCompleted) {
                await _todoRepository.toggleTodoComplete(todo.id);
                updatedCount++;
              }
            }

            AppLogger.info(
              _tag,
              'Bulk mark complete finished: updated=$updatedCount selected=${selectedTodos.length}',
            );

            _selectionManager.exitSelectionMode();
            await _loadData();
          } catch (e, stackTrace) {
            AppLogger.error(
              _tag,
              'Failed bulk mark complete action.',
              error: e,
              stackTrace: stackTrace,
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menandai semua tugas selesai'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onMarkAllIncomplete: () async {
          try {
            int updatedCount = 0;
            for (final todo in selectedTodos) {
              if (todo.isCompleted) {
                await _todoRepository.toggleTodoComplete(todo.id);
                updatedCount++;
              }
            }

            AppLogger.info(
              _tag,
              'Bulk mark incomplete finished: updated=$updatedCount selected=${selectedTodos.length}',
            );

            _selectionManager.exitSelectionMode();
            await _loadData();
          } catch (e, stackTrace) {
            AppLogger.error(
              _tag,
              'Failed bulk mark incomplete action.',
              error: e,
              stackTrace: stackTrace,
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menandai semua tugas belum selesai'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onDeleteAll: () async {
          try {
            int deletedCount = 0;
            for (final todo in selectedTodos) {
              await _todoRepository.deleteTodo(todo.id);
              deletedCount++;
            }

            AppLogger.info(
              _tag,
              'Bulk delete finished: deleted=$deletedCount selected=${selectedTodos.length}',
            );

            _selectionManager.exitSelectionMode();
            await _loadData();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$deletedCount task${deletedCount > 1 ? 's' : ''} deleted',
                ),
                backgroundColor: Colors.red,
              ),
            );
          } catch (e, stackTrace) {
            AppLogger.error(
              _tag,
              'Failed bulk delete action.',
              error: e,
              stackTrace: stackTrace,
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menghapus tugas terpilih'),
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

                AppLogger.debug(
                  _tag,
                  'Add task screen returned: result=$result',
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
