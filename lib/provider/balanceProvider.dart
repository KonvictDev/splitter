import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/BalanceState.dart';
import '../notifier/BalanceNotifier.dart';

final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>(
      (ref) => BalanceNotifier(),
);
