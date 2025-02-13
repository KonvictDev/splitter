class SplitCalculator {
  final double amount;
  final int contactCount;

  SplitCalculator({
    required this.amount,
    required this.contactCount,
  });

  int get totalParticipants => contactCount + 1;
  double get individualShare => amount / totalParticipants;
  double get individualProgressFraction => 1.0 / totalParticipants;
}