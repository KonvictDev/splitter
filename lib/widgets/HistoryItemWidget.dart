import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HistoryItemWidget extends StatelessWidget {
  final String note;
  final String expense;
  final String formattedDate;
  const HistoryItemWidget({Key? key, required this.note, required this.expense, required this.formattedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note,
                style: const TextStyle(fontFamily: 'interBold', fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount: ₹$expense',
                style: TextStyle(fontFamily: 'interSemiBold', fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Date: $formattedDate',
                style: TextStyle(fontFamily: 'interRegular', fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}