import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OwedTextWidget extends StatelessWidget {
  final Map<String, dynamic> groupData;
  final String? currentUserPhone;
  final double screenWidth;
  const OwedTextWidget({Key? key, required this.groupData, required this.currentUserPhone, required this.screenWidth}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String ownerName = groupData['groupOwnerName'] ?? 'Group Owner';
    double owedAmount = 0.0;
    if (groupData['splits'] is List) {
      List<dynamic> splitsList = groupData['splits'];
      for (var split in splitsList) {
        if (split is Map<String, dynamic> && split['phoneNumber'] == currentUserPhone) {
          owedAmount = double.tryParse(split['splitAmount'].toString()) ?? 0.0;
          break;
        }
      }
    }
    final double fontSizeOwed = screenWidth * 0.08;
    final double fontSizeLabel = screenWidth * 0.03;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '₹${owedAmount.toStringAsFixed(2)}\n',
                style: TextStyle(fontFamily: 'interSemiBold', fontSize: fontSizeOwed),
              ),
              TextSpan(
                text: 'You owe $ownerName',
                style: TextStyle(color: Colors.red, fontFamily: 'interSemiBold', fontSize: fontSizeLabel),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}