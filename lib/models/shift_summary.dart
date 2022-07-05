class ShiftSummary {
  final int? createdAt, closedAt, plannedDuration;
  bool forcedShiftEnd = false;
  int rating = 0;

  ShiftSummary(
      {this.createdAt,
      this.closedAt,
      this.plannedDuration,
      required this.forcedShiftEnd});

  ShiftSummary.fromMap(Map<String, dynamic> map)
      : createdAt = map['createdAt'] as int,
        closedAt = map['closedAt'] as int,
        plannedDuration =
            (map['plannedClosedAt'] as int) - (map['createdAt'] as int);
}
