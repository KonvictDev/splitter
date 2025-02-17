import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GroupCard extends StatelessWidget {
  final String groupName;
  final double owedAmount;
  final List<String> avatars;
  final bool isGroupOwner;
  final VoidCallback onAddExpense;

  const GroupCard({
    Key? key,
    required this.groupName,
    required this.owedAmount,
    required this.avatars,
    required this.isGroupOwner,
    required this.onAddExpense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Wrap(
                  spacing: -10,
                  children: avatars.map((avatar) {
                    return CircleAvatar(
                      radius: 23,
                      backgroundImage: NetworkImage(avatar),
                      onBackgroundImageError: (_, __) => const Icon(Icons.person),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 23,
                    backgroundImage: const AssetImage('assets/logo/Splitzo.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              groupName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroupOwner ? 'They owe' : 'You owe',
                      style: const TextStyle(fontSize: 12),
                    ),

                    Text(
                      '\$${owedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                if (isGroupOwner)
                  TextButton.icon(
                    onPressed: onAddExpense,
                    icon: const Icon(Icons.add, color: Color(0xFF27BDB5)),
                    label: const Text('Add Expense', style: TextStyle(color: Color(0xFF27BDB5))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}