// lib/src/domain/models/quiz_count.dart

sealed class QuizCount {
  const QuizCount();

  /// Factory that parses safely from the DB value.
  /// If the DB sends anything unexpected (null, "7", "AUTO", etc.),
  /// it falls back to Auto — no crash, no silent wrong value.
  factory QuizCount.fromJson(dynamic raw) {
    if (raw == null || raw == 'auto') return const Auto();
    final n = int.tryParse(raw.toString());
    return switch (n) {
      3  => const Fixed(3),
      5  => const Fixed(5),
      10 => const Fixed(10),
      _  => const Auto(),   // safe default for ANY unknown value
    };
  }

  /// Serializes back to the DB format ('auto' or '3'/'5'/'10').
  String toJson() => switch (this) {
    Auto()       => 'auto',
    Fixed(:final count) => count.toString(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return switch (this) {
      Auto() => other is Auto,
      Fixed(:final count) => other is Fixed && other.count == count,
    };
  }

  @override
  int get hashCode => switch (this) {
    Auto() => 'auto'.hashCode,
    Fixed(:final count) => count.hashCode,
  };
}

final class Auto extends QuizCount {
  const Auto();
}

final class Fixed extends QuizCount {
  final int count;   // guaranteed to be 3, 5, or 10
  const Fixed(this.count);
}
