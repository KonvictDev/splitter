class BalanceState {
  final double balance;
  final double theyOwe;
  final double youOwe;

  BalanceState({
    required this.balance,
    required this.theyOwe,
    required this.youOwe,
  });

  BalanceState copyWith({
    double? balance,
    double? theyOwe,
    double? youOwe,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      theyOwe: theyOwe ?? this.theyOwe,
      youOwe: youOwe ?? this.youOwe,
    );
  }
}