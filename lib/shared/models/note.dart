import 'package:uuid/uuid.dart';

class NoteItem {
  final String id;
  final String text;
  final DateTime date;

  NoteItem({String? id, required this.text, required this.date}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'date': date.toIso8601String(),
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as String?,
        text: json['text'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

