import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/BalanceState.dart';

class BalanceNotifier extends StateNotifier<BalanceState> {
  BalanceNotifier()
      : super(BalanceState(balance: 0.0, theyOwe: 0.0, youOwe: 0.0));

  void updateBalance(double balance, double theyOwe, double youOwe) {
    state = state.copyWith(
      balance: balance,
      theyOwe: theyOwe,
      youOwe: youOwe,
    );
  }
}