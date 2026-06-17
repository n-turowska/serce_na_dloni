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

  @override
  String toString() {
    return 'PressureEntry(id: $id, systolic: $systolic, diastolic: $diastolic, note: $note, createdAt: $createdAt)';
  }
}
