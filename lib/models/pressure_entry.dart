import 'package:uuid/uuid.dart';

class PressureEntry {
  final String id;
  final int systolic;
  final int diastolic;
  final String? note;
  final DateTime createdAt;

  PressureEntry({
    String? id,
    required this.systolic,
    required this.diastolic,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  PressureEntry copyWith({
    String? id,
    int? systolic,
    int? diastolic,
    String? note,
    DateTime? createdAt,
  }) {
    return PressureEntry(
      id: id ?? this.id,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ===========================================================================
  // TODO 1: Implement toMap() and fromMap() for SQLite serialization
  
  Map<String, dynamic> toMap() {
    return{
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  factory PressureEntry.fromMap(Map<String, dynamic> map) {
    return PressureEntry(
      id: map['id'] as String,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // TODO 1: Uncomment and complete:
  //
  // Map<String, dynamic> toMap() {
  //   return {};
  // }
  //
  // factory MoodEntry.fromMap(Map<String, dynamic> map) {
  //   return MoodEntry(score: 0); // Replace with actual implementation
  // }


  @override
  String toString() {
    return 'PressureEntry(id: $id, systolic: $systolic, diastolic: $diastolic, note: $note, createdAt: $createdAt)';
  }
}
