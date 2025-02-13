import 'package:flutter/material.dart';

class ExpenseBottomSheet extends StatefulWidget {
  final String groupName;
  final List<String> avatars;
  final List<dynamic> splits;
  final String? groupId;
  final Future<void> Function(
      double expense,
      List<dynamic> updatedSplits,
      Map<String, String> historyEntry,
      ) onExpenseAdded;

  const ExpenseBottomSheet({
    Key? key,
    required this.groupName,
    required this.avatars,
    required this.splits,
    required this.groupId,
    required this.onExpenseAdded,
  }) : super(key: key);

  @override
  _ExpenseBottomSheetState createState() => _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends State<ExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  /// Helper method to safely parse the expense amount.
  double? _parseExpense(String value) {
    try {
      return double.parse(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Wrap(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle indicator.
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add Expense for ${widget.groupName}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.avatars.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: CircleAvatar(
                            radius: 23,
                            backgroundImage:
                            NetworkImage(widget.avatars[index]),
                            onBackgroundImageError: (_, __) =>
                            const Icon(Icons.person),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expense Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expense amount.';
                      }
                      if (_parseExpense(value) == null) {
                        return 'Invalid amount entered.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Validates input and processes the expense addition.
  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final expense = _parseExpense(_amountController.text)!;
      final int numUsers = widget.splits.length;
      // Include current user in split calculation.
      final double splitShare = expense / (numUsers + 1);

      // Update each split's amount.
      List<dynamic> updatedSplits = widget.splits.map((split) {
        if (split is Map<String, dynamic>) {
          final currentAmount = double.tryParse(
              (split['splitAmount'] ?? '0').toString()) ??
              0.0;
          split['splitAmount'] =
              (currentAmount + splitShare).toStringAsFixed(2);
        }
        return split;
      }).toList();

      // Prepare the history entry.
      final historyEntry = {
        'note': _notesController.text,
        'expense': expense.toStringAsFixed(2),
      };

      // Callback to update the parent state.
      await widget.onExpenseAdded(expense, updatedSplits, historyEntry);
      Navigator.pop(context);
    }
  }
}
