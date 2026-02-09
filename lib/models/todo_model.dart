import 'package:json_annotation/json_annotation.dart';

part 'todo_model.g.dart';

enum TodoPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

@JsonSerializable()
class TodoModel {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final TodoPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TodoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) =>
      _$TodoModelFromJson(json);
  Map<String, dynamic> toJson() => _$TodoModelToJson(this);

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TodoPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
